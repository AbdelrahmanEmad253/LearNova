// LearNova Edge Function: submit-level-attempt
// Post-grading reward processor for written level exams.
// The ML-AI Railway service grades the written answers first and writes
// score/passed/mitchy_feedback/grade_breakdown to student_level_attempts.
// This function is idempotent: repeated calls do not award XP twice.
//
// CHANGE LOG (this update):
// Updated to "No-Webhook" architecture. If an attempt is ungraded, the
// function now pings Railway's /score/level-attempt endpoint directly,
// waits for Railway to grade the attempt, then refetches and continues
// with XP + badge processing. The old 409 "not graded yet" guard is gone.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const LEVEL_GRADER_URL = Deno.env.get("LEVEL_GRADER_URL");
const LEVEL_GRADER_API_KEY = Deno.env.get("LEVEL_GRADER_API_KEY");

const BADGE_SCORE_THRESHOLD = 90;
const DIFFICULTY_TO_METAL: Record<string, string> = { easy: "bronze", mid: "silver", hard: "gold" };
const METAL_RANK: Record<string, number> = { bronze: 1, silver: 2, gold: 3 };
const LEVEL_EXAM_BASE_XP = 30;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }
  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  let body: { attempt_id?: string };
  try { body = await req.json(); } catch { return respond({ error: "Invalid JSON body" }, 400); }
  if (!body.attempt_id) return respond({ error: "attempt_id is required" }, 400);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond({ error: "Missing Authorization" }, 401);

  const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { global: { headers: { Authorization: authHeader } } });
  const { data: { user }, error: authError } = await authClient.auth.getUser();
  if (authError || !user) return respond({ error: "Unauthorized" }, 401);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  let { data: attempt, error: attemptError } = await supabase
    .from("student_level_attempts")
    .select("id, user_id, assessment_id, score, passed, difficulty, reward_processed_at, xp_awarded")
    .eq("id", body.attempt_id)
    .single();

  if (attemptError || !attempt) return respond({ error: "Attempt not found" }, 404);
  if (attempt.user_id !== user.id) return respond({ error: "Forbidden" }, 403);

  if (attempt.score === null || attempt.score === undefined || attempt.passed === null || attempt.passed === undefined) {
    // 1. Verify Scoring Environment Variables
    if (!LEVEL_GRADER_URL || !LEVEL_GRADER_API_KEY) {
      return respond({ error: "Scoring service environment variables are missing" }, 500);
    }

    // 2. Format Railway URL
    const railwayBaseUrl = LEVEL_GRADER_URL.replace(/\/$/, "");
    const railwayUrl = `${railwayBaseUrl}/score/level-attempt`;

    // 3. Ping Railway to Grade the Attempt
    const railwayResponse = await fetch(railwayUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": LEVEL_GRADER_API_KEY },
      body: JSON.stringify({ attempt_id: attempt.id }),
    });

    if (!railwayResponse.ok) {
      const text = await railwayResponse.text();
      return respond({ error: `Railway scoring failed: ${text}` }, 500);
    }

    // 4. Refetch the newly graded attempt from Supabase
    const { data: gradedAttempt, error: gradedAttemptError } = await supabase
      .from("student_level_attempts")
      .select("id, user_id, assessment_id, score, passed, difficulty, reward_processed_at, xp_awarded")
      .eq("id", attempt.id)
      .single();

    if (gradedAttemptError || !gradedAttempt) {
      return respond({ error: "Failed to reload graded attempt" }, 500);
    }

    // 5. Update the local variable so XP processing can continue
    attempt = gradedAttempt;
  }

  // Atomic idempotency claim: prevents duplicate XP if Flutter retries.
  const { data: claimResult, error: claimError } = await supabase.rpc("claim_level_attempt_reward_processing", {
    p_attempt_id: attempt.id,
    p_user_id: user.id,
  });
  if (claimError) {
    console.error("claim_level_attempt_reward_processing failed:", claimError);
    return respond({ error: "Failed to claim reward processing" }, 500);
  }
  const claim = claimResult as { ok: boolean; already_processed?: boolean; error?: string };
  if (!claim.ok) return respond({ error: claim.error ?? "Attempt cannot be processed" }, 409);
  if (claim.already_processed) {
    return respond({
      attempt_id: attempt.id,
      score: attempt.score,
      passed: attempt.passed,
      difficulty: attempt.difficulty,
      xp_awarded: attempt.xp_awarded ?? 0,
      already_processed: true,
    }, 200);
  }

  if (!attempt.difficulty || !DIFFICULTY_TO_METAL[attempt.difficulty]) {
    return respond({ error: "Attempt is missing a valid difficulty tier" }, 500);
  }

  const { data: levelInfo, error: levelInfoError } = await supabase
    .from("level_assessments")
    .select("id, level_id, levels(order_index)")
    .eq("id", attempt.assessment_id)
    .single();
  if (levelInfoError || !levelInfo) return respond({ error: "Could not resolve level" }, 500);

  const levelNumber = (levelInfo as any).levels.order_index;
  let xpAwarded = 0;
  let badgeResult = { awarded: false, achievement_key: null as string | null, upgraded_from: null as string | null };

  if (attempt.passed) {
    xpAwarded = LEVEL_EXAM_BASE_XP;
    const { error: xpError } = await supabase.rpc("increment_xp", { user_id_input: user.id, xp_amount: xpAwarded });
    if (xpError) {
      console.error("increment_xp failed:", xpError);
      return respond({ error: "Failed to award XP" }, 500);
    }
  }

  const qualifiesForBadge = attempt.passed && Number(attempt.score) >= BADGE_SCORE_THRESHOLD;
  if (qualifiesForBadge) {
    badgeResult = await awardBadgeIfNeeded(supabase, user.id, attempt.difficulty, levelNumber);
  }

  const { error: markError } = await supabase
    .from("student_level_attempts")
    .update({ xp_awarded: xpAwarded })
    .eq("id", attempt.id);

  if (markError) {
    console.error("xp_awarded update failed:", markError);
  }

  if (badgeResult.awarded) {
    const metal = badgeResult.achievement_key!.split("_")[0];
    const metalLabel = metal[0].toUpperCase() + metal.slice(1);
    await supabase.from("in_app_notifications").insert({
      user_id: user.id,
      title: "Badge Unlocked!",
      body: `You earned ${metalLabel} Mind — Level ${levelNumber}! Keep pushing.`,
      notification_type: "achievement_unlocked",
      metadata: { achievement_key: badgeResult.achievement_key, level_number: levelNumber, upgraded_from: badgeResult.upgraded_from },
    });
  }

  return respond({
    attempt_id: attempt.id,
    score: attempt.score,
    passed: attempt.passed,
    difficulty: attempt.difficulty,
    level_number: levelNumber,
    xp_awarded: xpAwarded,
    badge: badgeResult,
    already_processed: false,
  }, 200);
});

