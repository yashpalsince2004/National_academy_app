// Validator for generated DPP JSON structure with subject and option uniqueness validation
import { GeminiDppPayload, GenerateDppRequest } from "./types.ts";

export class PayloadValidator {
  /**
   * Validates the generated GeminiDppPayload against schemas and request parameters.
   * Returns an array of error messages. If empty, the payload is valid.
   */
  public static validate(payload: GeminiDppPayload, req: GenerateDppRequest): string[] {
    const errors: string[] = [];

    // 1. Root Level Validation
    if (!payload.title || typeof payload.title !== "string" || payload.title.trim().length === 0) {
      errors.push("Missing or invalid DPP title");
    }
    if (!payload.exam || typeof payload.exam !== "string" || payload.exam.trim().length === 0) {
      errors.push("Missing or invalid exam category");
    } else if (payload.exam.toLowerCase().trim() !== req.exam.toLowerCase().trim()) {
      errors.push(`Exam mismatch: requested "${req.exam}" but received "${payload.exam}"`);
    }

    if (!payload.subject || typeof payload.subject !== "string" || payload.subject.trim().length === 0) {
      errors.push("Missing or invalid subject");
    } else {
      const requestedSub = req.subject.toLowerCase().trim();
      const generatedSub = payload.subject.toLowerCase().trim();
      // Subject should align (either contain it, or equal it)
      if (!generatedSub.includes(requestedSub) && !requestedSub.includes(generatedSub)) {
        errors.push(`Subject mismatch: requested "${req.subject}" but received "${payload.subject}"`);
      }
    }

    if (!payload.chapter || typeof payload.chapter !== "string" || payload.chapter.trim().length === 0) {
      errors.push("Missing or invalid chapter");
    } else {
      const requestedChap = req.chapter.toLowerCase().trim();
      const generatedChap = payload.chapter.toLowerCase().trim();
      // Chapter should align closely
      if (!generatedChap.includes(requestedChap) && !requestedChap.includes(generatedChap) && 
          this.calculateSimilarity(requestedChap, generatedChap) < 0.4) {
        errors.push(`Chapter mismatch: requested "${req.chapter}" but received "${payload.chapter}"`);
      }
    }

    if (!payload.questions || !Array.isArray(payload.questions)) {
      errors.push("Missing or invalid questions list array");
      return errors; // Stop validation early if questions array is missing
    }

    // 2. Question Count Match Validation
    if (payload.questions.length !== req.questionCount) {
      errors.push(`Question count mismatch: expected ${req.questionCount}, but received ${payload.questions.length}`);
    }

    const questionTexts = new Set<string>();

    // 3. Question-Level Validation
    payload.questions.forEach((q, index) => {
      const qIdx = index + 1;

      if (!q.question || typeof q.question !== "string" || q.question.trim().length === 0) {
        errors.push(`Question #${qIdx} text is empty or missing`);
      } else {
        // Check for duplicates
        const normalizedText = q.question.trim().toLowerCase().replace(/\s+/g, "");
        if (questionTexts.has(normalizedText)) {
          errors.push(`Duplicate question detected at question #${qIdx}`);
        }
        questionTexts.add(normalizedText);
      }

      if (!q.options || !Array.isArray(q.options) || q.options.length !== 4) {
        errors.push(`Question #${qIdx} does not have exactly 4 options`);
      } else {
        const optionValues = new Set<string>();
        q.options.forEach((opt, optIdx) => {
          if (!opt || typeof opt !== "string" || opt.trim().length === 0) {
            errors.push(`Question #${qIdx} has an empty option at choice #${optIdx + 1}`);
          } else {
            const normalizedOpt = opt.trim().toLowerCase();
            if (optionValues.has(normalizedOpt)) {
              errors.push(`Question #${qIdx} has duplicate options (value "${opt}" appears multiple times)`);
            }
            optionValues.add(normalizedOpt);
          }
        });
      }

      if (!q.answer || typeof q.answer !== "string" || q.answer.trim().length === 0) {
        errors.push(`Question #${qIdx} is missing correct answer mapping`);
      } else {
        const cleanAnswer = q.answer.trim().toUpperCase();
        // Support either single letter A/B/C/D or matching full text options
        const isValidLetter = ["A", "B", "C", "D"].includes(cleanAnswer);
        const matchesOption = q.options && q.options.some(opt => opt.trim() === q.answer.trim());
        if (!isValidLetter && !matchesOption) {
          errors.push(`Question #${qIdx} correct answer "${q.answer}" must be A, B, C, D or match an option value exactly`);
        }
      }

      if (!q.explanation || typeof q.explanation !== "object") {
        errors.push(`Question #${qIdx} is missing a structured explanation object`);
      } else {
        const exp = q.explanation;
        if (!exp.correct_answer || typeof exp.correct_answer !== "string" || exp.correct_answer.trim().length === 0) {
          errors.push(`Question #${qIdx} explanation correct_answer is missing or empty`);
        }
        if (!exp.step_by_step || typeof exp.step_by_step !== "string" || exp.step_by_step.trim().length === 0) {
          errors.push(`Question #${qIdx} explanation step_by_step is missing or empty`);
        }
        if (!exp.ncert_reference || typeof exp.ncert_reference !== "string" || exp.ncert_reference.trim().length === 0) {
          errors.push(`Question #${qIdx} explanation ncert_reference is missing or empty`);
        }
        if (!exp.why_others_incorrect || typeof exp.why_others_incorrect !== "object") {
          errors.push(`Question #${qIdx} explanation why_others_incorrect is missing`);
        } else {
          const w = exp.why_others_incorrect;
          ["A", "B", "C", "D"].forEach((letter) => {
            if (!w[letter] || typeof w[letter] !== "string" || w[letter].trim().length === 0) {
              errors.push(`Question #${qIdx} explanation why_others_incorrect for option ${letter} is missing or empty`);
            }
          });
        }
      }

      if (!q.concept || typeof q.concept !== "string" || q.concept.trim().length === 0) {
        errors.push(`Question #${qIdx} is missing concept name`);
      }
      if (typeof q.difficulty_score !== "number" || q.difficulty_score < 1 || q.difficulty_score > 10) {
        errors.push(`Question #${qIdx} difficulty_score must be a number between 1 and 10`);
      }
      if (!q.source_type || !["NCERT", "PYQ", "Conceptual"].includes(q.source_type.trim())) {
        errors.push(`Question #${qIdx} source_type must be NCERT, PYQ, or Conceptual`);
      }
    });

    return errors;
  }

  /**
   * Helper to estimate text similarity (simple Jaccard similarity)
   */
  private static calculateSimilarity(s1: string, s2: string): number {
    const set1 = new Set(s1.split(" "));
    const set2 = new Set(s2.split(" "));
    const intersection = new Set([...set1].filter(x => set2.has(x)));
    const union = new Set([...set1, ...set2]);
    return intersection.size / union.size;
  }
}
