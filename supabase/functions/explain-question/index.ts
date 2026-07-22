/**
 * ═══════════════════════════════════════════════════════════════════════════
 * explain-question/index.ts — Question Explanation Generator (Gemini 2.5 Flash)
 * Location: supabase/functions/explain-question/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ROUTE: POST /functions/v1/explain-question
 * ACCESS: Any authenticated user
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

import { handleCors }                                       from "../shared/cors.ts";
import { withErrorBoundary }                                from "../shared/errors.ts";
import { requireAuth }                                      from "../shared/auth.ts";
import { createLogger }                                     from "../shared/logger.ts";
import { validateExplanationRequest }                       from "../shared/validators.ts";
import { AiFactory }                                        from "../shared/ai/factory.ts";
import { buildExplanationSystemPrompt, buildExplanationUserPrompt } from "../shared/prompt_builder.ts";
import { parseAiJson, validateExplanationPayload }          from "../shared/json_parser.ts";
import { successResponse }                                  from "../shared/response.ts";
import { checkRateLimit, logUsage, estimateCost }           from "../shared/rate_limit.ts";
import { generateCacheKey, getCachedResponse, setCachedResponse } from "../shared/cache.ts";

serve(
  withErrorBoundary("explain-question", async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs   = Date.now();
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const log       = createLogger("explain-question", requestId);
    log.requestStart(req.method, "explain-question");

    const auth = await requireAuth(req);
    log.setUser(auth.id);

    await checkRateLimit(auth.adminClient, auth.id, "explain-question", auth.tier, log);

    const rawBody   = await req.json().catch(() => null);
    const validated = validateExplanationRequest(rawBody);

    log.info("Explanation request validated", {
      subject:  validated.subject,
      chapter:  validated.chapter,
      question: validated.question.slice(0, 50) + "...",
    });

    const cacheKey = await generateCacheKey("explain-question", {
      question:      validated.question,
      options:       validated.options,
      correctAnswer: validated.correctAnswer,
      language:      validated.language,
    });

    const cached = await getCachedResponse(auth.adminClient, cacheKey, "explain-question", log);
    if (cached) {
      log.requestEnd(200);
      return successResponse({ explanation: cached.explanation, fromCache: true, generationTimeMs: 0 }, requestId);
    }

    const systemPrompt = buildExplanationSystemPrompt();
    const userPrompt   = buildExplanationUserPrompt(validated);

    const aiProvider = AiFactory.getProvider(log, "gemini");
    let aiResult;
    let aiError: string | undefined;

    try {
      aiResult = await aiProvider.generateJSON("explanation", systemPrompt, userPrompt);
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      await logUsage(auth.adminClient, {
        userId: auth.id, feature: "explain-question",
        model: "gemini-2.5-flash", provider: "gemini",
        promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0,
        latencyMs: Date.now() - startMs, status: "failed", error: aiError,
      }, log);
      throw err;
    }

    const explanationPayload = parseAiJson<Record<string, unknown>>(aiResult.text);
    const validationErrors   = validateExplanationPayload(explanationPayload);
    if (validationErrors.length > 0) {
      log.warn("Explanation payload warnings", { errors: validationErrors });
    }

    const cost = estimateCost(aiResult.model, aiResult.promptTokens, aiResult.completionTokens);
    await logUsage(auth.adminClient, {
      userId: auth.id, feature: "explain-question",
      model: aiResult.model, provider: aiResult.provider,
      promptTokens: aiResult.promptTokens, completionTokens: aiResult.completionTokens,
      estimatedCostUsd: cost, latencyMs: aiResult.latencyMs, status: "success",
    }, log);

    await setCachedResponse(auth.adminClient, cacheKey, "explain-question", { explanation: explanationPayload }, log);

    const totalMs = Date.now() - startMs;
    log.requestEnd(200);

    return successResponse({
      explanation:      explanationPayload,
      fromCache:        false,
      generationTimeMs: totalMs,
      model:            aiResult.model,
      tokensUsed:       aiResult.totalTokens,
      finishReason:     aiResult.finishReason,
    }, requestId);
  })
);
