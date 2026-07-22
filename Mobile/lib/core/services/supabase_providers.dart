import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:national_academy/features/batches/data/models/exam_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Returns true if the currently logged-in student has been assigned to at least one batch.
final studentBatchAssignedProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return false;

  // First resolve the student row id from profile_id
  final studentRow = await client
      .from('students')
      .select('id')
      .eq('profile_id', user.id)
      .maybeSingle();

  if (studentRow == null) return false;
  final studentId = studentRow['id'] as String?;
  if (studentId == null) return false;

  // Check if there is at least one batch_enrollments row for this student
  final batchRows = await client
      .from('batch_enrollments')
      .select('id')
      .eq('student_id', studentId)
      .limit(1);

  return (batchRows as List).isNotEmpty;
});

/// Resolves the `students.id` UUID for the currently logged-in student.
final studentIdProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;
  final row = await client
      .from('students')
      .select('id')
      .eq('profile_id', user.id)
      .maybeSingle();
  return row?['id'] as String?;
});

/// Fetches all batch IDs the current student is actively enrolled in.
final studentBatchIdsProvider = FutureProvider<List<String>>((ref) async {
  final studentId = await ref.watch(studentIdProvider.future);
  if (studentId == null) return [];
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('batch_enrollments')
      .select('batch_id')
      .eq('student_id', studentId)
      .eq('status', 'active');
  return (rows as List).map((r) => r['batch_id'] as String).toList();
});

/// A combined DPP feed item — DPP + assignment + attempt status.
class StudentDppFeedItem {
  final String assignmentId;
  final String dppId;
  final String title;
  final String examType;
  final String subjectName;
  final String chapterName;
  final String difficulty;
  final int questionCount;
  final int timeMinutes;
  final int totalMarks;
  final DateTime scheduledAt;
  final DateTime? dueAt;
  final bool isAttempted;
  final double scorePercent; // 0–100, 0 if not attempted

  const StudentDppFeedItem({
    required this.assignmentId,
    required this.dppId,
    required this.title,
    required this.examType,
    required this.subjectName,
    required this.chapterName,
    required this.difficulty,
    required this.questionCount,
    required this.timeMinutes,
    required this.totalMarks,
    required this.scheduledAt,
    this.dueAt,
    required this.isAttempted,
    required this.scorePercent,
  });
}

/// Fetches published DPPs assigned to the student's batches (or directly to the student),
/// and enriches each with attempt status from dpp_attempts + dpp_results.
final studentDppFeedProvider = FutureProvider<List<StudentDppFeedItem>>((ref) async {
  final studentId = await ref.watch(studentIdProvider.future);
  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (studentId == null) return [];

  final client = ref.watch(supabaseClientProvider);

  // Fetch all assignments where:
  // - assignee_type = 'batch' AND batch_id IN student's batches
  // - OR assignee_type = 'individual' AND student_id = studentId
  // Also join dpps for full DPP info (only status = published)
  var query = client.from('dpp_assignments').select('''
        id,
        dpp_id,
        assignee_type,
        batch_id,
        student_id,
        scheduled_at,
        due_at,
        dpps (
          id,
          title,
          exam_type,
          chapter_name,
          difficulty,
          config_questions,
          config_time_minutes,
          config_total_marks,
          status,
          subjects ( name )
        ),
        dpp_attempts (
          id,
          student_id,
          submitted_at,
          dpp_results ( score, total_questions )
        )
      ''');

  if (batchIds.isNotEmpty) {
    query = query.or('student_id.eq.$studentId,batch_id.in.(${batchIds.join(',')})');
  } else {
    query = query.eq('student_id', studentId);
  }

  final List<dynamic> rows = await query
      .order('scheduled_at', ascending: false);

  final items = <StudentDppFeedItem>[];
  for (final row in rows) {
    final dpp = row['dpps'] as Map<String, dynamic>?;
    if (dpp == null) continue;

    // Client-side filter: only show published DPPs to students
    if (dpp['status'] != 'published') continue;


    // Resolve subject name
    final subjectName = (dpp['subjects'] != null)
        ? (dpp['subjects']['name'] as String? ?? 'General')
        : 'General';

    // Find this student's attempt (if any)
    final attempts = (row['dpp_attempts'] as List?) ?? [];
    final myAttempt = attempts.firstWhere(
      (a) => a['student_id'] == studentId && a['submitted_at'] != null,
      orElse: () => null,
    );

    double scorePercent = 0.0;
    if (myAttempt != null) {
      final results = (myAttempt['dpp_results'] as List?) ?? [];
      if (results.isNotEmpty) {
        final res = results.first;
        final score = (res['score'] as num?)?.toDouble() ?? 0;
        final total = (res['total_questions'] as num?)?.toDouble() ?? 1;
        scorePercent = (score / total) * 100;
      }
    }

    items.add(StudentDppFeedItem(
      assignmentId: row['id'] as String,
      dppId: dpp['id'] as String,
      title: dpp['title'] as String? ?? 'Untitled DPP',
      examType: dpp['exam_type'] as String? ?? '',
      subjectName: subjectName,
      chapterName: dpp['chapter_name'] as String? ?? '',
      difficulty: dpp['difficulty'] as String? ?? 'Medium',
      questionCount: (dpp['config_questions'] as num?)?.toInt() ?? 0,
      timeMinutes: (dpp['config_time_minutes'] as num?)?.toInt() ?? 0,
      totalMarks: (dpp['config_total_marks'] as num?)?.toInt() ?? 0,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      dueAt: row['due_at'] != null ? DateTime.tryParse(row['due_at'] as String) : null,
      isAttempted: myAttempt != null,
      scorePercent: scorePercent,
    ));
  }
  return items;
});

