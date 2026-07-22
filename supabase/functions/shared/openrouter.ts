/**
 * ═══════════════════════════════════════════════════════════════════════════
 * openrouter.ts — OpenRouter AI Gateway Client
 * Location: supabase/functions/shared/openrouter.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * This is the ONLY file that directly communicates with OpenRouter's API.
 * Every AI feature imports and uses this client.
 * Retry logic, timeouts, error classification, and token tracking live here.
 *
 * WHY OPENROUTER?
 * ──────────────────
 * OpenRouter is an AI model aggregator that gives you:
 * - ONE API key to access 200+ models (Gemini, GPT-4, Claude, Mistral, etc.)
 * - Automatic provider failover if one AI provider goes down
 * - Normalised request/response format across all models
 * - Unified billing and usage tracking
 * - Free tier models for development/low-cost deployment
 *
 * HOW SUPABASE SECRETS WORK FOR THIS KEY
 * ──────────────────────────────────────────
 * The OPENROUTER_API_KEY is stored in Supabase Vault.
 * To set it:
 *   supabase secrets set OPENROUTER_API_KEY=sk-or-v1-...
 *
 * Supabase injects it as an environment variable at Edge Function startup.
 * It's ONLY accessible via Deno.env.get("OPENROUTER_API_KEY").
 * Flutter app code never executes in Deno — it cannot read this.
 * If you decompile the Flutter app, there is no API key to find.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 * OPENROUTER HEADERS — WHY EACH ONE IS REQUIRED
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Authorization: Bearer <key>
 *   ↳ REQUIRED. Authenticates your account. Without it: 401 Unauthorized.
 *
 * HTTP-Referer: https://yourapp.com
 *   ↳ REQUIRED by OpenRouter's Terms of Service. Identifies your application
 *     for attribution. Without it: some models may be unavailable or
 *     your account may be flagged for suspicious usage.
 *
 * X-Title: "National Academy"
 *   ↳ RECOMMENDED. Appears in your OpenRouter dashboard under usage reports.
 *     Makes it easy to track which app is consuming your quota when you have
 *     multiple applications sharing one OpenRouter account.
 *
 * Content-Type: application/json
 *   ↳ REQUIRED. Tells OpenRouter that the request body is JSON.
 *     Without it: 415 Unsupported Media Type.
 *
 * Accept: application/json
 *   ↳ BEST PRACTICE. Tells the server you expect JSON back.
 *     Helps proxy layers and CDNs correctly cache/route the response.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 */

import {
  OPENROUTER_CONFIG,
  AI_MODELS,
  GENERATION_PARAMS,
  TIMEOUTS,
  AiFeature,
} from "./config.ts";
import { Logger } from "./logger.ts";

// ── Types ──────────────────────────────────────────────────────────────────

/** OpenAI-compatible message format (used by all major providers via OpenRouter) */
export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string | MessageContentPart[];
}

/** For multimodal requests (text + image) */
export interface MessageContentPart {
  type: "text" | "image_url";
  text?: string;
  image_url?: { url: string };  // base64 data URL or https URL
}

/** Options you can override per-call */
export interface GenerateOptions {
  model?: string;          // Override the feature's default model
  temperature?: number;    // Override default temperature
  top_p?: number;          // Override default top_p
  max_tokens?: number;     // Override default max_tokens
  seed?: number;           // For reproducibility
  jsonMode?: boolean;       // Force JSON output format
  jsonSchema?: Record<string, unknown>; // JSON Schema for structured output
  stream?: boolean;         // Enable streaming (future feature)
}

/** Result returned by all generation methods */
export interface GenerateResult {
  /** The generated text content */
  text: string;

  /** Number of input tokens consumed */
  promptTokens: number;

  /** Number of output tokens generated */
  completionTokens: number;

  /** Total tokens (prompt + completion) */
  totalTokens: number;

  /** Time taken for the AI call only (not retries) */
  latencyMs: number;

  /** Model that was actually used */
  model: string;

  /** Provider that served the request (e.g. "google", "openai") */
  provider: string;

