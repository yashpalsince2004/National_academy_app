import '../../data/models/dpp_model.dart';
import '../../data/models/dpp_question_model.dart';
import '../../data/models/dpp_assignment_model.dart';

abstract class DppRepository {
  Future<List<DppModel>> fetchDpps({
    String? searchQuery,
    String? subjectId,
    String? difficulty,
  });
  Future<DppModel?> fetchDppById(String id);
  Future<DppModel> createDpp(DppModel dpp);
  Future<void> updateDpp(DppModel dpp);
  Future<void> deleteDpp(String id);

  Future<void> saveQuestions(String dppId, List<DppQuestionModel> questions);
  Future<List<DppQuestionModel>> fetchQuestionsForDpp(String dppId);

  Future<void> assignDpp(DppAssignmentModel assignment);
  Future<List<DppAssignmentModel>> fetchAssignmentsForTeacher(String teacherId);
  Future<List<DppAssignmentModel>> fetchAssignmentsForStudent(String studentId);

  // Helpers to list options for dropdowns
  Future<List<Map<String, dynamic>>> fetchSubjectsForExam(String examType);
  Future<List<String>> fetchChaptersForSubject(String subjectId);
  Future<List<Map<String, dynamic>>> fetchAllBatches();
  Future<List<Map<String, dynamic>>> fetchAllStudents();
  // Attempting DPPs
  Future<DppAssignmentModel?> fetchAssignmentById(String id);
  Future<String> createAttempt({
    required String assignmentId,
    required String studentId,
  });
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
  });
}

