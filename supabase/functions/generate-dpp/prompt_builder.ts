// Composable Prompt Builder with Subject-Specific Isolation Templates
import { GenerateDppRequest } from "./types.ts";
import { neetBiologyTemplate } from "./prompt_templates/neet/biology.ts";
import { neetPhysicsTemplate } from "./prompt_templates/neet/physics.ts";
import { neetChemistryTemplate } from "./prompt_templates/neet/chemistry.ts";
import { jeePhysicsTemplate } from "./prompt_templates/jee/physics.ts";
import { jeeChemistryTemplate } from "./prompt_templates/jee/chemistry.ts";
import { jeeMathsTemplate } from "./prompt_templates/jee/maths.ts";
import { ndaMathsTemplate } from "./prompt_templates/nda/maths.ts";
import { ndaGatTemplate } from "./prompt_templates/nda/gat.ts";
import { getDifficultyWeightage } from "./prompt_templates/difficulty.ts";

export class PromptBuilder {
  /**
   * Resolves the target subject-specific template config
   */
  private static getTemplate(exam: string, subject: string) {
    const ex = exam.toUpperCase().trim();
    const sub = subject.toLowerCase().trim();

    if (ex === "NEET") {
      if (sub.includes("biology") || sub.includes("zoology") || sub.includes("botany")) {
        return neetBiologyTemplate;
      } else if (sub.includes("physics")) {
        return neetPhysicsTemplate;
      } else if (sub.includes("chemistry")) {
        return neetChemistryTemplate;
      }
    } else if (ex === "JEE") {
      if (sub.includes("physics")) {
        return jeePhysicsTemplate;
      } else if (sub.includes("chemistry")) {
        return jeeChemistryTemplate;
      } else if (sub.includes("math") || sub.includes("calculus") || sub.includes("mathematics")) {
        return jeeMathsTemplate;
      }
    } else if (ex === "NDA") {
      if (sub.includes("math") || sub.includes("calculus") || sub.includes("mathematics")) {
        return ndaMathsTemplate;
      } else {
        return ndaGatTemplate;
      }
    }

    // Default Fallback
    return {
      role: `You are a Senior Faculty and Subject Matter Expert in ${subject} at National Academy.`,
      pedagogy: `- Focus on building academic concept clarity and examination readiness.`,
      allowed: [`Concepts within the syllabus of ${subject}`],
      forbidden: ["Unrelated subjects, history, or General Knowledge leaks"],
      latexExample: "Use LaTeX for formulas ($x^2$) and formatting standard symbols.",
      difficultyGuideline: {
        basic: "Focus on standard terminology and direct conceptual applications.",
        medium: "Focus on multi-step reasoning and analytical problem solving.",
        high: "Focus on deep application of theories, synthesis, and advanced evaluation."
      }
    };
  }

  /**
   * Builds the strict system instruction configuring Gemini persona
   */
  public static buildSystemInstruction(): string {
    return `You are a Senior Coaching Faculty and Subject Matter Expert at National Academy. 
Your objective is to generate high-quality, academically rigorous, and accurate Daily Practice Problems (DPPs).

CRITICAL CONSTRAINTS:
1. You must respond ONLY with a raw, valid JSON object following the exact schema provided.
2. Every mathematical formula, symbol, equation, and variable MUST be formatted strictly in LaTeX using single dollar signs ($) for inline formulas and double dollar signs ($$) for block equations.
3. Ensure the questions, options, and explanations are highly professional, rigorous, and relevant to the target exam.`;
  }

