/**
 * ═══════════════════════════════════════════════════════════════════════════
 * notes-generator/index.ts — Study Notes Generator (Gemini 2.5 Flash)
 * Location: supabase/functions/notes-generator/index.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ROUTE: POST /functions/v1/notes-generator
 * ACCESS: teacher, admin, super_admin
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { handleCors }                            from "../shared/cors.ts";
import { withErrorBoundary, Errors }             from "../shared/errors.ts";
import { requireAuth }                           from "../shared/auth.ts";
import { createLogger }                          from "../shared/logger.ts";
import { AiFactory }                             from "../shared/ai/factory.ts";
import { parseAiJson }                           from "../shared/json_parser.ts";
import { successResponse }                       from "../shared/response.ts";
import { checkRateLimit, logUsage, estimateCost } from "../shared/rate_limit.ts";
import { generateCacheKey, getCachedResponse, setCachedResponse } from "../shared/cache.ts";

Deno.serve(
  withErrorBoundary("notes-generator", async (req: Request) => {
    const preflight = handleCors(req);
    if (preflight) return preflight;

    const startMs   = Date.now();
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const log       = createLogger("notes-generator", requestId);
    log.requestStart(req.method, "notes-generator");

    const auth = await requireAuth(req, ["teacher", "admin", "super_admin"]);
    log.setUser(auth.id);

    await checkRateLimit(auth.adminClient, auth.id, "notes-generator", auth.tier, log);

    const body = await req.json().catch(() => null);
    if (!body?.exam || !body?.subject || !body?.chapter) {
      throw Errors.badRequest("body", "'exam', 'subject', and 'chapter' are required.");
    }

    const { exam, subject, chapter, topics = [], language = "English", noteStyle = "detailed" } = body;

    log.info("Notes request validated", { exam, subject, chapter, noteStyle });

    const cacheKey = await generateCacheKey("notes-generator", { exam, subject, chapter, noteStyle, language });
    const cached   = await getCachedResponse(auth.adminClient, cacheKey, "notes-generator", log);
    if (cached) {
      log.requestEnd(200);
      return successResponse({ notes: cached.notes, fromCache: true, generationTimeMs: 0 }, requestId);
    }

    const systemPrompt = `You are a Senior Faculty and Curriculum Author at National Academy.
Generate comprehensive, exam-focused study notes in ${language} matching NCERT standards.
Format all equations in LaTeX ($inline$ and $$block$$). Return strict JSON only.`;

    const userPrompt = `EXAM: ${exam}
SUBJECT: ${subject}
CHAPTER: ${chapter}
TOPICS: ${topics.length > 0 ? topics.join(", ") : "All chapter topics"}
STYLE: ${noteStyle}

Generate complete structured JSON study notes:
{
  "title": "Chapter title",
  "summary": "High level overview",
  "sections": [
    {
      "heading": "Topic heading",
      "content": "Detailed theory with LaTeX formulas",
      "key_points": ["Key bullet point 1", "Key bullet point 2"],
      "formulas": ["$E = mc^2$"],
      "memory_tricks": ["Mnemonic aid"]
    }
  ],
  "pyq_insights": "Common PYQ trends",
  "quick_revision": ["Summary point 1", "Summary point 2"]
}`;

    const aiProvider = AiFactory.getProvider(log, "gemini");
    let aiResult;
    let aiError: string | undefined;

    try {
      aiResult = await aiProvider.generateJSON("notes", systemPrompt, userPrompt);
    } catch (err) {
      aiError = err instanceof Error ? err.message : String(err);
      await logUsage(auth.adminClient, {
        userId: auth.id, feature: "notes-generator",
        model: "gemini-2.5-flash", provider: "gemini",
        promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0,
        latencyMs: Date.now() - startMs, status: "failed", error: aiError,
      }, log);
      throw err;
    }

    const notesPayload = parseAiJson<Record<string, unknown>>(aiResult.text);

    let notesId: string | null = null;
    try {
      const { data: savedNotes } = await auth.adminClient
        .from("ai_notes")
        .insert({
          created_by: auth.id,
          exam,
          subject,
          chapter,
          topics,
          note_style: noteStyle,
          language,
          content: notesPayload,
        })
        .select("id")
        .single();

      notesId = savedNotes?.id ?? null;
    } catch (dbErr) {
      log.warn("Failed to persist notes to DB (non-fatal)", { dbErr: String(dbErr) });
    }

    const cost = estimateCost(aiResult.model, aiResult.promptTokens, aiResult.completionTokens);
    await logUsage(auth.adminClient, {
      userId: auth.id, feature: "notes-generator",
      model: aiResult.model, provider: aiResult.provider,
      promptTokens: aiResult.promptTokens, completionTokens: aiResult.completionTokens,
      estimatedCostUsd: cost, latencyMs: aiResult.latencyMs, status: "success",
    }, log);

    await setCachedResponse(auth.adminClient, cacheKey, "notes-generator", { notesId, notes: notesPayload }, log);

    const totalMs = Date.now() - startMs;
    log.requestEnd(200);

    return successResponse({
      notesId,
      notes:            notesPayload,
      fromCache:        false,
      generationTimeMs: totalMs,
      model:            aiResult.model,
      tokensUsed:       aiResult.totalTokens,
      finishReason:     aiResult.finishReason,
    }, requestId);
  })
);
