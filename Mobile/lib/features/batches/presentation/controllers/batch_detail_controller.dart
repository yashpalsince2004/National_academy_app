import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/batch_student_model.dart';
import '../../data/models/timetable_lecture_model.dart';
import '../../data/repositories/batch_repository_impl.dart';
import '../../domain/repositories/batch_repository.dart';
import 'batch_controller.dart';

class BatchDetailState {
  final bool isLoading;
  final String? errorMessage;
  final List<BatchStudentModel> students;
  final List<BatchStudentModel> availableStudents;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> subjects;
  final List<TimetableLectureModel> lectures;
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
      final attendance = await repository.fetchAttendanceStats(batchId);
      final performance = await repository.fetchPerformanceStats(batchId);
      
      state = state.copyWith(
        isLoading: false,
        students: students,
        teachers: teachers,
        lectures: lectures,
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
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.deleteLecture(lectureId);
      await loadAllDetails();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}