  /**
   * Dynamically constructs the user generation prompt based on request parameters and database grounded syllabus topics.
   */
  public static buildUserPrompt(req: GenerateDppRequest, approvedTopics: string[]): string {
    const topicsText = req.topics && req.topics.length > 0 
      ? `focused strictly on these topics: ${req.topics.join(", ")}` 
      : `covering these approved syllabus topics: ${approvedTopics.join(", ")}`;

    const marksValue = req.marks || (req.questionCount * 4);
    const lang = req.language || "English";

    // Load subject-specific template config
    const template = this.getTemplate(req.exam, req.subject);
    
    const difficultyDistribution = getDifficultyWeightage(req.difficulty);
    const diffLevel = req.difficulty.toLowerCase();
    const diffGuideline = (template.difficultyGuideline as any)[diffLevel] || "";

    const allowedList = template.allowed.map(item => `✅ Allowed: ${item}`).join("\n");
    const forbiddenList = template.forbidden.map(item => `❌ STRICTLY FORBIDDEN: ${item}`).join("\n");

    const teacherDirectives = req.teacherInstructions && req.teacherInstructions.length > 0
      ? req.teacherInstructions.map(instr => `- 📌 SPECIAL TEACHER DIRECTIVE: ${instr}`).join("\n")
      : "- No special instructions from the teacher.";

    // Advanced exam pattern context
    const examPatternInfo = req.exam.toUpperCase() === "JEE"
      ? "JEE Main & Advanced: Heavy mathematical rigour, multi-concept applications, high analytical complexity."
      : req.exam.toUpperCase() === "NEET"
      ? "NEET: Strict NCERT alignment, conceptual speed, accuracy, and clear factual application."
      : "NDA: Standard arithmetic, algebra, and general ability matching UPSC standards.";

    return `ROLE
${template.role}

------------------------------------
EXAM PATTERN CONTEXT
------------------------------------
${examPatternInfo}

------------------------------------
TARGET
------------------------------------
Exam: ${req.exam}
Subject: ${req.subject}
Chapter: ${req.chapter}
Syllabus Topics to Cover: ${topicsText}
Difficulty Level: ${req.difficulty}
Total Questions Requested: ${req.questionCount}
Time Limit: ${req.duration} minutes
Total Max Marks: ${marksValue}
Target Language: ${lang}

------------------------------------
PEDAGOGY & CURRICULUM GUIDELINES
------------------------------------
${template.pedagogy}
- Align questions strictly with NCERT concepts.
- Reflect recent 5-year PYQ (Previous Year Questions) trends for ${req.exam}.
- Balanced Bloom's Taxonomy distribution (Remembering, Understanding, Applying, Analyzing, Evaluating).
- Distribute concepts evenly so that NO concept is repeated across different questions.

------------------------------------
TEACHER INSTRUCTIONS / DIRECTIVES
------------------------------------
${teacherDirectives}

------------------------------------
DIFFICULTY WEIGHTS
------------------------------------
${difficultyDistribution}
- Guidelines: ${diffGuideline}

------------------------------------
CONTENT CONSTRAINTS
------------------------------------
${allowedList}
${forbiddenList}
- Every question must strictly belong to the subject "${req.subject}" and chapter "${req.chapter}".
- All 4 options in a question MUST be distinct. Avoid repeating option values or equations.
- Do NOT mention the exam name, subject name, chapter name, or difficulty level inside the question text or options. Just write the direct examination question.

------------------------------------
OUTPUT FORMAT SCHEMA
------------------------------------
Generate a single JSON object matching this model:
{
  "title": "A short professional title for this DPP set",
  "description": "A brief overview description detailing the syllabus, difficulty weightage, and learning goals",
  "exam": "${req.exam}",
  "subject": "${req.subject}",
  "chapter": "${req.chapter}",
  "difficulty": "${req.difficulty}",
  "duration": ${req.duration},
  "marks": ${marksValue},
  "questions": [
    {
      "id": 1,
      "type": "MCQ",
      "question": "Clear question text. ${template.latexExample}",
      "options": [
        "Option A text",
        "Option B text",
        "Option C text",
        "Option D text"
      ],
      "answer": "A",
      "explanation": {
        "correct_answer": "Option letter followed by its text value, e.g., 'A. 5 m/s^2'",
        "step_by_step": "Detailed step-by-step mathematical derivation or physical/biological reasoning in LaTeX.",
        "why_others_incorrect": {
          "A": "Brief scientific reason why Option A is incorrect (or why it is correct if it is the answer)",
          "B": "Brief scientific reason why Option B is incorrect",
          "C": "Brief scientific reason why Option C is incorrect",
          "D": "Brief scientific reason why Option D is incorrect"
        },
        "shortcut": "Alternative shortcut method, trick, or formula to solve quickly (if applicable, else empty)",
        "common_mistake": "Common trap, misconception, or mistake students make while solving this (if applicable, else empty)",
        "ncert_reference": "Exact chapter, heading, and page range in NCERT textbook, e.g., 'Class 11 Physics Part 1, Chapter 3, Section 3.4, Page 45'"
      },
      "concept": "The core conceptual equation, formula, or law tested, e.g., 'Newton's Second Law of Motion'",
      "topic": "The specific sub-topic this question tests",
      "difficulty": "Easy | Medium | Hard",
      "estimated_time": 120,
      "blooms_level": "Remembering | Understanding | Applying | Analyzing | Evaluating | Creating",
      "difficulty_score": 5,
      "source_type": "NCERT | PYQ | Conceptual"
    }
  ]
}

Double-check that the "questions" array contains exactly ${req.questionCount} unique items. Ensure the "answer" field holds one of the option letters ("A", "B", "C", or "D") and options contain precisely 4 items.`;
  }

  /**
   * Builds the prompt for the AI Critic/Reviewer to audit the generated questions
   */
  public static buildReviewerPrompt(
    exam: string,
    subject: string,
    chapter: string,
    rawJsonText: string
  ): string {
    const template = this.getTemplate(exam, subject);
    const forbiddenList = template.forbidden.map(item => `❌ STRICTLY FORBIDDEN: ${item}`).join("\n");

    return `SYSTEM
You are a Senior Curriculum Auditor and Quality Assurance Expert at National Academy.
Your task is to audit the following generated Daily Practice Problems (DPP) JSON payload for errors, subject contamination, answer accuracy, grammar, difficulty alignment, and LaTeX correctness.

---------------
TARGET CONFIGURATION
---------------
EXAM: ${exam}
SUBJECT: ${subject}
CHAPTER: ${chapter}

---------------
AUDIT CHECKS
---------------
1. SUBJECT CORRECTNESS: Ensure EVERY question is strictly from the subject "${subject}" and chapter "${chapter}".
2. ZERO CROSS-CONTAMINATION:
${forbiddenList}
- If the subject is Biology, there must be NO calculus, limits, differentiation, algebra, or math formulas.
3. UNIQUE OPTIONS & NO DUPLICATE QUESTIONS: Verify that for every question, the 4 options are completely distinct, and there are no repeated concepts or duplicate question styles.
4. METADATA & SCHEMA ALIGNMENT: Ensure that each question contains all the requested metadata: 'concept', 'difficulty_score', 'source_type', and the fully structured 'explanation' JSON sub-object.
5. ANSWER CORRECTNESS: Re-solve each question. Ensure the correct option letter (A, B, C, or D) matches the derivation and the explanation text perfectly.
6. LATEX FORMATTING: Check that all formulas use $ for inline and $$ for block equations.
7. GRAMMAR & READABILITY: Correct any grammatical errors, awkward sentences, or confusing options.

---------------
INPUT DPP JSON
---------------
${rawJsonText}

---------------
OUTPUT REQUIREMENT
---------------
Correct any violations found by rewriting the problematic question or explanation.
Return ONLY the corrected, valid JSON object matching the input schema. Do not add any conversational text, markdown wrapping, or explanations.`;
  }
}
