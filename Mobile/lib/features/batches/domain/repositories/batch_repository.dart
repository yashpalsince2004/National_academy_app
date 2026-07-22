import '../../data/models/batch_model.dart';
import '../../data/models/batch_student_model.dart';
import '../../data/models/timetable_lecture_model.dart';
import '../../data/models/exam_model.dart';

abstract class BatchRepository {
  Future<List<BatchModel>> fetchBatches();
  Future<void> createBatch(BatchModel batch);
  Future<void> updateBatch(BatchModel batch);
  Future<void> deleteBatch(String batchId);
  Future<void> archiveBatch(String batchId);
  
  Future<List<BatchStudentModel>> fetchStudentsForBatch(String batchId);
  Future<List<BatchStudentModel>> fetchAvailableStudentsForClass({
    required String classLevel,
    required String examType,
  });
  Future<void> assignStudentsToBatch(String batchId, List<String> studentIds);
  Future<void> removeStudentsFromBatch(String batchId, List<String> studentIds);
  
  Future<List<Map<String, dynamic>>> fetchTeachers();
  Future<List<Map<String, dynamic>>> fetchSubjectsForCourse(String courseId);
  Future<void> assignTeacherToBatch({
    required String batchId,
    required String teacherId,
    required String subjectId,
  });
  
  Future<List<TimetableLectureModel>> fetchTimetable(String batchId);
  Future<void> addLecture(TimetableLectureModel lecture);
  Future<void> deleteLecture(String lectureId);
  
  Future<Map<String, dynamic>> fetchAttendanceStats(String batchId);
  Future<Map<String, dynamic>> fetchPerformanceStats(String batchId);

  Future<List<ExamModel>> fetchExams(String batchId);
  Future<void> addExam(ExamModel exam);
  Future<void> updateExam(ExamModel exam);
}
