/**
 * ═══════════════════════════════════════════════════════════════════════════
 * config.ts — Central Configuration Registry (Gemini Primary)
 * Location: supabase/functions/shared/config.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Central registry for all AI engine settings, models, rate limits, timeouts,
 * and safety settings. Changing a value here updates the entire AI system.
 * ═══════════════════════════════════════════════════════════════════════════
 */

// ── OpenRouter API Configuration ───────────────────────────────────────────

export const OPENROUTER_CONFIG = {
  /** Base REST endpoint for OpenRouter API v1 */
  get baseUrl(): string {
    return Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1";
  },

  /** Environment variable name in Supabase Vault storing key */
  apiKeyEnv: "OPENROUTER_API_KEY",

  /** Default primary OpenRouter model */
  get defaultModel(): string {
    return Deno.env.get("OPENROUTER_DEFAULT_MODEL") ?? "google/gemma-4-26b-a4b-it:free";
  },

  /** Timeout in milliseconds */
  get timeoutMs(): number {
    return Number(Deno.env.get("OPENROUTER_TIMEOUT")) || 35000;
  },

  /** Max retries for transient errors */
  get maxRetries(): number {
    return Number(Deno.env.get("OPENROUTER_MAX_RETRIES")) || 2;
  },

  /** Enable fallback to Gemini on failure */
  get enableFallback(): boolean {
    return Deno.env.get("OPENROUTER_ENABLE_FALLBACK") !== "false";
  },

  /** Site URL sent in OpenRouter request headers */
  siteUrl: "https://nationalacademy.app",

  /** Site Name sent in OpenRouter request headers */
  siteName: "National Academy",
};

// ── Gemini API Configuration ───────────────────────────────────────────────

