import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type AyahLessonCompleteRequest = {
  child_id: string;
  surah_id: number;
  ayah_id: number;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-user-jwt, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("Missing SUPABASE_URL or service role key");
}

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

const jsonResponse = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });

const nowIso = () => new Date().toISOString();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const bearerToken = authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length).trim()
      : "";
    const userJwtHeader = req.headers.get("x-user-jwt") ?? "";
    const userToken = userJwtHeader.startsWith("Bearer ")
      ? userJwtHeader.slice("Bearer ".length).trim()
      : userJwtHeader.trim();
    const token = userToken || (bearerToken && bearerToken !== supabaseAnonKey ? bearerToken : "");
    if (!token) {
      return jsonResponse(401, { error: "Missing user auth token" });
    }

    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !authData?.user) {
      return jsonResponse(401, { error: "Invalid auth token" });
    }

    const payload = (await req.json()) as Partial<AyahLessonCompleteRequest>;
    const childId = payload.child_id;
    const surahId = payload.surah_id;
    const ayahId = payload.ayah_id;

    if (typeof childId !== "string" || typeof surahId !== "number" || typeof ayahId !== "number") {
      return jsonResponse(400, { error: "Missing required fields" });
    }

    const { data: childRow, error: childError } = await supabaseAdmin
      .from("children")
      .select("id, parent_id")
      .eq("id", childId)
      .maybeSingle();

    if (childError || !childRow) {
      return jsonResponse(404, { error: "Child not found" });
    }

    if (childRow.parent_id !== authData.user.id) {
      return jsonResponse(403, { error: "Forbidden" });
    }

    const { data: settingsRow } = await supabaseAdmin
      .from("child_settings")
      .select("passes_required")
      .eq("child_id", childId)
      .maybeSingle();

    const passesRequired = (settingsRow?.passes_required as number | undefined) ?? 3;

    const { data: ayahRow, error: ayahError } = await supabaseAdmin
      .from("ayah_progress")
      .select("pass_count_total, mastered_at")
      .eq("child_id", childId)
      .eq("surah_id", surahId)
      .eq("ayah_id", ayahId)
      .maybeSingle();

    if (ayahError) {
      return jsonResponse(500, { error: "Failed to load ayah progress" });
    }

    const passCountTotal = (ayahRow?.pass_count_total as number | undefined) ?? 0;
    const masteredAt = ayahRow?.mastered_at as string | null | undefined;
    const isMastered = !!masteredAt || passCountTotal >= passesRequired;
    if (!isMastered) {
      return jsonResponse(409, {
        error: "Recitation mastery required before lesson completion",
      });
    }

    const { data: levelRow, error: levelError } = await supabaseAdmin
      .from("levels")
      .select("id, surah_id, type, order_index")
      .eq("surah_id", surahId)
      .eq("type", "VERSE_LESSON")
      .eq("ayah_id", ayahId)
      .maybeSingle();

    if (levelError || !levelRow?.id) {
      return jsonResponse(409, { error: "Lesson level not available" });
    }

    const levelId = levelRow.id as string;
    const levelOrderIndex = levelRow.order_index as number;

    const { data: progressRow, error: progressError } = await supabaseAdmin
      .from("child_level_progress")
      .select("status, locked_until")
      .eq("child_id", childId)
      .eq("level_id", levelId)
      .maybeSingle();

    if (progressError || !progressRow) {
      return jsonResponse(400, { error: "Level not initialized for child" });
    }

    const status = (progressRow.status as string | undefined) ?? "LOCKED";
    if (status === "LOCKED") {
      return jsonResponse(409, { error: "Level is locked" });
    }

    const lockedUntil = progressRow.locked_until ? new Date(progressRow.locked_until as string) : null;
    if (lockedUntil && lockedUntil.getTime() > Date.now()) {
      return jsonResponse(409, {
        error: "Level locked",
        locked_until: lockedUntil.toISOString(),
      });
    }

    if (status !== "COMPLETED") {
      const { error: updateError } = await supabaseAdmin
        .from("child_level_progress")
        .update({
          status: "COMPLETED",
          completed_at: nowIso(),
          updated_at: nowIso(),
        })
        .eq("child_id", childId)
        .eq("level_id", levelId);

      if (updateError) {
        return jsonResponse(500, { error: "Failed to complete lesson level" });
      }
    }

    const { data: nextLevel, error: nextLevelError } = await supabaseAdmin
      .from("levels")
      .select("id, type, ayah_id, config")
      .eq("surah_id", surahId)
      .eq("order_index", levelOrderIndex + 1)
      .maybeSingle();

    if (nextLevelError) {
      return jsonResponse(500, { error: "Failed to load next level" });
    }

    if (nextLevel?.id) {
      await supabaseAdmin
        .from("child_level_progress")
        .update({
          status: "UNLOCKED",
          updated_at: nowIso(),
        })
        .eq("child_id", childId)
        .eq("level_id", nextLevel.id)
        .eq("status", "LOCKED");
    }

    let nextGate: string | null = null;
    let nextAyahId: number | null = null;

    if (nextLevel?.type === "CHECKPOINT") {
      const quizType = (nextLevel.config as Record<string, unknown> | null)?.quiz_type;
      if (quizType === "mini_1") {
        nextGate = "MINI_QUIZ_1";
      } else if (quizType === "mini_2") {
        nextGate = "MINI_QUIZ_2";
      }
    } else if (nextLevel?.type === "FINAL_EXAM") {
      nextGate = "FINAL_EXAM";
    } else if (nextLevel?.type === "VERSE_LESSON") {
      nextAyahId = (nextLevel.ayah_id as number | undefined) ?? null;
    }

    const { data: surahRow, error: surahError } = await supabaseAdmin
      .from("surah_progress")
      .select("stage, unlocked_ayah_max")
      .eq("child_id", childId)
      .eq("surah_id", surahId)
      .maybeSingle();

    if (surahError) {
      return jsonResponse(500, { error: "Failed to load surah progress" });
    }

    const baseStage = (surahRow?.stage as string | undefined) ?? "LEARN_1_2";
    const baseUnlocked = (surahRow?.unlocked_ayah_max as number | undefined) ?? 1;

    let updatedStage = baseStage;
    if (nextGate === "MINI_QUIZ_1") {
      updatedStage = "MINI_QUIZ_1";
    } else if (nextGate === "MINI_QUIZ_2") {
      updatedStage = "MINI_QUIZ_2";
    } else if (nextGate === "FINAL_EXAM") {
      updatedStage = "FINAL_EXAM";
    }

    await supabaseAdmin.from("surah_progress").upsert({
      child_id: childId,
      surah_id: surahId,
      stage: updatedStage,
      unlocked_ayah_max: Math.max(baseUnlocked, ayahId + 1),
      updated_at: nowIso(),
    });

    return jsonResponse(200, {
      child_id: childId,
      surah_id: surahId,
      ayah_id: ayahId,
      level_id: levelId,
      completed: true,
      next_level_id: (nextLevel?.id as string | undefined) ?? null,
      next_level_type: (nextLevel?.type as string | undefined) ?? null,
      nextAyahId,
      nextGate,
    });
  } catch (error) {
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unexpected error",
    });
  }
});
