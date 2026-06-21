import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const VALID_DIFFICULTIES = ["easy", "mid", "hard"] as const;
type Difficulty = typeof VALID_DIFFICULTIES[number];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  if (req.method !== "POST") {
    return respond({ error: "Method not allowed" }, 405);
  }

  let body: {
    assessment_id?: string;
    answers?: Record<string, string>;
    difficulty?: string;
    client_submission_id?: string;
  };
  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { assessment_id, answers, difficulty, client_submission_id } = body;

  if (!assessment_id || typeof assessment_id !== "string") {
    return respond({ error: "assessment_id is required" }, 400);
  }
  if (!answers || typeof answers !== "object" || Array.isArray(answers)) {
    return respond({ error: "answers must be an object { question_id: selected_answer }" }, 400);
  }
  if (!difficulty || !VALID_DIFFICULTIES.includes(difficulty as Difficulty)) {
    return respond({ error: "difficulty must be 'easy', 'mid', or 'hard'" }, 400);
  }
  // NEW: client_submission_id is required so every submission can be
  // de-duplicated. Flutter must generate one UUID per real attempt and
  // resend the SAME value if a request needs to be retried.
  if (!client_submission_id || typeof client_submission_id !== "string") {
    return respond({ error: "client_submission_id is required" }, 400);
  }

  const chosenDifficulty = difficulty as Difficulty;

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return respond({ error: "Missing Authorization header" }, 401);
  }

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: authError } = await clientForAuth.auth.getUser();
  if (authError || !user) {
    return respond({ error: "Unauthorized — invalid or expired token" }, 401);
  }
  const studentId = user.id;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  // ════════════════════════════════════════════════════════════
  // NEW: Idempotency check.
  // If a row already exists for this exact (user, client_submission_id)
  // pair, this is a RETRY of a request we already fully processed —
  // return the SAME result we already saved instead of re-scoring,
  // re-inserting, or re-awarding XP.
  // ════════════════════════════════════════════════════════════
  const { data: existingSubmission } = await supabase
    .from("student_module_attempts")
    .select("score, passed, difficulty")
    .eq("user_id", studentId)
    .eq("client_submission_id", client_submission_id)
    .maybeSingle();

  if (existingSubmission) {
    return respond(
      {
        score: existingSubmission.score,
        passed: existingSubmission.passed,
        difficulty: existingSubmission.difficulty,
        duplicate_submission: true,
      },
      200,
    );
  }

  const { data: assessment, error: assessmentError } = await supabase
    .from("module_assessments")
    .select("id, module_id, title, passing_score, is_active")
    .eq("id", assessment_id)
    .single();

  if (assessmentError || !assessment) {
    return respond({ error: "Assessment not found" }, 404);
  }
  if (!assessment.is_active) {
    return respond({ error: "Assessment is not active" }, 403);
  }

  const { data: questions, error: questionsError } = await supabase
    .from("module_assessment_questions")
    .select("id, correct_answer")
    .eq("assessment_id", assessment_id);

  if (questionsError || !questions || questions.length === 0) {
    return respond({ error: "No questions found for this assessment" }, 500);
  }

  let correctCount = 0;
  const totalQuestions = questions.length;

  for (const question of questions) {
    const studentAnswer = answers[question.id];
    if (studentAnswer && studentAnswer === question.correct_answer) {
      correctCount++;
    }
  }

  const score = Math.round((correctCount / totalQuestions) * 100);
  const passed = score >= assessment.passing_score;

  // ── Determine Streak Multiplier ──────────────────────────────
  let streakMultiplier = 1.0;
  const todayDateStr = new Date().toISOString().split("T")[0];

  const { data: streakData } = await supabase
    .from("user_streaks")
    .select("last_activity_date, current_streak_days")
    .eq("user_id", studentId)
    .maybeSingle();

  if (streakData && streakData.current_streak_days > 0 && streakData.last_activity_date) {
    const lastActive = new Date(streakData.last_activity_date);
    const todayDate = new Date(todayDateStr);
    const diffTime = todayDate.getTime() - lastActive.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays <= 1) {
      streakMultiplier = 1.1;
    }
  }

  // ── Calculate Flat XP ────────────────────────────────────────
  const FLAT_BASE_XP = 20;
  const xpAwarded = passed ? Math.round(FLAT_BASE_XP * streakMultiplier) : 0;

  // ════════════════════════════════════════════════════════════
  // NEW: client_submission_id saved alongside the attempt. The
  // unique index (user_id, client_submission_id) from the migration
  // means a true race (two near-simultaneous requests with the same
  // ID) would have the SECOND insert fail here with a constraint
  // violation — caught below and treated the same as a duplicate.
  // ════════════════════════════════════════════════════════════
  const { error: insertError } = await supabase
    .from("student_module_attempts")
    .insert({
      user_id:       studentId,
      assessment_id: assessment_id,
      answers:       answers,
      score:         score,
      passed:        passed,
      difficulty:    chosenDifficulty,
      client_submission_id: client_submission_id,
    });

  if (insertError) {
    if (insertError.code === "23505") {
      // Unique violation on (user_id, client_submission_id) — a
      // concurrent duplicate request beat us to the insert. Treat
      // exactly like the idempotency check above: fetch and return
      // the row that won, don't award XP twice.
      const { data: wonRow } = await supabase
        .from("student_module_attempts")
        .select("score, passed, difficulty")
        .eq("user_id", studentId)
        .eq("client_submission_id", client_submission_id)
        .maybeSingle();

      return respond(
        {
          score: wonRow?.score ?? score,
          passed: wonRow?.passed ?? passed,
          difficulty: wonRow?.difficulty ?? chosenDifficulty,
          duplicate_submission: true,
        },
        200,
      );
    }
    console.error("Insert error:", insertError);
    return respond({ error: "Failed to save attempt" }, 500);
  }

  if (passed && xpAwarded > 0) {
    const { error: xpError } = await supabase.rpc("increment_xp", {
      user_id_input: studentId,
      xp_amount:     xpAwarded,
    });
    if (xpError) {
      console.error("XP increment error:", xpError);
    }
  }

  return respond({
    score,
    passed,
    correct_count:   correctCount,
    total_questions: totalQuestions,
    difficulty:      chosenDifficulty,
    base_xp:         passed ? FLAT_BASE_XP : 0,
    streak_multiplier: streakMultiplier,
    xp_awarded:      xpAwarded,
    duplicate_submission: false,
  }, 200);
});

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}