/// Fetches the next scheduled lecture for the current student's active batches.
final AutoDisposeFutureProvider<Map<String, String>?> studentUpcomingLectureProvider = FutureProvider.autoDispose<Map<String, String>?>((ref) async {
  ref.watch(timetableSubscriptionProvider);
  final studentId = await ref.watch(studentIdProvider.future);
  if (studentId == null) return null;

  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return null;

  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    final rows = await client
        .from('timetable')
        .select('*, subjects(name), profiles:teacher_id(full_name)')
        .inFilter('batch_id', batchIds)
        .gte('lecture_date', todayStr)
        .order('lecture_date', ascending: true)
        .order('start_time', ascending: true)
        .limit(5);

    if ((rows as List).isEmpty) return null;
    final list = (rows as List).cast<Map<String, dynamic>>();
    final row = list.firstWhere(
      (r) => (r['is_cancelled'] as bool? ?? false) == false,
      orElse: () => list.first,
    );

    final isCancelled = row['is_cancelled'] as bool? ?? false;
    final sub = row['subjects'] as Map<String, dynamic>?;
    final prof = row['profiles'] as Map<String, dynamic>?;

    final subject = sub != null ? sub['name'] as String? ?? 'General' : 'General';
    final teacher = prof != null ? prof['full_name'] as String? ?? 'Teacher' : 'Teacher';
    final classroom = row['room'] as String? ?? 'Room 101';
    final startTime = row['start_time'] as String? ?? '';
    final endTime = row['end_time'] as String? ?? '';
    final lectureDate = row['lecture_date'] as String? ?? '';

    String formatTime(String timeStr) {
      if (timeStr.isEmpty) return '';
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final min = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {}
      return timeStr;
    }

    final formattedStartTime = formatTime(startTime);
    final formattedEndTime = formatTime(endTime);

    String countdownLabel = '';
    String formattedDate = '';
    if (lectureDate.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(lectureDate);
        final diffDays = DateTime(parsedDate.year, parsedDate.month, parsedDate.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        if (diffDays == 0) {
          countdownLabel = 'Today';
        } else if (diffDays == 1) {
          countdownLabel = 'Tomorrow';
        } else {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          countdownLabel = '${parsedDate.day} ${months[parsedDate.month - 1]}';
        }
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        formattedDate = '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
      } catch (_) {}
    }

    return {
      'subject': subject,
      'topic': 'Scheduled Class Lecture',
      'teacher': teacher,
      'classroom': classroom,
      'startTime': formattedStartTime,
      'endTime': formattedEndTime,
      'countdownLabel': countdownLabel,
      'date': formattedDate,
      'isCancelled': isCancelled ? 'true' : 'false',
    };
  } catch (e) {
    return null;
  }
});

