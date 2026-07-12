// Parser to clean and parse JSON response from Gemini
import { GeminiDppPayload } from "./types.ts";

export class ResponseParser {
  /**
   * Cleans potential Markdown wrapper indicators and parses JSON payload
   */
  public static parseGeminiResponse(rawText: string): GeminiDppPayload {
    if (!rawText) {
      throw new Error("Raw response text is empty");
    }

    let cleanedText = rawText.trim();

    // Remove markdown code block delimiters if present (e.g. ```json ... ```)
    if (cleanedText.startsWith("```")) {
      const match = cleanedText.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
      if (match && match[1]) {
        cleanedText = match[1].trim();
      } else {
        // Fallback: strip leading ```json and trailing ```
        cleanedText = cleanedText
          .replace(/^```json\s*/i, "")
          .replace(/^```\s*/, "")
          .replace(/\s*```$/, "")
          .trim();
      }
    }

    try {
      const parsed = JSON.parse(cleanedText);
      return parsed as GeminiDppPayload;
    } catch (err) {
      console.error("[ResponseParser] JSON Parse Failed! Raw text preview:", rawText.slice(0, 300));
      throw new Error(`Failed to parse response text into valid JSON: ${(err as Error).message}`);
    }
  }
}
