/**
 * ═══════════════════════════════════════════════════════════════════════════
 * ai-chat/index.ts — AI Tutor Chat Assistant (Gemini 2.5 Flash)
 * Location: supabase/functions/ai-chat/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ROUTE: POST /functions/v1/ai-chat
 * ACCESS: Any authenticated user
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

import { handleCors }            from "../shared/cors.ts";
import { withErrorBoundary }     from "../shared/errors.ts";
import { requireAuth }           from "../shared/auth.ts";
import { createLogger }          from "../shared/logger.ts";
import { validateChatRequest }   from "../shared/validators.ts";
import { AiFactory }             from "../shared/ai/factory.ts";
import { ChatMessage }           from "../shared/ai/provider.ts";
import { buildChatSystemPrompt } from "../shared/prompt_builder.ts";
import { successResponse }       from "../shared/response.ts";
import { checkRateLimit, logUsage, estimateCost } from "../shared/rate_limit.ts";

serve(
  withErrorBoundary("ai-chat", async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs   = Date.now();
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const log       = createLogger("ai-chat", requestId);
    log.requestStart(req.method, "ai-chat");

    const auth = await requireAuth(req);
    log.setUser(auth.id);

    await checkRateLimit(auth.adminClient, auth.id, "ai-chat", auth.tier, log);

    const rawBody   = await req.json().catch(() => null);
    const validated = validateChatRequest(rawBody);

    log.info("Chat request validated", {
      messageCount: validated.messages.length,
      context:      validated.context,
    });

    const systemPrompt = buildChatSystemPrompt(validated.context);

    const fullMessages: ChatMessage[] = [
      { role: "system", content: systemPrompt },
      ...validated.messages.map((m) => ({
        role:    m.role as ChatMessage["role"],
        content: m.content,
      })),
    ];

    const aiProvider = AiFactory.getProvider(log, "gemini");
    let aiResult;
    let aiError: string | undefined;

    try {
      aiResult = await aiProvider.chat("chat", fullMessages);
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      await logUsage(auth.adminClient, {
        userId: auth.id, feature: "ai-chat",
        model: "gemini-2.5-flash", provider: "gemini",
        promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0,
        latencyMs: Date.now() - startMs, status: "failed", error: aiError,
      }, log);
      throw err;
    }

    const cost = estimateCost(aiResult.model, aiResult.promptTokens, aiResult.completionTokens);
    await logUsage(auth.adminClient, {
      userId:           auth.id,
      feature:          "ai-chat",
      model:            aiResult.model,
      provider:         aiResult.provider,
      promptTokens:     aiResult.promptTokens,
      completionTokens: aiResult.completionTokens,
      estimatedCostUsd: cost,
      latencyMs:        aiResult.latencyMs,
      status:           "success",
    }, log);

    const totalMs = Date.now() - startMs;
    log.requestEnd(200);

    return successResponse({
      reply:        aiResult.text,
      model:        aiResult.model,
      tokensUsed:   aiResult.totalTokens,
      finishReason: aiResult.finishReason,
      latencyMs:    totalMs,
    }, requestId);
  })
);
