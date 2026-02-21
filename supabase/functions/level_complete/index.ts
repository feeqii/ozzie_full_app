import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type LevelCompleteRequest = {
  child_id: string;
  level_id: string;
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

    const payload = (await req.json()) as Partial<LevelCompleteRequest>;
    const childId = payload.child_id;
    const levelId = payload.level_id;
    if (typeof childId !== "string" || typeof levelId !== "string") {
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

    const { data: levelRow, error: levelError } = await supabaseAdmin
      .from("levels")
      .select("id, surah_id, type, order_index")
      .eq("id", levelId)
      .maybeSingle();

    if (levelError || !levelRow) {
      return jsonResponse(404, { error: "Level not found" });
    }

    // Guard against bypassing gated lesson/quiz progression via generic completion.
    if ((levelRow.type as string) !== "SURAH_INTRO") {
      return jsonResponse(409, {
        error: "Use lesson or quiz completion endpoints for this level type",
      });
    }

    const { data: progressRow, error: progressError } = await supabaseAdmin
      .from("child_level_progress")
      .select("status, locked_until")
      .eq("child_id", childId)
      .eq("level_id", levelId)
      .maybeSingle();

    if (progressError || !progressRow) {
      return jsonResponse(400, { error: "Level not initialized for child" });
    }

    const lockedUntil = progressRow.locked_until ? new Date(progressRow.locked_until as string) : null;
    if (lockedUntil && lockedUntil.getTime() > Date.now()) {
      return jsonResponse(409, {
        error: "Level locked",
        locked_until: lockedUntil.toISOString(),
      });
    }

    const status = progressRow.status as string;
    if (status === "LOCKED") {
      return jsonResponse(409, { error: "Level is locked" });
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
        return jsonResponse(500, { error: "Failed to complete level" });
      }
    }

    const surahId = levelRow.surah_id as number;
    const orderIndex = levelRow.order_index as number;

    const { data: nextLevel, error: nextError } = await supabaseAdmin
      .from("levels")
      .select("id, type, order_index")
      .eq("surah_id", surahId)
      .eq("order_index", orderIndex + 1)
      .maybeSingle();

    if (nextError) {
      return jsonResponse(500, { error: "Failed to load next level" });
    }

    if (nextLevel) {
      // Unlock next level only if currently locked.
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

    return jsonResponse(200, {
      child_id: childId,
      level_id: levelId,
      completed: true,
      next_level_id: nextLevel?.id ?? null,
      next_level_type: nextLevel?.type ?? null,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
