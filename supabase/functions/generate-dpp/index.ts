// Entry point for AI-powered Daily Practice Problem (DPP) Generator
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { GenerateDppRequest } from "./types.ts";
import { corsHeaders, buildErrorResponse, buildSuccessResponse } from "./utils.ts";
import { PromptBuilder } from "./prompt_builder.ts";
import { GeminiClient } from "./gemini_client.ts";
import { ResponseParser } from "./parser.ts";
import { PayloadValidator } from "./validator.ts";
import { DatabaseLayer } from "./database.ts";

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const requestStartTime = Date.now();
  console.log("[generate-dpp] Invoked. Processing request...");

  try {
    // ── 1. Verify User Authentication Session ─────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return buildErrorResponse("Missing Authorization header", 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    
    // Create Supabase Client authenticated with the caller's JWT session
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    const { data: { user }, error: authErr } = await userClient.auth.getUser();
    if (authErr || !user) {
      return buildErrorResponse(`Unauthorized: ${authErr?.message || "Invalid session"}`, 401);
    }

    const userId = user.id;
    console.log(`[generate-dpp] Authenticated User ID: ${userId}`);

    // ── 2. Parse and Validate Request Payload ──────────────────────────────
    const reqBody = await req.json().catch(() => null);
    if (!reqBody) {
      return buildErrorResponse("Invalid or malformed JSON request body", 400);
    }

    const {
      exam,
      subject,
      chapter,
      topics,
      difficulty,
      questionCount,
      duration,
      marks,
      language = "English"
    } = reqBody;

    // Strict validation check on inputs
    if (!exam || typeof exam !== "string") return buildErrorResponse("Missing parameter: exam target is required");
    if (!subject || typeof subject !== "string") return buildErrorResponse("Missing parameter: subject is required");
    if (!chapter || typeof chapter !== "string") return buildErrorResponse("Missing parameter: chapter is required");
    if (!difficulty || typeof difficulty !== "string") return buildErrorResponse("Missing parameter: difficulty level is required");
    if (typeof questionCount !== "number" || questionCount < 1 || questionCount > 200) {
      return buildErrorResponse("Invalid parameter: questionCount must be between 1 and 200");
    }
    if (typeof duration !== "number" || duration < 5 || duration > 240) {
      return buildErrorResponse("Invalid parameter: duration must be between 5 and 240 minutes");
    }

    const validatedRequest: GenerateDppRequest = {
      exam,
      subject,
      chapter,
      topics: Array.isArray(topics) ? topics : undefined,
      difficulty,
      questionCount,
      duration,
      marks: typeof marks === "number" ? marks : undefined,
      language
    };

    console.log(`[generate-dpp] Request Verified: ${exam} - ${subject} (${chapter}), Count: ${questionCount}`);

    // ── 3. Initialize AI Services ──────────────────────────────────────────
    const gemini = new GeminiClient();
    const systemPrompt = PromptBuilder.buildSystemInstruction();
    const userPrompt = PromptBuilder.buildUserPrompt(validatedRequest);

    let parsedPayload: any = null;
    let geminiRawText = "";
    let generationTimeMs = 0;
    let totalPromptTokens = 0;
    let totalCompletionTokens = 0;
    let retryAttempt = 0;
    const maxAiRetries = 2; // Retry on validation failure
    let lastError = "";

    // Privilege client for logs & inserts
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const adminClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false }
    });

    // ── 4. Generate & Validate Loop (Two-Step: Generate -> Audit -> Validate) ──
    while (retryAttempt <= maxAiRetries) {
      try {
        console.log(`[generate-dpp] Run #${retryAttempt + 1}: Step 1 - Generating initial DPP...`);
        const result = await gemini.generateDppJson(systemPrompt, userPrompt);
        generationTimeMs += result.generationTimeMs;
        totalPromptTokens += result.promptTokens;
        totalCompletionTokens += result.completionTokens;

        // Parse JSON output from first pass
        const rawPayload = ResponseParser.parseGeminiResponse(result.text);

        console.log(`[generate-dpp] Run #${retryAttempt + 1}: Step 2 - Submitting generated DPP to AI Critic Auditor...`);
        const reviewerPrompt = PromptBuilder.buildReviewerPrompt(exam, subject, chapter, JSON.stringify(rawPayload));
        const reviewResult = await gemini.generateDppJson(systemPrompt, reviewerPrompt);
        generationTimeMs += reviewResult.generationTimeMs;
        totalPromptTokens += reviewResult.promptTokens;
        totalCompletionTokens += reviewResult.completionTokens;

        geminiRawText = reviewResult.text;
        parsedPayload = ResponseParser.parseGeminiResponse(geminiRawText);

        // Run validation rules
        const validationErrors = PayloadValidator.validate(parsedPayload, validatedRequest);
        
        if (validationErrors.length > 0) {
          const errStr = validationErrors.join("; ");
          console.warn(`[generate-dpp] Validation failed on Attempt #${retryAttempt + 1}:`, errStr);
          throw new Error(`Validation failed: ${errStr}`);
        }

        // Successfully parsed, audited, and validated
        break;

      } catch (err) {
        retryAttempt++;
        lastError = (err as Error).message;
        console.error(`[generate-dpp] AI generation or audit phase failed (Attempt ${retryAttempt}/${maxAiRetries + 1}): ${lastError}`);
        
        if (retryAttempt > maxAiRetries) {
          // Log failure state to telemetry
          await DatabaseLayer.logAiGeneration(adminClient, {
            userId,
            exam,
            subject,
            chapter,
            promptTokens: totalPromptTokens,
            completionTokens: totalCompletionTokens,
            generationTimeMs,
            status: "failed",
            error: lastError,
          });
          return buildErrorResponse(`AI formulation failed validation checks after retries. Error: ${lastError}`, 502);
        }
      }
    }

    // ── 5. Database Insertion Layer (Transaction-Safe) ──────────────────
    console.log("[generate-dpp] Saving generated DPP package in transaction...");
    const dppId = await DatabaseLayer.saveDpp(
      adminClient,
      validatedRequest,
      parsedPayload,
      userId,
      userPrompt,
      geminiRawText
    );

    // ── 6. Log Telemetry to Database ──────────────────────────────────────
    await DatabaseLayer.logAiGeneration(adminClient, {
      userId,
      exam,
      subject,
      chapter,
      promptTokens: totalPromptTokens,
      completionTokens: totalCompletionTokens,
      generationTimeMs,
      status: "success",
    });

    const totalProcessingTime = Date.now() - requestStartTime;
    console.log(`[TELEMETRY] generate-dpp complete!`);
    console.log(`- Exam: ${exam}`);
    console.log(`- Subject: ${subject}`);
    console.log(`- Chapter: ${chapter}`);
    console.log(`- Questions: ${questionCount}`);
    console.log(`- Generation time: ${generationTimeMs}ms`);
    console.log(`- Total latency: ${totalProcessingTime}ms`);
    console.log(`- Tokens: ${totalPromptTokens + totalCompletionTokens} (Prompt: ${totalPromptTokens}, Completion: ${totalCompletionTokens})`);

    // ── 7. Return Final Response ──────────────────────────────────────────
    return buildSuccessResponse({
      success: true,
      dppId,
      title: parsedPayload.title,
      questionCount: parsedPayload.questions.length,
      estimatedDuration: parsedPayload.duration
    });

  } catch (globalErr) {
    const errorMsg = globalErr instanceof Error ? globalErr.message : String(globalErr);
    console.error(`[generate-dpp] Global execution crash: ${errorMsg}`);
    return buildErrorResponse(`Global execution crash: ${errorMsg}`, 500);
  }
});
