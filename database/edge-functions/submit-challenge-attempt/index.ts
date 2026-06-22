// ============================================================
// LearNova Edge Function: submit-challenge-attempt
// ============================================================
//
// UPDATED WEEKLY CHALLENGE TIMING FLOW:
// - Challenge availability is NOT checked inside this Edge Function anymore.
// - The student-specific timing window is validated by SQL RPC:
//     public.validate_student_challenge_submission(p_user_id, p_challenge_id)
// - SQL uses student_challenge_schedule.available_from / expires_at / status.
// - This function still uses localTime only for streak multiplier logic.
//
// EXPECTED DB TIMING RULE:
// - assigned_at      = diagnostic initialization / schedule creation time
// - available_from   = assigned_at + 14 days
// - expires_at       = available_from + 7 days
//
// OTHER BEHAVIOR KEPT:
// - Auth check
// - Answer shape normalization
// - Scoring
// - Streak multiplier
// - XP award
// - Perfect-score perk grant
// - Update student_challenge_schedule
// - schedule_next_challenge RPC after completion
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const VALID_DIFFICULTIES = ["easy", "mid", "hard"] as const;
type Difficulty = typeof VALID_DIFFICULTIES[number];

// ── Answer shape normalization ─────────────────────────────
// Accepts either:
//   Flat shape:    { "question-uuid": "B", ... }
//   Flutter shape: { answers: [{ question_id, selected_label: "B) Some text" }, ...] }
// Always returns a flat { question-uuid: "B" } map for scoring.
function normalizeAnswers(raw: unknown): Record<string, string> {
  if (!raw || typeof raw !== "object") return {};

  const asObj = raw as Record<string, unknown>;

  // Flutter shape: top-level key is "answers" and its value is an array
  if (Array.isArray(asObj.answers)) {
    const flat: Record<string, string> = {};
    for (const entry of asObj.answers) {
      if (!entry || typeof entry !== "object") continue;
      const { question_id, selected_label } = entry as Record<string, unknown>;
      if (typeof question_id !== "string" || typeof selected_label !== "string") continue;

      // selected_label is "B) Surveying only morning customers" → extract "B"
      const letter = selected_label.split(")")[0].trim();
      if (letter) flat[question_id] = letter;
    }
    return flat;
  }

  // Flat shape: already { question_id: "B" }
  const flat: Record<string, string> = {};
  for (const [k, v] of Object.entries(asObj)) {
    if (typeof v === "string") flat[k] = v;
  }
  return flat;
}

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

  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  let body: {
    challenge_id?: string;
    answers?: unknown;
    difficulty?: string;
    timezone_offset?: number;
  };

  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { challenge_id, answers: rawAnswers, difficulty, timezone_offset = 0 } = body;

  if (!challenge_id) return respond({ error: "challenge_id is required" }, 400);
  if (!rawAnswers) return respond({ error: "answers must be an object" }, 400);
  if (!difficulty || !VALID_DIFFICULTIES.includes(difficulty as Difficulty)) {
    return respond({ error: "Invalid difficulty tier" }, 400);
  }

  // Normalize to flat map before anything else touches answers.
  const answers = normalizeAnswers(rawAnswers);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond({ error: "Missing Authorization" }, 401);

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: authError } = await clientForAuth.auth.getUser();
  if (authError || !user) return respond({ error: "Unauthorized" }, 401);

  const studentId = user.id;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const { data: existingAttempt } = await supabase
    .from("student_challenge_attempts")
    .select("id")
    .eq("user_id", studentId)
    .eq("challenge_id", challenge_id)
    .maybeSingle();

  if (existingAttempt) return respond({ error: "Already submitted" }, 409);

  // ── Calculate Student's Local Time ─────────────────────────
  // Still used for streak multiplier calculation only.
  // Challenge availability is validated by SQL using student_challenge_schedule.
  const serverNow = new Date();
  const localTime = new Date(serverNow.getTime() + timezone_offset * 60 * 60 * 1000);

  const { data: challenge, error: challengeError } = await supabase
    .from("weekly_challenges")
    .select("*")
    .eq("id", challenge_id)
    .single();

  if (challengeError || !challenge || !challenge.is_active) {
    return respond({ error: "Challenge unavailable" }, 404);
  }

  // ── Validate student-specific challenge timing in SQL ───────
  // The Edge Function must not decide availability.
  // SQL checks student_challenge_schedule.available_from/expires_at/status/attempts.
  const { data: validationResult, error: validationError } = await supabase.rpc(
    "validate_student_challenge_submission",
    {
      p_user_id: studentId,
      p_challenge_id: challenge_id,
    },
  );

  if (validationError) {
    console.error("validate_student_challenge_submission RPC error:", validationError);
    return respond(
      {
        error: "Challenge validation failed",
        details: validationError.message,
      },
      500,
    );
  }

  const validation = validationResult as {
    ok?: boolean;
    reason?: string;
    message?: string;
    available_from?: string;
    expires_at?: string;
    server_now?: string;
    schedule_id?: string;
    status?: string;
  };

  if (!validation?.ok) {
    return respond(
      {
        error: validation?.message ?? "Challenge is not available",
        reason: validation?.reason ?? "not_available",
        available_from: validation?.available_from,
        expires_at: validation?.expires_at,
        server_now: validation?.server_now,
      },
      403,
    );
  }

  const { data: questions, error: questionsError } = await supabase
    .from("challenge_questions")
    .select("id, correct_answer")
    .eq("challenge_id", challenge_id);

  if (questionsError) {
    console.error("challenge_questions fetch error:", questionsError);
    return respond({ error: "Failed to load challenge questions" }, 500);
  }

  let correctCount = 0;
  const totalQuestions = questions?.length || 0;

  for (const question of questions || []) {
    if (answers[question.id] === question.correct_answer) correctCount++;
  }

  const score = totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 100) : 0;
  const isPerfectScore = totalQuestions > 0 && correctCount === totalQuestions;

  // ── Apply Streak Multiplier ────────────────────────────────
  let streakMultiplier = 1.0;
  const { data: streakData } = await supabase
    .from("user_streaks")
    .select("last_activity_date, current_streak_days")
    .eq("user_id", studentId)
    .maybeSingle();

  if (streakData && streakData.current_streak_days > 0 && streakData.last_activity_date) {
    const lastActive = new Date(streakData.last_activity_date);
    const diffTime = localTime.getTime() - lastActive.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays <= 1) streakMultiplier = 1.1;
  }

  const xpColumnMap = {
    easy: challenge.xp_reward_easy,
    mid: challenge.xp_reward_mid,
    hard: challenge.xp_reward_hard,
  };

  const baseXp = xpColumnMap[difficulty as Difficulty];
  const earnedXp = Math.round(baseXp * (score / 100));
  const finalXpAwarded = Math.round(earnedXp * streakMultiplier);

  // Store the normalized flat map — consistent shape in DB regardless of client.
  const { error: insertError } = await supabase.from("student_challenge_attempts").insert({
    user_id: studentId,
    challenge_id: challenge_id,
    answers: answers,
    score: score,
    completed: true,
    difficulty: difficulty,
  });

  if (insertError && insertError.code === "23505") {
    return respond({ error: "Already submitted" }, 409);
  }

  if (insertError) {
    console.error("student_challenge_attempts insert error:", insertError);
    return respond({ error: "Failed to save challenge attempt", details: insertError.message }, 500);
  }

  if (finalXpAwarded > 0) {
    const { error: xpError } = await supabase.rpc("increment_xp", {
      user_id_input: studentId,
      xp_amount: finalXpAwarded,
    });

    if (xpError) {
      console.error("increment_xp RPC error:", xpError);
    }
  }

  // ════════════════════════════════════════════════════════════
  // Perfect-score perk grant.
  // Fires only on a true N/N perfect score.
  // ════════════════════════════════════════════════════════════
  let perksGranted = false;
  if (isPerfectScore) {
    const { data: currentPerks } = await supabase
      .from("student_perks")
      .select("owl_hint_count, sly_fox_count")
      .eq("user_id", studentId)
      .maybeSingle();

    const { error: perkUpsertError } = await supabase.from("student_perks").upsert(
      {
        user_id: studentId,
        owl_hint_count: (currentPerks?.owl_hint_count ?? 0) + 1,
        sly_fox_count: (currentPerks?.sly_fox_count ?? 0) + 1,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" },
    );

    if (!perkUpsertError) {
      perksGranted = true;
      await supabase.from("in_app_notifications").insert({
        user_id: studentId,
        title: "Perfect Score!",
        body: "Perfect score! +1 Owl of Wisdom and +1 Sly Fox 5000 added.",
        notification_type: "general",
      });
    } else {
      console.error("student_perks perfect-score upsert error:", perkUpsertError);
    }
  }

  // ════════════════════════════════════════════════════════════
  // Update this student's schedule row for THIS challenge.
  // Marks it passed/failed and records completion + attempt count.
  // Passed means perfect score for this current challenge rule.
  // ════════════════════════════════════════════════════════════
  const { data: scheduleRow } = await supabase
    .from("student_challenge_schedule")
    .select("id, expires_at, current_attempts")
    .eq("user_id", studentId)
    .eq("challenge_id", challenge_id)
    .maybeSingle();

  if (scheduleRow) {
    const { error: scheduleUpdateError } = await supabase
      .from("student_challenge_schedule")
      .update({
        status: isPerfectScore ? "passed" : "failed",
        completed_at: new Date().toISOString(),
        current_attempts: (scheduleRow.current_attempts ?? 0) + 1,
        best_score: score,
        passed: isPerfectScore,
      })
      .eq("id", scheduleRow.id);

    if (scheduleUpdateError) {
      console.error("student_challenge_schedule update error:", scheduleUpdateError);
    }
  }

  // ════════════════════════════════════════════════════════════
  // Schedule the NEXT challenge.
  // Delegates to schedule_next_challenge() so next-challenge timing stays in SQL.
  // ════════════════════════════════════════════════════════════
  let nextChallengeScheduled = false;

  if (scheduleRow) {
    const { data: nextResult, error: nextError } = await supabase.rpc(
      "schedule_next_challenge",
      { p_user_id: studentId, p_completed_challenge_id: challenge_id },
    );

    if (nextError) {
      console.error("schedule_next_challenge RPC error:", nextError);
    } else {
      const result = nextResult as { ok: boolean; scheduled?: boolean; reason?: string };
      nextChallengeScheduled = result.ok && result.scheduled === true;
      if (result.ok && !result.scheduled) {
        console.warn("Next challenge not scheduled:", result.reason);
      }
    }
  }

  return respond(
    {
      score,
      correct_count: correctCount,
      total_questions: totalQuestions,
      base_xp: earnedXp,
      streak_multiplier: streakMultiplier,
      xp_awarded: finalXpAwarded,
      perfect_score: isPerfectScore,
      perks_granted: perksGranted,
      next_challenge_scheduled: nextChallengeScheduled,
      challenge_validation: {
        schedule_id: validation.schedule_id,
        status: validation.status,
        available_from: validation.available_from,
        expires_at: validation.expires_at,
        server_now: validation.server_now,
      },
    },
    200,
  );
});

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
