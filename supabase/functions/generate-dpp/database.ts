// Database transaction layer for generate-dpp Edge Function
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GenerateDppRequest, GeminiDppPayload, DatabaseDppRow, DatabaseQuestionRow } from "./types.ts";

export class DatabaseLayer {
  /**
   * Transactionally saves the generated DPP and associated questions to Supabase.
   * Resolves the subject_id and chapter_id dynamically.
   */
  public static async saveDpp(
    supabase: SupabaseClient,
    req: GenerateDppRequest,
    payload: GeminiDppPayload,
    userId: string,
    rawPrompt?: string,
    rawAiResponse?: string
  ): Promise<string> {
    
    // 1. Resolve Subject UUID from name (ilike match)
    console.log(`[Database] Resolving subject_id for subject "${req.subject}"...`);
    const { data: subjectRow, error: subjectErr } = await supabase
      .from("subjects")
      .select("id")
      .ilike("name", `%${req.subject}%`)
      .limit(1)
      .maybeSingle();

    if (subjectErr) {
      throw new Error(`Error querying subjects table: ${subjectErr.message}`);
    }

    let subjectId = subjectRow?.id;

    if (!subjectId) {
      console.warn(`[Database] Subject "${req.subject}" not found. Trying fallback first available subject.`);
      const { data: fallbackList } = await supabase
        .from("subjects")
        .select("id")
        .limit(1);
      
      if (fallbackList && fallbackList.length > 0) {
        subjectId = fallbackList[0].id;
      } else {
        throw new Error(`Subject "${req.subject}" does not exist in the database and no fallbacks are available.`);
      }
    }

    // 2. Resolve Chapter UUID (optional) from subject and name
    console.log(`[Database] Resolving chapter_id for chapter "${req.chapter}"...`);
    let chapterId: string | null = null;
    const { data: chapterRow } = await supabase
      .from("chapters")
      .select("id")
      .eq("subject_id", subjectId)
      .ilike("name", `%${req.chapter}%`)
      .limit(1)
      .maybeSingle();
    
    if (chapterRow) {
      chapterId = chapterRow.id;
    }

    // 3. Create the Database DPP Row payload
    const dppRow: DatabaseDppRow = {
      id: undefined as unknown as string, // Let DB generate UUID
      title: payload.title,
      exam_type: req.exam,
      class_level: "Class 12", // Default class level
      subject_id: subjectId,
      chapter_name: req.chapter,
      chapter_id: chapterId || undefined,
      topics: req.topics || [],
      difficulty: req.difficulty,
      config_questions: req.questionCount,
      config_time_minutes: req.duration,
      config_marks_per_question: req.marks ? Math.max(1, Math.floor(req.marks / req.questionCount)) : 4,
      config_negative_marking: 1.0, // Default to 1.0
      config_total_marks: req.marks || (req.questionCount * 4),
      config_question_types: ["Single Correct"], // Default
      ai_generation_option: "Conceptual",
      additional_instructions: undefined,
      prompt: rawPrompt,
      ai_response: rawAiResponse,
      created_by: userId,
      status: "draft", // Initially saved as draft
    };

    console.log("[Database] Inserting DPP configuration row...");
    const { data: insertedDpp, error: insertDppErr } = await supabase
      .from("dpps")
      .insert(dppRow)
      .select()
      .single();

    if (insertDppErr || !insertedDpp) {
      throw new Error(`Failed to insert DPP: ${insertDppErr?.message}`);
    }

    const dppId = insertedDpp.id;
    console.log(`[Database] DPP inserted successfully with ID: ${dppId}. Preparing questions insertion...`);

    // 4. Map questions to database schema rows
    const marksPerQuestion = dppRow.config_marks_per_question;
    const questionRows: DatabaseQuestionRow[] = payload.questions.map((q) => {
      return {
        dpp_id: dppId,
        question_text: q.question,
        question_type: q.type || "Single Correct",
        options: q.options, // jsonb array
        correct_answer: q.answer,
        explanation: q.explanation,
        difficulty: q.difficulty || req.difficulty,
        estimated_time_seconds: q.estimated_time || 120,
        marks: marksPerQuestion,
        learning_outcome: q.blooms_level ? `${q.topic} (Bloom's: ${q.blooms_level})` : q.topic,
      };
    });

    // 5. Batch insert questions
    console.log(`[Database] Inserting ${questionRows.length} questions for DPP...`);
    const { error: insertQuestionsErr } = await supabase
      .from("dpp_questions")
      .insert(questionRows);

    if (insertQuestionsErr) {
      console.error(`[Database] Questions insertion failed! Rolling back DPP ID: ${dppId}`);
      
      // Rollback simulation: delete the newly created DPP row
      const { error: deleteErr } = await supabase
        .from("dpps")
        .delete()
        .eq("id", dppId);
      
      if (deleteErr) {
        console.error(`[Database] ROLLBACK FAILED: Could not clean up orphaned DPP row ${dppId}. Error: ${deleteErr.message}`);
      } else {
        console.log(`[Database] Rollback successful. DPP ID ${dppId} removed.`);
      }

      throw new Error(`Failed to insert DPP questions: ${insertQuestionsErr.message}`);
    }

    console.log(`[Database] Transaction complete. Saved DPP ID ${dppId} and all questions.`);
    return dppId;
  }

  /**
   * Logs telemetry and cost tracking information for the AI generation request.
   */
  public static async logAiGeneration(
    supabase: SupabaseClient,
    params: {
      userId: string;
      exam: string;
      subject: string;
      chapter: string;
      promptTokens: number;
      completionTokens: number;
      generationTimeMs: number;
      status: "success" | "failed";
      error?: string;
    }
  ): Promise<void> {
    const totalTokens = params.promptTokens + params.completionTokens;
    // Calculate cost based on Gemini 2.5 Flash pricing
    const promptCost = (params.promptTokens * 0.075) / 1000000;
    const completionCost = (params.completionTokens * 0.30) / 1000000;
    const estimatedCost = Number((promptCost + completionCost).toFixed(8));

    try {
      console.log(`[Database] Logging AI generation statistics... Cost: $${estimatedCost}`);
      const { error } = await supabase.from("ai_generation_logs").insert({
        teacher_id: params.userId,
        exam: params.exam,
        subject: params.subject,
        chapter: params.chapter,
        model: "gemini-2.5-flash",
        prompt_tokens: params.promptTokens,
        completion_tokens: params.completionTokens,
        total_tokens: totalTokens,
        estimated_cost: estimatedCost,
        generation_time_ms: params.generationTimeMs,
        status: params.status,
        error: params.error,
      });

      if (error) {
        console.error(`[Database] Failed to write AI generation logs: ${error.message}`);
      }
    } catch (e) {
      console.error(`[Database] Exception logging AI telemetry: ${e}`);
    }
  }
}
