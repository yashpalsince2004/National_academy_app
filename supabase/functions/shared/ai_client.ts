/**
 * ai_client.ts — Universal AI Provider Client
 *
 * WHY THIS EXISTS
 * ───────────────
 * Your project uses Gemini today. Tomorrow you might add OpenRouter for
 * failover, or Claude for creative content generation. Without an abstraction
 * layer, you'd rewrite every function when you switch providers.
 *
 * This module provides ONE interface — `AiClient` — that any function uses.
 * To switch providers, you change ONE config value. The rest of the codebase
 * stays identical.
 *
 * HOW SECRETS WORK INTERNALLY
 * ────────────────────────────
 * API keys are stored as Supabase Secrets (encrypted at rest in Vault).
 * At Edge Function runtime, Supabase injects them as environment variables.
 * Deno.env.get("GEMINI_API_KEY") reads from this secure environment.
 *
 * WHY FLUTTER CANNOT SEE THEM
 * ─────────────────────────────
 * Flutter calls the Edge Function URL. It never sees the Edge Function's
 * source code, environment variables, or API keys. The Edge Function runs
 * on Supabase infrastructure, and the key stays there. It's equivalent to
 * calling a backend API — you call the endpoint, not the internals.
 *
 * ADDING A NEW PROVIDER
 * ──────────────────────
 * 1. Add a new case to the `AiProvider` enum
 * 2. Add a `case` block in `generateContent()` and `chat()`
 * 3. Store the API key in Supabase Secrets
 * Done. Zero other changes needed.
 *
 * ARCHITECTURE DIAGRAM
 * ──────────────────────────────────────────────────────────────────────────
 *
 *   Flutter App
 *       │  POST /functions/v1/generate-dpp
 *       │  Authorization: Bearer <JWT>
 *       ▼
 *   Edge Function (generate-dpp/index.ts)
 *       │
 *       ├─ requireAuth()          ← verify JWT
 *       ├─ AiClient.generateContent()
 *       │       │
 *       │       ├─ provider=GEMINI  → Google AI API
 *       │       ├─ provider=OPENROUTER → openrouter.ai API
 *       │       └─ provider=OPENAI → api.openai.com
 *       │
 *       └─ Return sanitised JSON to Flutter
 *
 * ─────────────────────────────────────────────────────────────────────────
 */

// ── Supported AI providers ────────────────────────────────────────────────
export type AiProvider =
  | "gemini"
  | "openrouter"
  | "openai"
  | "claude"
  | "deepseek"
  | "groq"
  | "mistral";

// ── Chat message format (OpenAI-compatible across most providers) ─────────
export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

// ── Generic generation request ────────────────────────────────────────────
export interface GenerateRequest {
  systemPrompt: string;
  userPrompt: string;
  /** Optional JSON schema to enforce structured output (Gemini native) */
  jsonSchema?: Record<string, unknown>;
  /** Temperature: 0.0 = deterministic, 1.0 = creative. Default: 0.15 */
  temperature?: number;
  /** Maximum tokens in the response */
  maxTokens?: number;
}

// ── Generation result ─────────────────────────────────────────────────────
export interface GenerateResult {
  text: string;
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  latencyMs: number;
  provider: AiProvider;
  model: string;
}

// ── Provider configuration map ────────────────────────────────────────────
// Each provider maps to its endpoint, model, and secret key name.
const PROVIDER_CONFIG: Record<
  AiProvider,
  { endpoint: string; model: string; secretKey: string }
> = {
  gemini: {
    endpoint: "https://generativelanguage.googleapis.com/v1beta/models",
    model: "gemini-2.5-flash",
    secretKey: "GEMINI_API_KEY",
  },
  openrouter: {
    endpoint: "https://openrouter.ai/api/v1/chat/completions",
    model: "google/gemini-2.5-flash",  // change to any model on openrouter.ai
    secretKey: "OPENROUTER_API_KEY",
  },
  openai: {
    endpoint: "https://api.openai.com/v1/chat/completions",
    model: "gpt-4o-mini",
    secretKey: "OPENAI_API_KEY",
  },
  claude: {
    endpoint: "https://api.anthropic.com/v1/messages",
    model: "claude-3-5-sonnet-20241022",
    secretKey: "CLAUDE_API_KEY",
  },
  deepseek: {
    endpoint: "https://api.deepseek.com/v1/chat/completions",
    model: "deepseek-chat",
    secretKey: "DEEPSEEK_API_KEY",
  },
  groq: {
    endpoint: "https://api.groq.com/openai/v1/chat/completions",
    model: "llama-3.1-70b-versatile",
    secretKey: "GROQ_API_KEY",
  },
  mistral: {
    endpoint: "https://api.mistral.ai/v1/chat/completions",
    model: "mistral-small-latest",
    secretKey: "MISTRAL_API_KEY",
  },
};

