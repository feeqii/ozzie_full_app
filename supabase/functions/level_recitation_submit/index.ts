import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type LevelRecitationRequest = {
  child_id: string;
  surah_id: number;
  quiz_type: "mini_1" | "mini_2" | "final";
  audio_path: string;
  meta?: Record<string, unknown> | null;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-user-jwt, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

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

    // Fallback: ensure progress.
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

    const payload = (await req.json()) as Partial<LevelRecitationRequest>;
    const { child_id, surah_id, quiz_type, audio_path } = payload ?? {};

    if (
      typeof child_id !== "string" ||
      typeof surah_id !== "number" ||
      (quiz_type !== "mini_1" && quiz_type !== "mini_2" && quiz_type !== "final") ||
      typeof audio_path !== "string" ||
      audio_path.length === 0
    ) {
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
      .select("pass_threshold")
      .eq("child_id", child_id)
      .maybeSingle();

    const checkpointThreshold = (settingsRow?.pass_threshold as number | undefined) ?? 80;

    const { data: surahRow, error: surahError } = await supabaseAdmin
      .from("surah_progress")
      .select("stage")
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .maybeSingle();

    if (surahError) {
      return jsonResponse(500, { error: "Failed to load surah progress" });
    }

    const stage = (surahRow?.stage as string | undefined) ?? "LEARN_1_2";
    const stageAllowsQuiz =
      (quiz_type === "mini_1" && stage === "MINI_QUIZ_1") ||
      (quiz_type === "mini_2" && stage === "MINI_QUIZ_2") ||
      (quiz_type === "final" && stage === "FINAL_EXAM");

    if (!stageAllowsQuiz) {
      return jsonResponse(400, { error: "Quiz type not allowed for current state" });
    }

    // Resolve level id (checkpoint/final) for this quiz type.
    const { data: levels, error: levelsError } = await supabaseAdmin
      .from("levels")
      .select("id, type, order_index, checkpoint_index, config")
      .eq("surah_id", surah_id)
      .order("order_index", { ascending: true });

    if (levelsError) {
      return jsonResponse(500, { error: "Failed to load levels" });
    }

    const match = (levels ?? []).find((level) => {
      if (quiz_type === "final") {
        return level.type === "FINAL_EXAM";
      }
      if (level.type !== "CHECKPOINT") return false;
      const config = level.config as Record<string, unknown> | null;
      return config?.quiz_type === quiz_type;
    });

    if (!match?.id) {
      return jsonResponse(409, { error: "Content not available yet" });
    }

    const levelId = match.id as string;
    const checkpointIndex = (match.checkpoint_index as number | null) ?? null;

    const { data: progressRow, error: progressError } = await supabaseAdmin
      .from("child_level_progress")
      .select("status, attempts_today, attempts_date, consecutive_fails, pass_count_total, locked_until")
      .eq("child_id", child_id)
      .eq("level_id", levelId)
      .maybeSingle();

    if (progressError) {
      return jsonResponse(500, { error: "Failed to load level progress" });
    }

    const status = (progressRow?.status as string | undefined) ?? "LOCKED";
    if (status === "LOCKED") {
      return jsonResponse(409, { error: "Level locked" });
    }

    const lockedUntilExisting = progressRow?.locked_until ? new Date(progressRow.locked_until as string) : null;
    if (lockedUntilExisting && lockedUntilExisting.getTime() > Date.now()) {
      return jsonResponse(200, {
        locked_until: lockedUntilExisting.toISOString(),
        attemptsLeftToday: 0,
      });
    }

    const today = toDateString(new Date());
    let attemptsToday = (progressRow?.attempts_today as number | undefined) ?? 0;
    let attemptsDate = (progressRow?.attempts_date as string | undefined) ?? today;

    if (attemptsDate !== today) {
      attemptsToday = 0;
      attemptsDate = today;
      await supabaseAdmin.from("child_level_progress").update({
        attempts_today: 0,
        attempts_date: today,
        updated_at: new Date().toISOString(),
      }).eq("child_id", child_id)
        .eq("level_id", levelId);
    }

    // Determine verse range for scoring.
    let fromAyah: number;
    let toAyah: number;
    if (quiz_type === "final") {
      const { data: surahRow, error: surahError } = await supabaseAdmin
        .from("surahs")
        .select("ayah_count")
        .eq("id", surah_id)
        .maybeSingle();

      if (surahError) {
        return jsonResponse(500, { error: "Failed to load surah metadata" });
      }

      const ayahCount = (surahRow?.ayah_count as number | undefined) ?? null;
      if (!ayahCount) {
        return jsonResponse(409, { error: "Content not available yet" });
      }
      fromAyah = 1;
      toAyah = ayahCount;
    } else {
      if (typeof checkpointIndex !== "number") {
        return jsonResponse(500, { error: "Checkpoint index missing" });
      }

      const { data: defRow, error: defError } = await supabaseAdmin
        .from("surah_checkpoint_defs")
        .select("from_ayah, to_ayah")
        .eq("surah_id", surah_id)
        .eq("checkpoint_index", checkpointIndex)
        .maybeSingle();

      if (defError) {
        return jsonResponse(500, { error: "Failed to load checkpoint definition" });
      }
      if (!defRow) {
        return jsonResponse(409, { error: "Content not available yet" });
      }

      fromAyah = defRow.from_ayah as number;
      toAyah = defRow.to_ayah as number;
    }

    // Load reference Arabic by concatenating verses in range.
    const { data: verseRows, error: versesError } = await supabaseAdmin
      .from("verses")
      .select("ayah_id, arabic")
      .eq("surah_id", surah_id)
      .gte("ayah_id", fromAyah)
      .lte("ayah_id", toAyah)
      .order("ayah_id", { ascending: true });

    if (versesError) {
      return jsonResponse(500, { error: "Failed to load verse reference text" });
    }

    const expectedCount = toAyah - fromAyah + 1;
    if (!verseRows || verseRows.length !== expectedCount) {
      return jsonResponse(409, { error: "Content not available yet" });
    }

    const referenceArabic = verseRows
      .map((row) => (row.arabic as string | undefined) ?? "")
      .join(" ")
      .trim();

    if (!referenceArabic) {
      return jsonResponse(409, { error: "Content not available yet" });
    }

    // Failure cap rules (PDF): checkpoints allow 2 failures/day; final allows 1 attempt/day.
    const maxFailures = quiz_type === "final" ? 1 : 2;
    const passThreshold = quiz_type === "final" ? 75 : checkpointThreshold;

    const todayStart = new Date(`${today}T00:00:00.000Z`);
    const tomorrowStart = startOfTomorrowUtc(new Date());

    // Combined failures = (level recitation failures) + (quiz failures) for this gate.
    const { count: levelFailsUsedToday, error: levelFailsError } = await supabaseAdmin
      .from("level_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("level_id", levelId)
      .eq("passed", false)
      .contains("meta", { attempt_kind: "memorization_recitation" })
      .gte("created_at", todayStart.toISOString())
      .lt("created_at", tomorrowStart.toISOString());

    if (levelFailsError) {
      return jsonResponse(500, { error: "Failed to load failure count" });
    }

    const { count: quizFailsUsedToday, error: quizFailsError } = await supabaseAdmin
      .from("quiz_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("quiz_type", quiz_type)
      .eq("passed", false)
      .gte("created_at", todayStart.toISOString())
      .lt("created_at", tomorrowStart.toISOString());

    if (quizFailsError) {
      return jsonResponse(500, { error: "Failed to load failure count" });
    }

    const failsUsedToday = (levelFailsUsedToday ?? 0) + (quizFailsUsedToday ?? 0);
    if (failsUsedToday >= maxFailures) {
      const newLockedUntil = startOfTomorrowUtc(new Date());
      await supabaseAdmin.from("child_level_progress").update({
        locked_until: newLockedUntil.toISOString(),
        updated_at: new Date().toISOString(),
      }).eq("child_id", child_id)
        .eq("level_id", levelId);

      return jsonResponse(200, {
        locked_until: newLockedUntil.toISOString(),
        attemptsLeftToday: 0,
        from_ayah: fromAyah,
        to_ayah: toAyah,
      });
    }

    const maxAudioBytes = 15 * 1024 * 1024;
    const mock = shouldUseMockScoring();

    if (!supabaseAnonKey || supabaseAnonKey.trim().length === 0) {
      return jsonResponse(500, { error: "SUPABASE_ANON_KEY is not configured" });
    }

    // Download audio as the caller to enforce Storage RLS.
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

    let score = 0;
    let passed = false;
    let transcript: string | null = null;
    let mistakeType: string | null = null;

    if (mock) {
      score = passThreshold;
      passed = true;
      transcript = null;
      mistakeType = null;
    } else {
      if (!openAiApiKey || openAiApiKey.trim().length === 0) {
        return jsonResponse(500, { error: "OPENAI_API_KEY is not configured" });
      }

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
    }

    const failureIndexToday = passed ? failsUsedToday : failsUsedToday + 1;
    const failuresLeftToday = Math.max(0, maxFailures - failureIndexToday);
    const lockOutNow = !passed && failureIndexToday >= maxFailures;
    const lockedUntilNow = lockOutNow ? startOfTomorrowUtc(new Date()) : null;

    const attemptNumberToday = attemptsToday + 1;
    const clientMeta = (payload?.meta as Record<string, unknown> | null) ?? null;
    const combinedMeta: Record<string, unknown> = {
      ...(clientMeta ?? {}),
      attempt_kind: "memorization_recitation",
      quiz_type,
      surah_id,
      from_ayah: fromAyah,
      to_ayah: toAyah,
      transcript: transcript ?? null,
      score_source: "server",
      scoring_backend: mock ? "mock" : "openai_direct",
      openai_model: mock ? null : openAiModel,
    };

    const { error: insertAttemptError } = await supabaseAdmin.from("level_attempts").insert({
      child_id,
      level_id: levelId,
      attempt_number_today: attemptNumberToday,
      score,
      passed,
      detailed_feedback_used: false,
      mistake_type: mistakeType,
      meta: combinedMeta,
    });

    if (insertAttemptError) {
      return jsonResponse(500, { error: "Failed to log attempt" });
    }

    const existingConsecutiveFails = (progressRow?.consecutive_fails as number | undefined) ?? 0;
    const existingPassCountTotal = (progressRow?.pass_count_total as number | undefined) ?? 0;
    const newConsecutiveFails = passed ? 0 : existingConsecutiveFails + 1;
    const newPassCountTotal = passed ? Math.max(existingPassCountTotal, 1) : existingPassCountTotal;

    const existingStatus = status;
    let nextStatus = existingStatus;
    if (existingStatus !== "COMPLETED") {
      if (existingStatus === "UNLOCKED") nextStatus = "IN_PROGRESS";
      if (existingStatus === "IN_PROGRESS") nextStatus = "IN_PROGRESS";
    }

    await supabaseAdmin.from("child_level_progress").update({
      status: nextStatus,
      attempts_today: attemptNumberToday,
      attempts_date: today,
      consecutive_fails: newConsecutiveFails,
      pass_count_total: newPassCountTotal,
      locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
      last_score: score,
      updated_at: new Date().toISOString(),
    }).eq("child_id", child_id)
      .eq("level_id", levelId);

    return jsonResponse(200, {
      score,
      passed,
      transcript,
      mistakeType,
      attemptsLeftToday: lockOutNow ? 0 : failuresLeftToday,
      locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
      from_ayah: fromAyah,
      to_ayah: toAyah,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