export const GEMINI_CONFIG = {
  /** Base REST endpoint for Google Gemini v1beta */
  baseUrl: "https://generativelanguage.googleapis.com/v1beta",

  /** Environment variable name in Supabase Vault storing key */
  apiKeyEnv: "GEMINI_API_KEY",

  /** Default primary model */
  defaultModel: "gemini-flash-latest",

  /** Default Top-K sampling */
  defaultTopK: 40,

  /**
   * Safety Settings tuned for Academic Educational Platforms
   *
   * WHY TUNED THIS WAY?
   * Physics (collisions, decay, mechanics), Chemistry (reactions, explosions, acids),
   * and Biology (genetics, reproduction, pathogens) use terminology that default
   * consumer filters might false-positive block.
   *
   * We keep strict blocks on Hate Speech, Harassment, and Sexually Explicit content,
   * while allowing academic scientific terminology.
   */
  safetySettings: [
    { category: "HARM_CATEGORY_HARASSMENT",        threshold: "BLOCK_MEDIUM_AND_ABOVE" },
    { category: "HARM_CATEGORY_HATE_SPEECH",        threshold: "BLOCK_MEDIUM_AND_ABOVE" },
    { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
    { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH"         },
  ],
} as const;

// ── Model Assignments per Feature ──────────────────────────────────────────

/**
 * Feature to Model Mapping.
 * These are native Gemini API model IDs (no provider prefix).
 * GeminiClient uses these directly in the URL:
 *   /v1beta/models/<model>:generateContent
 *
 * OpenRouterClient auto-prepends "google/" when needed via AI_OPENROUTER_MODELS.
 */
export const AI_MODELS = {
  dpp:           "gemini-flash-latest",
  bpp:           "gemini-flash-latest",
  chat:          "gemini-flash-latest",
  explanation:   "gemini-flash-latest",
  notes:         "gemini-flash-latest",
  doubt:         "gemini-flash-latest",
  questionPaper: "gemini-flash-latest",
  fallback:      "gemini-flash-latest",
} as const;

/**
 * OpenRouter-specific model slugs (include provider prefix for OpenRouter's API).
 */
export const AI_OPENROUTER_MODELS = {
  dpp:           "google/gemma-4-26b-a4b-it:free",
  bpp:           "google/gemma-4-26b-a4b-it:free",
  chat:          "google/gemma-4-26b-a4b-it:free",
  explanation:   "google/gemma-4-26b-a4b-it:free",
  notes:         "google/gemma-4-26b-a4b-it:free",
  doubt:         "google/gemma-4-26b-a4b-it:free",
  questionPaper: "google/gemma-4-26b-a4b-it:free",
  fallback:      "google/gemma-4-26b-a4b-it:free",
} as const;

export type AiFeature = keyof typeof AI_MODELS;

// ── Generation Parameters ──────────────────────────────────────────────────

export const GENERATION_PARAMS = {
  dpp: {
    temperature: 0.15,   // Accurate, consistent questions
    topP: 0.85,
    topK: 40,
    maxTokens: 3000,
  },
  bpp: {
    temperature: 0.15,
    topP: 0.85,
    topK: 40,
    maxTokens: 3000,
  },
  chat: {
    temperature: 0.5,    // Natural conversational tutoring
    topP: 0.9,
    topK: 40,
    maxTokens: 2048,
  },
  explanation: {
    temperature: 0.1,    // Deep accuracy for derivations
    topP: 0.8,
    topK: 40,
    maxTokens: 3500,
  },
  notes: {
    temperature: 0.2,
    topP: 0.85,
    topK: 40,
    maxTokens: 6000,
  },
  doubt: {
    temperature: 0.15,
    topP: 0.85,
    topK: 40,
    maxTokens: 2500,
  },
  questionPaper: {
    temperature: 0.1,
    topP: 0.8,
    topK: 40,
    maxTokens: 12000,
  },
} as const;

// ── Timeouts & Retries ─────────────────────────────────────────────────────

export const TIMEOUTS = {
  request: 45_000,          // 45 seconds per request
  totalOperation: 120_000,  // 2 minutes total limit
  initialRetryDelay: 1_000, // 1 second exponential backoff start
  maxRetryDelay: 8_000,     // 8 seconds max retry delay
  maxRetries: 3,            // 3 attempts
  cacheTtlSeconds: 3_600,   // 1 hour cache TTL
} as const;

// ── Rate Limits ────────────────────────────────────────────────────────────

export const RATE_LIMITS = {
  guest:   { windowMinutes: 60, maxRequests: 3,   dailyLimit: 5     },
  free:    { windowMinutes: 60, maxRequests: 20,  dailyLimit: 50    },
  student: { windowMinutes: 60, maxRequests: 40,  dailyLimit: 200   },
  teacher: { windowMinutes: 60, maxRequests: 60,  dailyLimit: 500   },
  admin:   { windowMinutes: 60, maxRequests: 500, dailyLimit: 10000 },
} as const;

export type UserTier = keyof typeof RATE_LIMITS;

export const FEATURE_LIMITS: Record<string, { windowMinutes: number; maxRequests: number }> = {
  "generate-dpp":      { windowMinutes: 60, maxRequests: 20 },
  "generate-bpp":      { windowMinutes: 60, maxRequests: 20 },
  "ai-chat":           { windowMinutes: 60, maxRequests: 50 },
  "explain-question":  { windowMinutes: 60, maxRequests: 30 },
  "notes-generator":   { windowMinutes: 60, maxRequests: 10 },
  "doubt-solver":      { windowMinutes: 60, maxRequests: 30 },
  "question-paper":    { windowMinutes: 60, maxRequests:  5 },
};

// ── Security Configuration ─────────────────────────────────────────────────

export const SECURITY = {
  maxPromptLength: 2000,
  maxChatHistory: 20,
  maxImageSizeBytes: 4 * 1024 * 1024,
  injectionPatterns: [
    "ignore all previous instructions",
    "ignore your instructions",
    "disregard your",
    "you are now",
    "new instructions:",
    "forget everything",
    "act as if",
    "pretend you are",
    "from now on you",
    "system: you are",
    "<system>",
    "</system>",
    "\\n\\nsystem:",
  ],
  allowedExams: ["JEE", "NEET", "NDA", "CUET", "BOARD", "OLYMPIAD"] as string[],
  allowedDifficulties: ["Easy", "Medium", "Hard", "Basic", "High", "Adaptive"] as string[],
  allowedQuestionTypes: [
    "MCQ",
    "Single Correct",
    "Multiple Correct",
    "Integer",
    "Assertion-Reason",
    "Match the Column",
  ] as string[],
} as const;

// ── Cache Configuration ────────────────────────────────────────────────────

export const CACHE_CONFIG = {
  enabled: true,
  defaultTtlSeconds: 3_600,
  cacheableFeatures: [
    "generate-dpp",
    "generate-bpp",
    "explain-question",
    "notes-generator",
  ] as string[],
  maxCachedResponseLength: 50_000,
} as const;
