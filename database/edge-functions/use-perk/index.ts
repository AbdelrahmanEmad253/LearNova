// ============================================================
// LearNova Edge Function: use-perk
// Location: supabase/functions/use-perk/index.ts
// ============================================================
//
// Fixes in this version:
// 1. Sly Fox supports the actual module_assessment_questions.options shape:
//    {
//      "choices": [
//        { "label": "Answer text", "value": "A" },
//        { "label": "Answer text", "value": "B" }
//      ]
//    }
// 2. Sly Fox also supports legacy shapes:
//    { "A": "text", "B": "text" }
//    ["text A", "text B"]
//    [{ "text": "text A", "value": "A" }]
// 3. It matches correct_answer by option key, value, label, text, numeric index, or embedded flags.
// 4. It does not decrement perks unless the effect can be returned safely.
// 5. It only supports module MCQ questions from module_assessment_questions.
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
  keyNormalized: string;
  index: number;
  value: string;
  valueNormalized: string;
  raw: unknown;
  embeddedCorrect: boolean;
  isCorrect: boolean;
};

type CorrectAnswer = {
  raw: unknown;
  normalized: string;
  possibleKeys: Set<string>;
  possibleTexts: Set<string>;
  possibleIndexes: Set<number>;
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

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond({ ok: false, error: "Missing Authorization" }, 401);

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: authError,
  } = await clientForAuth.auth.getUser();

  if (authError || !user) return respond({ ok: false, error: "Unauthorized" }, 401);

  const studentId = user.id;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const { data: question, error: questionError } = await supabase
    .from("module_assessment_questions")
    .select("id, question_text, options, correct_answer, mitchy_hint")
    .eq("id", questionId)
    .maybeSingle();

  if (questionError) {
    console.error("module_assessment_questions read error:", questionError);
    return respond(
      { ok: false, error: "Failed to read module MCQ question", details: questionError.message },
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
        debug: effectResult.debug ?? null,
      },
      200,
    );
  }

  const { data: perks, error: perksError } = await supabase
    .from("student_perks")
    .select("owl_hint_count, sly_fox_count")
    .eq("user_id", studentId)
    .maybeSingle();

  if (perksError) {
    console.error("student_perks read error:", perksError);
    return respond({ ok: false, error: "Failed to read perk balance" }, 500);
  }

  if (!perks) return respond({ ok: false, error: "No perks remaining" }, 200);

  const column = PERK_COLUMN[perkType];
  const currentCount = Number(perks[column] ?? 0);

  if (!Number.isFinite(currentCount) || currentCount <= 0) {
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  const newCount = currentCount - 1;
  const updatePayload: Record<string, unknown> = { updated_at: new Date().toISOString() };
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
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  const hint = typeof question.mitchy_hint === "string" ? question.mitchy_hint.trim() : "";

  if (!hint) {
    return {
      ok: false,
      error: "No Owl of Wisdom hint is available for this module question.",
      reason: "missing_mitchy_hint",
    };
  }

  return { ok: true, effect: { type: "hint", hint } };
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
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  const parsed = parseOptions(question.options, question.correct_answer);

  if (!parsed.ok) {
    return { ok: false, error: parsed.error, reason: parsed.reason, debug: parsed.debug };
  }

  const wrongOptions = parsed.options.filter((option) => !option.isCorrect);

  if (wrongOptions.length === 0) {
    return {
      ok: false,
      error: "Sly Fox could not safely find an incorrect option to eliminate.",
      reason: "no_wrong_options_found",
      debug: { options: parsed.options.map(debugOption) },
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
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  let parsedOptions = rawOptions;

  if (typeof parsedOptions === "string") {
    try {
      parsedOptions = JSON.parse(parsedOptions);
    } catch {
      return {
        ok: false,
        error: "Sly Fox requires options to be valid JSON.",
        reason: "options_not_json",
        debug: { raw_options_preview: String(rawOptions).slice(0, 500) },
      };
    }
  }

  const extractedOptions = extractOptionList(parsedOptions);

  if (!extractedOptions.ok) return extractedOptions;

  const candidates = extractedOptions.values
    .map((item, index) => buildCandidate(item.key, item.value, index))
    .filter((option) => option.value.trim().length > 0);

  if (candidates.length < 2) {
    return {
      ok: false,
      error: "Sly Fox requires at least two usable options.",
      reason: "not_enough_options",
      debug: { candidates_count: candidates.length },
    };
  }

  const embeddedCorrectCount = candidates.filter((option) => option.embeddedCorrect).length;
  if (embeddedCorrectCount === 1) {
    candidates.forEach((option) => (option.isCorrect = option.embeddedCorrect));
    return { ok: true, options: candidates };
  }

  const correct = parseCorrectAnswer(rawCorrectAnswer, candidates.length);

  if (
    !correct.normalized &&
    correct.possibleKeys.size === 0 &&
    correct.possibleTexts.size === 0 &&
    correct.possibleIndexes.size === 0
  ) {
    return {
      ok: false,
      error: "Sly Fox requires a correct_answer value on the module question.",
      reason: "missing_correct_answer",
      debug: { raw_correct_answer: rawCorrectAnswer, options: candidates.map(debugOption) },
    };
  }

  candidates.forEach((option) => {
    option.isCorrect = doesOptionMatchCorrect(option, correct);
  });

  let correctCount = candidates.filter((option) => option.isCorrect).length;

  if (correctCount === 0) {
    const strippedCorrect = stripLeadingOptionLabel(correct.normalized);
    candidates.forEach((option) => {
      if (stripLeadingOptionLabel(option.valueNormalized) === strippedCorrect) {
        option.isCorrect = true;
      }
    });
    correctCount = candidates.filter((option) => option.isCorrect).length;
  }

  if (correctCount === 0) {
    return {
      ok: false,
      error: "Sly Fox could not safely identify the correct answer, so it will not eliminate any option.",
      reason: "correct_answer_not_matched_to_options",
      debug: {
        raw_correct_answer: rawCorrectAnswer,
        parsed_correct_answer: debugCorrect(correct),
        extracted_options_shape: extractedOptions.shape,
        options: candidates.map(debugOption),
      },
    };
  }

  if (correctCount > 1) {
    return {
      ok: false,
      error: "Sly Fox found more than one correct answer match, so it will not eliminate any option.",
      reason: "multiple_correct_answer_matches",
      debug: {
        raw_correct_answer: rawCorrectAnswer,
        parsed_correct_answer: debugCorrect(correct),
        options: candidates.map(debugOption),
      },
    };
  }

  return { ok: true, options: candidates };
}

function extractOptionList(options: unknown):
  | { ok: true; shape: string; values: Array<{ key: string; value: unknown }> }
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  if (Array.isArray(options)) {
    return {
      ok: true,
      shape: "array",
      values: options.map((value, index) => ({
        key: extractOptionKey(value) || indexToOptionKey(index),
        value,
      })),
    };
  }

  if (!options || typeof options !== "object") {
    return {
      ok: false,
      error: "Sly Fox requires MCQ options on the module question.",
      reason: "missing_or_invalid_options",
      debug: { raw_options_type: typeof options },
    };
  }

  const objectOptions = options as Record<string, unknown>;

  // Actual LearnNova generated module MCQ shape.
  if (Array.isArray(objectOptions.choices)) {
    return {
      ok: true,
      shape: "object.choices[]",
      values: objectOptions.choices.map((choice, index) => ({
        key: extractOptionKey(choice) || indexToOptionKey(index),
        value: choice,
      })),
    };
  }

  // Other common wrapper shapes.
  for (const field of ["options", "answers", "answer_choices", "answerChoices"]) {
    const value = objectOptions[field];
    if (Array.isArray(value)) {
      return {
        ok: true,
        shape: `object.${field}[]`,
        values: value.map((choice, index) => ({
          key: extractOptionKey(choice) || indexToOptionKey(index),
          value: choice,
        })),
      };
    }
    if (value && typeof value === "object") {
      return {
        ok: true,
        shape: `object.${field}{}`,
        values: Object.entries(value as Record<string, unknown>).map(([key, choice]) => ({ key, value: choice })),
      };
    }
  }

  // Legacy direct object shape: { "A": "...", "B": "..." }
  return {
    ok: true,
    shape: "object.direct_key_value",
    values: Object.entries(objectOptions)
      .filter(([key]) => !["source", "context", "metadata"].includes(key))
      .map(([key, value]) => ({ key, value })),
  };
}

function buildCandidate(key: string, value: unknown, index: number): OptionCandidate {
  const displayValue = extractOptionText(value);
  return {
    key,
    keyNormalized: normalizeKey(key),
    index,
    value: displayValue,
    valueNormalized: normalizeText(displayValue),
    raw: value,
    embeddedCorrect: extractEmbeddedCorrectFlag(value),
    isCorrect: false,
  };
}

function parseCorrectAnswer(rawCorrectAnswer: unknown, optionCount: number): CorrectAnswer {
  const extracted = extractCorrectAnswerValue(rawCorrectAnswer);
  const normalized = normalizeText(extracted);
  const possibleKeys = new Set<string>();
  const possibleTexts = new Set<string>();
  const possibleIndexes = new Set<number>();

  if (!normalized) {
    return { raw: rawCorrectAnswer, normalized, possibleKeys, possibleTexts, possibleIndexes };
  }

  possibleTexts.add(normalized);

  const key = normalizeKey(normalized);
  if (key) possibleKeys.add(key);

  const keyFromPhrase = extractOptionKeyFromPhrase(normalized);
  if (keyFromPhrase) possibleKeys.add(keyFromPhrase);

  if (/^\d+$/.test(normalized)) {
    const n = Number(normalized);
    if (Number.isInteger(n)) {
      if (n >= 0 && n < optionCount) possibleIndexes.add(n);
      if (n >= 1 && n <= optionCount) possibleIndexes.add(n - 1);
    }
  }

  return { raw: rawCorrectAnswer, normalized, possibleKeys, possibleTexts, possibleIndexes };
}

function doesOptionMatchCorrect(option: OptionCandidate, correct: CorrectAnswer): boolean {
  if (correct.possibleKeys.has(option.keyNormalized)) return true;
  if (correct.possibleTexts.has(option.valueNormalized)) return true;
  if (correct.possibleIndexes.has(option.index)) return true;
  return false;
}

function extractCorrectAnswerValue(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (["string", "number", "boolean"].includes(typeof value)) return String(value);

  if (typeof value === "object") {
    const objectValue = value as Record<string, unknown>;
    for (const field of ["correct_answer", "correctAnswer", "answer", "key", "option", "value", "label", "text"]) {
      const fieldValue = objectValue[field];
      if (fieldValue !== null && fieldValue !== undefined && String(fieldValue).trim()) {
        return String(fieldValue);
      }
    }
  }

  return String(value);
}

function extractOptionKey(value: unknown): string | null {
  if (!value || typeof value !== "object") return null;
  const objectValue = value as Record<string, unknown>;

  // In the current table, choices are { label: "text", value: "A" }.
  // So value is the option key when it looks like A/B/C/D.
  const valueField = objectValue.value;
  if (valueField !== null && valueField !== undefined) {
    const normalizedValue = normalizeKey(String(valueField));
    if (normalizedValue) return String(valueField);
  }

  for (const field of ["key", "option_key", "optionKey", "letter", "id"]) {
    const fieldValue = objectValue[field];
    if (fieldValue !== null && fieldValue !== undefined && String(fieldValue).trim()) {
      return String(fieldValue);
    }
  }

  return null;
}

function extractOptionText(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (["string", "number", "boolean"].includes(typeof value)) return String(value);

  if (typeof value === "object") {
    const objectValue = value as Record<string, unknown>;

    // In the current table, choices are { label: "answer text", value: "A" }.
    for (const field of ["label", "text", "option_text", "optionText", "answer", "content", "title"]) {
      const fieldValue = objectValue[field];
      if (fieldValue !== null && fieldValue !== undefined && String(fieldValue).trim()) {
        return String(fieldValue);
      }
    }

    const valueField = objectValue.value;
    if (valueField !== null && valueField !== undefined) return String(valueField);
  }

  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

function extractEmbeddedCorrectFlag(value: unknown): boolean {
  if (!value || typeof value !== "object") return false;
  const objectValue = value as Record<string, unknown>;

  for (const field of ["is_correct", "isCorrect", "correct", "is_answer", "isAnswer"]) {
    const fieldValue = objectValue[field];
    if (fieldValue === true || fieldValue === 1) return true;
    if (typeof fieldValue === "string") {
      if (["true", "yes", "1", "correct"].includes(fieldValue.trim().toLowerCase())) return true;
    }
  }

  return false;
}

function normalizeKey(value: string): string {
  let text = String(value).trim().toLowerCase();
  text = text.replace(/^answer\s*:\s*/i, "").trim();
  text = text.replace(/^correct\s*answer\s*:\s*/i, "").trim();
  text = text.replace(/^option\s+/i, "").trim();
  text = text.replace(/^option[_-]/i, "").trim();
  const match = text.match(/^([a-z])[\.\)]?$/);
  return match ? match[1] : "";
}

function extractOptionKeyFromPhrase(value: string): string {
  const text = String(value).trim().toLowerCase();
  const patterns = [/^option\s+([a-z])$/, /^option[_-]([a-z])$/, /^([a-z])[\.\)]\s+.+$/, /^([a-z])\s*[-:]\s+.+$/];
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) return match[1];
  }
  return "";
}

function normalizeText(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/^answer\s*:\s*/i, "")
    .replace(/^correct\s*answer\s*:\s*/i, "")
    .replace(/\s+/g, " ");
}

function stripLeadingOptionLabel(value: string): string {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/^answer\s*:\s*/i, "")
    .replace(/^correct\s*answer\s*:\s*/i, "")
    .replace(/^option\s+[a-z][\.\)\-:]*\s*/i, "")
    .replace(/^option[_-][a-z][\.\)\-:]*\s*/i, "")
    .replace(/^[a-z][\.\)\-:]\s*/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

function debugCorrect(correct: CorrectAnswer): Record<string, unknown> {
  return {
    normalized: correct.normalized,
    possible_keys: Array.from(correct.possibleKeys),
    possible_texts: Array.from(correct.possibleTexts),
    possible_indexes: Array.from(correct.possibleIndexes),
  };
}

function debugOption(option: OptionCandidate): Record<string, unknown> {
  return {
    key: option.key,
    key_normalized: option.keyNormalized,
    index: option.index,
    value: option.value,
    value_normalized: option.valueNormalized,
    embedded_correct: option.embeddedCorrect,
    is_correct: option.isCorrect,
  };
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
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
