import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_providers.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../main.dart';
import '../../data/models/dpp_model.dart';
import '../../data/models/dpp_assignment_model.dart';
import '../../data/repositories/dpp_repository_impl.dart';
import '../../domain/repositories/dpp_repository.dart';
import 'dpp_history_controller.dart';

class DppGeneratorState {
  final bool isLoading;
  final bool isGenerating;
  final String? error;
  final DppModel? generatedDpp;
  final List<Map<String, dynamic>> subjects;
  final List<String> chapters;
  final List<Map<String, dynamic>> batches;
  final List<Map<String, dynamic>> students;

  DppGeneratorState({
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.generatedDpp,
    this.subjects = const [],
    this.chapters = const [],
    this.batches = const [],
    this.students = const [],
  });

  DppGeneratorState copyWith({
    bool? isLoading,
    bool? isGenerating,
    String? error,
    DppModel? generatedDpp,
    List<Map<String, dynamic>>? subjects,
    List<String>? chapters,
    List<Map<String, dynamic>>? batches,
    List<Map<String, dynamic>>? students,
  }) {
    return DppGeneratorState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error ?? this.error,
      generatedDpp: generatedDpp ?? this.generatedDpp,
      subjects: subjects ?? this.subjects,
      chapters: chapters ?? this.chapters,
      batches: batches ?? this.batches,
      students: students ?? this.students,
    );
  }
}

final dppGeneratorControllerProvider =
    StateNotifierProvider<DppGeneratorController, DppGeneratorState>((ref) {
  final repository = ref.watch(dppRepositoryProvider);
  return DppGeneratorController(repository: repository, ref: ref);
});

class DppGeneratorController extends StateNotifier<DppGeneratorState> {
  final DppRepository repository;
  final Ref ref;
  final _aiService = AiService();

  DppGeneratorController({
    required this.repository,
    required this.ref,
  }) : super(DppGeneratorState()) {
    loadDropdownData();
  }

