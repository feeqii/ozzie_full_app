import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type QuizAnswerItem = {
  question_id?: string;
  selected_option_id?: string | null;
  // App-graded correctness for this answer. Backend records and gates flow.
  correct?: boolean;
};

type QuizAnswers = {
  items?: QuizAnswerItem[];
} & Record<string, unknown>;

type QuizRequest = {
  child_id: string;
  surah_id: number;
  quiz_type: "mini_1" | "mini_2" | "final";
  answers: QuizAnswers;
};

type QuizGrade = {
  score: number;
  passed: boolean;
  details?: Record<string, unknown> | null;
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

const toDateString = (date: Date) => date.toISOString().slice(0, 10);

const startOfTomorrowUtc = (date: Date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1));

const gradeQuiz = (quizType: QuizRequest["quiz_type"], answers: QuizAnswers): QuizGrade => {
  const items = Array.isArray(answers.items) ? (answers.items as QuizAnswerItem[]) : [];

  let total = 0;
  let correct = 0;
  for (const item of items) {
    if (typeof item?.question_id !== "string") {
      continue;
    }
    if (typeof item.selected_option_id !== "string" || item.selected_option_id.trim().length === 0) {
      continue;
    }
    total += 1;
    if (item.correct === true) {
      correct += 1;
    }
  }

  const score = total > 0 ? Math.round((correct / total) * 100) : 0;
  const threshold = quizType === "final" ? 75 : 70;
  const passed = total > 0 && score >= threshold;

  return {
    score,
    passed,
    details: { total, correct, threshold },
  };
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

    const payload = (await req.json()) as Partial<QuizRequest>;
    const { child_id, surah_id, quiz_type, answers } = payload ?? {};

    if (
      typeof child_id !== "string" ||
      typeof surah_id !== "number" ||
      (quiz_type !== "mini_1" && quiz_type !== "mini_2" && quiz_type !== "final") ||
      typeof answers !== "object" ||
      answers === null
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

    const { data: surahRow, error: surahError } = await supabaseAdmin
      .from("surah_progress")
      .select("stage, unlocked_ayah_max")
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .maybeSingle();

    if (surahError) {
      return jsonResponse(500, { error: "Failed to load surah progress" });
    }

    const stage = surahRow?.stage ?? "LEARN_1_2";
    const stageAllowsQuiz =
      (quiz_type === "mini_1" && stage === "MINI_QUIZ_1") ||
      (quiz_type === "mini_2" && stage === "MINI_QUIZ_2") ||
      (quiz_type === "final" && stage === "FINAL_EXAM");

    const today = toDateString(new Date());
    const todayStart = new Date(`${today}T00:00:00.000Z`);
    const tomorrowStart = startOfTomorrowUtc(new Date());

    // New gating: allow quiz if the corresponding level node is unlocked/in progress.
    let levelAllowsQuiz = false;
    let levelId: string | null = null;
    let levelOrderIndex: number | null = null;
    let levelLockedUntil: string | null = null;
    let levelLocked = false;
    {
      const { data: levels, error: levelsError } = await supabaseAdmin
        .from("levels")
        .select("id, type, order_index, config")
        .eq("surah_id", surah_id)
        .order("order_index", { ascending: true });

      if (levelsError) {
        return jsonResponse(500, { error: "Failed to load levels" });
      }

      const match = (levels ?? []).find((level) => {
        if (quiz_type === "final") {
          return level.type === "FINAL_EXAM";
        }
        if (level.type !== "CHECKPOINT") {
          return false;
        }
        const config = level.config as Record<string, unknown> | null;
        return config?.quiz_type === quiz_type;
      });

      if (match?.id) {
        levelId = match.id as string;
        levelOrderIndex = match.order_index as number;
        const { data: progress, error: progressError } = await supabaseAdmin
          .from("child_level_progress")
          .select("status, locked_until")
          .eq("child_id", child_id)
          .eq("level_id", levelId)
          .maybeSingle();

        if (progressError) {
          return jsonResponse(500, { error: "Failed to load level progress" });
        }

        const lockedUntil = progress?.locked_until ? new Date(progress.locked_until as string) : null;
        const locked = !!(lockedUntil && lockedUntil.getTime() > Date.now());
        const status = (progress?.status as string | undefined) ?? "LOCKED";
        levelLocked = locked;
        levelLockedUntil = lockedUntil ? lockedUntil.toISOString() : null;
        levelAllowsQuiz = !locked && status !== "LOCKED";
      }
    }

    if (levelLocked) {
      return jsonResponse(200, { locked_until: levelLockedUntil, attemptsLeftToday: 0 });
    }

    if (!stageAllowsQuiz) {
      return jsonResponse(400, { error: "Quiz type not allowed for current state" });
    }

    if (!levelAllowsQuiz) {
      return jsonResponse(409, { error: "Content not available yet" });
    }

    if (!levelId) {
      return jsonResponse(409, { error: "Content not available yet" });
    }

    // Final exam quiz is attempted only once per day (PDF spec).
    if (quiz_type === "final") {
      const { count: attemptsToday, error: attemptsTodayError } = await supabaseAdmin
        .from("quiz_attempts")
        .select("id", { count: "exact", head: true })
        .eq("child_id", child_id)
        .eq("surah_id", surah_id)
        .eq("quiz_type", quiz_type)
        .gte("created_at", todayStart.toISOString())
        .lt("created_at", tomorrowStart.toISOString());

      if (attemptsTodayError) {
        return jsonResponse(500, { error: "Failed to load attempt count" });
      }

      if ((attemptsToday ?? 0) >= 1) {
        const newLockedUntil = startOfTomorrowUtc(new Date());
        // Also lock the level node so the UI map disables it.
        await supabaseAdmin.from("child_level_progress").update({
          locked_until: newLockedUntil.toISOString(),
          updated_at: new Date().toISOString(),
        }).eq("child_id", child_id)
          .eq("level_id", levelId);

        return jsonResponse(200, { locked_until: newLockedUntil.toISOString(), attemptsLeftToday: 0 });
      }
    }

    // Require a fresh server-graded recitation pass before allowing a quiz attempt.
    const { data: latestQuizAttempt, error: latestQuizAttemptError } = await supabaseAdmin
      .from("quiz_attempts")
      .select("created_at")
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("quiz_type", quiz_type)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (latestQuizAttemptError) {
      return jsonResponse(500, { error: "Failed to load last quiz attempt" });
    }

    const lastQuizAttemptAt = (latestQuizAttempt?.created_at as string | undefined) ?? null;
    let passQuery = supabaseAdmin
      .from("level_attempts")
      .select("id, created_at")
      .eq("child_id", child_id)
      .eq("level_id", levelId)
      .eq("passed", true)
      .contains("meta", { attempt_kind: "memorization_recitation" })
      .order("created_at", { ascending: false })
      .limit(1);

    if (lastQuizAttemptAt) {
      passQuery = passQuery.gt("created_at", lastQuizAttemptAt);
    }

    const { data: passAttempt, error: passAttemptError } = await passQuery.maybeSingle();
    if (passAttemptError) {
      return jsonResponse(500, { error: "Failed to verify recitation pass" });
    }
    if (!passAttempt) {
      return jsonResponse(409, { error: "Recitation required", code: "RECITATION_REQUIRED" });
    }

    const { count: attemptNumber } = await supabaseAdmin
      .from("quiz_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("quiz_type", quiz_type);

    const grade = gradeQuiz(quiz_type, answers as QuizAnswers);

    // Lockout rules (PDF): checkpoints allow 2 failures/day; final locks out until tomorrow on any failure.
    const maxFailures = quiz_type === "final" ? 1 : 2;
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
    const failureIndexToday = grade.passed ? failsUsedToday : failsUsedToday + 1;
    const failuresLeftToday = Math.max(0, maxFailures - failureIndexToday);
    const lockOutNow = !grade.passed && failureIndexToday >= maxFailures;
    const lockedUntilNow = lockOutNow ? startOfTomorrowUtc(new Date()) : null;

    if (lockOutNow && levelId) {
      await supabaseAdmin.from("child_level_progress").update({
        locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
        updated_at: new Date().toISOString(),
      }).eq("child_id", child_id)
        .eq("level_id", levelId);
    }

    const { error: insertError } = await supabaseAdmin.from("quiz_attempts").insert({
      child_id,
      surah_id,
      quiz_type,
      attempt_number: (attemptNumber ?? 0) + 1,
      score: grade.score,
      passed: grade.passed,
      details: grade.details ?? null,
    });

    if (insertError) {
      return jsonResponse(500, { error: "Failed to log quiz attempt" });
    }

    let nextStage = stage;
    const updatePayload: Record<string, unknown> = {
      child_id,
      surah_id,
      updated_at: new Date().toISOString(),
    };

    if (grade.passed) {
      if (quiz_type === "mini_1") {
        updatePayload.mini_quiz_1_passed_at = new Date().toISOString();
        updatePayload.stage = "LEARN_3_4";
        nextStage = "LEARN_3_4";
      }

      if (quiz_type === "mini_2") {
        updatePayload.mini_quiz_2_passed_at = new Date().toISOString();
        // If all ayahs are already unlocked (e.g. short surahs), jump straight to final exam.
        const { data: surahMeta } = await supabaseAdmin
          .from("surahs")
          .select("ayah_count")
          .eq("id", surah_id)
          .maybeSingle();

        const ayahCount = (surahMeta?.ayah_count as number | undefined) ?? null;
        const unlockedAyahMax = (surahRow?.unlocked_ayah_max as number | undefined) ?? 1;
        const allUnlocked = ayahCount != null && unlockedAyahMax > ayahCount;
        if (allUnlocked) {
          updatePayload.stage = "FINAL_EXAM";
          nextStage = "FINAL_EXAM";
        } else {
          updatePayload.stage = "LEARN_REST";
          nextStage = "LEARN_REST";
        }
      }

      if (quiz_type === "final") {
        updatePayload.final_exam_passed_at = new Date().toISOString();
        updatePayload.stage = "COMPLETED";
        nextStage = "COMPLETED";
      }
    }

    await supabaseAdmin.from("surah_progress").upsert(updatePayload);

    // Update level progress graph: complete this checkpoint/final and unlock the next level.
    if (grade.passed && levelId && typeof levelOrderIndex === "number") {
      await supabaseAdmin.from("child_level_progress").update({
        status: "COMPLETED",
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq("child_id", child_id)
        .eq("level_id", levelId);

      const { data: nextLevel } = await supabaseAdmin
        .from("levels")
        .select("id, type")
        .eq("surah_id", surah_id)
        .eq("order_index", levelOrderIndex + 1)
        .maybeSingle();

      if (nextLevel?.id) {
        await supabaseAdmin.from("child_level_progress").update({
          status: "UNLOCKED",
          updated_at: new Date().toISOString(),
        }).eq("child_id", child_id)
          .eq("level_id", nextLevel.id)
          .eq("status", "LOCKED");
      }
    }

    // On final exam pass, mark surah completed and free active slot.
    if (grade.passed && quiz_type === "final") {
      await supabaseAdmin.from("child_surah_state").upsert({
        child_id,
        surah_id,
        status: "COMPLETED",
        active_slot: null,
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }, { onConflict: "child_id,surah_id" });

      const { data: galaxyRow } = await supabaseAdmin
        .from("galaxy_surahs")
        .select("galaxy_id")
        .eq("surah_id", surah_id)
        .maybeSingle();

      const galaxyId = galaxyRow?.galaxy_id as number | undefined;
      if (typeof galaxyId === "number") {
        // If all surahs in this galaxy are completed for the child, mark the galaxy completed and unlock the next one.
        const { data: galaxySurahs } = await supabaseAdmin
          .from("galaxy_surahs")
          .select("surah_id")
          .eq("galaxy_id", galaxyId);

        const surahIds = (galaxySurahs ?? []).map((row) => row.surah_id as number);
        if (surahIds.length > 0) {
          const { data: completedRows } = await supabaseAdmin
            .from("child_surah_state")
            .select("surah_id")
            .eq("child_id", child_id)
            .in("surah_id", surahIds)
            .eq("status", "COMPLETED");

          const completedSet = new Set((completedRows ?? []).map((row) => row.surah_id as number));
          const galaxyCompleted = surahIds.every((id) => completedSet.has(id));
          if (galaxyCompleted) {
            await supabaseAdmin.from("child_galaxy_state").upsert({
              child_id,
              galaxy_id: galaxyId,
              unlocked: true,
              completed_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            }, { onConflict: "child_id,galaxy_id" });

            await supabaseAdmin.from("child_galaxy_state").upsert({
              child_id,
              galaxy_id: galaxyId + 1,
              unlocked: true,
              updated_at: new Date().toISOString(),
            }, { onConflict: "child_id,galaxy_id" });
          }
        }
      }
    }

    return jsonResponse(200, {
      score: grade.score,
      passed: grade.passed,
      nextStage,
      attemptsLeftToday: lockOutNow ? 0 : failuresLeftToday,
      locked_until: lockedUntilNow ? lockedUntilNow.toISOString() : null,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
