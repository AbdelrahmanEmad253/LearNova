// ============================================================
// LearNova Edge Function: use-perk
// Location: supabase/functions/use-perk/index.ts
// ============================================================
//
// Purpose:
// - Allows students to use Owl of Wisdom and Sly Fox perks on MODULE MCQ exam questions.
// - Reads module_assessment_questions only.
// - Does NOT support level written questions, diagnostic questions, or weekly challenge questions.
// - Deducts the perk only after confirming the question is a valid module MCQ question
//   and the perk effect can be returned safely.
//
// Request body:
// {
//   "perk_type": "owl_hint" | "sly_fox",
//   "question_id": "module_assessment_questions.id"
// }
//
// Response examples:
// Owl:
// {
//   "ok": true,
//   "perk_type": "owl_hint",
//   "remaining": 1,
//   "question_source": "module_assessment_questions",
//   "effect": {
//     "type": "hint",
//     "hint": "Think about..."
//   }
// }
//
// Sly Fox:
// {
//   "ok": true,
//   "perk_type": "sly_fox",
//   "remaining": 1,
//   "question_source": "module_assessment_questions",
//   "effect": {
//     "type": "eliminate_option",
//     "eliminated_option_key": "B",
//     "eliminated_option_value": "Wrong answer text"
//   }
// }
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

type PerkType = "owl_hint" | "sly_fox";
const VALID_PERK_TYPES: PerkType[] = ["owl_hint", "sly_fox"];

const PERK_COLUMN: Record<PerkType, "owl_hint_count" | "sly_fox_count"> = {
  owl_hint: "owl_hint_count",
  sly_fox: "sly_fox_count",
};

type ModuleQuestion = {
  id: string;
  question_text: string | null;
  options: unknown;
  correct_answer: unknown;
  mitchy_hint?: string | null;
};

type OptionCandidate = {
  key: string;
  value: string;
  isCorrect: boolean;
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
    return respond({ ok: false, error: "Method not allowed" }, 405);
  }

  let body: { perk_type?: string; question_id?: string };

  try {
    body = await req.json();
  } catch {
    return respond({ ok: false, error: "Invalid JSON body" }, 400);
  }

  const perkType = body.perk_type as PerkType | undefined;
  const questionId = body.question_id;

  if (!perkType || !VALID_PERK_TYPES.includes(perkType)) {
    return respond({ ok: false, error: "perk_type must be 'owl_hint' or 'sly_fox'" }, 400);
  }

  if (!questionId) {
    return respond({ ok: false, error: "question_id is required" }, 400);
  }

  // ── Auth ──────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");

  if (!authHeader) {
    return respond({ ok: false, error: "Missing Authorization" }, 401);
  }

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: authError,
  } = await clientForAuth.auth.getUser();

  if (authError || !user) {
    return respond({ ok: false, error: "Unauthorized" }, 401);
  }

  const studentId = user.id;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  // ── Read the module MCQ question first ─────────────────────
  // This is the key fix:
  // perks are valid for module_assessment_questions, not level/challenge/diagnostic question tables.
  const { data: question, error: questionError } = await supabase
    .from("module_assessment_questions")
    .select("id, question_text, options, correct_answer, mitchy_hint")
    .eq("id", questionId)
    .maybeSingle();

  if (questionError) {
    console.error("module_assessment_questions read error:", questionError);
    return respond(
      {
        ok: false,
        error: "Failed to read module MCQ question",
        details: questionError.message,
      },
      500,
    );
  }

  if (!question) {
    return respond(
      {
        ok: false,
        error: "This perk can only be used on module MCQ exam questions.",
        reason: "question_not_found_in_module_assessment_questions",
        question_id: questionId,
      },
      200,
    );
  }

  const moduleQuestion = question as ModuleQuestion;

  // ── Build the perk effect BEFORE decrementing ───────────────
  const effectResult =
    perkType === "owl_hint"
      ? buildOwlHintEffect(moduleQuestion)
      : buildSlyFoxEffect(moduleQuestion);

  if (!effectResult.ok) {
    return respond(
      {
        ok: false,
        error: effectResult.error,
        reason: effectResult.reason,
        question_id: questionId,
        question_source: "module_assessment_questions",
      },
      200,
    );
  }

  // ── Read current perk balance ───────────────────────────────
  const { data: perks, error: perksError } = await supabase
    .from("student_perks")
    .select("owl_hint_count, sly_fox_count")
    .eq("user_id", studentId)
    .maybeSingle();

  if (perksError) {
    console.error("student_perks read error:", perksError);
    return respond({ ok: false, error: "Failed to read perk balance" }, 500);
  }

  if (!perks) {
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  const column = PERK_COLUMN[perkType];
  const currentCount = Number(perks[column] ?? 0);

  if (!Number.isFinite(currentCount) || currentCount <= 0) {
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  // ── Decrement only after successful validation/effect build ─
  const newCount = currentCount - 1;

  const updatePayload: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };
  updatePayload[column] = newCount;

  const { data: updatedRows, error: updateError } = await supabase
    .from("student_perks")
    .update(updatePayload)
    .eq("user_id", studentId)
    .eq(column, currentCount)
    .select("user_id");

  if (updateError) {
    console.error("student_perks update error:", updateError);
    return respond({ ok: false, error: "Failed to use perk" }, 500);
  }

  if (!updatedRows || updatedRows.length === 0) {
    return respond(
      {
        ok: false,
        error: "Perk balance changed. Please refresh and try again.",
        reason: "perk_balance_race_condition",
      },
      409,
    );
  }

  return respond(
    {
      ok: true,
      remaining: newCount,
      perk_type: perkType,
      question_id: questionId,
      question_source: "module_assessment_questions",
      effect: effectResult.effect,
    },
    200,
  );
});