async function awardBadgeIfNeeded(supabase: any, userId: string, difficulty: string, levelNumber: number) {
  const metal = DIFFICULTY_TO_METAL[difficulty];
  const newKey = `${metal}_mind_level_${levelNumber}`;
  const { data: existingKey } = await supabase.rpc("get_user_badge_for_level", { p_user_id: userId, p_level_number: levelNumber });
  const { data: newAchievement, error: newAchievementError } = await supabase
    .from("achievements_dictionary")
    .select("id")
    .eq("achievement_key", newKey)
    .single();
  if (newAchievementError || !newAchievement) {
    console.error("Missing achievement key", newKey, newAchievementError);
    return { awarded: false, achievement_key: null, upgraded_from: null };
  }

  if (!existingKey) {
    const { error } = await supabase.from("user_achievements").insert({ user_id: userId, achievement_id: newAchievement.id });
    return error ? { awarded: false, achievement_key: null, upgraded_from: null } : { awarded: true, achievement_key: newKey, upgraded_from: null };
  }

  const existingMetal = String(existingKey).split("_")[0];
  if (METAL_RANK[metal] <= METAL_RANK[existingMetal]) {
    return { awarded: false, achievement_key: null, upgraded_from: null };
  }

  const { data: existingAchievement } = await supabase
    .from("achievements_dictionary")
    .select("id")
    .eq("achievement_key", existingKey)
    .single();
  if (existingAchievement) {
    await supabase.from("user_achievements").delete().eq("user_id", userId).eq("achievement_id", existingAchievement.id);
  }
  const { error } = await supabase.from("user_achievements").insert({ user_id: userId, achievement_id: newAchievement.id });
  return error ? { awarded: false, achievement_key: null, upgraded_from: null } : { awarded: true, achievement_key: newKey, upgraded_from: existingKey };
}

function corsHeaders(): HeadersInit {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", ...corsHeaders() } });
}