final AutoDisposeFutureProvider<List<Map<String, String>>> studentUpcomingLecturesProvider = FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  ref.watch(timetableSubscriptionProvider);
  final studentId = await ref.watch(studentIdProvider.future);
  if (studentId == null) return [];

  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return [];

  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    final rows = await client
        .from('timetable')
        .select('*, subjects(name), profiles:teacher_id(full_name)')
        .inFilter('batch_id', batchIds)
        .gte('lecture_date', todayStr)
        .order('lecture_date', ascending: true)
        .order('start_time', ascending: true);

    if ((rows as List).isEmpty) return [];

    String formatTime(String timeStr) {
      if (timeStr.isEmpty) return '';
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final min = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {}
      return timeStr;
    }

    return (rows as List).map((row) {
      final isCancelled = row['is_cancelled'] as bool? ?? false;
      final sub = row['subjects'] as Map<String, dynamic>?;
      final prof = row['profiles'] as Map<String, dynamic>?;

      final subject = sub != null ? sub['name'] as String? ?? 'General' : 'General';
      final teacher = prof != null ? prof['full_name'] as String? ?? 'Teacher' : 'Teacher';
      final classroom = row['room'] as String? ?? 'Room 101';
      final startTime = row['start_time'] as String? ?? '';
      final endTime = row['end_time'] as String? ?? '';
      final lectureDate = row['lecture_date'] as String? ?? '';

      final formattedStartTime = formatTime(startTime);
      final formattedEndTime = formatTime(endTime);

      String countdownLabel = '';
      String formattedDate = '';
      if (lectureDate.isNotEmpty) {
        try {
          final parsedDate = DateTime.parse(lectureDate);
          final diffDays = DateTime(parsedDate.year, parsedDate.month, parsedDate.day)
              .difference(DateTime(now.year, now.month, now.day))
              .inDays;
          if (diffDays == 0) {
            countdownLabel = 'Today';
          } else if (diffDays == 1) {
            countdownLabel = 'Tomorrow';
          } else {
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            countdownLabel = '${parsedDate.day} ${months[parsedDate.month - 1]}';
          }
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          formattedDate = '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
        } catch (_) {}
      }

      return {
        'subject': subject,
        'topic': 'Scheduled Class Lecture',
        'teacher': teacher,
        'classroom': classroom,
        'startTime': formattedStartTime,
        'endTime': formattedEndTime,
        'countdownLabel': countdownLabel,
        'date': formattedDate,
        'isCancelled': isCancelled ? 'true' : 'false',
      };
    }).toList();
  } catch (e) {
    return [];
  }
});

/// A provider that listens to real-time changes in the timetable table
/// and invalidates the upcoming lecture providers to reflect the changes immediately.
final timetableSubscriptionProvider = Provider.autoDispose<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final channel = client.channel('public:timetable').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'timetable',
    callback: (payload) {
      ref.invalidate(studentUpcomingLectureProvider);
      ref.invalidate(studentUpcomingLecturesProvider);
      ref.invalidate(studentLiveLectureProvider);
      ref.invalidate(studentLectureAlertProvider);
    },
  );
  channel.subscribe();
  ref.onDispose(() {
    client.removeChannel(channel);
  });
});

