import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type RecitationRequest = {
  child_id: string;
  surah_id: number;
  ayah_id: number;
  audio_path: string;
  // Deprecated: client-supplied scoring is no longer trusted.
  score?: number;
  transcript?: string | null;
  model?: string | null;
  meta?: Record<string, unknown> | null;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
const openAiApiKey = Deno.env.get("OPENAI_API_KEY");
const openAiEndpoint = Deno.env.get("OPENAI_TRANSCRIBE_ENDPOINT") ??
  "https://api.openai.com/v1/audio/transcriptions";
const openAiModel = Deno.env.get("OPENAI_TRANSCRIBE_MODEL") ?? "gpt-4o-transcribe";
const openAiTimeoutMs = Number(Deno.env.get("OPENAI_TIMEOUT_MS") ?? "25000");
const mockScoring = (Deno.env.get("MOCK_SCORING") ?? "").toLowerCase().trim();
const allowMockScoring = mockScoring === "1" || mockScoring === "true" || mockScoring === "yes";

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

const diacriticsRegex = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]/gu;
const nonArabicRegex = /[^\u0600-\u06FF\s]/gu;
const tatweelRegex = /\u0640/gu;
const whitespaceRegex = /\s+/gu;

const normalizeArabic = (input: string): string => {
  let text = input ?? "";
  text = text.replace(diacriticsRegex, "");
  text = text.replace(tatweelRegex, "");
  text = text.replace(nonArabicRegex, "");
  text = text
    .replaceAll("أ", "ا")
    .replaceAll("إ", "ا")
    .replaceAll("آ", "ا")
    .replaceAll("ٱ", "ا")
    .replaceAll("ى", "ي");
  text = text.replace(whitespaceRegex, " ").trim();
  return text;
};

const levenshtein = (s: string, t: string): number => {
  const m = s.length;
  const n = t.length;
  if (m === 0) return n;
  if (n === 0) return m;

  const prev = Array.from({ length: n + 1 }, (_, i) => i);
  const curr = new Array<number>(n + 1).fill(0);

  for (let i = 1; i <= m; i += 1) {
    curr[0] = i;
    const sChar = s.charCodeAt(i - 1);
    for (let j = 1; j <= n; j += 1) {
      const cost = sChar === t.charCodeAt(j - 1) ? 0 : 1;
      const del = prev[j] + 1;
      const ins = curr[j - 1] + 1;
      const sub = prev[j - 1] + cost;
      curr[j] = Math.min(del, ins, sub);
    }
    for (let j = 0; j <= n; j += 1) prev[j] = curr[j];
  }
  return prev[n];
};

const computeSimilarityScore = (transcript: string, reference: string): number => {
  const a = normalizeArabic(transcript);
  const b = normalizeArabic(reference);
  if (!a || !b) return 0;
  const dist = levenshtein(a, b);
  const maxLen = Math.max(a.length, b.length);
  if (maxLen === 0) return 0;
  const similarity = 1 - (dist / maxLen);
  return Math.max(0, Math.min(100, Math.round(similarity * 100)));
};

type WordDiffCounts = { inserts: number; deletes: number; subs: number };

const wordDiffCounts = (transcript: string, reference: string): WordDiffCounts => {
  const a = normalizeArabic(transcript).split(" ").filter(Boolean);
  const b = normalizeArabic(reference).split(" ").filter(Boolean);
  const m = a.length;
  const n = b.length;

  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array<number>(n + 1).fill(0));
  for (let i = 0; i <= m; i += 1) dp[i][0] = i;
  for (let j = 0; j <= n; j += 1) dp[0][j] = j;

  for (let i = 1; i <= m; i += 1) {
    for (let j = 1; j <= n; j += 1) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1, // delete
        dp[i][j - 1] + 1, // insert
        dp[i - 1][j - 1] + cost, // sub/match
      );
    }
  }

  let i = m;
  let j = n;
  let inserts = 0;
  let deletes = 0;
  let subs = 0;

  while (i > 0 || j > 0) {
    if (i > 0 && dp[i][j] === dp[i - 1][j] + 1) {
      deletes += 1;
      i -= 1;
      continue;
    }
    if (j > 0 && dp[i][j] === dp[i][j - 1] + 1) {
      inserts += 1;
      j -= 1;
      continue;
    }
    if (i > 0 && j > 0) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      if (dp[i][j] === dp[i - 1][j - 1] + cost) {
        if (cost === 1) subs += 1;
        i -= 1;
        j -= 1;
        continue;
      }
    }

    // Fallback (should not happen): make progress to avoid infinite loops.
    if (i > 0) {
      deletes += 1;
      i -= 1;
    } else if (j > 0) {
      inserts += 1;
      j -= 1;
    }
  }

  return { inserts, deletes, subs };
};

