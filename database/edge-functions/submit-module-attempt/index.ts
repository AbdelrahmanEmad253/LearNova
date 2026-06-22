// ============================================================
// LearNova Edge Function: submit-module-attempt
// ============================================================
//
// CHANGE LOG (this update):
// FIXED a critical scoring bug. Real Flutter submissions were always
// scoring 0, even with correct answers. Root cause, confirmed by direct
// testing on 2026-06-21:
//
//   The function expected:  answers = { [question_id]: "A" | "B" | "C" | "D" }
//   Flutter actually sends: answers = {
//     answers: [
//       { question_id, question_key, selected_index, selected_label }, ...
//     ]
//   }
//
// Because of this mismatch, `answers[question.id]` was ALWAYS undefined
// for every real submission, so correctCount was always 0 and every
// real student scored 0% regardless of what they actually answered.
// This was proven with a direct test: a 15/15-correct submission using
// the OLD flat shape scored 100 through this function; the SAME
// student's real submissions through the app, using Flutter's actual
// shape, scored 0 in the database.
//
// FIX: normalizeAnswers() below accepts EITHER shape:
//   1. Flutter's real shape: { answers: [{ question_id, selected_index, ... }] }
//   2. The old flat shape:   { [question_id]: "A" }
// and produces a single flat { [question_id]: "A" } map either way, by
// resolving selected_index against that question's own `options` array
// (each option is { label, value }, where `value` is the letter).
//
// This means: NO Flutter changes are required. The Edge Function now
// matches what the app already sends.
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const VALID_DIFFICULTIES = ["easy", "mid", "hard"] as const;
type Difficulty = typeof VALID_DIFFICULTIES[number];

type FlutterAnswerEntry = {
  question_id: string;
  question_key?: string | null;
  selected_index?: number;
  selected_label?: string;
};

type QuestionOption = { label: string; value: string };

type QuestionRow = {
  id: string;
  correct_answer: string;
  options: QuestionOption[] | null;
};

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
    answers?: unknown;
    difficulty?: string;
    client_submission_id?: string;
  };
  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { assessment_id, answers: rawAnswers, difficulty, client_submission_id } = body;

  if (!assessment_id || typeof assessment_id !== "string") {
    return respond({ error: "assessment_id is required" }, 400);
  }
  if (rawAnswers === undefined || rawAnswers === null || typeof rawAnswers !== "object") {
    return respond({ error: "answers must be an object" }, 400);
  }
  if (!difficulty || !VALID_DIFFICULTIES.includes(difficulty as Difficulty)) {
    return respond({ error: "difficulty must be 'easy', 'mid', or 'hard'" }, 400);
  }
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

  // ── Idempotency check (unchanged) ────────────────────────────
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
    .select("id, correct_answer, options")
    .eq("assessment_id", assessment_id);

  if (questionsError || !questions || questions.length === 0) {
    return respond({ error: "No questions found for this assessment" }, 500);
  }

  // ════════════════════════════════════════════════════════════
  // NORMALIZE: turn whatever shape `answers` arrived in into a flat
  // { [question_id]: "A" | "B" | "C" | "D" } map, the only shape the
  // scoring loop below needs to understand.
  // ════════════════════════════════════════════════════════════
  const normalizedAnswers = normalizeAnswers(rawAnswers, questions as QuestionRow[]);

  let correctCount = 0;
  const totalQuestions = questions.length;

  for (const question of questions as QuestionRow[]) {
    const studentAnswer = normalizedAnswers[question.id];
    if (studentAnswer && studentAnswer === question.correct_answer) {
      correctCount++;
    }
  }

  const score = Math.round((correctCount / totalQuestions) * 100);
  const passed = score >= assessment.passing_score;

  // ── Determine Streak Multiplier (unchanged) ──────────────────
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

  // ── Calculate Flat XP (unchanged) ────────────────────────────
  const FLAT_BASE_XP = 20;
  const xpAwarded = passed ? Math.round(FLAT_BASE_XP * streakMultiplier) : 0;

  // Store the answers in their ORIGINAL shape as received (preserves
  // selected_index/selected_label for any future review/analytics use),
  // not the normalized version — normalization is only for scoring.
  const { error: insertError } = await supabase
    .from("student_module_attempts")
    .insert({
      user_id:       studentId,
      assessment_id: assessment_id,
      answers:       rawAnswers,
      score:         score,
      passed:        passed,
      difficulty:    chosenDifficulty,
      client_submission_id: client_submission_id,
    });

  if (insertError) {
    if (insertError.code === "23505") {
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

// ════════════════════════════════════════════════════════════════
// normalizeAnswers
//
// Accepts whatever shape the client sent and returns a flat
// { [question_id]: "A" | "B" | ... } map for scoring.
//
// Supported input shapes:
//
//   Shape 1 (Flutter's actual shape, confirmed 2026-06-21):
//     { answers: [ { question_id, selected_index, selected_label? }, ... ] }
//
//   Shape 2 (flat letter map — old assumption, kept for backward
//   compatibility in case any other caller still uses it):
//     { [question_id]: "A" }
//
//   Shape 3 (array of entries with an explicit `selected_value` or
//   `answer` letter already resolved — also supported defensively):
//     { answers: [ { question_id, selected_value: "A" }, ... ] }
//     { answers: [ { question_id, answer: "A" }, ... ] }
//
// For entries that only provide `selected_index` (Shape 1), the
// matching question's `options` array is used to resolve the index to
// its letter `value`. If options are missing/malformed for a question,
// that single answer is simply left unresolved (counts as incorrect)
// rather than throwing — one bad question definition should not crash
// the whole submission.
// ════════════════════════════════════════════════════════════════
function normalizeAnswers(
  rawAnswers: unknown,
  questions: QuestionRow[],
): Record<string, string> {
  const result: Record<string, string> = {};

  if (!rawAnswers || typeof rawAnswers !== "object") return result;

  const optionsByQuestionId = new Map<string, QuestionOption[]>();
  for (const q of questions) {
    if (Array.isArray(q.options)) {
      optionsByQuestionId.set(q.id, q.options);
    }
  }

  const maybeArray = (rawAnswers as Record<string, unknown>).answers;

  // Shape 1 / 3: { answers: [ {...}, ... ] }
  if (Array.isArray(maybeArray)) {
    for (const entry of maybeArray as FlutterAnswerEntry[] & { selected_value?: string; answer?: string }[]) {
      if (!entry || typeof entry !== "object" || !entry.question_id) continue;

      // Already-resolved letter, if a caller provides one directly.
      const directLetter =
        (entry as any).selected_value ?? (entry as any).answer ?? null;
      if (typeof directLetter === "string" && directLetter.length > 0) {
        result[entry.question_id] = directLetter;
        continue;
      }

      // Resolve selected_index against this question's options.
      if (typeof entry.selected_index === "number") {
        const options = optionsByQuestionId.get(entry.question_id);
        const matchedOption = options?.[entry.selected_index];
        if (matchedOption && typeof matchedOption.value === "string") {
          result[entry.question_id] = matchedOption.value;
        }
        // If options are missing or index is out of range, we
        // deliberately leave this question unanswered (counts wrong)
        // rather than guessing or throwing.
      }
    }
    return result;
  }

  // Shape 2: flat { [question_id]: "A" } map.
  for (const [key, value] of Object.entries(rawAnswers as Record<string, unknown>)) {
    if (key === "answers") continue; // already handled above if present
    if (typeof value === "string") {
      result[key] = value;
    }
  }

  return result;
}

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}