// ── Retry + backoff helper ────────────────────────────────────────────────
function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Universal AI Client.
 *
 * Instantiate with a provider name. All subsequent calls use that provider.
 * To switch providers, change the constructor argument — nothing else changes.
 *
 * Example:
 *   const ai = new AiClient("gemini");
 *   const result = await ai.generateContent({ systemPrompt, userPrompt });
 */
export class AiClient {
  private readonly provider: AiProvider;
  private readonly apiKey: string;
  private readonly model: string;
  private readonly endpoint: string;
  private readonly maxRetries = 3;
  private readonly timeoutMs = 40_000; // 40 seconds

  constructor(provider: AiProvider = "gemini") {
    this.provider = provider;
    const config = PROVIDER_CONFIG[provider];

    // Read the API key from Supabase Secrets (injected as env vars at runtime)
    const key = Deno.env.get(config.secretKey);
    if (!key) {
      // Fail fast at construction time — better than failing mid-request
      throw new Error(
        `[AiClient] Secret "${config.secretKey}" is not set. ` +
        `Run: supabase secrets set ${config.secretKey}=<your-key>`
      );
    }

    this.apiKey = key;
    this.model = config.model;
    this.endpoint = config.endpoint;
    console.log(
      `[AiClient] Initialised provider=${provider} model=${this.model}`
    );
  }

  /**
   * Generate content from the AI provider.
   * Automatically retries on transient failures (429, 5xx) with exponential backoff.
   */
  public async generateContent(req: GenerateRequest): Promise<GenerateResult> {
    const startMs = Date.now();

    switch (this.provider) {
      case "gemini":
        return this._callGemini(req, startMs);
      case "openrouter":
      case "openai":
      case "deepseek":
      case "groq":
      case "mistral":
        return this._callOpenAiCompatible(req, startMs);
      case "claude":
        return this._callClaude(req, startMs);
      default:
        throw new Error(`[AiClient] Unsupported provider: ${this.provider}`);
    }
  }

  // ── GEMINI ──────────────────────────────────────────────────────────────
  private async _callGemini(
    req: GenerateRequest,
    startMs: number
  ): Promise<GenerateResult> {
    const url = `${this.endpoint}/${this.model}:generateContent?key=${this.apiKey}`;
    const body: Record<string, unknown> = {
      contents: [{ role: "user", parts: [{ text: req.userPrompt }] }],
      systemInstruction: { parts: [{ text: req.systemPrompt }] },
      generationConfig: {
        temperature: req.temperature ?? 0.15,
        maxOutputTokens: req.maxTokens ?? 8192,
        ...(req.jsonSchema
          ? {
              responseMimeType: "application/json",
              responseSchema: req.jsonSchema,
            }
          : {}),
      },
    };

    return this._fetchWithRetry(url, body, {
      "Content-Type": "application/json",
    }, (data: any) => {
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
      return {
        text,
        promptTokens: data.usageMetadata?.promptTokenCount ?? 0,
        completionTokens: data.usageMetadata?.candidatesTokenCount ?? 0,
        totalTokens: data.usageMetadata?.totalTokenCount ?? 0,
        latencyMs: Date.now() - startMs,
        provider: this.provider,
        model: this.model,
      };
    });
  }

