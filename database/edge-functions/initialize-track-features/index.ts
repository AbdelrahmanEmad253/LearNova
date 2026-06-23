import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INIT_TRACK_FEATURES_API_KEY = Deno.env.get("INIT_TRACK_FEATURES_API_KEY")!;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, x-api-key",
      },
    });
  }

  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  const apiKey = req.headers.get("x-api-key");
  if (!apiKey || apiKey !== INIT_TRACK_FEATURES_API_KEY) {
    return respond({ error: "Unauthorized" }, 401);
  }

  let body: {
    user_id?: string;
    assigned_track?: string | null;
    learning_style?: string | null;
    learning_mode?: string | null;
  };

  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { user_id } = body;
  if (!user_id) return respond({ error: "user_id is required" }, 400);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const { data, error } = await supabase.rpc("initialize_student_after_diagnostic", {
    p_user_id: user_id,
    p_assigned_track: body.assigned_track ?? null,
    p_learning_style: body.learning_style ?? null,
    p_learning_mode: body.learning_mode ?? null,
  });

  if (error) {
    console.error("initialize_student_after_diagnostic RPC error:", error);
    return respond(
      {
        error: "Failed to initialize track features and diagnostic rewards",
        details: error.message,
      },
      500,
    );
  }

  const result = data as Record<string, unknown>;

  if (result.ok === false) {
    return respond(result, 409);
  }

  return respond(result, 200);
});

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
