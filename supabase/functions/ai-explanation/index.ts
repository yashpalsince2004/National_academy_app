/**
 * AI Explanation Generator Edge Function
 * ─────────────────────────────────────────────────────────────────────────────
 * Route: POST /functions/v1/ai-explanation
 *
 * PURPOSE
 * ───────
 * Given a question (text) from a DPP or any source, generates a detailed,
 * pedagogically sound explanation with step-by-step reasoning, common mistakes,
 * shortcut methods, and NCERT references.
 *
 * This is the "Explain This" button feature in your Flutter app.
 *
 * REQUEST BODY (JSON)
 * ───────────────────
 * {
 *   "question": "A body is moving with uniform velocity. What is its acceleration?",
 *   "options": ["0 m/s²", "1 m/s²", "9.8 m/s²", "Cannot be determined"],
 *   "correctAnswer": "A",
 *   "exam": "JEE",
 *   "subject": "Physics",
 *   "chapter": "Laws of Motion",
 *   "language": "English"            // Optional — defaults to English
 * }
 *
 * RESPONSE BODY (JSON)
 * ─────────────────────
 * {
 *   "success": true,
 *   "explanation": {
 *     "correct_answer": "A. 0 m/s²",
 *     "step_by_step": "...",
 *     "why_others_incorrect": { "A": "...", "B": "...", "C": "...", "D": "..." },
 *     "shortcut": "...",
 *     "common_mistake": "...",
 *     "ncert_reference": "..."
 *   }
 * }
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { handleCors, jsonOk } from "../shared/cors.ts";
import { withErrorHandler, AppError } from "../shared/error_handler.ts";
import { requireAuth } from "../shared/auth.ts";
import { checkRateLimit } from "../shared/rate_limiter.ts";
import { AiClient } from "../shared/ai_client.ts";
import { parseAiJson } from "../shared/json_parser.ts";
import { logAiCall } from "../shared/telemetry.ts";

// ── JSON Schema for structured explanation output ─────────────────────────
const EXPLANATION_SCHEMA = {
  type: "OBJECT",
  properties: {
    correct_answer:    { type: "STRING" },
    step_by_step:      { type: "STRING" },
    why_others_incorrect: {
      type: "OBJECT",
      properties: {
        A: { type: "STRING" },
        B: { type: "STRING" },
        C: { type: "STRING" },
        D: { type: "STRING" },
      },
      required: ["A", "B", "C", "D"],
    },
    shortcut:         { type: "STRING" },
    common_mistake:   { type: "STRING" },
    ncert_reference:  { type: "STRING" },
    memory_tip:       { type: "STRING" },
  },
  required: ["correct_answer", "step_by_step", "why_others_incorrect", "ncert_reference"],
};

// ── Handler ───────────────────────────────────────────────────────────────

serve(
  withErrorHandler(async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs = Date.now();
    const { id: userId, adminClient } = await requireAuth(req);

    await checkRateLimit(adminClient, userId, "ai-explanation");

    // Parse request
    const body = await req.json().catch(() => null);
    if (!body) {
      throw new AppError("BAD_REQUEST", "Invalid JSON request body.");
    }

    const {
      question,
      options,
      correctAnswer,
      exam,
      subject,
      chapter,
      language = "English",
    } = body;

    if (!question || typeof question !== "string") {
      throw new AppError("BAD_REQUEST", "The 'question' field is required and must be a string.");
    }
    if (!subject || !chapter) {
      throw new AppError("BAD_REQUEST", "'subject' and 'chapter' are required.");
    }

    // Build options text
    const optionLetters = ["A", "B", "C", "D"];
    const optionsText = Array.isArray(options) && options.length === 4
      ? options.map((opt, i) => `${optionLetters[i]}. ${opt}`).join("\n")
      : "(No options provided — explain the concept directly)";

    const systemPrompt = `You are a Senior Faculty and Subject Matter Expert at National Academy.
Your role is to provide the most comprehensive, clear, and pedagogically correct explanations 
for exam questions to help students deeply understand concepts — not just memorise answers.

CRITICAL RULES:
1. All mathematical formulas, equations, and symbols MUST use LaTeX: $inline$ and $$block$$
2. Explanations must be in ${language}
3. NCERT references must be precise (Class, Part, Chapter, Section, Page range)
4. Never use placeholder text — every field must have real, helpful content`;

    const userPrompt = `QUESTION:
${question}

OPTIONS:
${optionsText}

CORRECT ANSWER: ${correctAnswer}

EXAM: ${exam ?? "General"}
SUBJECT: ${subject}
CHAPTER: ${chapter}

Generate a complete structured explanation JSON object for this question.
Explain WHY the correct answer is correct and WHY each wrong option is incorrect.
Include a memory tip if possible.`;

    const ai = new AiClient("gemini");
    let result;
    let aiStatus: "success" | "failed" = "failed";
    let aiError: string | undefined;

    try {
      result = await ai.generateContent({
        systemPrompt,
        userPrompt,
        jsonSchema: EXPLANATION_SCHEMA,
        temperature: 0.1, // Very low — we need accurate explanations
      });
      aiStatus = "success";
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      throw new AppError(
        "AI_PROVIDER_ERROR",
        "Could not generate explanation. Please try again.",
        err
      );
    } finally {
      await logAiCall(adminClient, {
        userId,
        feature: "ai-explanation",
        model: "gemini-2.5-flash",
        provider: "gemini",
        exam,
        subject,
        chapter,
        promptTokens: result?.promptTokens ?? 0,
        completionTokens: result?.completionTokens ?? 0,
        latencyMs: Date.now() - startMs,
        status: aiStatus,
        error: aiError,
      });
    }

    const explanation = parseAiJson(result!.text);

    return jsonOk({
      success: true,
      explanation,
    });
  })
);