function buildOwlHintEffect(question: ModuleQuestion):
  | { ok: true; effect: { type: "hint"; hint: string } }
  | { ok: false; error: string; reason: string } {
  const hint = typeof question.mitchy_hint === "string" ? question.mitchy_hint.trim() : "";

  if (!hint) {
    return {
      ok: false,
      error: "No Owl of Wisdom hint is available for this module question.",
      reason: "missing_mitchy_hint",
    };
  }

  return {
    ok: true,
    effect: {
      type: "hint",
      hint,
    },
  };
}

function buildSlyFoxEffect(question: ModuleQuestion):
  | {
      ok: true;
      effect: {
        type: "eliminate_option";
        eliminated_option_key: string;
        eliminated_option_value: string;
      };
    }
  | { ok: false; error: string; reason: string } {
  const parsedOptions = parseOptions(question.options, question.correct_answer);

  if (!parsedOptions.ok) {
    return {
      ok: false,
      error: parsedOptions.error,
      reason: parsedOptions.reason,
    };
  }

  const wrongOptions = parsedOptions.options.filter((option) => !option.isCorrect);

  if (wrongOptions.length === 0) {
    return {
      ok: false,
      error: "Sly Fox could not safely find an incorrect option to eliminate.",
      reason: "no_wrong_options_found",
    };
  }

  const selectedWrong = wrongOptions[randomIndex(wrongOptions.length)];

  return {
    ok: true,
    effect: {
      type: "eliminate_option",
      eliminated_option_key: selectedWrong.key,
      eliminated_option_value: selectedWrong.value,
    },
  };
}

function parseOptions(
  rawOptions: unknown,
  rawCorrectAnswer: unknown,
):
  | { ok: true; options: OptionCandidate[] }
  | { ok: false; error: string; reason: string } {
  const correctAnswer = normalizeAnswer(rawCorrectAnswer);

  if (!correctAnswer) {
    return {
      ok: false,
      error: "Sly Fox requires a correct_answer value on the module question.",
      reason: "missing_correct_answer",
    };
  }

  let options = rawOptions;

  if (typeof options === "string") {
    try {
      options = JSON.parse(options);
    } catch {
      return {
        ok: false,
        error: "Sly Fox requires options to be valid JSON.",
        reason: "options_not_json",
      };
    }
  }

  const candidates: OptionCandidate[] = [];

  if (Array.isArray(options)) {
    options.forEach((value, index) => {
      const key = indexToOptionKey(index);
      const textValue = stringifyOptionValue(value);
      candidates.push({
        key,
        value: textValue,
        isCorrect:
          normalizeAnswer(key) === correctAnswer ||
          normalizeAnswer(textValue) === correctAnswer,
      });
    });
  } else if (options && typeof options === "object") {
    Object.entries(options as Record<string, unknown>).forEach(([key, value]) => {
      const textValue = stringifyOptionValue(value);
      candidates.push({
        key,
        value: textValue,
        isCorrect:
          normalizeAnswer(key) === correctAnswer ||
          normalizeAnswer(textValue) === correctAnswer,
      });
    });
  } else {
    return {
      ok: false,
      error: "Sly Fox requires MCQ options on the module question.",
      reason: "missing_or_invalid_options",
    };
  }

  const usableCandidates = candidates.filter((option) => option.value.trim().length > 0);

  if (usableCandidates.length < 2) {
    return {
      ok: false,
      error: "Sly Fox requires at least two usable options.",
      reason: "not_enough_options",
    };
  }

  const correctCount = usableCandidates.filter((option) => option.isCorrect).length;

  if (correctCount === 0) {
    return {
      ok: false,
      error: "Sly Fox could not safely identify the correct answer, so it will not eliminate any option.",
      reason: "correct_answer_not_matched_to_options",
    };
  }

  return { ok: true, options: usableCandidates };
}

function normalizeAnswer(value: unknown): string {
  if (value === null || value === undefined) return "";

  let text = String(value).trim().toLowerCase();

  // Convert common labels like "A.", "B)", "option C", "answer: D"
  // into the bare option key when possible.
  text = text.replace(/^answer\s*:\s*/i, "").trim();
  text = text.replace(/^option\s+/i, "").trim();

  const singleLetterMatch = text.match(/^([a-z])[\.\)]?$/);
  if (singleLetterMatch) return singleLetterMatch[1];

  return text.replace(/\s+/g, " ");
}

function stringifyOptionValue(value: unknown): string {
  if (value === null || value === undefined) return "";

  if (typeof value === "string") return value;

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

function indexToOptionKey(index: number): string {
  return String.fromCharCode("A".charCodeAt(0) + index);
}

function randomIndex(length: number): number {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return array[0] % length;
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
