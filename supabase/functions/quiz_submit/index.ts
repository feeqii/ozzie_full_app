import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type QuizAnswerItem = {
  id?: string;
  correct?: boolean;
  value?: unknown;
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

const gradeQuiz = (answers: QuizAnswers): QuizGrade => {
  const items = Array.isArray(answers.items) ? answers.items : [];
  const total = items.length;
  const correct = items.filter((item) => item.correct === true).length;

  const score = total > 0 ? Math.round((correct / total) * 100) : 0;
  const passed = score >= 70;

  return {
    score,
    passed,
    details: { total, correct },
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

    if (!stageAllowsQuiz) {
      return jsonResponse(400, { error: "Quiz type not allowed for current stage" });
    }

    const { count: attemptNumber } = await supabaseAdmin
      .from("quiz_attempts")
      .select("id", { count: "exact", head: true })
      .eq("child_id", child_id)
      .eq("surah_id", surah_id)
      .eq("quiz_type", quiz_type);

    const grade = gradeQuiz(answers as QuizAnswers);

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
        updatePayload.stage = "LEARN_REST";
        nextStage = "LEARN_REST";
      }

      if (quiz_type === "final") {
        updatePayload.final_exam_passed_at = new Date().toISOString();
        updatePayload.stage = "COMPLETED";
        nextStage = "COMPLETED";
      }
    }

    await supabaseAdmin.from("surah_progress").upsert(updatePayload);

    return jsonResponse(200, {
      score: grade.score,
      passed: grade.passed,
      nextStage,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
