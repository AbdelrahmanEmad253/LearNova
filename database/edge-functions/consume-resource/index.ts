// ============================================================
// LearNova Edge Function: consume-resource
// Location: supabase/functions/consume-resource/index.ts
// ============================================================
//
// Purpose:
// - Logs topic resource consumption.
// - Awards XP once per (user, topic, resource_type).
// - Updates streak state.
// - Ensures student_progress.format_served is never null.
//
// Important:
// - format_served/resource_type must be one of: Visual, Auditory, Textual.
// - student_resource_logs keeps per-format history.
// - student_progress keeps the topic-level progress row and the latest/served format.
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

type ResourceType = "Visual" | "Auditory" | "Textual";

function normalizeResourceType(value: unknown): ResourceType | null {
  if (typeof value !== "string") return null;

  const normalized = value.trim().toLowerCase();

  if (normalized === "visual" || normalized === "v") return "Visual";
  if (normalized === "auditory" || normalized === "audio" || normalized === "a") return "Auditory";
  if (
    normalized === "textual" ||
    normalized === "text" ||
    normalized === "reading" ||
    normalized === "read/write" ||
    normalized === "read_write" ||
    normalized === "readwrite" ||
    normalized === "r"
  ) {
    return "Textual";
  }

  return null;
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
    topic_id?: string;
    resource_type?: string;
    is_topic_completion?: boolean;
    timezone_offset?: number;
  };

  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { topic_id, is_topic_completion = false, timezone_offset = 0 } = body;
  const resourceType = normalizeResourceType(body.resource_type);

  if (!topic_id) return respond({ error: "topic_id is required" }, 400);

  if (!resourceType) {
    return respond(
      {
        error: "resource_type is required and must be Visual, Auditory, or Textual",
        received: body.resource_type ?? null,
      },
      400,
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond({ error: "Missing Authorization" }, 401);

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: authError,
  } = await clientForAuth.auth.getUser();

  if (authError || !user) return respond({ error: "Unauthorized" }, 401);

  const studentId = user.id;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const serverNow = new Date();
  const nowIso = serverNow.toISOString();

  // ── Keep student_progress safe even if this call becomes duplicate ─────
  // This is the main fix for recurring null format_served rows.
  const progressResult = await ensureStudentProgress({
    supabase,
    userId: studentId,
    topicId: topic_id,
    resourceType,
    isTopicCompletion: is_topic_completion,
    nowIso,
  });

  if (!progressResult.ok) {
    return respond(
      {
        error: "Failed to update student_progress",
        details: progressResult.error,
      },
      500,
    );
  }

  // ── Prevent Duplicate XP Grinding ────────────────────────────
  // Ensure the student hasn't already claimed XP for this exact resource type in this topic.
  const { data: existingLog, error: existingLogError } = await supabase
    .from("student_resource_logs")
    .select("id")
    .eq("user_id", studentId)
    .eq("topic_id", topic_id)
    .eq("resource_type", resourceType)
    .maybeSingle();

  if (existingLogError) {
    return respond(
      {
        error: "Failed to check existing resource log",
        details: existingLogError.message,
      },
      500,
    );
  }

  if (existingLog) {
    return respond(
      {
        message: "Resource already consumed. No duplicate XP awarded.",
        topic_id,
        resource_type: resourceType,
        student_progress_updated: true,
      },
      200,
    );
  }

  // ── Calculate Micro-Dosing XP ──────────────────────────────
  const BASE_RESOURCE_XP = 5;
  const TOPIC_COMPLETION_BONUS = 15;
  let earnedXp = BASE_RESOURCE_XP;

  if (is_topic_completion) earnedXp += TOPIC_COMPLETION_BONUS;

  // ── Read current streak state ────────────────────────────────
  const localTime = new Date(serverNow.getTime() + timezone_offset * 60 * 60 * 1000);
  const localDateStr = localTime.toISOString().split("T")[0]; // YYYY-MM-DD

  const { data: streakData } = await supabase
    .from("user_streaks")
    .select("last_activity_date, current_streak_days, longest_streak_days")
    .eq("user_id", studentId)
    .maybeSingle();

  // ── Compute the correct new streak state ─────────────────────
  let streakMultiplier = 1.0;
  let newStreakDays: number;
  let newLongestStreak: number;

  if (!streakData || !streakData.last_activity_date) {
    // First-ever activity for this student. Start the streak at 1.
    newStreakDays = 1;
    newLongestStreak = 1;
    streakMultiplier = 1.1;
  } else {
    // Compare calendar dates, not raw timestamps.
    const lastActiveDate = new Date(streakData.last_activity_date + "T00:00:00Z");
    const todayDate = new Date(localDateStr + "T00:00:00Z");
    const diffTime = todayDate.getTime() - lastActiveDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      newStreakDays = streakData.current_streak_days;
      streakMultiplier = 1.1;
    } else if (diffDays === 1) {
      newStreakDays = streakData.current_streak_days + 1;
      streakMultiplier = 1.1;
    } else {
      newStreakDays = 1;
      streakMultiplier = 1.0;
    }

    newLongestStreak = Math.max(newStreakDays, streakData.longest_streak_days ?? 0);
  }

  const finalXpAwarded = Math.round(earnedXp * streakMultiplier);

  // ── Log the interaction and award XP ───────────────────────
  const { error: logInsertError } = await supabase.from("student_resource_logs").insert({
    user_id: studentId,
    topic_id,
    resource_type: resourceType,
    completed: true,
  });

  if (logInsertError) {
    // If a race condition created the unique row between the duplicate check and insert,
    // do not award XP twice.
    if (logInsertError.code === "23505") {
      return respond(
        {
          message: "Resource already consumed. No duplicate XP awarded.",
          topic_id,
          resource_type: resourceType,
          student_progress_updated: true,
        },
        200,
      );
    }

    return respond(
      {
        error: "Failed to insert student_resource_logs row",
        details: logInsertError.message,
      },
      500,
    );
  }

  const { error: xpError } = await supabase.rpc("increment_xp", {
    user_id_input: studentId,
    xp_amount: finalXpAwarded,
  });

  if (xpError) {
    return respond(
      {
        error: "Failed to award XP",
        details: xpError.message,
      },
      500,
    );
  }

  // ── Write the corrected streak state ────────────────────────
  const { error: streakUpsertError } = await supabase.from("user_streaks").upsert({
    user_id: studentId,
    last_activity_date: localDateStr,
    current_streak_days: newStreakDays,
    longest_streak_days: newLongestStreak,
    updated_at: nowIso,
  });

  if (streakUpsertError) {
    return respond(
      {
        error: "XP was awarded but streak update failed",
        details: streakUpsertError.message,
      },
      500,
    );
  }

  return respond(
    {
      topic_id,
      resource_type: resourceType,
      resource_xp: BASE_RESOURCE_XP,
      completion_bonus: is_topic_completion ? TOPIC_COMPLETION_BONUS : 0,
      streak_multiplier: streakMultiplier,
      xp_awarded: finalXpAwarded,
      current_streak_days: newStreakDays,
      longest_streak_days: newLongestStreak,
      student_progress_updated: true,
    },
    200,
  );
});

