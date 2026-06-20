// ============================================================
// LearNova Edge Function: submit-challenge-attempt
// ============================================================
//
// CHANGE LOG (this update, Section 4.4 of the handover):
// Added three things that did not exist before:
//   1. Perfect-score perk grant: if correct_count === total_questions,
//      grant +1 Owl of Wisdom AND +1 Sly Fox 5000.
//   2. Update the matching student_challenge_schedule row's status to
//      'passed' or 'failed' (depending on whether the challenge's own
//      pass/fail rule was met) and set completed_at / best_score.
//   3. Schedule the NEXT challenge for this student: a new 'locked' row
//      with available_from = (this challenge's expires_at) + 7 days,
//      matching the next week number for the same track.
// Everything else (auth, scoring, streak multiplier, XP, attempt insert)
// is unchanged from the existing implementation.
// ============================================================

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

  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  let body: {
    challenge_id?: string;
    answers?: Record<string, string>;
    difficulty?: string;
    timezone_offset?: number;
  };
  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { challenge_id, answers, difficulty, timezone_offset = 0 } = body;

  if (!challenge_id) return respond({ error: "challenge_id is required" }, 400);
  if (!answers) return respond({ error: "answers must be an object" }, 400);
  if (!difficulty || !VALID_DIFFICULTIES.includes(difficulty as Difficulty)) {
    return respond({ error: "Invalid difficulty tier" }, 400);
  }

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

  // ── Calculate Student's Local Date ─────────────────────────
  const serverNow = new Date();
  const localTime = new Date(serverNow.getTime() + timezone_offset * 60 * 60 * 1000);
  const localDateStr = localTime.toISOString().split("T")[0]; // YYYY-MM-DD

  const { data: challenge, error: challengeError } = await supabase
    .from("weekly_challenges")
    .select("*")
    .eq("id", challenge_id)
    .single();

  if (challengeError || !challenge || !challenge.is_active) {
    return respond({ error: "Challenge unavailable" }, 404);
  }

  // Use localDateStr to check if they are within the window
  if (localDateStr < challenge.available_from || localDateStr > challenge.available_until) {
    return respond({ error: "Outside of availability window" }, 403);
  }

  const { data: questions } = await supabase
    .from("challenge_questions")
    .select("id, correct_answer")
    .eq("challenge_id", challenge_id);

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

  if (finalXpAwarded > 0) {
    await supabase.rpc("increment_xp", { user_id_input: studentId, xp_amount: finalXpAwarded });
  }

  // ════════════════════════════════════════════════════════════
  // NEW (1/3): Perfect-score perk grant.
  // Fires only on a true 3/3 (or N/N) perfect score, per the
  // handover NOTE in Section 4.4 — partial scores grant no perks.
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
  // NEW (2/3): Update this student's schedule row for THIS challenge.
  // Marks it passed/failed and records when it was completed.
  // "Passed" here means a perfect score, since weekly challenges are
  // single-attempt and the handover doesn't define a separate passing
  // threshold distinct from "perfect" for the schedule's pass/fail
  // status — see the handout notes for why this assumption was made.
  // ════════════════════════════════════════════════════════════
  const { data: scheduleRow } = await supabase
    .from("student_challenge_schedule")
    .select("id, expires_at")
    .eq("user_id", studentId)
    .eq("challenge_id", challenge_id)
    .maybeSingle();

  if (scheduleRow) {
    await supabase
      .from("student_challenge_schedule")
      .update({
        status: isPerfectScore ? "passed" : "failed",
        completed_at: new Date().toISOString(),
        best_score: score,
        passed: isPerfectScore,
      })
      .eq("id", scheduleRow.id);
  }

  // ════════════════════════════════════════════════════════════
  // NEW (3/3): Schedule the NEXT challenge.
  // Delegates to the shared schedule_next_challenge() Postgres function
  // (2026_06_20_gamification_v2_addendum2.sql) so the "find next week,
  // same track" logic lives in exactly ONE place — reused by both this
  // Edge Function (submission path) and the daily Railway cron
  // (expire_and_reschedule_stale_challenges, for students who never
  // submit at all before their window closes).
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
