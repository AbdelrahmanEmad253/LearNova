// ============================================================
// LearNova Edge Function: consume-resource
// Location: supabase/functions/consume-resource/index.ts
// ============================================================
//
// CHANGE LOG (this update):
// Fixed the streak bug described in Section 5 of the handover doc.
// The OLD code always wrote back the SAME current_streak_days value it
// read, no matter how many days had passed — so streaks never grew and
// never reset. The NEW logic below applies the three rules from the
// handover:
//   diffDays === 0  -> same day, don't change the count, multiplier 1.1x
//   diffDays === 1  -> consecutive day, INCREMENT by 1, multiplier 1.1x
//   diffDays  > 1   -> streak broken, RESET to 1 (today is day 1), multiplier 1.0x
//
// Also added resource_type validation (Edit 4): rejects null/invalid
// resource_type before any DB work is done.
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

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
    topic_id?: string;
    resource_type?: "Visual" | "Auditory" | "Textual";
    is_topic_completion?: boolean;
    timezone_offset?: number;
  };

  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { topic_id, resource_type, is_topic_completion = false, timezone_offset = 0 } = body;

  if (!topic_id) return respond({ error: "topic_id is required" }, 400);

  if (!resource_type || !["Visual", "Auditory", "Textual"].includes(resource_type)) {
    return respond({ error: "resource_type must be Visual, Auditory, or Textual" }, 400);
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

  // ── Prevent Duplicate XP Grinding ────────────────────────────
  // Ensure the student hasn't already claimed XP for this exact resource type in this topic
  const { data: existingLog } = await supabase
    .from("student_resource_logs")
    .select("id")
    .eq("user_id", studentId)
    .eq("topic_id", topic_id)
    .eq("resource_type", resource_type)
    .maybeSingle();

  if (existingLog) {
    return respond({ message: "Resource already consumed. No duplicate XP awarded." }, 200);
  }

  // ── Calculate Micro-Dosing XP ──────────────────────────────
  const BASE_RESOURCE_XP = 5;
  const TOPIC_COMPLETION_BONUS = 15;
  let earnedXp = BASE_RESOURCE_XP;

  if (is_topic_completion) earnedXp += TOPIC_COMPLETION_BONUS;

  // ── Read current streak state ────────────────────────────────
  const serverNow = new Date();
  const localTime = new Date(serverNow.getTime() + timezone_offset * 60 * 60 * 1000);
  const localDateStr = localTime.toISOString().split("T")[0]; // YYYY-MM-DD

  const { data: streakData } = await supabase
    .from("user_streaks")
    .select("last_activity_date, current_streak_days, longest_streak_days")
    .eq("user_id", studentId)
    .maybeSingle();

  // ── FIXED: Compute the correct new streak state ───────────────
  let streakMultiplier = 1.0;
  let newStreakDays: number;
  let newLongestStreak: number;

  if (!streakData || !streakData.last_activity_date) {
    // First-ever activity for this student. Start the streak at 1.
    newStreakDays = 1;
    newLongestStreak = 1;
    streakMultiplier = 1.1; // Day 1 still counts as an active streak day.
  } else {
    // Compare calendar dates (not raw timestamps) so "diffDays" means
    // actual day boundaries crossed, matching the handover's wording.
    const lastActiveDate = new Date(streakData.last_activity_date + "T00:00:00Z");
    const todayDate = new Date(localDateStr + "T00:00:00Z");
    const diffTime = todayDate.getTime() - lastActiveDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      // Same day as last activity: don't change the streak count.
      newStreakDays = streakData.current_streak_days;
      streakMultiplier = 1.1;
    } else if (diffDays === 1) {
      // Consecutive day: increment.
      newStreakDays = streakData.current_streak_days + 1;
      streakMultiplier = 1.1;
    } else {
      // diffDays > 1 (or negative/unexpected clock skew): streak broken.
      // Today counts as day 1 of a new streak.
      newStreakDays = 1;
      streakMultiplier = 1.0;
    }

    newLongestStreak = Math.max(newStreakDays, streakData.longest_streak_days ?? 0);
  }

  const finalXpAwarded = Math.round(earnedXp * streakMultiplier);

  // ── Log the interaction and award XP ───────────────────────
  await supabase.from("student_resource_logs").insert({
    user_id: studentId,
    topic_id: topic_id,
    resource_type: resource_type,
    completed: true,
  });

  await supabase.rpc("increment_xp", { user_id_input: studentId, xp_amount: finalXpAwarded });

  // ── Write the CORRECTED streak state ────────────────────────
  await supabase.from("user_streaks").upsert({
    user_id: studentId,
    last_activity_date: localDateStr,
    current_streak_days: newStreakDays,
    longest_streak_days: newLongestStreak,
    updated_at: new Date().toISOString(),
  });

  return respond(
    {
      resource_xp: BASE_RESOURCE_XP,
      completion_bonus: is_topic_completion ? TOPIC_COMPLETION_BONUS : 0,
      streak_multiplier: streakMultiplier,
      xp_awarded: finalXpAwarded,
      current_streak_days: newStreakDays,
      longest_streak_days: newLongestStreak,
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
