import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/batch_student_model.dart';
import '../../data/models/timetable_lecture_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/repositories/batch_repository_impl.dart';
import '../../domain/repositories/batch_repository.dart';
import 'batch_controller.dart';
import '../../../../core/services/supabase_providers.dart';

class BatchDetailState {
  final bool isLoading;
  final String? errorMessage;
  final List<BatchStudentModel> students;
  final List<BatchStudentModel> availableStudents;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> subjects;
  final List<TimetableLectureModel> lectures;
  final List<ExamModel> exams;
  final Map<String, dynamic> attendanceStats;
  final Map<String, dynamic> performanceStats;

  BatchDetailState({
    this.isLoading = false,
    this.errorMessage,
    this.students = const [],
    this.availableStudents = const [],
    this.teachers = const [],
    this.subjects = const [],
    this.lectures = const [],
    this.exams = const [],
    this.attendanceStats = const {},
    this.performanceStats = const {},
  });

  BatchDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<BatchStudentModel>? students,
    List<BatchStudentModel>? availableStudents,
    List<Map<String, dynamic>>? teachers,
    List<Map<String, dynamic>>? subjects,
    List<TimetableLectureModel>? lectures,
    List<ExamModel>? exams,
    Map<String, dynamic>? attendanceStats,
    Map<String, dynamic>? performanceStats,
  }) {
    return BatchDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      students: students ?? this.students,
      availableStudents: availableStudents ?? this.availableStudents,
      teachers: teachers ?? this.teachers,
      subjects: subjects ?? this.subjects,
      lectures: lectures ?? this.lectures,
      exams: exams ?? this.exams,
      attendanceStats: attendanceStats ?? this.attendanceStats,
      performanceStats: performanceStats ?? this.performanceStats,
    );
  }
}

final batchDetailControllerProvider = StateNotifierProvider.family<BatchDetailController, BatchDetailState, String>((ref, batchId) {
  final repository = ref.watch(batchRepositoryProvider);
  return BatchDetailController(repository: repository, batchId: batchId, ref: ref);
});

class BatchDetailController extends StateNotifier<BatchDetailState> {
  final BatchRepository repository;
  final String batchId;
  final Ref ref;

  BatchDetailController({
    required this.repository,
    required this.batchId,
    required this.ref,
  }) : super(BatchDetailState()) {
    loadAllDetails();
  }

  Future<void> loadAllDetails() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final students = await repository.fetchStudentsForBatch(batchId);
      final teachers = await repository.fetchTeachers();
      final lectures = await repository.fetchTimetable(batchId);
      final exams = await repository.fetchExams(batchId);
      final attendance = await repository.fetchAttendanceStats(batchId);
      final performance = await repository.fetchPerformanceStats(batchId);
      
      state = state.copyWith(
        isLoading: false,
        students: students,
        teachers: teachers,
        lectures: lectures,
        exams: exams,
        attendanceStats: attendance,
        performanceStats: performance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadAvailableStudents({
    required String classLevel,
    required String examType,
  }) async {
    try {
      final avail = await repository.fetchAvailableStudentsForClass(
        classLevel: classLevel,
        examType: examType,
      );
      state = state.copyWith(availableStudents: avail);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> assignStudents(List<String> studentIds) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.assignStudentsToBatch(batchId, studentIds);
      await loadAllDetails();
      // Sync the dashboard batch list so card counts update immediately
      ref.invalidate(batchControllerProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> removeStudents(List<String> studentIds) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.removeStudentsFromBatch(batchId, studentIds);
      await loadAllDetails();
      // Sync the dashboard batch list so card counts update immediately
      ref.invalidate(batchControllerProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> loadSubjects(String courseId) async {
    try {
      final subs = await repository.fetchSubjectsForCourse(courseId);
      state = state.copyWith(subjects: subs);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> assignTeacher({
    required String teacherId,
    required String subjectId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.assignTeacherToBatch(
        batchId: batchId,
        teacherId: teacherId,
        subjectId: subjectId,
      );
      await loadAllDetails();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> addLecture({
    required String subjectName,
    required String teacherName,
    required String room,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? lectureDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final lec = TimetableLectureModel(
        id: '',
        batchId: batchId,
        subjectName: subjectName,
        teacherName: teacherName,
        room: room,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        lectureDate: lectureDate,
      );
      await repository.addLecture(lec);
      await loadAllDetails();
      ref.invalidate(studentUpcomingLectureProvider);
      ref.invalidate(studentUpcomingLecturesProvider);
      ref.invalidate(studentLiveLectureProvider);
      ref.invalidate(studentLectureAlertProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    state = state.copyWith(isLoading: true);
    try {
      // Find the lecture to add to cancelled list before deleting
      try {
        final lecture = state.lectures.firstWhere((l) => l.id == lectureId);
        if (!CancelledLecturesManager.cancelledLectures.any((l) => l.id == lectureId)) {
          CancelledLecturesManager.cancelledLectures.add(lecture);
        }
      } catch (_) {}
      await repository.deleteLecture(lectureId);
      await loadAllDetails();
      ref.invalidate(studentUpcomingLectureProvider);
      ref.invalidate(studentUpcomingLecturesProvider);
      ref.invalidate(studentLiveLectureProvider);
      ref.invalidate(studentLectureAlertProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> addExam(ExamModel exam) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.addExam(exam);
      await loadAllDetails();
      ref.invalidate(studentUpcomingTestProvider);
      ref.invalidate(studentExamsListProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateExam(ExamModel exam) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.updateExam(exam);
      await loadAllDetails();
      ref.invalidate(studentUpcomingTestProvider);
      ref.invalidate(studentExamsListProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

class CancelledLecturesManager {
  static final List<TimetableLectureModel> cancelledLectures = [
    TimetableLectureModel(
      id: 'cancelled-1',
      batchId: 'mock-1',
      subjectName: 'Physics',
      teacherName: 'Mr. R. Sharma',
      room: 'Room 101',
      dayOfWeek: 'Monday',
      startTime: '09:00 AM',
      endTime: '10:30 AM',
      lectureDate: '2026-07-16',
    ),
    TimetableLectureModel(
      id: 'cancelled-2',
      batchId: 'mock-1',
      subjectName: 'Chemistry',
      teacherName: 'Mrs. A. Gupta',
      room: 'Room 102',
      dayOfWeek: 'Wednesday',
      startTime: '11:00 AM',
      endTime: '12:30 PM',
      lectureDate: '2026-07-15',
    ),
  ];
}
