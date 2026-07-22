import { Logger } from "../logger.ts";
import { AIProvider, GenerateOptions, GenerateResult, ChatMessage } from "./provider.ts";
import { AI_OPENROUTER_MODELS, OPENROUTER_CONFIG } from "../config.ts";
import { AppError } from "../errors.ts";
import { getModelMetadata, ModelMetadata } from "./model_registry.ts";

export class OpenRouterClient implements AIProvider {
  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly log: Logger;
  private readonly activeModel: string;

  constructor(log: Logger) {
    this.log = log;
    this.baseUrl = OPENROUTER_CONFIG.baseUrl;
    this.activeModel = OPENROUTER_CONFIG.defaultModel;

    const key = Deno.env.get(OPENROUTER_CONFIG.apiKeyEnv);
    if (!key) {
      throw new AppError(
        "UNAUTHORISED",
        `Secret "${OPENROUTER_CONFIG.apiKeyEnv}" is not set in Supabase Vault. Please run: supabase secrets set ${OPENROUTER_CONFIG.apiKeyEnv}=sk-or-v1-...`
      );
    }
    this.apiKey = key;
    this.log.info("OpenRouter client initialised", { baseUrl: this.baseUrl, defaultModel: this.activeModel });
  }

  public async healthCheck(): Promise<boolean> {
    try {
      const res = await fetch(`${this.baseUrl}/models`, {
        headers: { "Authorization": `Bearer ${this.apiKey}` },
      });
      return res.ok;
    } catch {
      return false;
    }
  }

  public supportsThinking(): boolean { return false; }
  public supportsVision(): boolean { return false; }
  public supportsStructuredOutput(): boolean { return true; }
  public supportsFunctionCalling(): boolean { return false; }

  public getModelInfo(): ModelMetadata {
    return getModelMetadata(this.activeModel);
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
    const messages: ChatMessage[] = [];
    if (systemPrompt) {
      messages.push({ role: "system", content: systemPrompt });
    }
    messages.push({ role: "user", content: userPrompt });

    return this.chat(feature, messages, options);
  }

  public async chat(
    feature: string,
    messages: ChatMessage[],
    options: GenerateOptions = {}
  ): Promise<GenerateResult> {
    const model = options.model ?? AI_OPENROUTER_MODELS[feature as keyof typeof AI_OPENROUTER_MODELS] ?? this.activeModel;
    const startMs = Date.now();

    const requestBody: Record<string, unknown> = {
      model,
      messages,
      temperature: options.temperature ?? 0.2,
      max_tokens: options.maxOutputTokens ?? 3000,
      ...(options.jsonMode ? { response_format: { type: "json_object" } } : {}),
    };

    this.log.setModel(model);
    this.log.info("Calling OpenRouter API", { feature, model, jsonMode: options.jsonMode });

    try {
      const response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${this.apiKey}`,
          "HTTP-Referer": OPENROUTER_CONFIG.siteUrl,
          "X-Title": OPENROUTER_CONFIG.siteName,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      });

      const latencyMs = Date.now() - startMs;

      if (!response.ok) {
        const errText = await response.text().catch(() => "");
        this.log.warn(`OpenRouter HTTP ${response.status}`, { body: errText.slice(0, 250) });

        if (response.status === 401 || response.status === 403) {
          throw new AppError("UNAUTHORISED", `OpenRouter API key is invalid or unauthorized: ${errText.slice(0, 150)}`);
        }
        if (response.status === 429) {
          throw new AppError("RATE_LIMITED", "OpenRouter rate limit or credit limit reached.");
        }
        if (response.status === 404) {
          throw new AppError("MODEL_NOT_FOUND", `OpenRouter model '${model}' not found.`);
        }
        throw new AppError("AI_PROVIDER_ERROR", `OpenRouter HTTP ${response.status}: ${errText.slice(0, 150)}`);
      }

      const data = await response.json() as Record<string, unknown>;
      const choices = data.choices as Array<Record<string, unknown>> | undefined;
      const firstChoice = choices?.[0];
      const message = firstChoice?.message as Record<string, unknown> | undefined;
      const text = message?.content as string | undefined;

      if (!text) {
        throw new AppError("AI_PROVIDER_ERROR", "OpenRouter returned an empty completion response.");
      }

      const finishReason = (firstChoice?.finish_reason as string) ?? "stop";
      if (finishReason === "length" || finishReason === "max_tokens") {
        throw new AppError("OUTPUT_TRUNCATED", "OpenRouter generation was truncated due to max output tokens.");
      }

      const usage = data.usage as Record<string, number> | undefined;
      const promptTokens = usage?.prompt_tokens ?? 0;
      const completionTokens = usage?.completion_tokens ?? 0;
      const totalTokens = usage?.total_tokens ?? (promptTokens + completionTokens);

      return {
        text,
        promptTokens,
        completionTokens,
        totalTokens,
        latencyMs,
        model,
        provider: "openrouter",
        finishReason,
        retryCount: 0,
      };
    } catch (err) {
      if (err instanceof AppError) throw err;
      throw new AppError("AI_PROVIDER_ERROR", `OpenRouter call failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
}