  // ── OPENAI COMPATIBLE (OpenRouter, OpenAI, DeepSeek, Groq, Mistral) ─────
  private async _callOpenAiCompatible(
    req: GenerateRequest,
    startMs: number
  ): Promise<GenerateResult> {
    const messages: ChatMessage[] = [
      { role: "system", content: req.systemPrompt },
      { role: "user", content: req.userPrompt },
    ];

    const body: Record<string, unknown> = {
      model: this.model,
      messages,
      temperature: req.temperature ?? 0.15,
      max_tokens: req.maxTokens ?? 8192,
      ...(req.jsonSchema ? { response_format: { type: "json_object" } } : {}),
    };

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${this.apiKey}`,
    };

    // OpenRouter requires a site URL header
    if (this.provider === "openrouter") {
      headers["HTTP-Referer"] = "https://nationalacademy.app";
      headers["X-Title"] = "National Academy AI";
    }

    return this._fetchWithRetry(this.endpoint, body, headers, (data: any) => {
      const text = data.choices?.[0]?.message?.content ?? "";
      return {
        text,
        promptTokens: data.usage?.prompt_tokens ?? 0,
        completionTokens: data.usage?.completion_tokens ?? 0,
        totalTokens: data.usage?.total_tokens ?? 0,
        latencyMs: Date.now() - startMs,
        provider: this.provider,
        model: this.model,
      };
    });
  }

  // ── CLAUDE (Anthropic) ───────────────────────────────────────────────────
  private async _callClaude(
    req: GenerateRequest,
    startMs: number
  ): Promise<GenerateResult> {
    const body = {
      model: this.model,
      max_tokens: req.maxTokens ?? 8192,
      system: req.systemPrompt,
      messages: [{ role: "user", content: req.userPrompt }],
      temperature: req.temperature ?? 0.15,
    };

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "x-api-key": this.apiKey,
      "anthropic-version": "2023-06-01",
    };

    return this._fetchWithRetry(this.endpoint, body, headers, (data: any) => {
      const text = data.content?.[0]?.text ?? "";
      return {
        text,
        promptTokens: data.usage?.input_tokens ?? 0,
        completionTokens: data.usage?.output_tokens ?? 0,
        totalTokens:
          (data.usage?.input_tokens ?? 0) + (data.usage?.output_tokens ?? 0),
        latencyMs: Date.now() - startMs,
        provider: this.provider,
        model: this.model,
      };
    });
  }

  // ── Shared fetch with exponential-backoff retry ────────────────────────
  private async _fetchWithRetry(
    url: string,
    body: Record<string, unknown>,
    headers: Record<string, string>,
    parse: (data: any) => GenerateResult
  ): Promise<GenerateResult> {
    let attempt = 0;
    let delay = 1000;

    while (attempt < this.maxRetries) {
      attempt++;
      const controller = new AbortController();
      const tid = setTimeout(() => controller.abort(), this.timeoutMs);

      try {
        console.log(
          `[AiClient] ${this.provider} attempt ${attempt}/${this.maxRetries}...`
        );

        const response = await fetch(url, {
          method: "POST",
          headers,
          body: JSON.stringify(body),
          signal: controller.signal,
        });

        clearTimeout(tid);

        if (!response.ok) {
          const errText = await response.text();
          // Retry on rate-limit or server error
          if (
            (response.status === 429 || response.status >= 500) &&
            attempt < this.maxRetries
          ) {
            console.warn(
              `[AiClient] ${response.status} — backing off ${delay}ms`
            );
            await sleep(delay);
            delay *= 2;
            continue;
          }
          throw new Error(
            `[AiClient] ${this.provider} HTTP ${response.status}: ${errText}`
          );
        }

        const data = await response.json();
        const result = parse(data);

        if (!result.text) {
          throw new Error(
            `[AiClient] ${this.provider} returned empty text`
          );
        }

        console.log(
          `[AiClient] ✓ ${this.provider} success. ` +
          `Tokens: ${result.totalTokens} | Latency: ${result.latencyMs}ms`
        );

        return result;
      } catch (err) {
        clearTimeout(tid);
        const isAbort = err instanceof Error && err.name === "AbortError";

        if (isAbort) {
          console.error(
            `[AiClient] Request timed out after ${this.timeoutMs}ms`
          );
        } else {
          console.error(`[AiClient] Attempt ${attempt} error:`, err);
        }

        if (attempt >= this.maxRetries) {
          throw new Error(
            `[AiClient] ${this.provider} failed after ${this.maxRetries} attempts. ` +
            `Last error: ${err instanceof Error ? err.message : String(err)}`
          );
        }

        await sleep(delay);
        delay *= 2;
      }
    }

    throw new Error("[AiClient] Unexpected exit from retry loop");
  }
}
