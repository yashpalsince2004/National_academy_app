import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

