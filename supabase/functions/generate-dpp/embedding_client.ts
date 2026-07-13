// Gemini Embedding Client for Semantic Duplicate Check in Deno Edge Runtime
import { sleep } from "./utils.ts";

export class EmbeddingClient {
  private readonly apiKey: string;
  private readonly modelName = "text-embedding-004";
  private readonly maxRetries = 2;
  private readonly timeoutMs = 15000;

  constructor() {
    const key = Deno.env.get("GEMINI_API_KEY");
    if (!key) {
      throw new Error("GEMINI_API_KEY is not configured in Deno.env");
    }
    this.apiKey = key;
  }

  /**
   * Generates a vector embedding array for the given input text.
   */
  public async getEmbedding(text: string): Promise<number[]> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:embedContent?key=${this.apiKey}`;
    let attempt = 0;
    let delay = 1000;

    while (attempt < this.maxRetries) {
      attempt++;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

      try {
        const response = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: `models/${this.modelName}`,
            content: {
              parts: [{ text }],
            },
          }),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          const errBody = await response.text();
          if (response.status === 429 || response.status >= 500) {
            if (attempt < this.maxRetries) {
              await sleep(delay);
              delay *= 2;
              continue;
            }
          }
          throw new Error(`Embedding API status ${response.status}: ${errBody}`);
        }

        const data = await response.json();
        const values = data.embedding?.values;
        if (!values || !Array.isArray(values)) {
          throw new Error("Failed to parse embedding values from API response");
        }

        return values;

      } catch (err) {
        clearTimeout(timeoutId);
        if (attempt >= this.maxRetries) {
          console.error(`[EmbeddingClient] Failed to generate embedding: ${err}`);
          throw err;
        }
        await sleep(delay);
        delay *= 2;
      }
    }
    throw new Error("Unexpected end of retry loop in EmbeddingClient");
  }

  /**
   * Computes the cosine similarity between two vectors.
   */
  public static calculateCosineSimilarity(vecA: number[], vecB: number[]): number {
    if (vecA.length !== vecB.length) {
      throw new Error(`Dimension mismatch: vecA (${vecA.length}) vs vecB (${vecB.length})`);
    }

    let dotProduct = 0.0;
    let normA = 0.0;
    let normB = 0.0;

    for (let i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA === 0 || normB === 0) return 0.0;
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  /**
   * Checks a set of texts for duplicate content. Returns a list of duplicates found.
   */
  public async detectDuplicates(texts: string[], threshold = 0.85): Promise<string[]> {
    console.log(`[EmbeddingClient] Running semantic duplicate detection on ${texts.length} questions...`);
    const embeddings = await Promise.all(
      texts.map(text => this.getEmbedding(text).catch(() => []))
    );

    const duplicates: string[] = [];

    for (let i = 0; i < texts.length; i++) {
      if (embeddings[i].length === 0) continue;
      for (let j = i + 1; j < texts.length; j++) {
        if (embeddings[j].length === 0) continue;
        const sim = EmbeddingClient.calculateCosineSimilarity(embeddings[i], embeddings[j]);
        if (sim > threshold) {
          console.warn(`[EmbeddingClient] Semantic duplicate found: Q#${i + 1} and Q#${j + 1} are too similar (Similarity: ${(sim * 100).toFixed(1)}%)`);
          duplicates.push(`Question #${i + 1} is semantically similar to Question #${j + 1} (${(sim * 100).toFixed(1)}%)`);
        }
      }
    }

    return duplicates;
  }
}
