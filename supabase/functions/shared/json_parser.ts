/**
 * ═══════════════════════════════════════════════════════════════════════════
 * json_parser.ts — Safe JSON Parser & Response Validator
 * Location: supabase/functions/shared/json_parser.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * AI models are instructed to return JSON, but they don't always comply.
 * Common failures:
 * 1. Wraps JSON in ```json ... ``` markdown fences
 * 2. Adds explanatory prose before/after the JSON
 * 3. Generates trailing commas (invalid JSON)
 * 4. Cuts off in the middle if token limit is hit
 * 5. Returns "I'm sorry, I can't..." instead of JSON
 *
 * This module handles all these cases gracefully.
 *
 * JSON MODE IN OPENROUTER
 * ────────────────────────
 * When we set response_format: { type: "json_object" } in the request,
 * the model is constrained to output ONLY JSON. This significantly reduces
 * failures #1-#3. But #4 (truncation) and #5 (refusal) can still happen.
 *
 * VALIDATION
 * ──────────
 * After parsing, we validate the result has the expected structure.
 * Invalid responses are logged and the caller can decide to retry.
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { Errors } from "./errors.ts";

/**
 * Parses a JSON string from AI response text.
 * Handles all common AI formatting quirks.
 *
 * @param rawText - The raw string returned by the AI
 * @returns       - Parsed object
 * @throws Error  - If the text cannot be parsed as valid JSON after all attempts
 */
export function parseAiJson<T = unknown>(rawText: string): T {
  if (!rawText || typeof rawText !== "string" || rawText.trim().length === 0) {
    throw Errors.internal("AI returned an empty response.");
  }

  let text = rawText.trim();

  // ── Step 1: Strip markdown code fences ────────────────────────────────────
  // AI sometimes wraps JSON in: ```json { ... } ```
  // or just: ``` { ... } ```
  if (text.startsWith("```")) {
    // Try extracting content between fences
    const fenceMatch = text.match(/^```(?:json|typescript|js|text)?\s*([\s\S]*?)\s*```$/);
    if (fenceMatch?.[1]) {
      text = fenceMatch[1].trim();
    } else {
      // Fallback: strip opening and closing fences line by line
      text = text
        .replace(/^```(?:json|typescript|js|text)?\s*/i, "")
        .replace(/\s*```\s*$/, "")
        .trim();
    }
  }

  // ── Step 2: Try direct parse ──────────────────────────────────────────────
  try {
    return JSON.parse(text) as T;
  } catch (err) {
    console.error("JSON.parse (direct) failed:", err);
  }

  // ── Step 2b: Repair invalid LaTeX backslashes ──────────────────────────────
  const repairedText = text.replace(/\\([a-zA-Z]{2,})/g, (match, p1) => {
    if (/^[uU][0-9a-fA-F]{4}/.test(p1)) return match;
    return `\\\\${p1}`;
  });
  try {
    return JSON.parse(repairedText) as T;
  } catch (err) {
    console.error("JSON.parse (LaTeX repaired) failed:", err);
  }

  // ── Step 3: Extract JSON object from surrounding text ─────────────────────
  // AI sometimes outputs: "Here is the JSON:\n{ ... }"
  // We find the first { and last } and extract
  const objectMatch = text.match(/\{[\s\S]*\}/);
  if (objectMatch) {
    try {
      return JSON.parse(objectMatch[0]) as T;
    } catch (err) {
      console.error("JSON.parse (object extract) failed:", err);
    }
  }

  // ── Step 4: Extract JSON array from surrounding text ─────────────────────
  const arrayMatch = text.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    try {
      return JSON.parse(arrayMatch[0]) as T;
    } catch (err) {
      console.error("JSON.parse (array extract) failed:", err);
    }
  }

  // ── Step 5: Remove trailing commas (common AI mistake) ───────────────────
  // JSON doesn't allow trailing commas: { "a": 1, } → { "a": 1 }
  const noTrailingCommas = text
    .replace(/,(\s*[}\]])/g, "$1")  // Remove trailing commas before } or ]
    .trim();

  try {
    return JSON.parse(noTrailingCommas) as T;
  } catch (err) {
    console.error("JSON.parse (no trailing commas) failed:", err);
  }

  // ── Final: Log and throw ───────────────────────────────────────────────────
  // Log a preview for server-side debugging (never sent to client)
  console.error(
    JSON.stringify({
      level: "error",
      message: "JSON parse failed after all recovery strategies",
      rawPreview: rawText.slice(0, 500),
    })
  );

  throw Errors.aiProvider(
    `Failed to parse AI response as JSON. ` +
    `Raw preview: ${rawText.slice(0, 200)}`
  );
}

