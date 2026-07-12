import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/utils/exceptions.dart';
import 'package:national_academy/main.dart';
import '../../domain/repositories/dpp_repository.dart';
import '../models/dpp_model.dart';
import '../models/dpp_question_model.dart';
import '../models/dpp_assignment_model.dart';

final dppRepositoryProvider = Provider<DppRepository>((ref) {
  final isSupabaseReady = ref.watch(supabaseInitializedProvider);
  if (isSupabaseReady) {
    return SupabaseDppRepositoryImpl(
      supabaseClient: ref.watch(supabaseClientProvider),
    );
  } else {
    return MockDppRepository();
  }
});

class SupabaseDppRepositoryImpl implements DppRepository {
  final supabase.SupabaseClient supabaseClient;

  SupabaseDppRepositoryImpl({required this.supabaseClient});

  @override
  Future<List<DppModel>> fetchDpps({
    String? searchQuery,
    String? subjectId,
    String? difficulty,
  }) async {
    try {
      var query = supabaseClient
          .from('dpps')
          .select('*, subjects(name), profiles:created_by(full_name)');

      if (subjectId != null && subjectId.isNotEmpty) {
        query = query.eq('subject_id', subjectId);
      }
      if (difficulty != null && difficulty.isNotEmpty && difficulty != 'All') {
        query = query.eq('difficulty', difficulty);
      }

      final res = await query.order('created_at', ascending: false);

      List<DppModel> list = (res as List).map((json) => DppModel.fromJson(json)).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        list = list.where((d) => d.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
            (d.chapterName ?? '').toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching DPPs: $e');
      throw AuthException('Failed to fetch DPPs: $e');
    }
  }

  @override
  Future<DppModel?> fetchDppById(String id) async {
    try {
      final res = await supabaseClient
          .from('dpps')
          .select('*, subjects(name), profiles:created_by(full_name), dpp_questions(*)')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return DppModel.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching DPP by ID: $e');
      throw AuthException('Failed to fetch DPP detail: $e');
    }
  }

  @override
  Future<DppModel> createDpp(DppModel dpp) async {
    try {
      final json = dpp.toJson();
      final res = await supabaseClient.from('dpps').insert(json).select().single();
      return DppModel.fromJson(res);
    } catch (e) {
      debugPrint('Error creating DPP: $e');
      throw AuthException('Failed to create DPP: $e');
    }
  }

  @override
  Future<void> updateDpp(DppModel dpp) async {
    try {
      await supabaseClient
          .from('dpps')
          .update(dpp.toJson())
          .eq('id', dpp.id);
    } catch (e) {
      debugPrint('Error updating DPP: $e');
      throw AuthException('Failed to update DPP: $e');
    }
  }

  @override
  Future<void> deleteDpp(String id) async {
    try {
      await supabaseClient.from('dpps').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting DPP: $e');
      throw AuthException('Failed to delete DPP: $e');
    }
  }

  @override
  Future<void> saveQuestions(String dppId, List<DppQuestionModel> questions) async {
    try {
      // 1. Delete existing questions
      await supabaseClient.from('dpp_questions').delete().eq('dpp_id', dppId);

      // 2. Insert new questions
      if (questions.isNotEmpty) {
        final rows = questions.map((q) => q.copyWith(dppId: dppId).toJson()).toList();
        await supabaseClient.from('dpp_questions').insert(rows);
      }
    } catch (e) {
      debugPrint('Error saving questions: $e');
      throw AuthException('Failed to save DPP questions: $e');
    }
  }

  @override
  Future<List<DppQuestionModel>> fetchQuestionsForDpp(String dppId) async {
    try {
      final res = await supabaseClient
          .from('dpp_questions')
          .select()
          .eq('dpp_id', dppId)
          .order('created_at', ascending: true);

      return (res as List).map((json) => DppQuestionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      throw AuthException('Failed to fetch questions: $e');
    }
  }

  @override
  Future<void> assignDpp(DppAssignmentModel assignment) async {
    try {
      await supabaseClient.from('dpp_assignments').insert(assignment.toJson());
    } catch (e) {
      debugPrint('Error assigning DPP: $e');
      throw AuthException('Failed to assign DPP: $e');
    }
  }

  @override
  Future<List<DppAssignmentModel>> fetchAssignmentsForTeacher(String teacherId) async {
    try {
      final res = await supabaseClient
          .from('dpp_assignments')
          .select('*, dpps(title), batches(name), students(profiles(full_name))')
          .eq('assigned_by', teacherId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => DppAssignmentModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      return [];
    }
  }

  @override
  Future<List<DppAssignmentModel>> fetchAssignmentsForStudent(String studentId) async {
    try {
      final res = await supabaseClient
          .from('dpp_assignments')
          .select('*, dpps(title), batches(name), students(profiles(full_name))')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => DppAssignmentModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching student assignments: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSubjectsForExam(String examType) async {
    try {
      // Map exam type to Seeded Course ID
      String courseId = 'd1a3b5c7-e9f1-4a3b-8c5d-7e9f1a3b5c7d'; // JEE Default
      if (examType.toUpperCase() == 'NEET') {
        courseId = 'e2b4c6d8-f0a2-5b4c-9d6e-8f0a2b4c6d8e';
      } else if (examType.toUpperCase() == 'NDA') {
        courseId = 'f3c5d7e9-f1a3-6b5c-0d7f-9f1a3b5c7d9e';
      } else if (examType.toUpperCase() == 'BOARDS') {
        courseId = 'a4d6e8f0-a2b4-7b6c-1d8f-0a2b4c6d8e0f';
      }

      final res = await supabaseClient
          .from('subjects')
          .select('id, name')
          .eq('course_id', courseId);

      return (res as List).map((s) => {
        'id': s['id'] as String,
        'name': s['name'] as String,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      return [];
    }
  }

  @override
  Future<List<String>> fetchChaptersForSubject(String subjectId) async {
    try {
      final res = await supabaseClient
          .from('chapters')
          .select('name')
          .eq('subject_id', subjectId);
      return (res as List).map((c) => c['name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching chapters: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllBatches() async {
    try {
      final res = await supabaseClient.from('batches').select('id, name');
      return (res as List).map((b) => {
        'id': b['id'] as String,
        'name': b['name'] as String,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllStudents() async {
    try {
      final res = await supabaseClient
          .from('students')
          .select('id, profiles(full_name)');
      return (res as List).map((s) {
        final profile = s['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'id': s['id'] as String,
          'name': profile['full_name'] as String? ?? 'Student',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return [];
    }
  }

  @override
  Future<DppAssignmentModel?> fetchAssignmentById(String id) async {
    try {
      final res = await supabaseClient
          .from('dpp_assignments')
          .select('*, dpps(*), batches(name), students(profiles(full_name))')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return DppAssignmentModel.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching assignment: $e');
      return null;
    }
  }

  @override
  Future<String> createAttempt({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final res = await supabaseClient.from('dpp_attempts').insert({
        'assignment_id': assignmentId,
        'student_id': studentId,
        'started_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      return res['id'] as String;
    } catch (e) {
      debugPrint('Error creating attempt: $e');
      throw Exception('Failed to start attempt: $e');
    }
  }

  @override
  Future<void> submitAttempt({
    required String attemptId,
    required String studentId,
    required Map<String, String> answers,
    required double score,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required int skippedQuestions,
    required int timeTakenSeconds,
  }) async {
    try {
      // 1. Update the attempt row with submitted_at and answers_json
      await supabaseClient.from('dpp_attempts').update({
        'submitted_at': DateTime.now().toIso8601String(),
        'answers_json': answers,
      }).eq('id', attemptId);

      // 2. Insert result
      await supabaseClient.from('dpp_results').insert({
        'attempt_id': attemptId,
        'student_id': studentId,
        'score': score,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'wrong_answers': wrongAnswers,
        'skipped_questions': skippedQuestions,
        'time_taken_seconds': timeTakenSeconds,
      });
    } catch (e) {
      debugPrint('Error submitting attempt: $e');
      throw Exception('Failed to submit attempt: $e');
    }
  }
}

class MockDppRepository implements DppRepository {
  final List<DppModel> _dpps = [];
  final List<DppAssignmentModel> _assignments = [];

  MockDppRepository() {
    _seedMocks();
  }

  void _seedMocks() {
    final mockDpp = DppModel(
      id: 'dpp-mock-1',
      title: 'Electrostatics Basic Test 1',
      examType: 'JEE',
      classLevel: 'Class 12',
      subjectId: 'sub-phys-1',
      subjectName: 'Physics (JEE)',
      chapterName: 'Electrostatics',
      topics: ['Coulombs Law', 'Electric Field'],
      difficulty: 'Medium',
      configQuestions: 5,
      configTimeMinutes: 20,
      configMarksPerQuestion: 4,
      configNegativeMarking: 1.0,
      configTotalMarks: 20,
      configQuestionTypes: ['Single Correct'],
      aiGenerationOption: 'Conceptual',
      createdBy: 'mock-teacher',
      creatorName: 'Mr. Sharma',
      status: 'published',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      questions: [
        DppQuestionModel(
          id: 'q-1',
          dppId: 'dpp-mock-1',
          questionText: 'Two charges of \$1\\mu C\$ and \$5\\mu C\$ are placed some distance apart. What is the ratio of the force acting on them?',
          questionType: 'Single Correct',
          options: ['1:5', '5:1', '1:1', '25:1'],
          correctAnswer: '1:1',
          explanation: 'According to Newton\'s third law, the force exerted by charge 1 on charge 2 is equal and opposite to the force exerted by charge 2 on charge 1.',
          difficulty: 'Easy',
          estimatedTimeSeconds: 120,
          marks: 4,
          learningOutcome: 'Newtonian reciprocity in electrostatic forces',
        ),
        DppQuestionModel(
          id: 'q-2',
          dppId: 'dpp-mock-1',
          questionText: 'Which of the following is not a property of electric field lines?',
          questionType: 'Single Correct',
          options: [
            'They start from positive charge and end at negative charge.',
            'They can form closed loops.',
            'Two field lines never intersect.',
            'They are normal to the surface of a conductor.'
          ],
          correctAnswer: 'They can form closed loops.',
          explanation: 'Electrostatic field lines are conservative in nature and do not form closed loops. Only magnetic field lines do.',
          difficulty: 'Medium',
          estimatedTimeSeconds: 150,
          marks: 4,
          learningOutcome: 'Properties of electric field lines',
        )
      ],
    );
    _dpps.add(mockDpp);
  }

  @override
  Future<List<DppModel>> fetchDpps({
    String? searchQuery,
    String? subjectId,
    String? difficulty,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = [..._dpps];
    if (subjectId != null && subjectId.isNotEmpty) {
      list = list.where((d) => d.subjectId == subjectId).toList();
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'All') {
      list = list.where((d) => d.difficulty == difficulty).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      list = list.where((d) => d.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Future<DppModel?> fetchDppById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final matches = _dpps.where((d) => d.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<DppModel> createDpp(DppModel dpp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDpp = dpp.copyWith(
      id: 'dpp-mock-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _dpps.add(newDpp);
    return newDpp;
  }

  @override
  Future<void> updateDpp(DppModel dpp) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _dpps.indexWhere((d) => d.id == dpp.id);
    if (index != -1) {
      _dpps[index] = dpp;
    }
  }

  @override
  Future<void> deleteDpp(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _dpps.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> saveQuestions(String dppId, List<DppQuestionModel> questions) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _dpps.indexWhere((d) => d.id == dppId);
    if (index != -1) {
      _dpps[index] = _dpps[index].copyWith(questions: questions);
    }
  }

  @override
  Future<List<DppQuestionModel>> fetchQuestionsForDpp(String dppId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _dpps.indexWhere((d) => d.id == dppId);
    return index != -1 ? _dpps[index].questions : [];
  }

  @override
  Future<void> assignDpp(DppAssignmentModel assignment) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final ass = DppAssignmentModel(
      id: 'ass-mock-${DateTime.now().millisecondsSinceEpoch}',
      dppId: assignment.dppId,
      dppTitle: _dpps.firstWhere((d) => d.id == assignment.dppId).title,
      assignedBy: assignment.assignedBy,
      assigneeType: assignment.assigneeType,
      batchId: assignment.batchId,
      batchName: assignment.batchId != null ? 'Batch Alpha' : null,
      studentId: assignment.studentId,
      studentName: assignment.studentId != null ? 'Shubham' : null,
      scheduledAt: assignment.scheduledAt,
      dueAt: assignment.dueAt,
      notify: assignment.notify,
      createdAt: DateTime.now(),
    );
    _assignments.add(ass);
  }

  @override
  Future<List<DppAssignmentModel>> fetchAssignmentsForTeacher(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _assignments.where((a) => a.assignedBy == teacherId).toList();
  }

  @override
  Future<List<DppAssignmentModel>> fetchAssignmentsForStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _assignments.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSubjectsForExam(String examType) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (examType.toUpperCase() == 'NEET') {
      return [
        {'id': 'sub-phys-2', 'name': 'Physics (NEET)'},
        {'id': 'sub-chem-2', 'name': 'Chemistry (NEET)'},
        {'id': 'sub-bio-2', 'name': 'Biology (NEET)'},
      ];
    } else if (examType.toUpperCase() == 'NDA') {
      return [
        {'id': 'sub-math-3', 'name': 'Mathematics (NDA)'},
        {'id': 'sub-gen-3', 'name': 'General Ability (NDA)'},
      ];
    } else {
      return [
        {'id': 'sub-phys-1', 'name': 'Physics (JEE)'},
        {'id': 'sub-chem-1', 'name': 'Chemistry (JEE)'},
        {'id': 'sub-math-1', 'name': 'Mathematics (JEE)'},
      ];
    }
  }

  @override
  Future<List<String>> fetchChaptersForSubject(String subjectId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (subjectId.contains('phys')) {
      return ['Kinematics', 'Thermodynamics', 'Electrostatics', 'Rotational Motion'];
    } else if (subjectId.contains('chem')) {
      return ['Organic Chemistry', 'Chemical Bonding', 'Solutions', 'Electrochemistry'];
    } else if (subjectId.contains('bio')) {
      return ['Cell Biology', 'Genetics', 'Human Physiology', 'Plant Kingdom'];
    } else {
      return ['Matrices', 'Limits & Derivatives', 'Probability', 'Vectors'];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllBatches() async {
    return [
      {'id': '5943fc08-75f9-4fa0-89fb-43791ac36c05', 'name': 'JEE 2026 Batch A'},
      {'id': 'batch-mock-2', 'name': 'NEET 2026 Batch B'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllStudents() async {
    return [
      {'id': 'stud-1', 'name': 'Shubham Kumar'},
      {'id': 'stud-2', 'name': 'Veera Raghavan'},
    ];
  }

  @override
  Future<DppAssignmentModel?> fetchAssignmentById(String id) async {
    final list = _assignments.where((a) => a.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<String> createAttempt({
    required String assignmentId,
    required String studentId,
  }) async {
    return 'attempt-mock-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> submitAttempt({
    required String attemptId,
    required String studentId,
    required Map<String, String> answers,
    required double score,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required int skippedQuestions,
    required int timeTakenSeconds,
  }) async {
    // No-op for mock repo
  }
}

