/**
 * ═══════════════════════════════════════════════════════════════════════════
 * generate-dpp/index.ts — Daily Practice Problem Generator (Gemini 2.5 Flash)
 * Location: supabase/functions/generate-dpp/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ROUTE: POST /functions/v1/generate-dpp
 * ACCESS: teacher, admin, super_admin
 *
 * WORKFLOW & ADMIN CONTROL
 * ─────────────────────────
 * 1. Only Teachers / Admins can generate DPPs.
 * 2. Students NEVER call Gemini directly.
 * 3. Workflow:
 *    Admin Request → JWT Check → Rate Limit → Prompt Build → Gemini 2.5 Flash
 *    → JSON Validation → Admin Preview → Database Save → Publish to Students.
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { handleCors }                          from "../shared/cors.ts";
import { withErrorBoundary }                   from "../shared/errors.ts";
import { requireAuth }                         from "../shared/auth.ts";
import { createLogger }                        from "../shared/logger.ts";
import { validateDppRequest }                  from "../shared/validators.ts";
import { AiFactory }                           from "../shared/ai/factory.ts";
import { buildDppSystemPrompt, buildDppUserPrompt } from "../shared/prompt_builder.ts";
import { parseAiJson, validateDppPayload }     from "../shared/json_parser.ts";
import { successResponse }                     from "../shared/response.ts";
import { checkRateLimit, logUsage, estimateCost } from "../shared/rate_limit.ts";
import { generateCacheKey, getCachedResponse, setCachedResponse } from "../shared/cache.ts";

Deno.serve(
  withErrorBoundary("generate-dpp", async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs   = Date.now();
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const log       = createLogger("generate-dpp", requestId);
    log.requestStart(req.method, "generate-dpp");

    // Admin & Teacher authorization check
    const auth = await requireAuth(req, ["teacher", "admin", "super_admin"]);
    log.setUser(auth.id);

    await checkRateLimit(auth.adminClient, auth.id, "generate-dpp", auth.tier, log);

    const rawBody   = await req.json().catch(() => null);
    const validated = validateDppRequest(rawBody);

    log.info("DPP request validated", {
      exam:          validated.exam,
      subject:       validated.subject,
      chapter:       validated.chapter,
      difficulty:    validated.difficulty,
      questionCount: validated.questionCount,
    });

    const forceRefresh = rawBody?.forceRefresh === true || rawBody?.regenerate === true;

    // ── Cache Lookup (bypassed on forceRefresh / regenerate) ────────────────
    const cacheKey = await generateCacheKey("generate-dpp", {
      exam:          validated.exam,
      subject:       validated.subject,
      chapter:       validated.chapter,
      difficulty:    validated.difficulty,
      questionCount: validated.questionCount,
      questionType:  validated.questionType,
      language:      validated.language,
    });

    if (!forceRefresh) {
      const cached = await getCachedResponse(auth.adminClient, cacheKey, "generate-dpp", log);
      if (cached) {
        log.requestEnd(200);
        return successResponse(
          {
            dppId:            cached.dppId,
            dpp:              cached.dpp,
            fromCache:        true,
            generationTimeMs: 0,
          },
          requestId
        );
      }
    }

    // ── Build System & User Prompts ───────────────────────────────────────
    const systemPrompt = buildDppSystemPrompt();
    let userPrompt   = buildDppUserPrompt(validated, validated.topics ?? []);
    if (forceRefresh) {
      userPrompt += `\n\n[REGENERATION DIRECTIVE: Generate a completely fresh, unique set of questions different from previous outputs. Request ID: ${requestId}]`;
    }

    // ── Execute via AI Gateway (OpenRouter primary, Gemini fallback) ──────
    const aiProvider = AiFactory.getProvider(log, "openrouter");
    let aiResult;
    let aiError: string | undefined;

    try {
      aiResult = await aiProvider.generateJSON("dpp", systemPrompt, userPrompt);
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      await logUsage(auth.adminClient, {
        userId: auth.id, feature: "generate-dpp",
        model: "gemini-2.5-flash", provider: "gemini",
        promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0,
        latencyMs: Date.now() - startMs, status: "failed", error: aiError,
      }, log);
      throw err;
    }

    // ── Parse + Validate AI JSON ───────────────────────────────────────────
    console.log("************* VERSION 7 *************");
    console.log("========== RAW GEMINI RESPONSE ==========");
    console.log(aiResult.text);
    console.log("=========================================");

    const dppPayload = parseAiJson<Record<string, unknown>>(aiResult.text);
    const validationErrors = validateDppPayload(dppPayload, validated.questionCount);
    if (validationErrors.length > 0) {
      log.warn("DPP payload validation warnings", { errors: validationErrors });
    }

    // ── Save Generated DPP to DB (Draft status for admin preview) ─────────
    let dppId: string | null = null;
    try {
      const { data: savedDpp } = await auth.adminClient
        .from("dpps")
        .insert({
          teacher_id:     auth.id,
          exam:           validated.exam,
          subject:        validated.subject,
          chapter:        validated.chapter,
          difficulty:     validated.difficulty,
          question_count: validated.questionCount,
          duration:       validated.duration,
          marks:          validated.marks,
          language:       validated.language,
          question_type:  validated.questionType,
          content:        dppPayload,
          model:          aiResult.model,
          status:         "active",
        })
        .select("id")
        .single();

      dppId = savedDpp?.id ?? null;
      log.info("DPP saved to DB", { dppId });

      // ── Insert Questions into dpp_questions table ─────────────────────────
      const rawQuestions = Array.isArray(dppPayload.questions)
        ? (dppPayload.questions as Array<Record<string, unknown>>)
        : Array.isArray(dppPayload.data)
        ? (dppPayload.data as Array<Record<string, unknown>>)
        : [];

      if (dppId && rawQuestions.length > 0) {
        const marksPerQ = Math.max(1, Math.floor((validated.marks ?? 40) / validated.questionCount));

        const questionsToInsert = rawQuestions.map((q, idx) => {
          let expStr = "";
          if (typeof q.explanation === "string") {
            expStr = q.explanation;
          } else if (typeof q.explanation === "object" && q.explanation !== null) {
            const expObj = q.explanation as Record<string, unknown>;
            expStr = String(expObj.step_by_step || expObj.correct_answer || JSON.stringify(expObj));
          }

          let correctAns = String(q.correct_answer || q.answer || "A");
          if (correctAns.length === 1 && Array.isArray(q.options) && q.options.length >= 4) {
            // Convert 'A', 'B', 'C', 'D' index to option text or label
            const charCode = correctAns.toUpperCase().charCodeAt(0);
            const optIdx = charCode - 65; // 'A' -> 0
            if (optIdx >= 0 && optIdx < q.options.length) {
              correctAns = String(q.options[optIdx]);
            }
          }

          return {
            dpp_id: dppId,
            question_text: String(q.question_text || q.question || `Question ${idx + 1}`),
            question_type: String(q.question_type || q.type || validated.questionType || "Single Correct"),
            options: Array.isArray(q.options) ? q.options : [],
            correct_answer: correctAns,
            explanation: expStr,
            difficulty: String(q.difficulty || validated.difficulty),
            estimated_time_seconds: Number(q.estimated_time_seconds || q.estimated_time || 90),
            marks: Number(q.marks || marksPerQ),
            learning_outcome: String(q.learning_outcome || q.concept || ""),
          };
        });

        const { error: qErr } = await auth.adminClient.from("dpp_questions").insert(questionsToInsert);
        if (qErr) {
          log.error("Failed to insert dpp_questions", qErr);
        } else {
          log.info("DPP questions saved to DB", { count: questionsToInsert.length });
        }
      }
    } catch (dbErr) {
      log.error("Failed to save DPP (non-fatal)", dbErr);
    }

    // ── Telemetry & Cache ──────────────────────────────────────────────────
    const cost = estimateCost(aiResult.model, aiResult.promptTokens, aiResult.completionTokens);
    await logUsage(auth.adminClient, {
      userId:           auth.id,
      feature:          "generate-dpp",
      model:            aiResult.model,
      provider:         aiResult.provider,
      promptTokens:     aiResult.promptTokens,
      completionTokens: aiResult.completionTokens,
      estimatedCostUsd: cost,
      latencyMs:        aiResult.latencyMs,
      status:           "success",
    }, log);

    await setCachedResponse(auth.adminClient, cacheKey, "generate-dpp", { dppId, dpp: dppPayload }, log);

    const totalMs = Date.now() - startMs;
    log.requestEnd(200);

    return successResponse(
      {
        dppId,
        dpp:              dppPayload,
        fromCache:        false,
        generationTimeMs: totalMs,
        model:            aiResult.model,
        tokensUsed:       aiResult.totalTokens,
        finishReason:     aiResult.finishReason,
      },
      requestId
    );
  })
);