/**
 * Validates that a parsed DPP payload has the required structure.
 *
 * WHY VALIDATE AFTER PARSING?
 * ────────────────────────────
 * Parsing succeeds if the text is valid JSON.
 * But valid JSON doesn't mean it's the right structure.
 * The AI might return: { "error": "I cannot generate this" }
 * Which is valid JSON but useless to us.
 *
 * @returns Array of validation error strings (empty = valid)
 */
export function validateDppPayload(
  payload: Record<string, unknown>,
  expectedQuestionCount: number
): string[] {
  const errors: string[] = [];

  // Root level checks
  if (!payload.title || typeof payload.title !== "string") {
    errors.push("Missing or invalid 'title'");
  }
  if (!payload.questions || !Array.isArray(payload.questions)) {
    errors.push("Missing or invalid 'questions' array");
    return errors; // Cannot continue without questions
  }
  if (payload.questions.length !== expectedQuestionCount) {
    errors.push(
      `Expected ${expectedQuestionCount} questions, got ${payload.questions.length}`
    );
  }

  const seenQuestions = new Set<string>();

  // Per-question checks
  (payload.questions as Array<Record<string, unknown>>).forEach((q, i) => {
    const idx = i + 1;

    if (!q.question || typeof q.question !== "string" || q.question.trim().length < 5) {
      errors.push(`Q${idx}: question text missing or too short`);
    } else {
      const norm = q.question.trim().toLowerCase().replace(/\s+/g, " ");
      if (seenQuestions.has(norm)) {
        errors.push(`Q${idx}: duplicate question detected`);
      }
      seenQuestions.add(norm);
    }

    if (!Array.isArray(q.options) || q.options.length !== 4) {
      errors.push(`Q${idx}: must have exactly 4 options`);
    } else {
      const uniqueOpts = new Set(q.options.map((o: unknown) => String(o).trim().toLowerCase()));
      if (uniqueOpts.size !== 4) {
        errors.push(`Q${idx}: options must be distinct`);
      }
    }

    if (!q.answer || !["A", "B", "C", "D"].includes(String(q.answer).trim().toUpperCase())) {
      errors.push(`Q${idx}: answer must be A, B, C, or D`);
    }

    if (!q.explanation || typeof q.explanation !== "object") {
      errors.push(`Q${idx}: missing explanation object`);
    } else {
      const exp = q.explanation as Record<string, unknown>;
      if (!exp.step_by_step || typeof exp.step_by_step !== "string") {
        errors.push(`Q${idx}: explanation.step_by_step is missing`);
      }
      if (!exp.ncert_reference || typeof exp.ncert_reference !== "string") {
        errors.push(`Q${idx}: explanation.ncert_reference is missing`);
      }
    }
  });

  return errors;
}

/**
 * Validates that an explanation payload has the required structure.
 */
export function validateExplanationPayload(payload: Record<string, unknown>): string[] {
  const errors: string[] = [];

  if (!payload.correct_answer || typeof payload.correct_answer !== "string") {
    errors.push("Missing 'correct_answer'");
  }
  if (!payload.step_by_step || typeof payload.step_by_step !== "string") {
    errors.push("Missing 'step_by_step'");
  }
  if (!payload.ncert_reference || typeof payload.ncert_reference !== "string") {
    errors.push("Missing 'ncert_reference'");
  }
  if (!payload.why_others_incorrect || typeof payload.why_others_incorrect !== "object") {
    errors.push("Missing 'why_others_incorrect' object");
  } else {
    const w = payload.why_others_incorrect as Record<string, unknown>;
    ["A", "B", "C", "D"].forEach((letter) => {
      if (!w[letter] || typeof w[letter] !== "string") {
        errors.push(`why_others_incorrect.${letter} is missing`);
      }
    });
  }

  return errors;
}