const classifyMistakeType = (counts: WordDiffCounts): string | null => {
  if (counts.deletes > 0) return "missing_words";
  if (counts.inserts > 0) return "additional_words";
  if (counts.subs > 0) return "incorrect_words";
  return null;
};

const shouldUseMockScoring = (): boolean => {
  // Mock scoring is a dev-only fallback. If a real OpenAI key is configured, always prefer it.
  if (openAiApiKey && openAiApiKey.trim().length > 0) return false;
  return allowMockScoring;
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

    const todayStart = new Date(`${today}T00:00:00.000Z`);
    const tomorrowStart = startOfTomorrowUtc(new Date());

    // Enforce "max failures per day" (PDF spec) rather than max total attempts.
    const { count: failsUsedToday, error: failsError } = await supabaseAdmin
      .from("recitation_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("ayah_id", ayah_id)
      .eq("passed", false)
      .gte("created_at", todayStart.toISOString())
      .lt("created_at", tomorrowStart.toISOString());

    if (failsError) {
      return jsonResponse(500, { error: "Failed to load failure count" });
    }

    if ((failsUsedToday ?? 0) >= dailyAttemptCap) {
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

    const { count: detailedUsedToday } = await supabaseAdmin
      .from("recitation_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("detailed_feedback_used", true)
      .gte("created_at", todayStart.toISOString())
      .lt("created_at", tomorrowStart.toISOString());

    const clientMeta = payload?.meta ?? null;

    let score = 0;
    let passed = false;
    let transcript: string | null = null;
    let mistakeType: string | null = null;
    let meta: Record<string, unknown> | null = null;

    // Load verse reference text for scoring.
    const { data: verseRow, error: verseError } = await supabaseAdmin
      .from("verses")
      .select("arabic")
      .eq("surah_id", surah_id)
      .eq("ayah_id", ayah_id)
      .maybeSingle();

    if (verseError) {
      return jsonResponse(500, { error: "Failed to load verse reference text" });
    }

    const referenceArabic = (verseRow?.arabic as string | undefined) ?? "";
    if (!referenceArabic) {
      return jsonResponse(409, { error: "Verse content not available yet" });
    }

    const maxAudioBytes = 15 * 1024 * 1024;
    const mock = shouldUseMockScoring();

    if (!supabaseAnonKey || supabaseAnonKey.trim().length === 0) {
      return jsonResponse(500, { error: "SUPABASE_ANON_KEY is not configured" });
    }

    // Download audio as the caller to enforce Storage RLS (prevents scoring someone else's upload).
    const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: audioBlob, error: downloadError } = await supabaseUser.storage
      .from("recitations")
      .download(audio_path);

    if (downloadError || !audioBlob) {
      return jsonResponse(404, { error: "Audio not found" });
    }

    if (audioBlob.size > maxAudioBytes) {
      return jsonResponse(413, { error: "Audio too large" });
    }

    if (mock) {
      // Dev-only fallback to exercise the progression system end-to-end without wiring OpenAI.
      score = passThreshold;
      passed = true;
      transcript = null;
      meta = { mock_scoring: true };
    } else {
      if (!openAiApiKey || openAiApiKey.trim().length === 0) {
        return jsonResponse(500, { error: "OPENAI_API_KEY is not configured" });
      }

      // Transcribe with OpenAI (server-side).
      const form = new FormData();
      form.append("model", openAiModel);
      form.append("response_format", "json");
      form.append("language", "ar");
      const fileName = audio_path.split("/").pop() || "recitation.m4a";
      form.append("file", audioBlob, fileName);

      const controller = new AbortController();
      const timeout = Number.isFinite(openAiTimeoutMs) && openAiTimeoutMs > 0 ? openAiTimeoutMs : 25000;
      const timeoutId = setTimeout(() => controller.abort("timeout"), timeout);

      let openAiResp: Response;
      try {
        openAiResp = await fetch(openAiEndpoint, {
          method: "POST",
          headers: { Authorization: `Bearer ${openAiApiKey}` },
          body: form,
          signal: controller.signal,
        });
      } catch (err) {
        const reason = err instanceof Error ? err.message : "unknown";
        return jsonResponse(502, { error: `OpenAI transcription failed: ${reason}` });
      } finally {
        clearTimeout(timeoutId);
      }

      const openAiBodyText = await openAiResp.text();
      if (!openAiResp.ok) {
        let message = `OpenAI transcription failed (status ${openAiResp.status})`;
        try {
          const parsed = JSON.parse(openAiBodyText) as { error?: { message?: unknown } };
          const apiMessage = parsed?.error?.message;
          if (typeof apiMessage === "string" && apiMessage.trim().length > 0) {
            message = `OpenAI transcription failed: ${apiMessage.trim()}`;
          }
        } catch (_) {
          // ignore parsing errors
        }
        return jsonResponse(502, { error: message });
      }

      let openAiJson: Record<string, unknown> | null = null;
      try {
        openAiJson = JSON.parse(openAiBodyText) as Record<string, unknown>;
      } catch (_) {
        return jsonResponse(502, { error: "OpenAI transcription returned invalid JSON" });
      }

      const openAiText = openAiJson?.text;
      if (typeof openAiText !== "string" || openAiText.trim().length === 0) {
        return jsonResponse(502, { error: "OpenAI transcription missing text" });
      }

      transcript = openAiText.trim();
      score = computeSimilarityScore(transcript, referenceArabic);
      passed = score >= passThreshold;

      const wordCounts = wordDiffCounts(transcript, referenceArabic);
      mistakeType = classifyMistakeType(wordCounts);

      meta = {
        scoring_backend: "openai_direct",
        openai_model: openAiModel,
        openai_timeout_ms: timeout,
        word_inserts: wordCounts.inserts,
        word_deletes: wordCounts.deletes,
        word_subs: wordCounts.subs,
      };
    }

    // Detailed feedback is quota-limited, and only provided after the first 3 failures (PDF spec).
    const failureIndexToday = passed ? (failsUsedToday ?? 0) : (failsUsedToday ?? 0) + 1;
    const allowDetailedFeedbackQuota = (detailedUsedToday ?? 0) < realtimeFeedbackCap;
    const shouldShowDetailedFeedback = !passed && failureIndexToday > 3 && allowDetailedFeedbackQuota;
    const failuresLeftToday = Math.max(0, dailyAttemptCap - failureIndexToday);
    const lockOutNow = !passed && failureIndexToday >= dailyAttemptCap;
    const lockedUntilNow = lockOutNow ? startOfTomorrowUtc(new Date()) : null;

    const combinedMeta: Record<string, unknown> = {
      ...(meta ?? {}),
      ...(clientMeta ?? {}),
      score_source: "server",
    };

    const attemptNumberToday = attemptsToday + 1;

    const { error: insertAttemptError } = await supabaseAdmin.from("recitation_attempts").insert({
      child_id,
      surah_id,
      ayah_id,
      attempt_number_today: attemptNumberToday,
      score,
      passed,
      detailed_feedback_used: shouldShowDetailedFeedback,
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
        locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
        last_score: score,
        updated_at: new Date().toISOString(),
      });

    if (updateAyahError) {
      return jsonResponse(500, { error: "Failed to update ayah progress" });
    }

    let nextGate: string | null = null;

    // Keep child_level_progress in sync when the new level graph exists.
    const { data: levelRow } = await supabaseAdmin
      .from("levels")
      .select("id, surah_id, type, order_index, config")
      .eq("surah_id", surah_id)
      .eq("type", "VERSE_LESSON")
      .eq("ayah_id", ayah_id)
      .maybeSingle();

    if (levelRow?.id) {
      // Insert into level_attempts (best-effort).
      try {
        await supabaseAdmin.from("level_attempts").insert({
          child_id,
          level_id: levelRow.id,
          attempt_number_today: attemptNumberToday,
          score,
          passed,
          detailed_feedback_used: shouldShowDetailedFeedback,
          mistake_type: mistakeType,
          meta: combinedMeta,
        });
      } catch (_) {
        // best-effort
      }

      const { data: existingLevelProgress } = await supabaseAdmin
        .from("child_level_progress")
        .select("status")
        .eq("child_id", child_id)
        .eq("level_id", levelRow.id)
        .maybeSingle();

      const existingStatus = (existingLevelProgress?.status as string | undefined) ?? "LOCKED";
      let nextStatus = existingStatus;
      if (existingStatus !== "COMPLETED") {
        if (ayahMasteredNow) nextStatus = "COMPLETED";
        else if (existingStatus === "UNLOCKED") nextStatus = "IN_PROGRESS";
      }

      await supabaseAdmin.from("child_level_progress").upsert(
        {
          child_id,
          level_id: levelRow.id,
          status: nextStatus,
          attempts_today: attemptNumberToday,
          attempts_date: today,
          consecutive_fails: newConsecutiveFails,
          pass_count_total: newPassCountTotal,
          locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
          last_score: score,
          completed_at: ayahMasteredNow ? new Date().toISOString() : null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "child_id,level_id" },
      );

      if (ayahMasteredNow) {
        const { data: nextLevel } = await supabaseAdmin
          .from("levels")
          .select("id, type, config")
          .eq("surah_id", surah_id)
          .eq("order_index", (levelRow.order_index as number) + 1)
          .maybeSingle();

        if (nextLevel?.id) {
          // Unlock next level if currently locked.
          await supabaseAdmin.from("child_level_progress").update({
            status: "UNLOCKED",
            updated_at: new Date().toISOString(),
          }).eq("child_id", child_id)
            .eq("level_id", nextLevel.id)
            .eq("status", "LOCKED");

          const quizType = (nextLevel.config as Record<string, unknown> | null)?.quiz_type;
          if (nextLevel.type === "CHECKPOINT" && typeof quizType === "string") {
            nextGate = quizType === "mini_1"
              ? "MINI_QUIZ_1"
              : quizType === "mini_2"
                ? "MINI_QUIZ_2"
                : null;
          }
          if (nextLevel.type === "FINAL_EXAM") {
            nextGate = "FINAL_EXAM";
          }
        }
      }
    }

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
    let updatedUnlockedAyah = surahBase.unlocked_ayah_max ?? 1;

    if (ayahMasteredNow) {
      updatedUnlockedAyah = Math.max(updatedUnlockedAyah, ayah_id + 1);
    }

    if (nextGate === "MINI_QUIZ_1") {
      updatedStage = "MINI_QUIZ_1";
    }
    if (nextGate === "MINI_QUIZ_2") {
      updatedStage = "MINI_QUIZ_2";
    }
    if (nextGate === "FINAL_EXAM") {
      updatedStage = "FINAL_EXAM";
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
      mistakeType,
      passCountTotal: newPassCountTotal,
      passesRemaining: Math.max(0, passesRequired - newPassCountTotal),
      attemptsToday: attemptNumberToday,
      attemptsLeftToday: lockOutNow ? 0 : failuresLeftToday,
      showDetailedFeedback: shouldShowDetailedFeedback,
      mustReplayLearnStep: newConsecutiveFails >= 2 && !passed,
      shouldBlurVerse: blurAfterAttempt ? attemptNumberToday >= blurAfterAttempt : false,
      ayahMasteredNow,
      nextGate,
      locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
