import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type RecitationRequest = {
  child_id: string;
  surah_id: number;
  ayah_id: number;
  audio_path: string;
  score?: number;
  transcript?: string | null;
  model?: string | null;
  meta?: Record<string, unknown> | null;
};

type ScoringResponse = {
  score: number;
  passed?: boolean;
  transcript?: string | null;
  mistake_type?: string | null;
  meta?: Record<string, unknown> | null;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const scoringUrl = Deno.env.get("SCORING_API_URL");
const scoringApiKey = Deno.env.get("SCORING_API_KEY");

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

const toDateString = (date: Date) => date.toISOString().slice(0, 10);

const startOfTomorrowUtc = (date: Date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1));

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

    const payload = (await req.json()) as RecitationRequest;
    const { child_id, surah_id, ayah_id, audio_path } = payload ?? {};

    if (!child_id || !surah_id || !ayah_id || !audio_path) {
      return jsonResponse(400, { error: "Missing required fields" });
    }

    const { data: childRow, error: childError } = await supabaseAdmin
      .from("children")
      .select("id, parent_id")
      .eq("id", child_id)
      .maybeSingle();

    if (childError || !childRow) {
      return jsonResponse(404, { error: "Child not found" });
    }

    if (childRow.parent_id !== authData.user.id) {
      return jsonResponse(403, { error: "Forbidden" });
    }

    const { data: settingsRow } = await supabaseAdmin
      .from("child_settings")
      .select("daily_attempt_cap, realtime_feedback_cap, passes_required, pass_threshold, blur_after_attempt")
      .eq("child_id", child_id)
      .maybeSingle();

    const dailyAttemptCap = settingsRow?.daily_attempt_cap ?? 6;
    const realtimeFeedbackCap = settingsRow?.realtime_feedback_cap ?? 3;
    const passesRequired = settingsRow?.passes_required ?? 3;
    const passThreshold = settingsRow?.pass_threshold ?? 80;
    const blurAfterAttempt = settingsRow?.blur_after_attempt ?? null;

    const today = toDateString(new Date());

    const { data: ayahRow, error: ayahError } = await supabaseAdmin
      .from("ayah_progress")
      .select(
        "child_id, surah_id, ayah_id, pass_count_total, attempts_today, attempts_date, consecutive_fails, mastered_at, locked_until"
      )
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("ayah_id", ayah_id)
      .maybeSingle();

    if (ayahError) {
      return jsonResponse(500, { error: "Failed to load ayah progress" });
    }

    const baseAyah = ayahRow ?? {
      child_id,
      surah_id,
      ayah_id,
      pass_count_total: 0,
      attempts_today: 0,
      attempts_date: today,
      consecutive_fails: 0,
      mastered_at: null,
      locked_until: null,
    };

    let attemptsToday = baseAyah.attempts_today ?? 0;
    let attemptsDate = baseAyah.attempts_date ?? today;

    if (attemptsDate !== today) {
      attemptsToday = 0;
      attemptsDate = today;

      await supabaseAdmin
        .from("ayah_progress")
        .upsert({
          child_id,
          surah_id,
          ayah_id,
          attempts_today: 0,
          attempts_date: today,
          updated_at: new Date().toISOString(),
        });
    }

    const lockedUntil = baseAyah.locked_until ? new Date(baseAyah.locked_until) : null;
    if (lockedUntil && lockedUntil.getTime() > Date.now()) {
      return jsonResponse(200, {
        locked_until: lockedUntil.toISOString(),
        attemptsToday,
        attemptsLeftToday: 0,
      });
    }

    if (attemptsToday >= dailyAttemptCap) {
      const newLockedUntil = startOfTomorrowUtc(new Date());
      await supabaseAdmin
        .from("ayah_progress")
        .upsert({
          child_id,
          surah_id,
          ayah_id,
          locked_until: newLockedUntil.toISOString(),
          attempts_date: today,
          updated_at: new Date().toISOString(),
        });

      return jsonResponse(200, {
        locked_until: newLockedUntil.toISOString(),
        attemptsToday,
        attemptsLeftToday: 0,
      });
    }

    const todayStart = new Date(`${today}T00:00:00.000Z`);
    const tomorrowStart = startOfTomorrowUtc(new Date());

    const { count: detailedUsedToday } = await supabaseAdmin
      .from("recitation_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("detailed_feedback_used", true)
      .gte("created_at", todayStart.toISOString())
      .lt("created_at", tomorrowStart.toISOString());

    const allowDetailedFeedback = (detailedUsedToday ?? 0) < realtimeFeedbackCap;

    const clientScore = typeof payload?.score === "number" ? Number(payload.score) : null;
    const clientTranscript = payload?.transcript ?? null;
    const clientModel = payload?.model ?? null;
    const clientMeta = payload?.meta ?? null;

    let scoreSource = "server";
    let score = 0;
    let passed = false;
    let transcript: string | null = clientTranscript;
    let mistakeType: string | null = null;
    let meta: Record<string, unknown> | null = null;

    if (clientScore !== null && Number.isFinite(clientScore)) {
      scoreSource = "client";
      score = Math.max(0, Math.min(100, clientScore));
      passed = score >= passThreshold;
      meta = clientMeta;
    } else {
      if (!scoringUrl) {
        return jsonResponse(500, { error: "SCORING_API_URL is not configured" });
      }

      const scoringResponse = await fetch(scoringUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(scoringApiKey ? { Authorization: `Bearer ${scoringApiKey}` } : {}),
        },
        body: JSON.stringify({
          audio_path,
          surah_id,
          ayah_id,
          child_id,
        }),
      });

      if (!scoringResponse.ok) {
        return jsonResponse(502, { error: "Scoring service failed" });
      }

      const scoringPayload = (await scoringResponse.json()) as ScoringResponse;
      score = Math.max(0, Math.min(100, Number(scoringPayload.score ?? 0)));
      passed =
        typeof scoringPayload.passed === "boolean" ? scoringPayload.passed : score >= passThreshold;
      transcript = scoringPayload.transcript ?? transcript;
      mistakeType = scoringPayload.mistake_type ?? null;
      meta = scoringPayload.meta ?? null;
    }

    const combinedMeta: Record<string, unknown> = {
      ...(meta ?? {}),
      ...(clientMeta ?? {}),
      score_source: scoreSource,
      ...(clientModel ? { model: clientModel } : {}),
    };

    const attemptNumberToday = attemptsToday + 1;

    const { error: insertAttemptError } = await supabaseAdmin.from("recitation_attempts").insert({
      child_id,
      surah_id,
      ayah_id,
      attempt_number_today: attemptNumberToday,
      score,
      passed,
      detailed_feedback_used: allowDetailedFeedback,
      mistake_type: mistakeType,
      audio_path,
      transcript: transcript ?? null,
      meta: combinedMeta,
    });

    if (insertAttemptError) {
      return jsonResponse(500, { error: "Failed to log attempt" });
    }

    const newPassCountTotal = (baseAyah.pass_count_total ?? 0) + (passed ? 1 : 0);
    const newConsecutiveFails = passed ? 0 : (baseAyah.consecutive_fails ?? 0) + 1;
    const ayahMasteredNow = !baseAyah.mastered_at && newPassCountTotal >= passesRequired;
    const masteredAt = ayahMasteredNow ? new Date().toISOString() : baseAyah.mastered_at;

    const { error: updateAyahError } = await supabaseAdmin
      .from("ayah_progress")
      .upsert({
        child_id,
        surah_id,
        ayah_id,
        pass_count_total: newPassCountTotal,
        attempts_today: attemptNumberToday,
        attempts_date: today,
        consecutive_fails: newConsecutiveFails,
        mastered_at: masteredAt,
        last_score: score,
        updated_at: new Date().toISOString(),
      });

    if (updateAyahError) {
      return jsonResponse(500, { error: "Failed to update ayah progress" });
    }

    let nextGate: string | null = null;

    const { data: surahRow, error: surahError } = await supabaseAdmin
      .from("surah_progress")
      .select("child_id, surah_id, stage, unlocked_ayah_max")
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .maybeSingle();

    if (surahError) {
      return jsonResponse(500, { error: "Failed to load surah progress" });
    }

    const surahBase = surahRow ?? {
      child_id,
      surah_id,
      stage: "LEARN_1_2",
      unlocked_ayah_max: 1,
    };

    let updatedStage = surahBase.stage;
    let updatedUnlockedAyah = Math.max(surahBase.unlocked_ayah_max ?? 1, ayah_id + 1);

    if (ayahMasteredNow) {
      if (ayah_id === 2 && surahBase.stage === "LEARN_1_2") {
        updatedStage = "MINI_QUIZ_1";
        nextGate = "MINI_QUIZ_1";
      }

      if (ayah_id === 4 && surahBase.stage === "LEARN_3_4") {
        updatedStage = "MINI_QUIZ_2";
        nextGate = "MINI_QUIZ_2";
      }
    }

    await supabaseAdmin.from("surah_progress").upsert({
      child_id,
      surah_id,
      stage: updatedStage,
      unlocked_ayah_max: updatedUnlockedAyah,
      updated_at: new Date().toISOString(),
    });

    const { data: streakRow } = await supabaseAdmin
      .from("streaks")
      .select("child_id, current_streak, best_streak, last_practice_date")
      .eq("child_id", child_id)
      .maybeSingle();

    const yesterday = toDateString(new Date(Date.now() - 24 * 60 * 60 * 1000));

    if (!streakRow) {
      await supabaseAdmin.from("streaks").insert({
        child_id,
        current_streak: 1,
        best_streak: 1,
        last_practice_date: today,
      });
    } else if (streakRow.last_practice_date !== today) {
      const nextStreak = streakRow.last_practice_date === yesterday ? streakRow.current_streak + 1 : 1;
      const bestStreak = Math.max(streakRow.best_streak ?? 0, nextStreak);

      await supabaseAdmin.from("streaks").update({
        current_streak: nextStreak,
        best_streak: bestStreak,
        last_practice_date: today,
      }).eq("child_id", child_id);
    }

    return jsonResponse(200, {
      score,
      passed,
      passCountTotal: newPassCountTotal,
      passesRemaining: Math.max(0, passesRequired - newPassCountTotal),
      attemptsToday: attemptNumberToday,
      attemptsLeftToday: Math.max(0, dailyAttemptCap - attemptNumberToday),
      showDetailedFeedback: allowDetailedFeedback,
      mustReplayLearnStep: newConsecutiveFails >= 2 && !passed,
      shouldBlurVerse: blurAfterAttempt ? attemptNumberToday >= blurAfterAttempt : false,
      ayahMasteredNow,
      nextGate,
      locked_until: null,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
