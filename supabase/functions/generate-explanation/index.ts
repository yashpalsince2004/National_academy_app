/**
 * ═══════════════════════════════════════════════════════════════════════════
 * generate-explanation — Edge Function for On-Demand Solution Explanations
 * Location: supabase/functions/generate-explanation/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Generates detailed step-by-step solution explanations for questions on-demand.
 * Triggered ONLY when a teacher previews a DPP or a student opens a solution.
 * Uses PostgreSQL caching in `dpp_question_explanations` to avoid duplicate AI calls.
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { withErrorBoundary } from "../shared/errors.ts";
import { requireAuth } from "../shared/auth.ts";
import { successResponse } from "../shared/response.ts";
import { validateExplanationRequest } from "../shared/validators.ts";
import {
  buildExplanationSystemPrompt,
  buildExplanationUserPrompt,
} from "../shared/prompt_builder.ts";
import { parseAiJson } from "../shared/json_parser.ts";
import { Logger } from "../shared/logger.ts";
import { AiFactory } from "../shared/ai/factory.ts";

serve(
  withErrorBoundary("generate-explanation", async (req: Request) => {
    const log = new Logger("generate-explanation");
    const startMs = Date.now();

    // ── 1. Require Authenticated User ───────────────────────────────────────
    const auth = await requireAuth(req);
    log.setUser(auth.id);

    // ── 2. Validate Input ───────────────────────────────────────────────────
    const body = await req.json();
    const validated = validateExplanationRequest(body);
    const questionId = typeof body.questionId === "string" ? body.questionId : null;

    // ── 3. Check Explanation DB Cache ───────────────────────────────────────
    if (questionId) {
      const { data: cached } = await auth.adminClient
        .from("dpp_question_explanations")
        .select("*")
        .eq("question_id", questionId)
        .maybeSingle();

      if (cached) {
        log.info("Explanation cache hit", { questionId });
        return successResponse(
          {
            explanation: cached.explanation,
            fromCache: true,
            latencyMs: Date.now() - startMs,
          },
          log.getRequestId()
        );
      }
    }

    // ── 4. Generate Explanation via AI ──────────────────────────────────────
    const systemPrompt = buildExplanationSystemPrompt();
    const userPrompt = buildExplanationUserPrompt(validated);

    const aiProvider = AiFactory.getProvider(log, "gemini");
    const aiResult = await aiProvider.generateJSON(
      "explanation",
      systemPrompt,
      userPrompt,
      { temperature: 0.1, maxOutputTokens: 2000 }
    );

    const explanationPayload = parseAiJson<Record<string, unknown>>(aiResult.text);

    // ── 5. Store in Explanation DB Cache ────────────────────────────────────
    if (questionId) {
      await auth.adminClient.from("dpp_question_explanations").upsert({
        question_id: questionId,
        explanation: explanationPayload,
        model: aiResult.model,
        language: validated.language,
        generated_at: new Date().toISOString(),
      });
    }

    return successResponse(
      {
        explanation: explanationPayload,
        fromCache: false,
        latencyMs: Date.now() - startMs,
        model: aiResult.model,
      },
      log.getRequestId()
    );
  })
);
