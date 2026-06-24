// ============================================================
// LearNova Edge Function: consume-resource
// Location: supabase/functions/consume-resource/index.ts
// ============================================================
//
// Resource-level completion fix:
// - Flutter should send resource_id = topic_resources.id.
// - The function logs completion by resource_id, not only topic_id + resource_type.
// - This prevents one file/video from marking all resources under the same topic completed.
//
// Preferred request body:
// {
//   "resource_id": "topic_resources.id",
//   "is_topic_completion": false,
//   "timezone_offset": 3
// }
//
// Legacy request body still works, but should be avoided:
// {
//   "topic_id": "topics.id",
//   "resource_type": "Textual",
//   "is_topic_completion": false,
//   "timezone_offset": 3
// }
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
  if (["textual", "text", "reading", "read/write", "read_write", "readwrite", "r"].includes(normalized)) return "Textual";
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
    resource_id?: string;
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

  const resourceId = body.resource_id ?? null;
  const isTopicCompletion = body.is_topic_completion === true;
  const timezoneOffset = typeof body.timezone_offset === "number" ? body.timezone_offset : 0;

  let topicId = body.topic_id ?? null;
  let resourceType = normalizeResourceType(body.resource_type);

  // Preferred path: derive topic_id + format_type from topic_resources.id.
  if (resourceId) {
    const { data: resourceRow, error: resourceError } = await supabase
      .from("topic_resources")
      .select("id, topic_id, format_type")
      .eq("id", resourceId)
      .maybeSingle();

    if (resourceError) {
      return respond({ error: "Failed to read topic resource", details: resourceError.message }, 500);
    }

    if (!resourceRow) {
      return respond({ error: "resource_id was not found in topic_resources", resource_id: resourceId }, 404);
    }

    topicId = resourceRow.topic_id;
    resourceType = normalizeResourceType(resourceRow.format_type);
  }

  if (!topicId) return respond({ error: "topic_id is required when resource_id is not provided" }, 400);
  if (!resourceType) return respond({ error: "resource_type must be Visual, Auditory, or Textual" }, 400);

  const serverNow = new Date();
  const nowIso = serverNow.toISOString();

  // Topic-level progress remains topic-level. Do not mark completed unless Flutter says the topic is completed.
  const progressResult = await ensureStudentProgress({
    supabase,
    userId: studentId,
    topicId,
    resourceType,
    isTopicCompletion,
    nowIso,
  });

  if (!progressResult.ok) {
    return respond({ error: "Failed to update student_progress", details: progressResult.error }, 500);
  }

  // Resource-level duplicate check.
  let existingLogQuery = supabase
    .from("student_resource_logs")
    .select("id")
    .eq("user_id", studentId)
    .limit(1);

  if (resourceId) {
    existingLogQuery = existingLogQuery.eq("resource_id", resourceId);
  } else {
    existingLogQuery = existingLogQuery.eq("topic_id", topicId).eq("resource_type", resourceType).is("resource_id", null);
  }

  const { data: existingRows, error: existingError } = await existingLogQuery;

  if (existingError) {
    return respond({ error: "Failed to check existing resource log", details: existingError.message }, 500);
  }

  if (existingRows && existingRows.length > 0) {
    return respond(
      {
        message: "Resource already consumed. No duplicate XP awarded.",
        resource_id: resourceId,
        topic_id: topicId,
        resource_type: resourceType,
        student_progress_updated: true,
      },
      200,
    );
  }

  const BASE_RESOURCE_XP = 5;
  const TOPIC_COMPLETION_BONUS = 15;
  let earnedXp = BASE_RESOURCE_XP;
  if (isTopicCompletion) earnedXp += TOPIC_COMPLETION_BONUS;

  const localTime = new Date(serverNow.getTime() + timezoneOffset * 60 * 60 * 1000);
  const localDateStr = localTime.toISOString().split("T")[0];

  const { data: streakData } = await supabase
    .from("user_streaks")
    .select("last_activity_date, current_streak_days, longest_streak_days")
    .eq("user_id", studentId)
    .maybeSingle();

  let streakMultiplier = 1.0;
  let newStreakDays: number;
  let newLongestStreak: number;

  if (!streakData || !streakData.last_activity_date) {
    newStreakDays = 1;
    newLongestStreak = 1;
    streakMultiplier = 1.1;
  } else {
    const lastActiveDate = new Date(streakData.last_activity_date + "T00:00:00Z");
    const todayDate = new Date(localDateStr + "T00:00:00Z");
    const diffDays = Math.round((todayDate.getTime() - lastActiveDate.getTime()) / (1000 * 60 * 60 * 24));

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

  const { error: logInsertError } = await supabase.from("student_resource_logs").insert({
    user_id: studentId,
    topic_id: topicId,
    resource_id: resourceId,
    resource_type: resourceType,
    completed: true,
  });

  if (logInsertError) {
    if (logInsertError.code === "23505") {
      return respond(
        {
          message: "Resource already consumed. No duplicate XP awarded.",
          resource_id: resourceId,
          topic_id: topicId,
          resource_type: resourceType,
          student_progress_updated: true,
        },
        200,
      );
    }
    return respond({ error: "Failed to insert student_resource_logs row", details: logInsertError.message }, 500);
  }

  const { error: xpError } = await supabase.rpc("increment_xp", {
    user_id_input: studentId,
    xp_amount: finalXpAwarded,
  });

  if (xpError) return respond({ error: "Failed to award XP", details: xpError.message }, 500);

  const { error: streakError } = await supabase.from("user_streaks").upsert({
    user_id: studentId,
    last_activity_date: localDateStr,
    current_streak_days: newStreakDays,
    longest_streak_days: newLongestStreak,
    updated_at: nowIso,
  });

  if (streakError) return respond({ error: "XP was awarded but streak update failed", details: streakError.message }, 500);

  return respond(
    {
      resource_id: resourceId,
      topic_id: topicId,
      resource_type: resourceType,
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
  const { data: progressRows, error: readError } = await supabase
    .from("student_progress")
    .select("id, status, started_at, completed_at, format_served")
    .eq("user_id", userId)
    .eq("topic_id", topicId)
    .order("started_at", { ascending: true })
    .limit(1);

  if (readError) return { ok: false, error: readError.message };

  const existingProgress = Array.isArray(progressRows) && progressRows.length > 0 ? progressRows[0] : null;

  if (existingProgress?.id) {
    const { error: updateError } = await supabase
      .from("student_progress")
      .update({
        status: isTopicCompletion ? "completed" : existingProgress.status ?? "in_progress",
        format_served: resourceType,
        started_at: existingProgress.started_at ?? nowIso,
        completed_at: isTopicCompletion ? nowIso : existingProgress.completed_at,
      })
      .eq("id", existingProgress.id);

    if (updateError) return { ok: false, error: updateError.message };
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

  if (insertError) return { ok: false, error: insertError.message };
  return { ok: true };
}

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
