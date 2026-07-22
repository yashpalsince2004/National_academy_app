/**
 * ═══════════════════════════════════════════════════════════════════════════
 * model_registry.ts — Unified Model Capabilities & Metadata Registry
 * Location: supabase/functions/shared/ai/model_registry.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Defines metadata, context windows, cost parameters, and features for all supported
 * models across providers (OpenRouter, Gemini, Anthropic, OpenAI, DeepSeek, Qwen).
 * ═══════════════════════════════════════════════════════════════════════════
 */

export interface ModelMetadata {
  id: string;
  name: string;
  provider: "openrouter" | "gemini" | "anthropic" | "openai";
  contextWindow: number;
  maxOutputTokens: number;
  supportsJson: boolean;
  supportsVision: boolean;
  supportsThinking: boolean;
  supportsFunctionCalling: boolean;
  costPer1kInputUsd: number;
  costPer1kOutputUsd: number;
  latencyEstimateMs: number;
  availability: "available" | "limited" | "deprecated";
}

export const MODEL_REGISTRY: Record<string, ModelMetadata> = {
  "google/gemma-4-26b-a4b-it:free": {
    id: "google/gemma-4-26b-a4b-it:free",
    name: "Gemma 4 26B Instruct (Free)",
    provider: "openrouter",
    contextWindow: 16384,
    maxOutputTokens: 4096,
    supportsJson: true,
    supportsVision: false,
    supportsThinking: false,
    supportsFunctionCalling: false,
    costPer1kInputUsd: 0,
    costPer1kOutputUsd: 0,
    latencyEstimateMs: 1200,
    availability: "available",
  },

  "gemini-flash-latest": {
    id: "gemini-flash-latest",
    name: "Google Gemini 2.5 Flash",
    provider: "gemini",
    contextWindow: 1048576,
    maxOutputTokens: 8192,
    supportsJson: true,
    supportsVision: true,
    supportsThinking: false,
    supportsFunctionCalling: true,
    costPer1kInputUsd: 0.000075,
    costPer1kOutputUsd: 0.0003,
    latencyEstimateMs: 1500,
    availability: "available",
  },

  "anthropic/claude-3.5-sonnet": {
    id: "anthropic/claude-3.5-sonnet",
    name: "Claude 3.5 Sonnet",
    provider: "openrouter",
    contextWindow: 200000,
    maxOutputTokens: 8192,
    supportsJson: true,
    supportsVision: true,
    supportsThinking: true,
    supportsFunctionCalling: true,
    costPer1kInputUsd: 0.003,
    costPer1kOutputUsd: 0.015,
    latencyEstimateMs: 2200,
    availability: "available",
  },

  "openai/gpt-4o-mini": {
    id: "openai/gpt-4o-mini",
    name: "GPT-4o Mini",
    provider: "openrouter",
    contextWindow: 128000,
    maxOutputTokens: 16384,
    supportsJson: true,
    supportsVision: true,
    supportsThinking: false,
    supportsFunctionCalling: true,
    costPer1kInputUsd: 0.00015,
    costPer1kOutputUsd: 0.0006,
    latencyEstimateMs: 1100,
    availability: "available",
  },

  "deepseek/deepseek-r1": {
    id: "deepseek/deepseek-r1",
    name: "DeepSeek R1",
    provider: "openrouter",
    contextWindow: 64000,
    maxOutputTokens: 8192,
    supportsJson: true,
    supportsVision: false,
    supportsThinking: true,
    supportsFunctionCalling: false,
    costPer1kInputUsd: 0.00055,
    costPer1kOutputUsd: 0.00219,
    latencyEstimateMs: 3500,
    availability: "available",
  },
};

export function getModelMetadata(modelId: string): ModelMetadata {
  return (
    MODEL_REGISTRY[modelId] ?? {
      id: modelId,
      name: modelId,
      provider: modelId.includes("/") ? "openrouter" : "gemini",
      contextWindow: 16384,
      maxOutputTokens: 4096,
      supportsJson: true,
      supportsVision: false,
      supportsThinking: false,
      supportsFunctionCalling: false,
      costPer1kInputUsd: 0,
      costPer1kOutputUsd: 0,
      latencyEstimateMs: 1500,
      availability: "available",
    }
  );
}
