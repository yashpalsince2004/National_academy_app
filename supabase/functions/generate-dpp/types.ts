// Types for AI Smart DPP Edge Function

/**
 * Incoming request parameters from Flutter/client
 */
export interface GenerateDppRequest {
  exam: string;                    // JEE, NEET, NDA, etc.
  subject: string;                 // Physics, Chemistry, etc.
  chapter: string;                 // e.g. Kinematics
  topics?: string[];               // list of specific topics (optional)
  difficulty: string;              // Basic, Medium, High
  questionCount: number;           // e.g. 5
  duration: number;                // time limit in minutes, e.g. 30
  marks?: number;                  // total marks, optional (defaults to questionCount * 4)
  language?: string;               // e.g. English (optional)
  teacherInstructions?: string[];  // e.g. ["Focus on PYQs", "Assertion & Reason", etc.]
}

/**
 * Structured explanation format to prevent thin/vague reasoning
 */
export interface StructuredExplanation {
  correct_answer: string;
  step_by_step: string;
  why_others_incorrect: {
    A: string;
    B: string;
    C: string;
    D: string;
  };
  shortcut?: string;
  common_mistake?: string;
  ncert_reference?: string;
}

/**
 * Question structure returned by Gemini
 */
export interface GeminiQuestion {
  id: number;
  type: string;                    // MCQ, Single Correct, etc.
  question: string;                // Support LaTeX wrapped in $ or $$
  options: string[];               // Exactly 4 options
  answer: string;                  // The correct option letter (A, B, C, or D)
  explanation: StructuredExplanation; // Detailed structured solution
  concept: string;                 // The core scientific or mathematical concept tested
  topic: string;                   // Specific sub-topic name
  difficulty: string;              // Easy, Medium, Hard
  estimated_time: number;          // estimated completion time in seconds
  blooms_level: string;            // Remembering, Understanding, Applying, Analyzing, Evaluating, Creating
  difficulty_score: number;        // AI rating of complexity from 1 to 10
  source_type: string;             // 'NCERT', 'PYQ', or 'Conceptual'
}

/**
 * JSON Schema required from Gemini response
 */
export interface GeminiDppPayload {
  title: string;
  description: string;
  exam: string;
  subject: string;
  chapter: string;
  difficulty: string;
  duration: number;
  marks: number;
  questions: GeminiQuestion[];
}

/**
 * Database representation of the inserted DPP row
 */
export interface DatabaseDppRow {
  id: string;
  title: string;
  exam_type: string;
  class_level: string;
  subject_id: string;
  chapter_name: string;
  chapter_id?: string;
  topics: string[];
  difficulty: string;
  config_questions: number;
  config_time_minutes: number;
  config_marks_per_question: number;
  config_negative_marking: number;
  config_total_marks: number;
  config_question_types: string[];
  ai_generation_option: string;
  additional_instructions?: string;
  prompt?: string;
  ai_response?: string;
  created_by: string;
  status: string;
  created_at?: string;
  updated_at?: string;
}

/**
 * Database representation of the inserted DPP Question row
 */
export interface DatabaseQuestionRow {
  id?: string;
  dpp_id: string;
  question_text: string;
  question_type: string;
  options: string[];               // JSONB column
  correct_answer: string;
  explanation: StructuredExplanation; // JSONB column
  difficulty: string;
  estimated_time_seconds: number;
  marks: number;
  learning_outcome: string;        // Combination of Bloom's and concept
  concept: string;
  blooms_level: string;
  difficulty_score: number;
  source_type: string;
}

/**
 * Return response from Edge Function to client
 */
export interface GenerateDppResponse {
  success: boolean;
  dppId: string;
  title: string;
  questionCount: number;
  estimatedDuration: number;
}
