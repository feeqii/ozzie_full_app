import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type MapStateRequest = {
  child_id: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

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
    const token = authHeader.replace("Bearer ", "");
    if (!token) {
      return jsonResponse(401, { error: "Missing bearer token" });
    }

    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !authData?.user) {
      return jsonResponse(401, { error: "Invalid auth token" });
    }

    const payload = (await req.json()) as Partial<MapStateRequest>;
    const childId = payload.child_id;
    if (typeof childId !== "string" || childId.length === 0) {
      return jsonResponse(400, { error: "Missing child_id" });
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

    // Ensure Galaxy 1 is unlocked for this child (idempotent).
    await supabaseAdmin.from("child_galaxy_state").upsert(
      {
        child_id: childId,
        galaxy_id: 1,
        unlocked: true,
        updated_at: nowIso(),
      },
      { onConflict: "child_id,galaxy_id" },
    );

    const [{ data: galaxies, error: galaxiesError }, { data: surahStates, error: surahStatesError }, {
      data: galaxyStates,
      error: galaxyStatesError,
    }, { data: playableLevels, error: playableError }] = await Promise.all([
      supabaseAdmin
        .from("galaxies")
        .select("id, name_en, name_ar, order_index")
        .order("order_index", { ascending: true }),
      supabaseAdmin
        .from("child_surah_state")
        .select("surah_id, status, active_slot, started_at, completed_at")
        .eq("child_id", childId),
      supabaseAdmin
        .from("child_galaxy_state")
        .select("galaxy_id, unlocked, completed_at")
        .eq("child_id", childId),
      supabaseAdmin.from("levels").select("surah_id").order("surah_id", { ascending: true }),
    ]);

    if (galaxiesError) {
      return jsonResponse(500, { error: "Failed to load galaxies" });
    }
    if (surahStatesError) {
      return jsonResponse(500, { error: "Failed to load surah state" });
    }
    if (galaxyStatesError) {
      return jsonResponse(500, { error: "Failed to load galaxy state" });
    }
    if (playableError) {
      return jsonResponse(500, { error: "Failed to load levels" });
    }

    const stateBySurahId = new Map<number, Record<string, unknown>>();
    const activeSlotsUsed = new Set<number>();
    let activeCount = 0;
    for (const row of (surahStates ?? []) as Array<Record<string, unknown>>) {
      const surahId = row.surah_id as number;
      stateBySurahId.set(surahId, row);
      if (row.status === "ACTIVE") {
        activeCount += 1;
        const slot = row.active_slot;
        if (typeof slot === "number") {
          activeSlotsUsed.add(slot);
        }
      }
    }

    const slotsRemaining = Math.max(0, 3 - activeCount);

    const playableSet = new Set<number>();
    for (const row of (playableLevels ?? []) as Array<Record<string, unknown>>) {
      const surahId = row.surah_id as number;
      if (typeof surahId === "number") {
        playableSet.add(surahId);
      }
    }

    const galaxyStateById = new Map<number, Record<string, unknown>>();
    for (const row of (galaxyStates ?? []) as Array<Record<string, unknown>>) {
      galaxyStateById.set(row.galaxy_id as number, row);
    }

    const galaxySurahRowsByGalaxy = new Map<number, Array<Record<string, unknown>>>();
    const { data: galaxySurahs, error: galaxySurahsError } = await supabaseAdmin
      .from("galaxy_surahs")
      .select("galaxy_id, order_index, surah_id, surahs (id, name, translation, ayah_count)")
      .order("galaxy_id", { ascending: true })
      .order("order_index", { ascending: true });

    if (galaxySurahsError) {
      return jsonResponse(500, { error: "Failed to load galaxy surahs" });
    }

    for (const row of (galaxySurahs ?? []) as Array<Record<string, unknown>>) {
      const galaxyId = row.galaxy_id as number;
      const list = galaxySurahRowsByGalaxy.get(galaxyId) ?? [];
      list.push(row);
      galaxySurahRowsByGalaxy.set(galaxyId, list);
    }

    const resolvedGalaxies = (galaxies ?? []).map((galaxy) => {
      const galaxyId = galaxy.id as number;
      const previousCompleted = galaxyId <= 1
        ? true
        : !!galaxyStateById.get(galaxyId - 1)?.completed_at;
      const unlocked = galaxyId <= 1 ? true : previousCompleted;

      const surahs = (galaxySurahRowsByGalaxy.get(galaxyId) ?? []).map((item) => {
        const surah = item.surahs as Record<string, unknown> | null;
        const surahId = item.surah_id as number;
        const state = stateBySurahId.get(surahId) ?? null;

        const status = (state?.status as string | undefined) ?? "NOT_STARTED";
        const playable = playableSet.has(surahId);
        const lockedBySlots = status === "NOT_STARTED" && activeCount >= 3;
        const lockedByGalaxy = !unlocked;
        const lockedByComingSoon = !playable;

        const locked = lockedByGalaxy || lockedBySlots || lockedByComingSoon;
        let lockReason: string | null = null;
        if (lockedByGalaxy) lockReason = "GALAXY_LOCKED";
        else if (lockedBySlots) lockReason = "NO_SLOTS";
        else if (lockedByComingSoon) lockReason = "COMING_SOON";

        return {
          id: surahId,
          order_index: item.order_index,
          name: surah?.name ?? `Surah ${surahId}`,
          translation: surah?.translation ?? "",
          ayah_count: surah?.ayah_count ?? null,
          status,
          active_slot: state?.active_slot ?? null,
          locked,
          lock_reason: lockReason,
          playable,
        };
      });

      const completed = surahs.length > 0 && surahs.every((s) => s.status === "COMPLETED");

      return {
        id: galaxyId,
        name_en: galaxy.name_en,
        name_ar: galaxy.name_ar,
        order_index: galaxy.order_index,
        unlocked,
        completed,
        surahs,
      };
    });

    return jsonResponse(200, {
      child_id: childId,
      active_count: activeCount,
      slots_remaining: slotsRemaining,
      galaxies: resolvedGalaxies,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});

