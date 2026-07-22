/**
 * ═══════════════════════════════════════════════════════════════════════════
 * provider.ts — AI Provider Abstraction Interface
 * Location: supabase/functions/shared/ai/provider.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Defines a clean, provider-agnostic interface for AI operations.
 * All feature logic (DPP, BPP, Chat, Notes, Explanation) depends strictly
 * on this interface — NEVER on concrete SDK implementations directly.
 *
 * WHY PROVIDER ABSTRACTION?
 * ──────────────────────────
 * 1. Low Coupling: Feature code doesn't care whether Gemini, OpenAI,
 *    or OpenRouter generates the text.
 * 2. Rapid Switching: Allows changing the underlying AI engine from Gemini
 *    to OpenRouter or Claude by modifying only the factory instantiation.
 * 3. Testing: Makes mocking AI responses straightforward for unit testing.
 * ═══════════════════════════════════════════════════════════════════════════
 */

// ── Options passed to generation methods ───────────────────────────────────

export interface GenerateOptions {
  model?: string;             // Override default feature model
  temperature?: number;       // Randomness control (0.0 to 2.0)
  topP?: number;              // Nucleus sampling
  topK?: number;              // Top-K sampling (Gemini specific)
  maxOutputTokens?: number;   // Maximum tokens in completion
  jsonMode?: boolean;          // Enforce strict JSON output
  jsonSchema?: Record<string, unknown>; // Structured JSON Schema
  safetySettings?: Array<{ category: string; threshold: string }>;
}

// ── Unified result returned by all providers ───────────────────────────────

export interface GenerateResult {
  /** The generated text content */
  text: string;

  /** Number of prompt tokens used */
  promptTokens: number;

  /** Number of completion tokens generated */
  completionTokens: number;

  /** Total tokens consumed */
  totalTokens: number;

  /** Time taken for the API call in milliseconds */
  latencyMs: number;

  /** Model name that served the request */
  model: string;

  /** Provider name (e.g. "gemini", "openrouter") */
  provider: string;

  /** Finish reason from model (e.g. "STOP", "MAX_TOKENS", "SAFETY") */
  finishReason?: string;

  /** Number of retries that were executed */
  retryCount: number;
}

// ── Chat Message format ───────────────────────────────────────────────────

export interface ChatMessage {
  role: "system" | "user" | "model" | "assistant";
  content: string;
}

// ── Abstract AI Provider Interface ─────────────────────────────────────────

import { ModelMetadata } from "./model_registry.ts";

export interface AIProvider {
  /**
   * Generates a strict JSON output response.
   */
  generateJSON(
    feature: string,
    systemPrompt: string,
    userPrompt: string,
    options?: GenerateOptions
  ): Promise<GenerateResult>;

  /**
   * Generates free-form text output.
   */
  generateText(
    feature: string,
    systemPrompt: string,
    userPrompt: string,
    options?: GenerateOptions
  ): Promise<GenerateResult>;

  /**
   * Multi-turn chat conversation.
   */
  chat(
    feature: string,
    messages: ChatMessage[],
    options?: GenerateOptions
  ): Promise<GenerateResult>;

  /** Checks provider health/reachability */
  healthCheck(): Promise<boolean>;

  /** Capability checks */
  supportsThinking(): boolean;
  supportsVision(): boolean;
  supportsStructuredOutput(): boolean;
  supportsFunctionCalling(): boolean;

  /** Metadata for active model */
  getModelInfo(): ModelMetadata;
}