/// Fetches the live/active lecture happening right now for the current student's active batches.
final studentLiveLectureProvider = FutureProvider<Map<String, String>?>((ref) async {
  // Re-evaluate every 30 seconds to handle boundary changes of lecture times
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final studentId = await ref.watch(studentIdProvider.future);
  if (studentId == null) return null;

  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return null;

  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  // Format current time as HH:MM:SS
  final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

  try {
    final rows = await client
        .from('timetable')
        .select('*, subjects(name), profiles:teacher_id(full_name)')
        .inFilter('batch_id', batchIds)
        .eq('lecture_date', todayStr)
        .lte('start_time', timeStr)
        .gte('end_time', timeStr)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    final row = rows.first;
    
    final sub = row['subjects'] as Map<String, dynamic>?;
    final prof = row['profiles'] as Map<String, dynamic>?;
    
    final subject = sub != null ? sub['name'] as String? ?? 'General' : 'General';
    final teacher = prof != null ? prof['full_name'] as String? ?? 'Teacher' : 'Teacher';
    final classroom = row['room'] as String? ?? 'Room 101';
    final startTime = row['start_time'] as String? ?? '';
    final endTime = row['end_time'] as String? ?? '';
    
    String formatTime(String timeStr) {
      if (timeStr.isEmpty) return '';
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final min = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {}
      return timeStr;
    }
    
    final formattedStartTime = formatTime(startTime);
    final formattedEndTime = formatTime(endTime);
    
    return {
      'subject': subject,
      'topic': 'Active Class Lecture',
      'teacher': teacher,
      'classroom': classroom,
      'startTime': formattedStartTime,
      'endTime': formattedEndTime,
    };
  } catch (e) {
    return null;
  }
});

/// Fetches the live/active or starting soon (<= 5 mins) lecture alert map for the student.
final studentLectureAlertProvider = FutureProvider<Map<String, String>?>((ref) async {
  // Re-evaluate every 30 seconds to handle boundary changes of lecture times
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final studentId = await ref.watch(studentIdProvider.future);
  if (studentId == null) return null;

  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return null;

  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    // Query all lectures for today
    final rows = await client
        .from('timetable')
        .select('*, subjects(name), profiles:teacher_id(full_name)')
        .inFilter('batch_id', batchIds)
        .eq('lecture_date', todayStr);

    if ((rows as List).isEmpty) return null;

    String formatTime(String timeStr) {
      if (timeStr.isEmpty) return '';
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final min = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {}
      return timeStr;
    }

    for (final row in rows) {
      final startTime = row['start_time'] as String? ?? '';
      final endTime = row['end_time'] as String? ?? '';
      if (startTime.isEmpty || endTime.isEmpty) continue;

      try {
        final partsStart = startTime.split(':');
        final partsEnd = endTime.split(':');
        final startDateTime = DateTime(now.year, now.month, now.day, int.parse(partsStart[0]), int.parse(partsStart[1]));
        final endDateTime = DateTime(now.year, now.month, now.day, int.parse(partsEnd[0]), int.parse(partsEnd[1]));

        final sub = row['subjects'] as Map<String, dynamic>?;
        final prof = row['profiles'] as Map<String, dynamic>?;
        final subject = sub != null ? sub['name'] as String? ?? 'General' : 'General';
        final teacher = prof != null ? prof['full_name'] as String? ?? 'Teacher' : 'Teacher';
        final classroom = row['room'] as String? ?? 'Room 101';
        final formattedStartTime = formatTime(startTime);
        final formattedEndTime = formatTime(endTime);

        if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
          // Live now
          return {
            'status': 'live',
            'subject': subject,
            'topic': 'Active Class Lecture',
            'teacher': teacher,
            'classroom': classroom,
            'startTime': formattedStartTime,
            'endTime': formattedEndTime,
          };
        } else if (now.isBefore(startDateTime)) {
          final diffMin = startDateTime.difference(now).inMinutes;
          final diffSec = startDateTime.difference(now).inSeconds;
          if (diffSec >= 0 && diffSec <= 300) { // 5 minutes = 300 seconds
            // Starting soon (in <= 5 minutes)
            return {
              'status': 'starting_soon',
              'minutes': diffMin.toString(),
              'subject': subject,
              'topic': diffSec <= 30 ? 'Starting Right Now' : 'Starts in $diffMin minutes',
              'teacher': teacher,
              'classroom': classroom,
              'startTime': formattedStartTime,
              'endTime': formattedEndTime,
            };
          }
        }
      } catch (_) {}
    }
  } catch (e) {
    return null;
  }
  return null;
});

