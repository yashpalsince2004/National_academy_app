/**
 * ═══════════════════════════════════════════════════════════════════════════
 * gemini_client.ts — Google Gemini API Client Implementation
 * Location: supabase/functions/shared/ai/gemini_client.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * High-performance, production-ready Google Gemini API client implementing the
 * AIProvider interface. Uses native fetch against the Gemini v1beta REST API.
 *
 * WHY NATIVE FETCH INSTEAD OF SDK?
 * ─────────────────────────────────
 * In Deno / Supabase Edge Functions, native fetch has 0 external dependencies,
 * loads instantly (<1ms cold start), and avoids npm bundling incompatibilities.
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { GEMINI_CONFIG, AI_MODELS, GENERATION_PARAMS, TIMEOUTS } from "../config.ts";
import { Logger } from "../logger.ts";
import { AIProvider, GenerateOptions, GenerateResult, ChatMessage } from "./provider.ts";
import { AppError } from "../errors.ts";
import { getModelMetadata, ModelMetadata } from "./model_registry.ts";

export class GeminiClient implements AIProvider {
  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly log: Logger;

  constructor(log: Logger) {
    this.log = log;
    this.baseUrl = GEMINI_CONFIG.baseUrl;

    const key = Deno.env.get(GEMINI_CONFIG.apiKeyEnv);
    if (!key) {
      throw new AppError(
        "UNAUTHORISED",
        `Secret "${GEMINI_CONFIG.apiKeyEnv}" is not set in Supabase Vault. Please run: supabase secrets set GEMINI_API_KEY=AIzaSy...`
      );
    }
    this.apiKey = key;

    // Task 8: Startup verification logging
    console.log(`
==================================================
Gemini Edge Client Initialized
==================================================
API Key Present: true
Selected Provider: gemini
Default Model: ${GEMINI_CONFIG.defaultModel}
Base URL: ${this.baseUrl}
API Version: v1beta
Edge Function Version: 1.0.0
Timestamp: ${new Date().toISOString()}
==================================================
`);
    this.log.info("Gemini client initialised", { baseUrl: this.baseUrl });
  }

  // ── AIProvider Interface Implementation ───────────────────────────────────

  public async healthCheck(): Promise<boolean> {
    try {
      const res = await fetch(`${this.baseUrl}/models?key=${this.apiKey}`);
      return res.ok;
    } catch {
      return false;
    }
  }

  public supportsThinking(): boolean { return false; }
  public supportsVision(): boolean { return true; }
  public supportsStructuredOutput(): boolean { return true; }
  public supportsFunctionCalling(): boolean { return true; }

  public getModelInfo(): ModelMetadata {
    return getModelMetadata(GEMINI_CONFIG.defaultModel);
  }

  public async generateJSON(
    feature: string,
    systemPrompt: string,
    userPrompt: string,
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    return this.generateText(feature, systemPrompt, userPrompt, {
      ...options,
      jsonMode: true,
    });
  }

  public async generateText(
    feature: string,
    systemPrompt: string,
    userPrompt: string,
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    const contents = [
      {
        role: "user",
        parts: [{ text: userPrompt }],
      },
    ];

    return this._executeCall(feature, systemPrompt, contents, options);
  }

  public async chat(
    feature: string,
    messages: ChatMessage[],
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    let systemPrompt = "";
    const conversationContents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

    for (const msg of messages) {
      if (msg.role === "system") {
        systemPrompt += (systemPrompt ? "\n" : "") + msg.content;
      } else {
        const geminiRole = msg.role === "assistant" || msg.role === "model" ? "model" : "user";
        conversationContents.push({
          role: geminiRole,
          parts: [{ text: msg.content }],
        });
      }
    }

    return this._executeCall(feature, systemPrompt, conversationContents, options);
  }

  // ── PRIVATE Execution & Retry Core ───────────────────────────────────────

  private async _executeCall(
    feature: string,
    systemPrompt: string,
    contents: Array<{ role: string; parts: Array<{ text: string }> }>,
    options: GenerateOptions
  ): Promise<GenerateResult> {
    const model = options.model ?? AI_MODELS[feature as keyof typeof AI_MODELS] ?? GEMINI_CONFIG.defaultModel;
    const defaultParams = GENERATION_PARAMS[feature as keyof typeof GENERATION_PARAMS] ?? {
      temperature: 0.2,
      topP: 0.85,
      maxTokens: 4096,
    };

    const url = `${this.baseUrl}/models/${model}:generateContent?key=${this.apiKey}`;

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "x-goog-api-key": this.apiKey,
    };

    // ── Task 3: Request Body Build & Validation ───────────────────────────
    const generationConfig: Record<string, unknown> = {
      temperature:     options.temperature     ?? defaultParams.temperature,
      topP:            options.topP            ?? defaultParams.topP,
      topK:            options.topK            ?? GEMINI_CONFIG.defaultTopK,
      maxOutputTokens: options.maxOutputTokens ?? defaultParams.maxTokens,
      ...(options.jsonMode ? { responseMimeType: "application/json" } : {}),
    };

    const requestBody: Record<string, unknown> = {
      contents,
      generationConfig,
      safetySettings: options.safetySettings ?? GEMINI_CONFIG.safetySettings,
    };

    if (systemPrompt) {
      requestBody.systemInstruction = {
        parts: [{ text: systemPrompt }],
      };
    }

    const systemPromptLen = systemPrompt ? systemPrompt.length : 0;
    const userPromptLen = contents.reduce(
      (acc, c) => acc + c.parts.reduce((pAcc, p) => pAcc + (p.text?.length ?? 0), 0),
      0
    );

    // Task 3 Logging: Validate request structure before fetch
    console.log(`
========================
Gemini Request Debug
========================
Model: ${model}
Feature: ${feature}
URL: ${url}
System Prompt Length: ${systemPromptLen}
User Prompt Length: ${userPromptLen}
Generation Config: ${JSON.stringify(generationConfig)}
Safety Settings: ${JSON.stringify(requestBody.safetySettings)}
Timeout: ${TIMEOUTS.request}ms
========================
`);

    let attempt = 0;
    let retryDelay: number = TIMEOUTS.initialRetryDelay;
    let lastError: AppError | Error | null = null;

    this.log.setModel(model);
    this.log.info("Calling Gemini API", { feature, model, jsonMode: options.jsonMode });

    while (attempt < TIMEOUTS.maxRetries) {
      attempt++;
      const callStart = Date.now();

      const controller = new AbortController();
      const timeoutId  = setTimeout(() => controller.abort(), TIMEOUTS.request);

      try {
        const response = await fetch(url, {
          method:  "POST",
          headers,
          body:    JSON.stringify(requestBody),
          signal:  controller.signal,
        });

        clearTimeout(timeoutId);
        const latencyMs = Date.now() - callStart;

        if (!response.ok) {
          const errText = await response.text().catch(() => "");

          const headersObj: Record<string, string> = {};
          response.headers.forEach((value, key) => {
            headersObj[key] = value;
          });

          // Task 1: Complete structured response logging (un-truncated)
          console.error(`
========================
Gemini Response Error
========================
Model: ${model}
Feature: ${feature}
URL: ${url}
Status: ${response.status} ${response.statusText}
Headers: ${JSON.stringify(headersObj)}
Retry Attempt: ${attempt}/${TIMEOUTS.maxRetries}
Latency: ${latencyMs}ms
Response Body:
${errText}
========================
`);

          const classifiedError = this._classifyError(
            response.status,
            errText,
            model,
            feature,
            attempt,
            latencyMs
          );

          // Task 5: Retry ONLY on 429, 500, 502, 503, 504
          const isRetryable = response.status === 429 || (response.status >= 500 && response.status <= 504);
          if (isRetryable && attempt < TIMEOUTS.maxRetries) {
            lastError = classifiedError;
            await sleep(retryDelay);
            retryDelay = Math.min(retryDelay * 2, TIMEOUTS.maxRetryDelay);
            continue;
          }

          throw classifiedError;
        }

        const data = await response.json() as Record<string, unknown>;
        const result = this._parseGeminiResponse(data, model, latencyMs, attempt - 1);

        this.log.aiComplete({
          status:           "success",
          promptTokens:     result.promptTokens,
          completionTokens: result.completionTokens,
          latencyMs:        result.latencyMs,
          retryCount:       result.retryCount,
          provider:         "gemini",
        });

        return result;

      } catch (err) {
        clearTimeout(timeoutId);

        if (err instanceof AppError) {
          throw err;
        }

        if (err instanceof Error && err.name === "AbortError") {
          lastError = new AppError(
            "TIMEOUT",
            `Gemini request timed out after ${TIMEOUTS.request / 1000}s on attempt ${attempt}`
          );
          this.log.warn(`Timeout attempt ${attempt}/${TIMEOUTS.maxRetries}`);
        } else {
          lastError = err instanceof Error ? err : new Error(String(err));
          this.log.warn(`Network error attempt ${attempt}: ${lastError.message}`);
        }

        if (attempt < TIMEOUTS.maxRetries) {
          await sleep(retryDelay);
          retryDelay = Math.min(retryDelay * 2, TIMEOUTS.maxRetryDelay);
          continue;
        }
      }
    }

    // Task 6: Final exception preserves AppError
    this.log.error("Exhausted retries for Gemini call", lastError);
    if (lastError instanceof AppError) {
      throw lastError;
    }

    throw new AppError(
      "AI_PROVIDER_ERROR",
      `Gemini API call failed after ${TIMEOUTS.maxRetries} attempts: ${lastError?.message ?? "Unknown error"}`,
      lastError
    );
  }

  // ── PRIVATE Response Parser ───────────────────────────────────────────────

  private _parseGeminiResponse(
    data: Record<string, unknown>,
    model: string,
    latencyMs: number,
    retryCount: number
  ): GenerateResult {
    const candidates = data.candidates as Array<Record<string, unknown>> | undefined;
    const firstCandidate = candidates?.[0];

    if (!firstCandidate) {
      throw new Error("Gemini returned no response candidates.");
    }

    const content = firstCandidate.content as Record<string, unknown> | undefined;
    const parts   = content?.parts as Array<Record<string, unknown>> | undefined;
    const text    = parts?.[0]?.text as string | undefined;

    if (!text || typeof text !== "string") {
      const finishReason = firstCandidate.finishReason as string | undefined;
      throw new Error(`Gemini candidate empty. Finish reason: ${finishReason ?? "UNKNOWN"}`);
    }

    const usage = data.usageMetadata as Record<string, number> | undefined;
    const finishReason     = (firstCandidate.finishReason as string) ?? "STOP";

    console.log("Finish Reason:", finishReason);
    console.log("Text Length:", text.length);
    console.log("Usage:", usage);
    console.log("Last 300 chars:");
    console.log(text.slice(-300));

    if (finishReason === "MAX_TOKENS") {
      throw new AppError(
        "OUTPUT_TRUNCATED",
        "AI output was truncated due to maximum token limit (MAX_TOKENS) before JSON completion.",
        { finishReason, textLength: text.length }
      );
    }

    const promptTokens     = usage?.promptTokenCount     ?? 0;
    const completionTokens = usage?.candidatesTokenCount ?? 0;
    const totalTokens      = usage?.totalTokenCount      ?? (promptTokens + completionTokens);

    return {
      text,
      promptTokens,
      completionTokens,
      totalTokens,
      latencyMs,
      model,
      provider: "gemini",
      finishReason,
      retryCount,
    };
  }

  // ── Task 4: Error Classification ─────────────────────────────────────────

  private _classifyError(
    status: number,
    body: string,
    model: string,
    feature: string,
    attempt: number,
    latencyMs: number
  ): AppError {
    let geminiMessage = body;
    try {
      const parsed = JSON.parse(body);
      if (parsed.error?.message) {
        geminiMessage = parsed.error.message;
      }
    } catch {
      // Keep raw body text if not valid JSON
    }

    const contextDetails = {
      status,
      model,
      feature,
      attempt,
      latencyMs,
      rawResponseBody: body,
    };

    switch (status) {
      case 400:
        return new AppError(
          "BAD_REQUEST",
          `Gemini API Bad Request (400): ${geminiMessage}`,
          contextDetails
        );
      case 401:
        return new AppError(
          "UNAUTHORISED",
          `Gemini API Unauthorized (401): ${geminiMessage}`,
          contextDetails
        );
      case 403:
        return new AppError(
          "FORBIDDEN",
          `Gemini API Forbidden (403): ${geminiMessage}`,
          contextDetails
        );
      case 404:
        return new AppError(
          "MODEL_NOT_FOUND",
          `Gemini API Model/Endpoint Not Found (404): ${geminiMessage}`,
          contextDetails
        );
      case 429:
        return new AppError(
          "RATE_LIMITED",
          `Gemini API Quota/Rate Limit Exceeded (429): ${geminiMessage}`,
          contextDetails
        );
      default:
        if (status >= 500) {
          return new AppError(
            "SERVER_ERROR",
            `Gemini Server Error (${status}): ${geminiMessage}`,
            contextDetails
          );
        }
        return new AppError(
          "AI_PROVIDER_ERROR",
          `Gemini Service Error (${status}): ${geminiMessage}`,
          contextDetails
        );
    }
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
