/**
 * ═══════════════════════════════════════════════════════════════════════════
 * factory.ts — AI Provider Factory & Multi-Provider Failover Gateway
 * Location: supabase/functions/shared/ai/factory.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Instantiates and returns an AIProvider implementation.
 * Edge Functions call AiFactory.getProvider(log) to acquire an AIProvider instance.
 * Automatically handles multi-provider failover (OpenRouter primary, Gemini fallback).
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { Logger } from "../logger.ts";
import { AIProvider, GenerateOptions, GenerateResult, ChatMessage } from "./provider.ts";
import { GeminiClient } from "./gemini_client.ts";
import { OpenRouterClient } from "./openrouter_client.ts";
import { ModelMetadata } from "./model_registry.ts";

export type ProviderType = "gemini" | "openrouter";

export class FailoverAIProvider implements AIProvider {
  private primary: AIProvider;
  private secondary: AIProvider | null;
  private log: Logger;

  constructor(primary: AIProvider, secondary: AIProvider | null, log: Logger) {
    this.primary = primary;
    this.secondary = secondary;
    this.log = log;
  }

  public async generateJSON(
    feature: string,
    systemPrompt: string,
    userPrompt: string,
    options?: GenerateOptions
  ): Promise<GenerateResult> {
    try {
      return await this.primary.generateJSON(feature, systemPrompt, userPrompt, options);
    } catch (err) {
      if (this.secondary) {
        this.log.warn(
          `Primary AI provider failed (${err instanceof Error ? err.message : String(err)}). Retrying with fallback provider...`
        );
        return await this.secondary.generateJSON(feature, systemPrompt, userPrompt, options);
      }
      throw err;
    }
  }

  public async generateText(
    feature: string,
    systemPrompt: string,
    userPrompt: string,
    options?: GenerateOptions
  ): Promise<GenerateResult> {
    try {
      return await this.primary.generateText(feature, systemPrompt, userPrompt, options);
    } catch (err) {
      if (this.secondary) {
        this.log.warn(
          `Primary AI provider failed (${err instanceof Error ? err.message : String(err)}). Retrying with fallback provider...`
        );
        return await this.secondary.generateText(feature, systemPrompt, userPrompt, options);
      }
      throw err;
    }
  }

  public async chat(
    feature: string,
    messages: ChatMessage[],
    options?: GenerateOptions
  ): Promise<GenerateResult> {
    try {
      return await this.primary.chat(feature, messages, options);
    } catch (err) {
      if (this.secondary) {
        this.log.warn(
          `Primary AI provider failed (${err instanceof Error ? err.message : String(err)}). Retrying with fallback provider...`
        );
        return await this.secondary.chat(feature, messages, options);
      }
      throw err;
    }
  }

  public async healthCheck(): Promise<boolean> {
    const pHealth = await this.primary.healthCheck();
    if (pHealth) return true;
    return this.secondary ? await this.secondary.healthCheck() : false;
  }

  public supportsThinking(): boolean {
    return this.primary.supportsThinking();
  }

  public supportsVision(): boolean {
    return this.primary.supportsVision();
  }

  public supportsStructuredOutput(): boolean {
    return this.primary.supportsStructuredOutput();
  }

  public supportsFunctionCalling(): boolean {
    return this.primary.supportsFunctionCalling();
  }

  public getModelInfo(): ModelMetadata {
    return this.primary.getModelInfo();
  }
}

export class AiFactory {
  /**
   * Returns an instance of AIProvider with automatic multi-provider failover.
   * OpenRouter (google/gemma-4-26b-a4b-it:free) is primary.
   * Gemini (gemini-flash-latest) is secondary fallback.
   */
  public static getProvider(
    log: Logger,
    preferredProvider: ProviderType = "openrouter"
  ): AIProvider {
    const hasOpenRouter = Boolean(Deno.env.get("OPENROUTER_API_KEY"));
    const hasGemini = Boolean(Deno.env.get("GEMINI_API_KEY"));

    let primaryClient: AIProvider | null = null;
    let secondaryClient: AIProvider | null = null;

    if (preferredProvider === "openrouter") {
      if (hasOpenRouter) primaryClient = new OpenRouterClient(log);
      if (hasGemini) secondaryClient = new GeminiClient(log);
    } else {
      if (hasGemini) primaryClient = new GeminiClient(log);
      if (hasOpenRouter) secondaryClient = new OpenRouterClient(log);
    }

    if (!primaryClient && secondaryClient) {
      primaryClient = secondaryClient;
      secondaryClient = null;
    }

    if (!primaryClient) {
      return new GeminiClient(log);
    }

    return new FailoverAIProvider(primaryClient, secondaryClient, log);
  }
}
