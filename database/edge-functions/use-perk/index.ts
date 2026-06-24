// ============================================================
// LearNova Edge Function: use-perk
// Location: supabase/functions/use-perk/index.ts
// ============================================================
//
// Purpose:
// - Allows students to use Owl of Wisdom and Sly Fox perks on MODULE MCQ exam questions.
// - Sly Fox now uses the hardcoded DB column:
//     module_assessment_questions.sly_fox_removed_option
//
// Required DB column:
//   module_assessment_questions.sly_fox_removed_option text
//
// Rule stored in DB:
//   correct_answer = A -> remove D
//   correct_answer = D -> remove A
//   correct_answer = B -> remove C
//   correct_answer = C -> remove B
//
// Flutter should remove/disable the option matching:
//   response.effect.eliminated_option_key
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
  sly_fox_removed_option?: string | null;
};

type OptionValue = {
  key: string;
  value: string;
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
  const { data: question, error: questionError } = await supabase
    .from("module_assessment_questions")
    .select("id, question_text, options, correct_answer, mitchy_hint, sly_fox_removed_option")
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
        eliminated_option_value: string | null;
      };
    }
  | { ok: false; error: string; reason: string } {
  const removeKey = normalizeOptionKey(question.sly_fox_removed_option);

  if (!removeKey) {
    return {
      ok: false,
      error: "Sly Fox removed option is missing for this module question.",
      reason: "missing_sly_fox_removed_option",
    };
  }

  if (!["A", "B", "C", "D"].includes(removeKey)) {
    return {
      ok: false,
      error: "Sly Fox removed option must be A, B, C, or D.",
      reason: "invalid_sly_fox_removed_option",
    };
  }

  const optionValue = findOptionValueByKey(question.options, removeKey);

  return {
    ok: true,
    effect: {
      type: "eliminate_option",
      eliminated_option_key: removeKey,
      eliminated_option_value: optionValue,
    },
  };
}

function normalizeOptionKey(value: unknown): string {
  if (value === null || value === undefined) return "";

  let text = String(value).trim().toUpperCase();

  text = text.replace(/^ANSWER\s*:\s*/i, "").trim();
  text = text.replace(/^CORRECT\s*ANSWER\s*:\s*/i, "").trim();
  text = text.replace(/^OPTION[\s_-]*/i, "").trim();
  text = text.replace(/[\.\)]$/g, "").trim();

  if (/^[A-D]$/.test(text)) return text;

  return "";
}

function findOptionValueByKey(rawOptions: unknown, key: string): string | null {
  let options = rawOptions;

  if (typeof options === "string") {
    try {
      options = JSON.parse(options);
    } catch {
      return null;
    }
  }

  const normalizedKey = normalizeOptionKey(key);

  if (!normalizedKey) return null;

  // Your current common shape:
  // { "choices": [{ "label": "...", "value": "A" }] }
  if (options && typeof options === "object" && !Array.isArray(options)) {
    const objectOptions = options as Record<string, unknown>;

    if (Array.isArray(objectOptions.choices)) {
      for (const choice of objectOptions.choices) {
        if (!choice || typeof choice !== "object") continue;

        const choiceObj = choice as Record<string, unknown>;
        const choiceKey = normalizeOptionKey(choiceObj.value ?? choiceObj.key ?? choiceObj.option ?? choiceObj.letter);

        if (choiceKey === normalizedKey) {
          return stringifyOptionText(choiceObj.label ?? choiceObj.text ?? choiceObj.value);
        }
      }
    }

    // Also support { "A": "text", "B": "text" }
    if (Object.prototype.hasOwnProperty.call(objectOptions, normalizedKey)) {
      return stringifyOptionText(objectOptions[normalizedKey]);
    }

    // Also support lowercase keys.
    const lowerKey = normalizedKey.toLowerCase();
    if (Object.prototype.hasOwnProperty.call(objectOptions, lowerKey)) {
      return stringifyOptionText(objectOptions[lowerKey]);
    }
  }

  // Also support arrays:
  // ["A text", "B text", "C text", "D text"]
  // [{ "label": "A text", "value": "A" }]
  if (Array.isArray(options)) {
    for (let i = 0; i < options.length; i++) {
      const fallbackKey = String.fromCharCode("A".charCodeAt(0) + i);
      const item = options[i];

      if (item && typeof item === "object") {
        const itemObj = item as Record<string, unknown>;
        const itemKey = normalizeOptionKey(itemObj.value ?? itemObj.key ?? itemObj.option ?? itemObj.letter ?? fallbackKey);

        if (itemKey === normalizedKey) {
          return stringifyOptionText(itemObj.label ?? itemObj.text ?? itemObj.value);
        }
      } else if (fallbackKey === normalizedKey) {
        return stringifyOptionText(item);
      }
    }
  }

  return null;
}

function stringifyOptionText(value: unknown): string | null {
  if (value === null || value === undefined) return null;

  if (typeof value === "string") return value;

  if (typeof value === "number" || typeof value === "boolean") return String(value);

  if (typeof value === "object") {
    const objectValue = value as Record<string, unknown>;

    for (const field of ["label", "text", "value", "answer", "content", "title"]) {
      if (objectValue[field] !== null && objectValue[field] !== undefined) {
        return String(objectValue[field]);
      }
    }

    try {
      return JSON.stringify(value);
    } catch {
      return String(value);
    }
  }

  return String(value);
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