/// Fetches the student's full name from the profiles table.
final studentProfileNameProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  final res = await client
      .from('profiles')
      .select('full_name')
      .eq('id', user.id)
      .maybeSingle();

  return res?['full_name'] as String?;
});

/// Details model for the student's enrolled batch
class StudentEnrolledBatch {
  final String id;
  final String name;
  final String classLevel;
  final String examType;

  const StudentEnrolledBatch({
    required this.id,
    required this.name,
    required this.classLevel,
    required this.examType,
  });

  String get formattedClassAndExam {
    final level = classLevel.isEmpty
        ? ''
        : (classLevel.toLowerCase().contains('th') ? classLevel : '${classLevel}th');
    if (level.isNotEmpty && examType.isNotEmpty) {
      return '$level • $examType';
    } else if (level.isNotEmpty) {
      return level;
    } else if (examType.isNotEmpty) {
      return examType;
    }
    return '';
  }
}

/// Fetches details of the batch the current student is actively enrolled in.
final studentEnrolledBatchProvider = FutureProvider<StudentEnrolledBatch?>((ref) async {
  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return null;

  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('batches')
      .select('id, name, class_level, exam_type')
      .eq('id', batchIds.first)
      .maybeSingle();

  if (res == null) return null;

  return StudentEnrolledBatch(
    id: res['id'] as String? ?? '',
    name: res['name'] as String? ?? '',
    classLevel: res['class_level'] as String? ?? '',
    examType: res['exam_type'] as String? ?? '',
  );
});

/// Real-time subscription to tests & exams tables to auto-refresh student providers immediately.
final AutoDisposeProvider<void> testsSubscriptionProvider = Provider.autoDispose<void>((ref) {
  final client = ref.watch(supabaseClientProvider);

  final channelTests = client.channel('public:tests_realtime').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'tests',
    callback: (payload) {
      ref.invalidate(studentUpcomingTestProvider);
      ref.invalidate(studentExamsListProvider);
    },
  );
  channelTests.subscribe();

  final channelExams = client.channel('public:exams_realtime').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'exams',
    callback: (payload) {
      ref.invalidate(studentUpcomingTestProvider);
      ref.invalidate(studentExamsListProvider);
    },
  );
  channelExams.subscribe();

  ref.onDispose(() {
    client.removeChannel(channelTests);
    client.removeChannel(channelExams);
  });
});