  Future<void> loadDropdownData() async {
    try {
      final batches = await repository.fetchAllBatches();
      final students = await repository.fetchAllStudents();
      state = state.copyWith(
        batches: batches,
        students: students,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> onExamTypeChanged(String examType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subjects = await repository.fetchSubjectsForExam(examType);
      state = state.copyWith(
        isLoading: false,
        subjects: subjects,
        chapters: [], // Reset chapters
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> onSubjectChanged(String subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chapters = await repository.fetchChaptersForSubject(subjectId);
      state = state.copyWith(
        isLoading: false,
        chapters: chapters,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateDpp({
    required String title,
    required String examType,
    required String classLevel,
    required String subjectId,
    required String subjectName,
    required String chapterName,
    required List<String> topics,
    required String difficulty,
    required int questionCount,
    required int timeMinutes,
    required int marksPerQuestion,
    required double negativeMarking,
    required List<String> questionTypes,
    required String aiOption,
    String? additionalInstructions,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isGenerating: true, error: null, generatedDpp: null);

    final isSupabaseReady = ref.read(supabaseInitializedProvider);

    if (isSupabaseReady) {
      try {
        debugPrint('[DppGenerator] Initializing generation via Supabase Edge Function...');
        final client = ref.read(supabaseClientProvider);

        final response = await client.functions.invoke(
          'generate-dpp',
          body: {
            'exam': examType,
            'subject': subjectName,
            'chapter': chapterName,
            'topics': topics,
            'difficulty': difficulty,
            'questionCount': questionCount,
            'duration': timeMinutes,
            'marks': questionCount * marksPerQuestion,
            'language': 'English',
            'forceRefresh': forceRefresh,
          },
        );

        if (response.status != 200) {
          final errMsg = response.data is Map ? response.data['error'] : 'Unknown HTTP ${response.status} error';
          throw Exception(errMsg);
        }

        final data = response.data as Map<String, dynamic>;
        final String generatedDppId = data['dppId'] as String;
        debugPrint('[DppGenerator] Edge function success. Retrieved DPP ID: $generatedDppId');

        // Fetch fully populated configuration and question entities from the DB
        final dppRow = await client
            .from('dpps')
            .select('*, subjects(name), profiles(full_name)')
            .eq('id', generatedDppId)
            .single();

        final questionsRows = await client
            .from('dpp_questions')
            .select()
            .eq('dpp_id', generatedDppId)
            .order('created_at', ascending: true);

        final dpp = DppModel.fromJson({
          ...dppRow,
          'dpp_questions': questionsRows,
        });

        state = state.copyWith(
          isGenerating: false,
          generatedDpp: dpp,
        );

        // Notify the history log list to fetch latest creations
        ref.read(dppHistoryControllerProvider.notifier).loadHistory();
        return;
      } catch (e) {
        debugPrint('[DppGenerator] Remote Edge Function failed ($e). Falling back to mock generator...');
      }
    }

    // Fallback: Local Client-side mock AI Generator
    try {
      final questions = await _aiService.generateQuestions(
        examType: examType,
        classLevel: classLevel,
        subjectName: subjectName,
        chapterName: chapterName,
        topics: topics,
        difficulty: difficulty,
        questionCount: questionCount,
        questionTypes: questionTypes,
        aiOption: aiOption,
        additionalInstructions: additionalInstructions,
        marksPerQuestion: marksPerQuestion,
      );

      final totalMarks = questionCount * marksPerQuestion;

      final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

      final dpp = DppModel(
        id: 'dpp-mock-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        examType: examType,
        classLevel: classLevel,
        subjectId: subjectId,
        subjectName: subjectName,
        chapterName: chapterName,
        topics: topics,
        difficulty: difficulty,
        configQuestions: questionCount,
        configTimeMinutes: timeMinutes,
        configMarksPerQuestion: marksPerQuestion,
        configNegativeMarking: negativeMarking,
        configTotalMarks: totalMarks,
        configQuestionTypes: questionTypes,
        aiGenerationOption: aiOption,
        additionalInstructions: additionalInstructions,
        createdBy: currentUserId,
        status: 'draft',
        createdAt: DateTime.now(),
        questions: questions,
      );

      state = state.copyWith(
        isGenerating: false,
        generatedDpp: dpp,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate DPP: $e',
      );
    }
  }

  Future<void> regenerateDpp() async {
    final dpp = state.generatedDpp;
    if (dpp == null) return;

    await generateDpp(
      title: dpp.title,
      examType: dpp.examType,
      classLevel: dpp.classLevel,
      subjectId: dpp.subjectId,
      subjectName: dpp.subjectName ?? dpp.subjectId,
      chapterName: dpp.chapterName ?? '',
      topics: dpp.topics,
      difficulty: dpp.difficulty,
      questionCount: dpp.configQuestions,
      timeMinutes: dpp.configTimeMinutes,
      marksPerQuestion: dpp.configMarksPerQuestion,
      negativeMarking: dpp.configNegativeMarking,
      questionTypes: dpp.configQuestionTypes.isEmpty ? const ['Single Correct'] : dpp.configQuestionTypes,
      aiOption: dpp.aiGenerationOption,
      additionalInstructions: dpp.additionalInstructions,
      forceRefresh: true,
    );
  }

  /// Returns true if the DPP ID is a local mock (not yet persisted to DB).
  bool _isMockId(String id) => id.isEmpty || id.startsWith('dpp-mock');

  Future<void> saveDppDraft() async {
    final dpp = state.generatedDpp;
    if (dpp == null) return;

    state = state.copyWith(isLoading: true);
    try {
      DppModel saved;
      if (_isMockId(dpp.id)) {
        // Not yet in DB — create a new record
        saved = await repository.createDpp(dpp.copyWith(status: 'draft', id: ''));
        await repository.saveQuestions(saved.id, dpp.questions);
      } else {
        // Already in DB — update status and keep local model
        await repository.updateDpp(dpp.copyWith(status: 'draft'));
        saved = dpp.copyWith(status: 'draft');
      }

      // Refresh history list
      ref.read(dppHistoryControllerProvider.notifier).loadHistory();

      state = state.copyWith(
        isLoading: false,
        generatedDpp: saved.copyWith(questions: dpp.questions),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save draft: $e',
      );
    }
  }

  Future<void> assignDpp({
    required String assigneeType,
    String? batchId,
    String? studentId,
    required DateTime scheduledAt,
    DateTime? dueAt,
    required bool notify,
  }) async {
    final dpp = state.generatedDpp;
    if (dpp == null) return;

    state = state.copyWith(isLoading: true);
    try {
      // 1. Ensure DPP is saved first.
      //    Mock IDs (e.g. 'dpp-mock-...') are not valid UUIDs — always create.
      DppModel savedDpp = dpp;
      if (_isMockId(dpp.id)) {
        savedDpp = await repository.createDpp(dpp.copyWith(status: 'published', id: ''));
        await repository.saveQuestions(savedDpp.id, dpp.questions);
      } else {
        await repository.updateDpp(dpp.copyWith(status: 'published'));
        savedDpp = dpp.copyWith(status: 'published');
      }

      final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

      // 2. Create the assignment
      final assignment = DppAssignmentModel(
        id: '',
        dppId: savedDpp.id,
        assignedBy: currentUserId,
        assigneeType: assigneeType,
        batchId: batchId,
        studentId: studentId,
        scheduledAt: scheduledAt,
        dueAt: dueAt,
        notify: notify,
        createdAt: DateTime.now(),
      );

      await repository.assignDpp(assignment);

      // Refresh history
      ref.read(dppHistoryControllerProvider.notifier).loadHistory();

      state = state.copyWith(
        isLoading: false,
        generatedDpp: savedDpp.copyWith(questions: dpp.questions),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to assign DPP: $e',
      );
    }
  }

  void updateGeneratedDpp(DppModel updated) {
    state = state.copyWith(generatedDpp: updated);
  }

  void clearGenerator() {
    state = DppGeneratorState(
      batches: state.batches,
      students: state.students,
    );
  }
}
