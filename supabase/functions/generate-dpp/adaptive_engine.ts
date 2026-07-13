// Adaptive Assessment Engine architecture stub for Deno Edge Runtime
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface StudentPerformanceSummary {
  studentId: string;
  totalAttempts: number;
  averageScore: number;
  weakConcepts: string[];
  recommendedDifficulty: "Basic" | "Medium" | "High";
}

export class AdaptiveEngine {
  /**
   * Evaluates student attempts telemetry to recommend optimal difficulty and highlight weak conceptual areas.
   */
  public static async analyzePerformance(
    supabase: SupabaseClient,
    studentId: string,
    subjectId: string
  ): Promise<StudentPerformanceSummary> {
    console.log(`[AdaptiveEngine] Querying historical metrics for student: ${studentId}, subject: ${subjectId}...`);

    try {
      // 1. Fetch recent attempts for the student in this subject
      const { data: attempts, error } = await supabase
        .from("dpp_results")
        .select(`
          score,
          total_questions,
          correct_answers,
          wrong_answers,
          attempt_id,
          dpp_attempts (
            assignment_id,
            dpp_assignments (
              dpp_id,
              dpps (
                subject_id,
                difficulty
              )
            )
          )
        `)
        .eq("student_id", studentId)
        .order("created_at", { ascending: false })
        .limit(10);

      if (error || !attempts || attempts.length === 0) {
        console.log(`[AdaptiveEngine] No history found. Recommending default settings.`);
        return {
          studentId,
          totalAttempts: 0,
          averageScore: 100,
          weakConcepts: [],
          recommendedDifficulty: "Basic"
        };
      }

      // Filter attempts belonging to target subject
      const subjectAttempts = attempts.filter((att: any) => 
        att.dpp_attempts?.dpp_assignments?.dpps?.subject_id === subjectId
      );

      if (subjectAttempts.length === 0) {
        return {
          studentId,
          totalAttempts: 0,
          averageScore: 100,
          weakConcepts: [],
          recommendedDifficulty: "Basic"
        };
      }

      let totalScorePercentage = 0.0;
      let totalWrong = 0;

      subjectAttempts.forEach((att: any) => {
        const score = Number(att.score);
        const maxScore = att.total_questions * 4; // Default marks configuration
        const pct = maxScore > 0 ? (score / maxScore) * 100 : 0;
        totalScorePercentage += pct;
        totalWrong += att.wrong_answers;
      });

      const avgScore = totalScorePercentage / subjectAttempts.length;
      console.log(`[AdaptiveEngine] Student average score: ${avgScore.toFixed(1)}%`);

      // Determine adaptive difficulty recommendation
      let recommendedDifficulty: "Basic" | "Medium" | "High" = "Basic";
      if (avgScore >= 80) {
        recommendedDifficulty = "High";
      } else if (avgScore >= 50) {
        recommendedDifficulty = "Medium";
      }

      // 2. Identify weak conceptual tags from wrong answers (STUB logic, queries analytics logs)
      const weakConcepts: string[] = [];
      if (totalWrong > 0) {
        // Here we could query questions corresponding to attempts with incorrect answer logs
        // and aggregate the question.concept values.
        weakConcepts.push("Advanced Rotational Mechanics", "Calculus Integrals");
      }

      return {
        studentId,
        totalAttempts: subjectAttempts.length,
        averageScore: avgScore,
        weakConcepts,
        recommendedDifficulty
      };

    } catch (e) {
      console.error(`[AdaptiveEngine] Error during student profile analysis: ${e}`);
      return {
        studentId,
        totalAttempts: 0,
        averageScore: 100,
        weakConcepts: [],
        recommendedDifficulty: "Basic"
      };
    }
  }

  /**
   * Adapts the parameters of a DPP generation request dynamically.
   */
  public static async adaptDppRequestParameters(
    supabase: SupabaseClient,
    studentId: string,
    subjectId: string,
    originalDifficulty: string
  ): Promise<{ adaptedDifficulty: string; focusConcepts: string[] }> {
    const analysis = await this.analyzePerformance(supabase, studentId, subjectId);
    
    // If the original difficulty is unset, let the analytics engine decide
    const finalDifficulty = originalDifficulty === "Adaptive" 
      ? analysis.recommendedDifficulty 
      : originalDifficulty;

    console.log(`[AdaptiveEngine] Adaptive mapping complete. Target Difficulty: ${finalDifficulty}`);
    return {
      adaptedDifficulty: finalDifficulty,
      focusConcepts: analysis.weakConcepts
    };
  }
}
