import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type StartSurahRequest = {
  child_id: string;
  surah_id: number;
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

const galaxyUnlocked = async (childId: string, galaxyId: number): Promise<boolean> => {
  if (galaxyId <= 1) {
    return true;
  }

  const { data: prevRow, error: prevError } = await supabaseAdmin
    .from("child_galaxy_state")
    .select("completed_at")
    .eq("child_id", childId)
    .eq("galaxy_id", galaxyId - 1)
    .maybeSingle();

  if (prevError) {
    throw new Error("Failed to load galaxy state");
  }

  return !!prevRow?.completed_at;
};

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

    const payload = (await req.json()) as Partial<StartSurahRequest>;
    const childId = payload.child_id;
    const surahId = payload.surah_id;

    if (typeof childId !== "string" || typeof surahId !== "number") {
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

    // Ensure Galaxy 1 is unlocked row exists for this child.
    await supabaseAdmin.from("child_galaxy_state").upsert(
      {
        child_id: childId,
        galaxy_id: 1,
        unlocked: true,
        updated_at: nowIso(),
      },
      { onConflict: "child_id,galaxy_id" },
    );

    const { data: galaxyRow, error: galaxyError } = await supabaseAdmin
      .from("galaxy_surahs")
      .select("galaxy_id")
      .eq("surah_id", surahId)
      .maybeSingle();

    if (galaxyError || !galaxyRow) {
      return jsonResponse(400, { error: "Surah not mapped to a galaxy" });
    }

    const galaxyId = galaxyRow.galaxy_id as number;
    const unlocked = await galaxyUnlocked(childId, galaxyId);
    if (!unlocked) {
      return jsonResponse(409, {
        error: "Galaxy locked",
        galaxy_id: galaxyId,
        required_galaxy_id: galaxyId - 1,
      });
    }

    // Mark this galaxy unlocked for the child.
    await supabaseAdmin.from("child_galaxy_state").upsert(
      {
        child_id: childId,
        galaxy_id: galaxyId,
        unlocked: true,
        updated_at: nowIso(),
      },
      { onConflict: "child_id,galaxy_id" },
    );

    // Require the surah to be "playable" (levels exist), otherwise surface "coming soon".
    const { count: levelCount, error: levelCountError } = await supabaseAdmin
      .from("levels")
      .select("id", { count: "exact", head: true })
      .eq("surah_id", surahId);

    if (levelCountError) {
      return jsonResponse(500, { error: "Failed to inspect levels" });
    }

    if ((levelCount ?? 0) <= 0) {
      return jsonResponse(409, { error: "Content not available yet" });
    }

    const { data: existingState, error: stateError } = await supabaseAdmin
      .from("child_surah_state")
      .select("status, active_slot, completed_at, started_at")
      .eq("child_id", childId)
      .eq("surah_id", surahId)
      .maybeSingle();

    if (stateError) {
      return jsonResponse(500, { error: "Failed to load surah state" });
    }

    if (existingState?.status === "COMPLETED") {
      return jsonResponse(200, {
        child_id: childId,
        surah_id: surahId,
        status: "COMPLETED",
        galaxy_id: galaxyId,
      });
    }

    if (existingState?.status === "ACTIVE") {
      return jsonResponse(200, {
        child_id: childId,
        surah_id: surahId,
        status: "ACTIVE",
        active_slot: existingState.active_slot,
        galaxy_id: galaxyId,
      });
    }

    const { data: activeRows, error: activeError } = await supabaseAdmin
      .from("child_surah_state")
      .select("surah_id, active_slot")
      .eq("child_id", childId)
      .eq("status", "ACTIVE");

    if (activeError) {
      return jsonResponse(500, { error: "Failed to load active surahs" });
    }

    const usedSlots = new Set<number>();
    for (const row of (activeRows ?? []) as Array<{ active_slot: number | null }>) {
      if (typeof row.active_slot === "number") {
        usedSlots.add(row.active_slot);
      }
    }

    const activeCount = (activeRows ?? []).length;
    if (activeCount >= 3) {
      return jsonResponse(409, {
        error: "No active slots available",
        active_count: activeCount,
      });
    }

    const slot = [1, 2, 3].find((value) => !usedSlots.has(value)) ?? null;
    const startedAt = existingState?.started_at ?? nowIso();

    await supabaseAdmin.from("child_surah_state").upsert(
      {
        child_id: childId,
        surah_id: surahId,
        status: "ACTIVE",
        active_slot: slot,
        started_at: startedAt,
        updated_at: nowIso(),
      },
      { onConflict: "child_id,surah_id" },
    );

    // Initialize level progress for this surah (idempotent; do not overwrite existing rows).
    const { data: levels, error: levelsError } = await supabaseAdmin
      .from("levels")
      .select("id, order_index")
      .eq("surah_id", surahId)
      .order("order_index", { ascending: true });

    if (levelsError) {
      return jsonResponse(500, { error: "Failed to load levels" });
    }

    const progressRows = (levels ?? []).map((level) => ({
      child_id: childId,
      level_id: level.id,
      status: level.order_index === 1 ? "UNLOCKED" : "LOCKED",
      updated_at: nowIso(),
    }));

    if (progressRows.length > 0) {
      const { error: initError } = await supabaseAdmin
        .from("child_level_progress")
        .upsert(progressRows, {
          onConflict: "child_id,level_id",
          ignoreDuplicates: true,
        });

      if (initError) {
        return jsonResponse(500, { error: "Failed to initialize level progress" });
      }
    }

    return jsonResponse(200, {
      child_id: childId,
      surah_id: surahId,
      status: "ACTIVE",
      active_slot: slot,
      galaxy_id: galaxyId,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
