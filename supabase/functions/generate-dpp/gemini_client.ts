// Gemini Client wrapper for Deno Edge Runtime
import { sleep } from "./utils.ts";

export class GeminiClient {
  private readonly apiKey: string;
  private readonly modelName = "gemini-2.5-flash";
  private readonly maxRetries = 3;
  private readonly timeoutMs = 35000; // 35 seconds timeout

  constructor() {
    // Read the API Key securely from Supabase Edge environment variables
    const key = Deno.env.get("GEMINI_API_KEY");
    if (!key) {
      throw new Error("GEMINI_API_KEY is not configured in Deno.env");
    }
    this.apiKey = key;
  }

  /**
   * Generates content from Gemini using the specified system instruction, prompt, and structured JSON schema.
   * Handles timeouts, rate limits, retries, and records statistics.
   */
  public async generateDppJson(
    systemInstruction: string,
    prompt: string
  ): Promise<{ text: string; generationTimeMs: number; tokensUsed: number; promptTokens: number; completionTokens: number }> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:generateContent?key=${this.apiKey}`;
    
    // Define the strict structured JSON schema in OpenAPI format
    const responseSchema = {
      type: "OBJECT",
      properties: {
        title: { type: "STRING" },
        description: { type: "STRING" },
        exam: { type: "STRING" },
        subject: { type: "STRING" },
        chapter: { type: "STRING" },
        difficulty: { type: "STRING" },
        duration: { type: "INTEGER" },
        marks: { type: "INTEGER" },
        questions: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              id: { type: "INTEGER" },
              type: { type: "STRING" },
              question: { type: "STRING" },
              options: {
                type: "ARRAY",
                items: { type: "STRING" }
              },
              answer: { type: "STRING" },
              explanation: {
                type: "OBJECT",
                properties: {
                  correct_answer: { type: "STRING" },
                  step_by_step: { type: "STRING" },
                  why_others_incorrect: {
                    type: "OBJECT",
                    properties: {
                      A: { type: "STRING" },
                      B: { type: "STRING" },
                      C: { type: "STRING" },
                      D: { type: "STRING" }
                    },
                    required: ["A", "B", "C", "D"]
                  },
                  shortcut: { type: "STRING" },
                  common_mistake: { type: "STRING" },
                  ncert_reference: { type: "STRING" }
                },
                required: ["correct_answer", "step_by_step", "why_others_incorrect", "ncert_reference"]
              },
              concept: { type: "STRING" },
              topic: { type: "STRING" },
              difficulty: { type: "STRING" },
              estimated_time: { type: "INTEGER" },
              blooms_level: { type: "STRING" },
              difficulty_score: { type: "INTEGER" },
              source_type: { type: "STRING" }
            },
            required: [
              "id",
              "type",
              "question",
              "options",
              "answer",
              "explanation",
              "concept",
              "topic",
              "difficulty",
              "estimated_time",
              "blooms_level",
              "difficulty_score",
              "source_type"
            ]
          }
        }
      },
      required: [
        "title",
        "description",
        "exam",
        "subject",
        "chapter",
        "difficulty",
        "duration",
        "marks",
        "questions"
      ]
    };

    let attempt = 0;
    let delay = 1000; // start backoff at 1 second

    while (attempt < this.maxRetries) {
      attempt++;
      const startTime = Date.now();
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

      try {
        console.log(`[GeminiClient] Querying model ${this.modelName} (Attempt ${attempt}/${this.maxRetries}) with JSON Schema...`);

        const response = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            contents: [
              {
                role: "user",
                parts: [{ text: prompt }],
              },
            ],
            systemInstruction: {
              parts: [{ text: systemInstruction }],
            },
            generationConfig: {
              responseMimeType: "application/json",
              responseSchema: responseSchema,
              temperature: 0.15,
            },
          }),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);
        const generationTimeMs = Date.now() - startTime;

        if (!response.ok) {
          const errorBody = await response.text();
          console.error(`[GeminiClient] API Error (Status ${response.status}): ${errorBody}`);

          // Retry on Rate Limit (429) or Server Errors (5xx)
          if (response.status === 429 || response.status >= 500) {
            if (attempt < this.maxRetries) {
              console.log(`[GeminiClient] Backing off for ${delay}ms before retrying...`);
              await sleep(delay);
              delay *= 2; // exponential backoff
              continue;
            }
          }
          throw new Error(`Gemini API returned status ${response.status}: ${errorBody}`);
        }

        const data = await response.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) {
          throw new Error("Empty response returned from Gemini API");
        }

        // Retrieve token usage statistics from Gemini response metadata
        const tokensUsed = data.usageMetadata?.totalTokenCount || 0;
        const promptTokens = data.usageMetadata?.promptTokenCount || 0;
        const completionTokens = data.usageMetadata?.candidatesTokenCount || 0;

        console.log(`[GeminiClient] Success! Time taken: ${generationTimeMs}ms, Tokens used: ${tokensUsed} (Prompt: ${promptTokens}, Completion: ${completionTokens})`);

        return {
          text,
          generationTimeMs,
          tokensUsed,
          promptTokens,
          completionTokens,
        };

      } catch (err) {
        clearTimeout(timeoutId);
        const errName = err instanceof Error ? err.name : "UnknownError";
        const errMsg = err instanceof Error ? err.message : String(err);

        console.error(`[GeminiClient] Attempt ${attempt} failed with ${errName}: ${errMsg}`);

        if (errName === "AbortError") {
          console.error(`[GeminiClient] Request timed out after ${this.timeoutMs / 1000}s`);
        }

        if (attempt >= this.maxRetries) {
          throw new Error(`Gemini client failed after ${this.maxRetries} attempts. Last error: ${errMsg}`);
        }

        // Retry with backoff for connection dropouts or aborts
        await sleep(delay);
        delay *= 2;
      }
    }

    throw new Error("Unexpected end of retry loop in GeminiClient");
  }
}
