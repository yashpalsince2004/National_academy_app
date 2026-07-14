import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/main.dart';
import 'package:national_academy/core/utils/exceptions.dart';
import '../../domain/repositories/batch_repository.dart';
import '../models/batch_model.dart';
import '../models/batch_student_model.dart';
import '../models/timetable_lecture_model.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final isSupabaseReady = ref.watch(supabaseInitializedProvider);
  if (isSupabaseReady) {
    return SupabaseBatchRepositoryImpl(
      supabaseClient: ref.watch(supabaseClientProvider),
    );
  } else {
    return MockBatchRepository();
  }
});

class SupabaseBatchRepositoryImpl implements BatchRepository {
  final supabase.SupabaseClient supabaseClient;

  SupabaseBatchRepositoryImpl({required this.supabaseClient});

  @override
  Future<List<BatchModel>> fetchBatches() async {
    try {
      // 1. Fetch all batches
      final res = await supabaseClient.from('batches').select();

      // 2. Fetch real enrollment counts per batch in one query
      final enrollmentCounts = await supabaseClient
          .from('batch_enrollments')
          .select('batch_id');

      // Build a count map: batchId -> count
      final countMap = <String, int>{};
      for (final row in enrollmentCounts as List) {
        final bid = row['batch_id'] as String;
        countMap[bid] = (countMap[bid] ?? 0) + 1;
      }

      // 3. Fetch primary teacher assignments
      final teacherRes = await supabaseClient
          .from('teacher_assignments')
          .select('batch_id, profiles:teacher_id(full_name)');

      final teacherMap = <String, String>{};
      for (var t in teacherRes as List) {
        final bId = t['batch_id'] as String;
        final prof = t['profiles'] as Map<String, dynamic>?;
        if (prof != null && prof['full_name'] != null) {
          teacherMap[bId] = prof['full_name'] as String;
        }
      }

      return (res as List).map((json) {
        final id = json['id'] as String;
        return BatchModel.fromJson({
          ...json,
          'student_count': countMap[id] ?? 0,
          'teacher_name': teacherMap[id] ?? 'Unassigned',
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> createBatch(BatchModel batch) async {
    try {
      // Check duplicate name
      final existing = await supabaseClient
          .from('batches')
          .select('id')
          .eq('name', batch.name.trim())
          .maybeSingle();
      if (existing != null) {
        throw AuthException('A batch with the name "${batch.name}" already exists.');
      }

      final payload = batch.toJson();
      payload.remove('id'); // let Supabase generate UUID
      await supabaseClient.from('batches').insert(payload);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to create batch: $e');
    }
  }

  @override
  Future<void> updateBatch(BatchModel batch) async {
    try {
      await supabaseClient
          .from('batches')
          .update(batch.toJson())
          .eq('id', batch.id);
    } catch (e) {
      throw AuthException('Failed to update batch: $e');
    }
  }

  @override
  Future<void> deleteBatch(String batchId) async {
    try {
      // Check if students are assigned
      final countRes = await supabaseClient
          .from('batch_enrollments')
          .select('id')
          .eq('batch_id', batchId)
          .limit(1);
      
      if ((countRes as List).isNotEmpty) {
        throw AuthException('Cannot delete batch because it has students enrolled. Archive it instead.');
      }

      await supabaseClient.from('batches').delete().eq('id', batchId);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to delete batch: $e');
    }
  }

  @override
  Future<void> archiveBatch(String batchId) async {
    try {
      await supabaseClient
          .from('batches')
          .update({'status': 'completed'}) // completing/archiving
          .eq('id', batchId);
    } catch (e) {
      throw AuthException('Failed to archive batch: $e');
    }
  }

  @override
  Future<List<BatchStudentModel>> fetchStudentsForBatch(String batchId) async {
    try {
      final res = await supabaseClient
          .from('batch_enrollments')
          .select('*, students(*, profiles(*))')
          .eq('batch_id', batchId);

      return (res as List).map((json) {
        final student = json['students'] as Map<String, dynamic>? ?? {};
        final profile = student['profiles'] as Map<String, dynamic>? ?? {};
        final rollNo = student['roll_no'] as String? ?? 'Unassigned';
        final status = json['status'] as String? ?? 'active';

        return BatchStudentModel(
          id: student['id'] as String? ?? '',
          fullName: profile['full_name'] as String? ?? '',
          email: profile['email'] as String? ?? '',
          rollNo: rollNo,
          attendancePercentage: 85.0, // default placeholder, mock for charts
          feeStatus: 'Paid',
          classLevel: student['previous_class'] as String? ?? '12',
          examType: 'JEE',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching batch students: $e');
      return [];
    }
  }

  @override
  Future<List<BatchStudentModel>> fetchAvailableStudentsForClass({
    required String classLevel,
    required String examType,
  }) async {
    try {
      // 1. Fetch all active students
      final studentsRes = await supabaseClient
          .from('students')
          .select('*, profiles(*)')
          .eq('status', 'active');

      // 2. Fetch all current enrollments to identify already assigned ones
      final enrollmentsRes = await supabaseClient
          .from('batch_enrollments')
          .select('student_id, batch_id');
      
      final enrolledStudentIds = {
        for (var e in enrollmentsRes as List) e['student_id'] as String
      };

      final List<BatchStudentModel> available = [];
      for (var s in studentsRes as List) {
        final profile = s['profiles'] as Map<String, dynamic>? ?? {};
        final id = s['id'] as String;
        final info = s['additional_info'] as Map<String, dynamic>? ?? {};

        // Parse fields
        final sClass = info['academic_class'] as String? ?? '12';
        final sExams = info['target_exams'] as List? ?? [];
        final isEnrolled = enrolledStudentIds.contains(id);

        // Filter by class level matching
        if (sClass == classLevel) {
          available.add(BatchStudentModel(
            id: id,
            fullName: profile['full_name'] as String? ?? '',
            email: profile['email'] as String? ?? '',
            rollNo: s['roll_no'] as String? ?? 'Unassigned',
            attendancePercentage: 90.0,
            feeStatus: isEnrolled ? 'Assigned' : 'Paid', // flag already assigned
            classLevel: sClass,
            examType: sExams.isNotEmpty ? sExams.first.toString() : examType,
          ));
        }
      }

      return available;
    } catch (e) {
      debugPrint('Error fetching available students: $e');
      return [];
    }
  }

  @override
  Future<void> assignStudentsToBatch(String batchId, List<String> studentIds) async {
    try {
      final rows = studentIds.map((sid) => {
        'batch_id': batchId,
        'student_id': sid,
        'status': 'active',
      }).toList();
      await supabaseClient.from('batch_enrollments').insert(rows);
    } catch (e) {
      throw AuthException('Failed to assign students: $e');
    }
  }

  @override
  Future<void> removeStudentsFromBatch(String batchId, List<String> studentIds) async {
    try {
      await supabaseClient
          .from('batch_enrollments')
          .delete()
          .eq('batch_id', batchId)
          .inFilter('student_id', studentIds);
    } catch (e) {
      throw AuthException('Failed to remove students: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    try {
      final res = await supabaseClient
          .from('profiles')
          .select('id, full_name, email, subject')
          .eq('role', 'teacher');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSubjectsForCourse(String courseId) async {
    try {
      final res = await supabaseClient
          .from('subjects')
          .select('id, name')
          .eq('course_id', courseId);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      // fallback subjects fetch
      final fallbackRes = await supabaseClient.from('subjects').select('id, name');
      return List<Map<String, dynamic>>.from(fallbackRes as List);
    }
  }

  @override
  Future<void> assignTeacherToBatch({
    required String batchId,
    required String teacherId,
    required String subjectId,
  }) async {
    try {
      await supabaseClient.from('teacher_assignments').upsert({
        'batch_id': batchId,
        'teacher_id': teacherId,
        'subject_id': subjectId,
      }, onConflict: 'teacher_id,batch_id,subject_id');
    } catch (e) {
      throw AuthException('Failed to assign teacher: $e');
    }
  }

  @override
  Future<List<TimetableLectureModel>> fetchTimetable(String batchId) async {
    try {
      final res = await supabaseClient
          .from('timetable')
          .select('*, subjects(name), profiles:teacher_id(full_name)')
          .eq('batch_id', batchId);

      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      return (res as List).map((json) {
        final sub = json['subjects'] as Map<String, dynamic>?;
        final prof = json['profiles'] as Map<String, dynamic>?;

        final dayInt = json['day_of_week'] as int? ?? 0;
        final dayStr = (dayInt >= 0 && dayInt <= 6) ? weekdays[dayInt] : 'Monday';

        return TimetableLectureModel(
          id: json['id'] as String? ?? '',
          batchId: json['batch_id'] as String? ?? '',
          subjectName: sub != null ? sub['name'] as String? ?? 'Subject' : 'Subject',
          teacherName: prof != null ? prof['full_name'] as String? ?? 'Teacher' : 'Teacher',
          room: json['room'] as String? ?? 'Room 101',
          dayOfWeek: dayStr,
          startTime: json['start_time'] as String? ?? '',
          endTime: json['end_time'] as String? ?? '',
          lectureDate: json['lecture_date'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      return [];
    }
  }

  @override
  Future<void> addLecture(TimetableLectureModel lecture) async {
    try {
      // Find subject_id from name or fallback
      final subRes = await supabaseClient
          .from('subjects')
          .select('id')
          .eq('name', lecture.subjectName)
          .limit(1)
          .maybeSingle();
      
      final subId = subRes != null ? subRes['id'] as String : null;

      // Find teacher_id from name
      final teachRes = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('full_name', lecture.teacherName)
          .limit(1)
          .maybeSingle();
      
      final teachId = teachRes != null ? teachRes['id'] as String : null;

      if (subId == null || teachId == null) {
        throw AuthException('Invalid Subject or Teacher specified.');
      }

      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayInt = weekdays.indexOf(lecture.dayOfWeek);
      final dayToSend = dayInt == -1 ? 0 : dayInt;

      await supabaseClient.from('timetable').insert({
        'batch_id': lecture.batchId,
        'subject_id': subId,
        'teacher_id': teachId,
        'day_of_week': dayToSend,
        'start_time': lecture.startTime,
        'end_time': lecture.endTime,
        'room': lecture.room,
        'lecture_date': lecture.lectureDate,
      });
    } catch (e) {
      throw AuthException('Failed to add lecture: $e');
    }
  }

  @override
  Future<void> deleteLecture(String lectureId) async {
    try {
      await supabaseClient.from('timetable').delete().eq('id', lectureId);
    } catch (e) {
      throw AuthException('Failed to delete lecture: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAttendanceStats(String batchId) async {
    return {
      'present_today': 18,
      'absent_today': 2,
      'total': 20,
      'attendance_rate': 90.0,
      'weekly_trend': [88.0, 92.0, 90.0, 85.0, 91.0, 90.0],
    };
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceStats(String batchId) async {
    return {
      'average_marks': 72.5,
      'completed_syllabus': 45.0,
      'top_performers': [
        {'name': 'Shubham', 'score': '95%'},
        {'name': 'YASH', 'score': '92%'}
      ],
      'weak_students': [
        {'name': 'Pranav Desai', 'score': '48%'}
      ],
    };
  }
}

class MockBatchRepository implements BatchRepository {
  final List<BatchModel> _mockBatches = [
    BatchModel(
      id: 'mock-1',
      courseId: 'course-1',
      name: 'Fanta',
      capacity: 40,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 300)),
      examType: 'JEE',
      classLevel: '12',
      medium: 'English',
      lectureDays: ['Monday', 'Wednesday', 'Friday'],
      startTime: '09:00:00',
      endTime: '11:00:00',
      roomNumber: 'Room 101',
      color: 'blue',
      remarks: 'Alpha JEE level 12 batch',
      status: 'active',
      studentCount: 2,
      teacherName: 'Mr. Sharma',
    ),
    BatchModel(
      id: 'mock-2',
      courseId: 'course-1',
      name: 'Samrat jee',
      capacity: 35,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 320)),
      examType: 'JEE',
      classLevel: '12',
      medium: 'Hindi',
      lectureDays: ['Tuesday', 'Thursday', 'Saturday'],
      startTime: '11:00:00',
      endTime: '13:00:00',
      roomNumber: 'Room 102',
      color: 'blue',
      remarks: 'JEE batch in Hindi medium',
      status: 'active',
      studentCount: 1,
      teacherName: 'Mr. Verma',
    ),
    BatchModel(
      id: 'mock-3',
      courseId: 'course-3',
      name: 'NDA 2026 Foundation',
      capacity: 50,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 180)),
      examType: 'NDA',
      classLevel: '12',
      medium: 'English',
      lectureDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      startTime: '14:00:00',
      endTime: '16:00:00',
      roomNumber: 'Lab B',
      color: 'purple',
      remarks: 'NDA preparation basic batch',
      status: 'active',
      studentCount: 0,
      teacherName: 'Maj. Singh',
    ),
  ];

  final List<BatchStudentModel> _mockStudents = [
    BatchStudentModel(
      id: 'stud-1',
      fullName: 'YASH',
      email: 'yash@example.com',
      rollNo: 'NA-2026-0001',
      attendancePercentage: 92.5,
      feeStatus: 'Paid',
      classLevel: '12',
      examType: 'JEE',
    ),
    BatchStudentModel(
      id: 'stud-2',
      fullName: 'Shubham',
      email: 'shubham@example.com',
      rollNo: 'NA-2026-0002',
      attendancePercentage: 88.0,
      feeStatus: 'Paid',
      classLevel: '12',
      examType: 'JEE',
    ),
    BatchStudentModel(
      id: 'stud-3',
      fullName: 'Pranav Desai',
      email: 'pranav@example.com',
      rollNo: 'NA-2026-0003',
      attendancePercentage: 45.0,
      feeStatus: 'Pending',
      classLevel: '12',
      examType: 'NEET',
    ),
    BatchStudentModel(
      id: 'stud-4',
      fullName: 'Sumit',
      email: 'sumit@example.com',
      rollNo: 'NA-2026-0004',
      attendancePercentage: 95.0,
      feeStatus: 'Paid',
      classLevel: '12',
      examType: 'JEE',
    ),
  ];

  final List<TimetableLectureModel> _mockLectures = [
    TimetableLectureModel(
      id: 'lec-1',
      batchId: 'mock-1',
      subjectName: 'Physics',
      teacherName: 'Mr. Sharma',
      room: 'Room 101',
      dayOfWeek: 'Monday',
      startTime: '09:00:00',
      endTime: '11:00:00',
    ),
    TimetableLectureModel(
      id: 'lec-2',
      batchId: 'mock-1',
      subjectName: 'Chemistry',
      teacherName: 'Dr. Sen',
      room: 'Room 102',
      dayOfWeek: 'Wednesday',
      startTime: '09:00:00',
      endTime: '11:00:00',
    ),
    TimetableLectureModel(
      id: 'lec-3',
      batchId: 'mock-1',
      subjectName: 'Maths',
      teacherName: 'Mr. Verma',
      room: 'Room 101',
      dayOfWeek: 'Friday',
      startTime: '09:00:00',
      endTime: '11:00:00',
    ),
  ];

  @override
  Future<List<BatchModel>> fetchBatches() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockBatches;
  }

  @override
  Future<void> createBatch(BatchModel batch) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_mockBatches.any((b) => b.name.trim().toLowerCase() == batch.name.trim().toLowerCase())) {
      throw AuthException('A batch with the name "${batch.name}" already exists.');
    }
    final newId = 'mock-${_mockBatches.length + 1}';
    _mockBatches.add(batch.copyWith(id: newId));
  }

  @override
  Future<void> updateBatch(BatchModel batch) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _mockBatches.indexWhere((b) => b.id == batch.id);
    if (idx != -1) {
      _mockBatches[idx] = batch;
    }
  }

  @override
  Future<void> deleteBatch(String batchId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final b = _mockBatches.firstWhere((element) => element.id == batchId);
    if (b.studentCount > 0) {
      throw AuthException('Cannot delete batch because it has students enrolled. Archive it instead.');
    }
    _mockBatches.removeWhere((b) => b.id == batchId);
  }

  @override
  Future<void> archiveBatch(String batchId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _mockBatches.indexWhere((b) => b.id == batchId);
    if (idx != -1) {
      _mockBatches[idx] = _mockBatches[idx].copyWith(status: 'completed');
    }
  }

  @override
  Future<List<BatchStudentModel>> fetchStudentsForBatch(String batchId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (batchId == 'mock-1') {
      return _mockStudents.sublist(0, 2);
    } else if (batchId == 'mock-2') {
      return _mockStudents.sublist(1, 2);
    }
    return [];
  }

  @override
  Future<List<BatchStudentModel>> fetchAvailableStudentsForClass({
    required String classLevel,
    required String examType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockStudents;
  }

  @override
  Future<void> assignStudentsToBatch(String batchId, List<String> studentIds) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _mockBatches.indexWhere((b) => b.id == batchId);
    if (idx != -1) {
      final b = _mockBatches[idx];
      _mockBatches[idx] = b.copyWith(studentCount: b.studentCount + studentIds.length);
    }
  }

  @override
  Future<void> removeStudentsFromBatch(String batchId, List<String> studentIds) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _mockBatches.indexWhere((b) => b.id == batchId);
    if (idx != -1) {
      final b = _mockBatches[idx];
      _mockBatches[idx] = b.copyWith(studentCount: (b.studentCount - studentIds.length).clamp(0, 100));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'id': 'teach-1', 'full_name': 'Mr. Sharma', 'email': 'sharma@example.com'},
      {'id': 'teach-2', 'full_name': 'Dr. Sen', 'email': 'sen@example.com'},
      {'id': 'teach-3', 'full_name': 'Mr. Verma', 'email': 'verma@example.com'},
      {'id': 'teach-4', 'full_name': 'Maj. Singh', 'email': 'singh@example.com'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSubjectsForCourse(String courseId) async {
    return [
      {'id': 'sub-1', 'name': 'Physics'},
      {'id': 'sub-2', 'name': 'Chemistry'},
      {'id': 'sub-3', 'name': 'Mathematics'},
      {'id': 'sub-4', 'name': 'Biology'},
    ];
  }

  @override
  Future<void> assignTeacherToBatch({
    required String batchId,
    required String teacherId,
    required String subjectId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<List<TimetableLectureModel>> fetchTimetable(String batchId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockLectures;
  }

  @override
  Future<void> addLecture(TimetableLectureModel lecture) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockLectures.add(lecture);
  }

  @override
  Future<void> deleteLecture(String lectureId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockLectures.removeWhere((l) => l.id == lectureId);
  }

  @override
  Future<Map<String, dynamic>> fetchAttendanceStats(String batchId) async {
    return {
      'present_today': 18,
      'absent_today': 2,
      'total': 20,
      'attendance_rate': 90.0,
      'weekly_trend': [88.0, 92.0, 90.0, 85.0, 91.0, 90.0],
    };
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceStats(String batchId) async {
    return {
      'average_marks': 72.5,
      'completed_syllabus': 45.0,
      'top_performers': [
        {'name': 'Shubham', 'score': '95%'},
        {'name': 'YASH', 'score': '92%'}
      ],
      'weak_students': [
        {'name': 'Pranav Desai', 'score': '48%'}
      ],
    };
  }
}
