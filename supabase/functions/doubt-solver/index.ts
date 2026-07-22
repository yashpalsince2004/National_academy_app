/**
 * ═══════════════════════════════════════════════════════════════════════════
 * doubt-solver/index.ts — Doubt Solver (Gemini 2.5 Flash)
 * Location: supabase/functions/doubt-solver/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ROUTE: POST /functions/v1/doubt-solver
 * ACCESS: Any authenticated user
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

import { handleCors }                            from "../shared/cors.ts";
import { withErrorBoundary, Errors }             from "../shared/errors.ts";
import { requireAuth }                           from "../shared/auth.ts";
import { createLogger }                          from "../shared/logger.ts";
import { AiFactory }                             from "../shared/ai/factory.ts";
import { parseAiJson }                           from "../shared/json_parser.ts";
import { successResponse }                       from "../shared/response.ts";
import { checkRateLimit, logUsage, estimateCost } from "../shared/rate_limit.ts";

serve(
  withErrorBoundary("doubt-solver", async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs   = Date.now();
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const log       = createLogger("doubt-solver", requestId);
    log.requestStart(req.method, "doubt-solver");

    const auth = await requireAuth(req);
    log.setUser(auth.id);

    await checkRateLimit(auth.adminClient, auth.id, "doubt-solver", auth.tier, log);

    const body = await req.json().catch(() => null);
    if (!body?.doubt) {
      throw Errors.badRequest("body", "'doubt' text is required.");
    }

    const { doubt, exam, subject, chapter, saveToHistory = true } = body;
    log.info("Doubt request validated", { doubtLength: doubt.length, exam, subject, chapter });

    const systemPrompt = `You are an expert AI Doubt Solver at National Academy.
Solve the student's academic doubt with complete conceptual clarity.
Format all formulas in LaTeX ($inline$ and $$block$$). Provide NCERT references. Return strict JSON.`;

    const userPrompt = `STUDENT DOUBT:
${doubt}

CONTEXT: ${[exam, subject, chapter].filter(Boolean).join(" > ") || "General"}

Generate structured JSON answer:
{
  "concept_name": "Core concept name",
  "explanation": "Detailed explanation with LaTeX formulas",
  "key_formula": "$Formula$",
  "example": "Practical example",
  "ncert_reference": "Class X, Chapter Y, Page Z",
  "related_concepts": ["Concept 1", "Concept 2"],
  "exam_tip": "Specific exam tip"
}`;

    const aiProvider = AiFactory.getProvider(log, "gemini");
    let aiResult;
    let aiError: string | undefined;

    try {
      aiResult = await aiProvider.generateJSON("doubt", systemPrompt, userPrompt);
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      await logUsage(auth.adminClient, {
        userId: auth.id, feature: "doubt-solver",
        model: "gemini-2.5-flash", provider: "gemini",
        promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0,
        latencyMs: Date.now() - startMs, status: "failed", error: aiError,
      }, log);
      throw err;
    }

    const answerPayload = parseAiJson<Record<string, unknown>>(aiResult.text);

    let doubtId: string | null = null;
    if (saveToHistory) {
      try {
        const { data: savedDoubt } = await auth.adminClient
          .from("student_doubts")
          .insert({
            student_id:  auth.id,
            doubt_text:  doubt,
            exam,
            subject,
            chapter,
            answer:      answerPayload,
            solved_at:   new Date().toISOString(),
          })
          .select("id")
          .single();

        doubtId = savedDoubt?.id ?? null;
      } catch (dbErr) {
        log.warn("Failed to save doubt to history (non-fatal)", { dbErr: String(dbErr) });
      }
    }

    const cost = estimateCost(aiResult.model, aiResult.promptTokens, aiResult.completionTokens);
    await logUsage(auth.adminClient, {
      userId: auth.id, feature: "doubt-solver",
      model: aiResult.model, provider: aiResult.provider,
      promptTokens: aiResult.promptTokens, completionTokens: aiResult.completionTokens,
      estimatedCostUsd: cost, latencyMs: aiResult.latencyMs, status: "success",
    }, log);

    const totalMs = Date.now() - startMs;
    log.requestEnd(200);

    return successResponse({
      doubtId,
      answer:           answerPayload,
      generationTimeMs: totalMs,
      model:            aiResult.model,
      tokensUsed:       aiResult.totalTokens,
      finishReason:     aiResult.finishReason,
    }, requestId);
  })
);