/// Fetches all active & cancelled exams/tests for the student's batches.
final AutoDisposeFutureProvider<List<ExamModel>> studentExamsListProvider = FutureProvider.autoDispose<List<ExamModel>>((ref) async {
  ref.watch(testsSubscriptionProvider);
  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return [];

  final client = ref.watch(supabaseClientProvider);
  try {
    final res = await client
        .from('tests')
        .select('*, subjects(name)')
        .inFilter('batch_id', batchIds)
        .order('test_date', ascending: true);

    if ((res as List).isNotEmpty) {
      return (res as List).map((json) {
        final Map<String, dynamic> adaptedJson = Map<String, dynamic>.from(json);
        adaptedJson['name'] = json['title'] ?? json['name'] ?? '';
        adaptedJson['exam_date'] = json['test_date'] ?? json['exam_date'] ?? '';
        adaptedJson['exam_time'] = json['timing'] ?? json['exam_time'] ?? '';
        adaptedJson['max_marks'] = json['total_marks'] ?? json['max_marks'] ?? 100;
        return ExamModel.fromJson(adaptedJson);
      }).toList();
    }
  } catch (_) {}

  try {
    final res = await client
        .from('exams')
        .select('*, subjects(name)')
        .inFilter('batch_id', batchIds)
        .order('exam_date', ascending: true);
    return (res as List).map((json) => ExamModel.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

/// Fetches the next upcoming test scheduled (or cancelled test) for any of the student's active batches.
final AutoDisposeFutureProvider<Map<String, String>?> studentUpcomingTestProvider = FutureProvider.autoDispose<Map<String, String>?>((ref) async {
  ref.watch(testsSubscriptionProvider);
  final batchIds = await ref.watch(studentBatchIdsProvider.future);
  if (batchIds.isEmpty) return null;

  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    // 1. Primary Source: Query 'tests' table
    final testRows = await client
        .from('tests')
        .select('*, subjects(name)')
        .inFilter('batch_id', batchIds)
        .gte('test_date', todayStr)
        .order('test_date', ascending: true)
        .limit(5);

    if ((testRows as List).isNotEmpty) {
      final list = (testRows as List).cast<Map<String, dynamic>>();
      final selectedTest = list.firstWhere(
        (t) => (t['is_cancelled'] as bool? ?? false) == false,
        orElse: () => list.first,
      );

      final title = selectedTest['title'] as String? ?? selectedTest['name'] as String? ?? 'Scheduled Test';
      final testDateStr = selectedTest['test_date'] as String? ?? selectedTest['exam_date'] as String? ?? '';
      final timing = selectedTest['timing'] as String? ?? selectedTest['exam_time'] as String? ?? '10:00 AM';
      final marks = selectedTest['total_marks'] ?? selectedTest['max_marks'] ?? 100;
      final isCancelled = selectedTest['is_cancelled'] as bool? ?? false;
      final subMap = selectedTest['subjects'] as Map<String, dynamic>?;
      final subject = subMap?['name'] as String? ?? 'General';

      final testDate = DateTime.tryParse(testDateStr) ?? now;
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final testMidnight = DateTime(testDate.year, testDate.month, testDate.day);
      final diffDays = testMidnight.difference(todayMidnight).inDays;
      final daysLeft = diffDays < 0 ? 0 : diffDays;

      String formattedDate = '';
      if (testMidnight == todayMidnight) {
        formattedDate = 'Today';
      } else if (testMidnight == todayMidnight.add(const Duration(days: 1))) {
        formattedDate = 'Tomorrow';
      } else {
        formattedDate = '${testDate.day}/${testDate.month}/${testDate.year}';
      }

      return {
        'subject': subject,
        'topic': title.isEmpty ? 'Scheduled Test' : title,
        'date': formattedDate,
        'daysLeft': daysLeft.toString(),
        'time': timing.isEmpty ? '10:00 AM' : timing,
        'duration': 'Test',
        'marks': '$marks',
        'isCancelled': isCancelled ? 'true' : 'false',
        'status': isCancelled ? 'Test Cancelled' : 'Upcoming',
      };
    }
  } catch (_) {}

  try {
    // 2. Secondary Source: Query 'exams' table
    final examRows = await client
        .from('exams')
        .select('*, subjects(name)')
        .inFilter('batch_id', batchIds)
        .gte('exam_date', todayStr)
        .order('exam_date', ascending: true)
        .limit(5);

    if ((examRows as List).isNotEmpty) {
      final list = (examRows as List).cast<Map<String, dynamic>>();
      final selectedExamJson = list.firstWhere(
        (t) => (t['is_cancelled'] as bool? ?? false) == false,
        orElse: () => list.first,
      );
      final exam = ExamModel.fromJson(selectedExamJson);

      final examDate = DateTime.tryParse(exam.examDate) ?? now;
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final examMidnight = DateTime(examDate.year, examDate.month, examDate.day);
      final diffDays = examMidnight.difference(todayMidnight).inDays;
      final daysLeft = diffDays < 0 ? 0 : diffDays;

      String formattedDate = '';
      if (examMidnight == todayMidnight) {
        formattedDate = 'Today';
      } else if (examMidnight == todayMidnight.add(const Duration(days: 1))) {
        formattedDate = 'Tomorrow';
      } else {
        formattedDate = '${examDate.day}/${examDate.month}/${examDate.year}';
      }

      return {
        'subject': exam.subjectName,
        'topic': exam.name.isEmpty ? 'Scheduled Exam' : exam.name,
        'date': formattedDate,
        'daysLeft': daysLeft.toString(),
        'time': exam.examTime.isEmpty ? '10:00 AM' : exam.examTime,
        'duration': 'Exam',
        'marks': '${exam.maxMarks}',
        'isCancelled': exam.isCancelled ? 'true' : 'false',
        'status': exam.isCancelled ? 'Test Cancelled' : 'Upcoming',
      };
    }
  } catch (_) {}

  try {
    // 3. Fallback: check dpp_assignments where title/type is test
    final dppRows = await client
        .from('dpp_assignments')
        .select('*, dpps(*)')
        .inFilter('batch_id', batchIds)
        .gte('scheduled_at', todayStr)
        .order('scheduled_at', ascending: true)
        .limit(5);

    for (final row in (dppRows as List)) {
      final dpp = row['dpps'] as Map<String, dynamic>?;
      final title = dpp?['title'] as String? ?? '';
      final examType = dpp?['exam_type'] as String? ?? '';
      if (title.toLowerCase().contains('test') || title.toLowerCase().contains('exam') || examType.toLowerCase().contains('test')) {
        final scheduledAtStr = row['scheduled_at'] as String? ?? '';
        final scheduledAt = DateTime.tryParse(scheduledAtStr) ?? now;
        final diffDays = scheduledAt.difference(now).inDays;
        final daysLeft = diffDays < 0 ? 0 : diffDays;

        String formattedDate = '';
        if (scheduledAt.day == now.day) {
          formattedDate = 'Today';
        } else if (scheduledAt.day == now.day + 1) {
          formattedDate = 'Tomorrow';
        } else {
          formattedDate = '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}';
        }

        return {
          'subject': dpp?['subject'] as String? ?? 'Batch Test',
          'topic': title,
          'date': formattedDate,
          'daysLeft': daysLeft.toString(),
          'time': '10:00 AM',
          'duration': '${dpp?['time_minutes'] ?? 180} mins',
          'marks': '${dpp?['total_marks'] ?? 100}',
        };
      }
    }
  } catch (_) {}

  return null;
});

class StudentFullProfileData {
  final String name;
  final String email;
  final String phone;
  final String parentPhone;
  final String rollNo;
  final String registeredClass;
  final String targetExams;
  final String status;

  const StudentFullProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.parentPhone,
    required this.rollNo,
    required this.registeredClass,
    required this.targetExams,
    required this.status,
  });
}

/// Fetches full student profile details from students & profiles table in Supabase.
final studentFullProfileProvider = FutureProvider<StudentFullProfileData?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  try {
    final studentData = await client
        .from('students')
        .select('*')
        .or('profile_id.eq.${user.id},auth_user_id.eq.${user.id}')
        .maybeSingle();

    final profileData = await client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    final name = (studentData?['full_name'] as String?)?.trim().isNotEmpty == true
        ? studentData!['full_name'] as String
        : (profileData?['full_name'] as String?)?.trim().isNotEmpty == true
            ? profileData!['full_name'] as String
            : user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'Student';

    final email = studentData?['email'] as String? ?? user.email ?? '';
    final phone = studentData?['phone'] as String? ?? user.phone ?? 'Not provided';
    final parentPhone = studentData?['parent_phone'] as String? ?? 'Not provided';
    
    final idStr = studentData?['id']?.toString() ?? user.id;
    final rollNo = studentData?['roll_no'] as String? ??
        'NA-${idStr.substring(0, math.min(8, idStr.length)).toUpperCase()}';

    final regClass = studentData?['registered_class'] as String? ??
        studentData?['class_level'] as String? ??
        '12th';

    final targetExam = studentData?['target_exam'] as String? ??
        studentData?['target_exams'] as String? ??
        'JEE / NEET';

    final status = studentData?['status'] as String? ?? 'Active';

    return StudentFullProfileData(
      name: name,
      email: email,
      phone: phone,
      parentPhone: parentPhone,
      rollNo: rollNo,
      registeredClass: regClass,
      targetExams: targetExam,
      status: status,
    );
  } catch (e) {
    final name = user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'Student';
    return StudentFullProfileData(
      name: name,
      email: user.email ?? '',
      phone: user.phone ?? 'Not provided',
      parentPhone: 'Not provided',
      rollNo: 'NA-${user.id.substring(0, math.min(8, user.id.length)).toUpperCase()}',
      registeredClass: '12th',
      targetExams: 'JEE / NEET',
      status: 'Active',
    );
  }
});





