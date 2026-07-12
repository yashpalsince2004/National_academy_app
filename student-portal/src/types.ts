export interface DPPQuestion {
  id: string;
  question: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
  difficulty?: 'Easy' | 'Medium' | 'Hard';
  estimatedTimeSeconds?: number;
  marks?: number;
  learningOutcome?: string;
}

export type SubjectType = 'Physics' | 'Chemistry' | 'Mathematics' | 'Biology';

export interface DPP {
  id: string;
  topicId: string;
  name: string;
  subject: SubjectType;
  totalQuestions: number;
  questions: DPPQuestion[];
  batch: string;
  dueDate: string;
  estimatedTime: number; // in minutes
}

export interface DPPAttempt {
  dppId: string;
  status: 'TODO' | 'IN_PROGRESS' | 'COMPLETED';
  savedAnswers: Record<string, string>; // Maps questionId -> selectedOption (A/B/C/D)
  score?: number;
  timeSpent?: number; // in seconds
  completedAt?: string;
  correctCount?: number;
  wrongCount?: number;
  skippedCount?: number;
  timeSpentPerQuestion?: Record<string, number>; // questionId -> time in seconds
  confidenceRating?: number; // 1 to 5 scale
}

export interface StudentProfile {
  name: string;
  rollNo: string;
  batch: string;
  streak: number;
  xp: number;
  unlockedBadges: string[];
}