async function ensureStudentProgress({
  supabase,
  userId,
  topicId,
  resourceType,
  isTopicCompletion,
  nowIso,
}: {
  supabase: ReturnType<typeof createClient>;
  userId: string;
  topicId: string;
  resourceType: ResourceType;
  isTopicCompletion: boolean;
  nowIso: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const { data: progressRows, error: progressReadError } = await supabase
    .from("student_progress")
    .select("id, status, started_at, completed_at, format_served")
    .eq("user_id", userId)
    .eq("topic_id", topicId)
    .order("started_at", { ascending: true })
    .limit(1);

  if (progressReadError) {
    return { ok: false, error: progressReadError.message };
  }

  const existingProgress = Array.isArray(progressRows) && progressRows.length > 0 ? progressRows[0] : null;

  if (existingProgress?.id) {
    const nextStatus = isTopicCompletion ? "completed" : existingProgress.status ?? "in_progress";

    const { error: updateError } = await supabase
      .from("student_progress")
      .update({
        status: nextStatus,
        format_served: resourceType,
        started_at: existingProgress.started_at ?? nowIso,
        completed_at: isTopicCompletion ? nowIso : existingProgress.completed_at,
      })
      .eq("id", existingProgress.id);

    if (updateError) {
      return { ok: false, error: updateError.message };
    }

    return { ok: true };
  }

  const { error: insertError } = await supabase.from("student_progress").insert({
    user_id: userId,
    topic_id: topicId,
    status: isTopicCompletion ? "completed" : "in_progress",
    format_served: resourceType,
    started_at: nowIso,
    completed_at: isTopicCompletion ? nowIso : null,
  });

  if (insertError) {
    return { ok: false, error: insertError.message };
  }

  return { ok: true };
}

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