  /** Number of retries that were needed */
  retryCount: number;
}

// ── OpenRouter Client ──────────────────────────────────────────────────────

/**
 * The central OpenRouter gateway client.
 *
 * Instantiate once per Edge Function invocation:
 *   const ai = new OpenRouterClient(log);
 *
 * Then use any of its methods:
 *   const result = await ai.generateText("generate-dpp", systemPrompt, userPrompt);
 *   const result = await ai.generateJSON("explanation", schema, sys, usr);
 */
export class OpenRouterClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly log: Logger;

  constructor(log: Logger) {
    this.log = log;
    this.baseUrl = OPENROUTER_CONFIG.BASE_URL;

    // ── API Key from Supabase Vault ─────────────────────────────────────────
    // This reads from the Deno runtime environment — injected by Supabase.
    // Flutter runs on the user's device. It CANNOT execute this line.
    // The key never leaves Supabase's infrastructure.
    const key = Deno.env.get(OPENROUTER_CONFIG.API_KEY_ENV);
    if (!key) {
      throw new Error(
        `[OpenRouter] Secret "${OPENROUTER_CONFIG.API_KEY_ENV}" is not set in Supabase Vault. ` +
        `Run: supabase secrets set ${OPENROUTER_CONFIG.API_KEY_ENV}=sk-or-v1-...`
      );
    }
    this.apiKey = key;
    this.log.info(`OpenRouter client initialised`, { baseUrl: this.baseUrl });
  }

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  /**
   * generateText()
   * ──────────────
   * Single-turn text generation. Given a system prompt and a user prompt,
   * returns the AI's text response.
   *
   * USE WHEN: You want a free-form text answer (essay, explanation, notes).
   *
   * @param feature       - Feature key from AI_MODELS (picks default model)
   * @param systemPrompt  - The "role" instruction for the AI
   * @param userPrompt    - The actual user query or task
   * @param options       - Optional overrides for model, temperature, etc.
   */
  public async generateText(
    feature: AiFeature,
    systemPrompt: string,
    userPrompt: string,
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    const messages: ChatMessage[] = [
      { role: "system", content: systemPrompt },
      { role: "user",   content: userPrompt   },
    ];
    return this._callWithRetry(feature, messages, options);
  }

  /**
   * generateJSON()
   * ──────────────
   * Generates a response in strict JSON mode.
   * The AI is instructed to return ONLY valid JSON — no markdown, no prose.
   *
   * USE WHEN: You need a structured, machine-parseable response.
   * Example: DPP questions, explanations, notes with sections.
   *
   * HOW JSON MODE WORKS IN OPENROUTER
   * ────────────────────────────────────
   * We set `response_format: { type: "json_object" }` in the request.
   * This tells the model to only output JSON. Combined with our system prompt
   * that explicitly says "respond ONLY with JSON", this gives very reliable output.
   *
   * @param feature       - Feature key from AI_MODELS
   * @param systemPrompt  - Include JSON schema description here
   * @param userPrompt    - The actual generation task
   * @param options       - Optional overrides; jsonMode is forced true here
   */
  public async generateJSON(
    feature: AiFeature,
    systemPrompt: string,
    userPrompt: string,
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    return this.generateText(feature, systemPrompt, userPrompt, {
      ...options,
      jsonMode: true,   // Force JSON output regardless of caller's setting
    });
  }

  /**
   * chat()
   * ──────
   * Multi-turn conversation. Takes a full message history and continues the conversation.
   *
   * USE WHEN: Implementing a tutoring chatbot where conversation context matters.
   * Each call includes the entire previous conversation so the AI can refer back.
   *
   * @param feature   - Feature key from AI_MODELS (uses "chat" model by default)
   * @param messages  - Full conversation history (system + user + assistant turns)
   * @param options   - Optional overrides
   */
  public async chat(
    feature: AiFeature,
    messages: ChatMessage[],
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    return this._callWithRetry(feature, messages, options);
  }

  /**
   * stream()
   * ────────
   * FUTURE FEATURE: Returns a streaming response for real-time AI output.
   *
   * USE WHEN: You want the response to appear token-by-token (like ChatGPT typing).
   * Requires Flutter to read Server-Sent Events (SSE) from the response stream.
   *
   * Currently stubbed — implement when Flutter SSE support is added.
   */
  public async stream(
    _feature: AiFeature,
    _systemPrompt: string,
    _userPrompt: string
  ): Promise<ReadableStream> {
    throw new Error(
      "[OpenRouter] Streaming is not yet implemented. " +
      "Set stream: false or use generateText() for now."
    );
  }

  // ── PRIVATE: Core request builder ─────────────────────────────────────────

  /**
   * Builds the complete OpenRouter request body.
   *
   * WHY IS THIS PRIVATE?
   * ─────────────────────
   * Callers shouldn't know about OpenRouter's internal request format.
   * If OpenRouter changes their API, we only update this one method.
   */
  private buildRequestBody(
    feature: AiFeature,
    messages: ChatMessage[],
    options: GenerateOptions
  ): Record<string, unknown> {
    // Resolve the model: use override if provided, else feature default
    const model = options.model ?? AI_MODELS[feature];

    // Resolve generation params: use override if provided, else feature default
    const defaultParams = GENERATION_PARAMS[feature as keyof typeof GENERATION_PARAMS] ?? {
      temperature: 0.3,
      topP: 0.9,
      maxTokens: 4096,
    };

    const body: Record<string, unknown> = {
      // Which model to use (from config or override)
      model,

      // The conversation messages
      messages,

      // Generation parameters (from config, overridable per-call)
      temperature: options.temperature  ?? defaultParams.temperature,
      top_p:       options.top_p        ?? defaultParams.topP,
      max_tokens:  options.max_tokens   ?? defaultParams.maxTokens,

      // Optional seed for reproducibility (useful for caching verification)
      ...(options.seed !== undefined ? { seed: options.seed } : {}),
    };

    // ── JSON Mode ─────────────────────────────────────────────────────────
    // When jsonMode is true, we tell OpenRouter to return ONLY JSON.
    // This eliminates markdown code fences and prose around the JSON.
    if (options.jsonMode) {
      body.response_format = { type: "json_object" };
    }

    // ── Provider routing preferences ──────────────────────────────────────
    // Tell OpenRouter to prefer certain providers for this model.
    // "allow_fallbacks: true" means: if the primary provider is down,
    // try others that support this model. Essential for production reliability.
    body.provider = {
      allow_fallbacks: true,
      // Optional: order of preferred providers (if the model is on multiple)
      // order: ["Google", "Anthropic"],
    };

    // ── Transforms ────────────────────────────────────────────────────────
    // "middle-out" compression removes repeated content to save tokens.
    // Useful for long DPP prompts with repetitive structure.
    body.transforms = ["middle-out"];

    this.log.debug("Request body built", { model, feature, jsonMode: options.jsonMode });
    return body;
  }

  /**
   * Builds the HTTP headers for OpenRouter requests.
   *
   * EVERY HEADER IS REQUIRED OR STRONGLY RECOMMENDED — see module comment above.
   */
  private buildHeaders(): Record<string, string> {
    return {
      // REQUIRED: Authenticates your OpenRouter account
      // Format MUST be "Bearer " + key (note the space after Bearer)
      "Authorization": `Bearer ${this.apiKey}`,

      // REQUIRED by ToS: Identifies your application domain
      // OpenRouter uses this for attribution and abuse prevention
      "HTTP-Referer": OPENROUTER_CONFIG.SITE_URL,

      // RECOMMENDED: Human-readable app name in OpenRouter dashboard
      "X-Title": OPENROUTER_CONFIG.SITE_NAME,

      // REQUIRED: Tells OpenRouter the request body is JSON
      "Content-Type": "application/json",

      // BEST PRACTICE: Tells OpenRouter you expect JSON back
      // Some provider proxies use this for content negotiation
      "Accept": "application/json",
    };
  }

  // ── PRIVATE: Retry loop ───────────────────────────────────────────────────

  /**
   * Executes the AI call with exponential backoff retry.
   *
   * RETRY STRATEGY
   * ──────────────
   * - 429 (Rate Limited): Wait and retry — OpenRouter is throttling us
   * - 502/503/504 (Server Error): Retry — provider is temporarily down
   * - 401 (Unauthorised): DO NOT retry — the API key is wrong (would fail again)
   * - 400 (Bad Request): DO NOT retry — our request format is wrong (would fail again)
   * - Network/Timeout: Retry — transient network issue
   *
   * EXPONENTIAL BACKOFF
   * ────────────────────
   * Attempt 1: Wait 1s before retry
   * Attempt 2: Wait 2s before retry
   * Attempt 3: Wait 4s before retry (capped at maxRetryDelay)
   *
   * This prevents hammering a struggling server and helps recovery.
   */
  private async _callWithRetry(
    feature: AiFeature,
    messages: ChatMessage[],
    options: GenerateOptions
  ): Promise<GenerateResult> {
    const url = `${this.baseUrl}/chat/completions`;
    const body = this.buildRequestBody(feature, messages, options);
    const headers = this.buildHeaders();
    const model = body.model as string;

    let attempt = 0;
    let retryDelay: number = TIMEOUTS.initialRetryDelay;
    let lastError: Error | null = null;

    this.log.setModel(model);
    this.log.info(`Calling OpenRouter`, { feature, model, attempt: attempt + 1 });

    while (attempt < TIMEOUTS.maxRetries) {
      attempt++;
      const callStart = Date.now();

      // ── Timeout via AbortController ──────────────────────────────────────
      // Without this, a hung request blocks the Edge Function until Supabase
      // kills it with a hard timeout, giving the user a cryptic error.
      // With AbortController, we catch the timeout gracefully and retry.
      const controller = new AbortController();
      const timeoutId  = setTimeout(() => controller.abort(), TIMEOUTS.request);

      try {
        const response = await fetch(url, {
          method:  "POST",
          headers,
          body:    JSON.stringify(body),
          signal:  controller.signal,
        });

        clearTimeout(timeoutId);
        const latencyMs = Date.now() - callStart;

        // ── Parse and handle HTTP error codes ─────────────────────────────
        if (!response.ok) {
          const errorBody = await response.text().catch(() => "");
          this.log.warn(
            `OpenRouter HTTP error`,
            { status: response.status, attempt, body: errorBody.slice(0, 300) }
          );

          // These errors are RETRYABLE (transient server problems)
          const isRetryable = response.status === 429 || response.status >= 500;

          if (isRetryable && attempt < TIMEOUTS.maxRetries) {
            // For 429, parse Retry-After header if present
            const retryAfter = response.headers.get("Retry-After");
            const waitMs = retryAfter
              ? parseInt(retryAfter, 10) * 1000
              : retryDelay;

            this.log.warn(`Retrying after ${waitMs}ms (attempt ${attempt}/${TIMEOUTS.maxRetries})`);
            await sleep(waitMs);
            retryDelay = Math.min(retryDelay * 2, TIMEOUTS.maxRetryDelay);
            continue;
          }

          // Non-retryable or out of retries — classify and throw
          throw this._classifyHttpError(response.status, errorBody);
        }

        // ── Parse successful response ──────────────────────────────────────
        const data = await response.json() as Record<string, unknown>;
        const result = this._extractResult(data, model, latencyMs, attempt - 1);

        this.log.aiComplete({
          status:           "success",
          promptTokens:     result.promptTokens,
          completionTokens: result.completionTokens,
          latencyMs:        result.latencyMs,
          retryCount:       result.retryCount,
          provider:         result.provider,
        });

        return result;

      } catch (err) {
        clearTimeout(timeoutId);

        // AbortError = timeout
        if (err instanceof Error && err.name === "AbortError") {
          lastError = new Error(`Request timed out after ${TIMEOUTS.request / 1000}s`);
          this.log.warn(`Request timed out on attempt ${attempt}/${TIMEOUTS.maxRetries}`);

          if (attempt < TIMEOUTS.maxRetries) {
            await sleep(retryDelay);
            retryDelay = Math.min(retryDelay * 2, TIMEOUTS.maxRetryDelay);
            continue;
          }
          throw new Error("AI request timed out after all retries. Please try again.");
        }

        // Re-throw AppErrors (already classified, don't retry)
        if (err instanceof Error && "code" in err) throw err;

        // Unknown network error — retry if attempts remain
        lastError = err instanceof Error ? err : new Error(String(err));
        this.log.warn(`Network error on attempt ${attempt}: ${lastError.message}`);

        if (attempt < TIMEOUTS.maxRetries) {
          await sleep(retryDelay);
          retryDelay = Math.min(retryDelay * 2, TIMEOUTS.maxRetryDelay);
          continue;
        }
      }
    }

    // Exhausted all retries
    this.log.error("All retries exhausted", lastError);
    throw new Error(
      `OpenRouter failed after ${TIMEOUTS.maxRetries} attempts. ` +
      `Last error: ${lastError?.message ?? "Unknown"}`
    );
  }

  // ── PRIVATE: Response extraction ──────────────────────────────────────────

  /**
   * Extracts the generated text and metadata from OpenRouter's response.
   *
   * OPENROUTER RESPONSE FORMAT (OpenAI-compatible):
   * {
   *   "id": "gen-...",
   *   "model": "google/gemini-2.0-flash-exp:free",
   *   "choices": [{
   *     "message": { "role": "assistant", "content": "..." },
   *     "finish_reason": "stop"
   *   }],
   *   "usage": {
   *     "prompt_tokens": 1234,
   *     "completion_tokens": 567,
   *     "total_tokens": 1801
   *   }
   * }
   */
  private _extractResult(
    data: Record<string, unknown>,
    requestedModel: string,
    latencyMs: number,
    retryCount: number
  ): GenerateResult {
    const choices = data.choices as Array<Record<string, unknown>> | undefined;
    const text = (choices?.[0]?.message as Record<string, unknown>)?.content as string | undefined;

    if (!text || typeof text !== "string") {
      throw new Error(
        "OpenRouter returned an empty or malformed response. " +
        "The model may have refused the request."
      );
    }

    const usage = data.usage as Record<string, number> | undefined;
    const promptTokens     = usage?.prompt_tokens     ?? 0;
    const completionTokens = usage?.completion_tokens ?? 0;

    // OpenRouter returns the actual model used (may differ from requested)
    const actualModel = (data.model as string) ?? requestedModel;

    // Extract provider from model string: "google/gemini-..." → "google"
    const provider = actualModel.includes("/")
      ? actualModel.split("/")[0]
      : "unknown";

    return {
      text,
      promptTokens,
      completionTokens,
      totalTokens: promptTokens + completionTokens,
      latencyMs,
      model: actualModel,
      provider,
      retryCount,
    };
  }

  // ── PRIVATE: Error classification ─────────────────────────────────────────

  /**
   * Converts HTTP status codes to descriptive Error objects.
   * Internal details go to logs. Public messages go to Flutter.
   */
  private _classifyHttpError(status: number, body: string): Error {
    const truncatedBody = body.slice(0, 200);

    switch (status) {
      case 401:
        this.log.error("OpenRouter API key is invalid or expired", truncatedBody);
        return new Error("AI service authentication failed. Contact support.");

      case 403:
        this.log.error("OpenRouter access forbidden", truncatedBody);
        return new Error("AI service access denied. The model may require credits.");

      case 429:
        this.log.warn("OpenRouter rate limit exceeded", { body: truncatedBody });
        return new Error("AI rate limit reached. Please wait a moment and try again.");

      case 500:
      case 502:
      case 503:
        this.log.error(`OpenRouter server error ${status}`, truncatedBody);
        return new Error("AI provider is temporarily unavailable. Please try again.");

      default:
        this.log.error(`OpenRouter unexpected HTTP ${status}`, truncatedBody);
        return new Error(`AI request failed with status ${status}. Please try again.`);
    }
  }
}

// ── Utility ────────────────────────────────────────────────────────────────
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
