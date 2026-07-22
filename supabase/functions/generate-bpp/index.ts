/**
 * ═══════════════════════════════════════════════════════════════════════════
 * generate-bpp/index.ts — Batch Practice Problem Generator (Gemini 2.5 Flash)
 * Location: supabase/functions/generate-bpp/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ROUTE: POST /functions/v1/generate-bpp
 * ACCESS: teacher, admin, super_admin
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { handleCors }                          from "../shared/cors.ts";
import { withErrorBoundary }                   from "../shared/errors.ts";
import { requireAuth }                         from "../shared/auth.ts";
import { createLogger }                        from "../shared/logger.ts";
import { validateBppRequest }                  from "../shared/validators.ts";
import { AiFactory }                           from "../shared/ai/factory.ts";
import { buildBppSystemPrompt, buildBppUserPrompt } from "../shared/prompt_builder.ts";
import { parseAiJson, validateDppPayload }     from "../shared/json_parser.ts";
import { successResponse }                     from "../shared/response.ts";
import { checkRateLimit, logUsage, estimateCost } from "../shared/rate_limit.ts";
import { generateCacheKey, getCachedResponse, setCachedResponse } from "../shared/cache.ts";

Deno.serve(
  withErrorBoundary("generate-bpp", async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs   = Date.now();
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const log       = createLogger("generate-bpp", requestId);
    log.requestStart(req.method, "generate-bpp");

    const auth = await requireAuth(req, ["teacher", "admin", "super_admin"]);
    log.setUser(auth.id);

    await checkRateLimit(auth.adminClient, auth.id, "generate-bpp", auth.tier, log);

    const rawBody   = await req.json().catch(() => null);
    const validated = validateBppRequest(rawBody);

    log.info("BPP request validated", {
      exam:          validated.exam,
      subject:       validated.subject,
      chapter:       validated.chapter,
      questionCount: validated.questionCount,
      batchId:       validated.batchId,
    });

    const forceRefresh = rawBody?.forceRefresh === true || rawBody?.regenerate === true;

    const cacheKey = await generateCacheKey("generate-bpp", {
      exam:          validated.exam,
      subject:       validated.subject,
      chapter:       validated.chapter,
      difficulty:    validated.difficulty,
      questionCount: validated.questionCount,
      language:      validated.language,
    });

    if (!forceRefresh) {
      const cached = await getCachedResponse(auth.adminClient, cacheKey, "generate-bpp", log);
      if (cached) {
        if (validated.batchId && cached.bppId) {
          await auth.adminClient
            .from("batch_content")
            .upsert({ batch_id: validated.batchId, bpp_id: cached.bppId })
            .then()
            .catch(() => {});
        }
        log.requestEnd(200);
        return successResponse({ bppId: cached.bppId, bpp: cached.bpp, fromCache: true, generationTimeMs: 0 }, requestId);
      }
    }

    const systemPrompt = buildBppSystemPrompt();
    let userPrompt   = buildBppUserPrompt(validated, validated.topics ?? []);
    if (forceRefresh) {
      userPrompt += `\n\n[REGENERATION DIRECTIVE: Generate a completely fresh, unique set of questions different from previous outputs. Request ID: ${requestId}]`;
    }

    const aiProvider = AiFactory.getProvider(log, "openrouter");
    let aiResult;
    let aiError: string | undefined;

    try {
      aiResult = await aiProvider.generateJSON("bpp", systemPrompt, userPrompt);
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      await logUsage(auth.adminClient, {
        userId: auth.id, feature: "generate-bpp",
        model: "gemini-2.5-flash", provider: "gemini",
        promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0,
        latencyMs: Date.now() - startMs, status: "failed", error: aiError,
      }, log);
      throw err;
    }

    const bppPayload = parseAiJson<Record<string, unknown>>(aiResult.text);
    const validationErrors = validateDppPayload(bppPayload, validated.questionCount);
    if (validationErrors.length > 0) {
      log.warn("BPP validation warnings", { errors: validationErrors });
    }

    let bppId: string | null = null;
    try {
      const { data: savedBpp } = await auth.adminClient
        .from("dpps")
        .insert({
          teacher_id:     auth.id,
          exam:           validated.exam,
          subject:        validated.subject,
          chapter:        validated.chapter,
          difficulty:     validated.difficulty,
          question_count: validated.questionCount,
          duration:       validated.duration,
          language:       validated.language,
          content:        bppPayload,
          model:          aiResult.model,
          status:         "active",
          is_batch:       true,
        })
        .select("id")
        .single();

      bppId = savedBpp?.id ?? null;

      if (bppId && validated.batchId) {
        await auth.adminClient
          .from("batch_content")
          .upsert({ batch_id: validated.batchId, bpp_id: bppId })
          .then()
          .catch(() => {});
      }
    } catch (dbErr) {
      log.error("Failed to save BPP (non-fatal)", dbErr);
    }

    const cost = estimateCost(aiResult.model, aiResult.promptTokens, aiResult.completionTokens);
    await logUsage(auth.adminClient, {
      userId: auth.id, feature: "generate-bpp",
      model: aiResult.model, provider: aiResult.provider,
      promptTokens: aiResult.promptTokens, completionTokens: aiResult.completionTokens,
      estimatedCostUsd: cost, latencyMs: aiResult.latencyMs, status: "success",
    }, log);

    await setCachedResponse(auth.adminClient, cacheKey, "generate-bpp", { bppId, bpp: bppPayload }, log);

    const totalMs = Date.now() - startMs;
    log.requestEnd(200);

    return successResponse({
      bppId,
      bpp:              bppPayload,
      fromCache:        false,
      generationTimeMs: totalMs,
      model:            aiResult.model,
      tokensUsed:       aiResult.totalTokens,
      finishReason:     aiResult.finishReason,
    }, requestId);
  })
);
