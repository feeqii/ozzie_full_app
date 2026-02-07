import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type QuizAnswerItem = {
  question_id?: string;
  selected_option_id?: string | null;
  // Deprecated: client-supplied correctness is no longer trusted.
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

const answerKeys: Record<number, Record<QuizRequest["quiz_type"], Record<string, string>>> = {
  1: {
    mini_1: {
      // s1m1q1 is a recitation prompt (ungraded until full recitation scoring is implemented).
      s1m1q2: "a",
    },
    mini_2: {
      s1m2q1: "a",
      s1m2q2: "b",
    },
    final: {
      // s1fq1 is a recitation prompt (ungraded).
      s1fq2: "a",
    },
  },
  112: {
    mini_1: {
      // s112m1q1 is a recitation prompt (ungraded).
      s112m1q2: "a",
    },
    mini_2: {
      s112m2q1: "a",
      s112m2q2: "a",
    },
    final: {
      // s112fq1 is a recitation prompt (ungraded).
      s112fq2: "a",
    },
  },
};

const gradeQuiz = (surahId: number, quizType: QuizRequest["quiz_type"], answers: QuizAnswers): QuizGrade => {
  const key = answerKeys[surahId]?.[quizType] ?? null;
  if (!key) {
    return {
      score: 0,
      passed: false,
      details: { total: 0, correct: 0, reason: "NO_ANSWER_KEY" },
    };
  }

  const items = Array.isArray(answers.items) ? (answers.items as QuizAnswerItem[]) : [];
  const byQuestionId = new Map<string, QuizAnswerItem>();
  for (const item of items) {
    if (typeof item?.question_id === "string") {
      byQuestionId.set(item.question_id, item);
    }
  }

  let total = 0;
  let correct = 0;
  const missing: string[] = [];
  for (const [questionId, correctOptionId] of Object.entries(key)) {
    total += 1;
    const item = byQuestionId.get(questionId);
    if (!item) {
      missing.push(questionId);
      continue;
    }
    if (item.selected_option_id === correctOptionId) {
      correct += 1;
    }
  }

  const score = total > 0 ? Math.round((correct / total) * 100) : 0;
  const threshold = quizType === "final" ? 75 : 70;
  const passed = total > 0 && score >= threshold;

  return {
    score,
    passed,
    details: { total, correct, missing, threshold },
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
    const token = authHeader.replace("Bearer ", "");

    if (!token) {
      return jsonResponse(401, { error: "Missing bearer token" });
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

    // New gating: allow quiz if the corresponding level node is unlocked/in progress.
    let levelAllowsQuiz = false;
    let levelId: string | null = null;
    let levelOrderIndex: number | null = null;
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
        const locked = lockedUntil && lockedUntil.getTime() > Date.now();
        const status = (progress?.status as string | undefined) ?? "LOCKED";
        levelAllowsQuiz = !locked && status !== "LOCKED";
      }
    }

    if (!stageAllowsQuiz && !levelAllowsQuiz) {
      return jsonResponse(400, { error: "Quiz type not allowed for current state" });
    }

    const { count: attemptNumber } = await supabaseAdmin
      .from("quiz_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("quiz_type", quiz_type);

    const grade = gradeQuiz(surah_id, quiz_type, answers as QuizAnswers);
    if (grade.details?.reason === "NO_ANSWER_KEY") {
      return jsonResponse(409, { error: "Quiz content not available yet" });
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
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
