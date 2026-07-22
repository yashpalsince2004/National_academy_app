import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../batches/presentation/controllers/batch_controller.dart';
import '../../../batches/presentation/controllers/batch_detail_controller.dart';
import '../../../batches/data/models/batch_model.dart';
import '../../../batches/data/models/timetable_lecture_model.dart';
import '../../../batches/data/models/exam_model.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String? _selectedBatchId;

  // Overrideable lecture data (editable by admin)
  String _lectureSubject = 'Physics — Chapter 12';
  String _lectureTeacher = 'Mr. R. Sharma';
  String _lectureStartTime = '09:00 AM';
  String _lectureEndTime = '10:30 AM';
  final String _lectureDayOfWeek = 'Monday';
  String _lectureRoom = 'Room 101';
  String? _lectureDate = '2026-07-16';

  String _getTodayFormatted() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${now.day} ${months[now.month - 1]} ${now.year}";
  }

  String _formatDbDateToDisplay(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _getStartTimeOnly(String timeStr) {
    if (timeStr.isEmpty) return timeStr;
    final splitters = [' - ', ' – ', '-'];
    for (final splitter in splitters) {
      if (timeStr.contains(splitter)) {
        return timeStr.split(splitter).first.trim();
      }
    }
    return timeStr;
  }

  String _formatDisplayDateToDb(String displayDate) {
    try {
      final parts = displayDate.split(' ');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months.indexOf(monthStr) + 1;
        if (month > 0) {
          return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
        }
      }
    } catch (_) {}
    return displayDate;
  }

  DateTime? _parseDisplayDate(String displayDate) {
    try {
      final dbStr = _formatDisplayDateToDb(displayDate);
      return DateTime.parse(dbStr);
    } catch (_) {
      return null;
    }
  }

  Future<String> _getSubjectId(String name) async {
    try {
      final client = Supabase.instance.client;
      final res = await client.from('subjects').select('id, name');
      for (final row in res as List) {
        final sName = row['name'] as String;
        if (sName.toLowerCase().contains(name.toLowerCase())) {
          return row['id'] as String;
        }
      }
    } catch (_) {}
    switch (name.toLowerCase()) {
      case 'physics':
        return 'deadaaa2-158c-4741-bb3a-99551f555a44';
      case 'chemistry':
        return '0039f38c-67e5-48d6-8e00-37975b1721d5';
      case 'mathematics':
      case 'maths':
        return '01cac33b-9478-49a0-aaa1-341face0da54';
      case 'biology':
        return '000e59e1-8115-4584-b89e-977b63dd4878';
      default:
        return 'deadaaa2-158c-4741-bb3a-99551f555a44';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final batchesAsync = ref.watch(batchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: batchesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading batches: $err',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        data: (batches) {
          if (batches.isEmpty) {
            return _EmptyBatchesView(isDark: isDark);
          }

          if (_selectedBatchId == null ||
              !batches.any((b) => b.id == _selectedBatchId)) {
            _selectedBatchId = batches.first.id;
          }

          final activeBatch =
              batches.firstWhere((b) => b.id == _selectedBatchId);
          final batchDetails =
              ref.watch(batchDetailControllerProvider(_selectedBatchId!));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _GreetingSection(isDark: isDark, activeBatchName: activeBatch.name),
                const SizedBox(height: 20),
                _BatchSelectorCard(
                  activeBatch: activeBatch,
                  isDark: isDark,
                  onTap: () => _showBatchSelector(context, batches),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.calendar_month_rounded,
                        bgIcon: Icons.menu_book_rounded,
                        label: 'Schedule\nLecture',
                        description: "Create today's class",
                        accentColor: AppColors.primary,
                        isDark: isDark,
                        onTap: () => _showScheduleLectureDialog(
                            context, _selectedBatchId!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.assignment_rounded,
                        bgIcon: Icons.assignment_turned_in_rounded,
                        label: 'Schedule\nTest',
                        description: 'Create new exam',
                        accentColor: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () =>
                            _showScheduleTestDialog(context, activeBatch),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildUpcomingLectureCard(context, batchDetails, isDark),
                const SizedBox(height: 20),
                _buildUpcomingTestCard(context, batchDetails, isDark, activeBatch.id),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingLectureCard(
      BuildContext context, BatchDetailState details, bool isDark) {
    if (details.isLoading) {
      return _UpcomingLectureCard(
        isDark: isDark,
        isLoading: true,
        subject: '',
        teacher: '',
        startTime: '',
        endTime: '',
        dayOfWeek: '',
        room: '',
      );
    }

    final activeLectures = details.lectures.where((l) => !l.isCancelled).toList();
    final cardWidth = (MediaQuery.of(context).size.width - 42) / 2;

    if (activeLectures.isNotEmpty) {
      final lectureContent = activeLectures.length == 1
          ? SizedBox(
              width: cardWidth,
              child: _UpcomingLectureCard(
                isDark: isDark,
                isLoading: false,
                subject: activeLectures.first.subjectName,
                teacher: activeLectures.first.teacherName,
                startTime: activeLectures.first.startTime,
                endTime: activeLectures.first.endTime,
                dayOfWeek: activeLectures.first.dayOfWeek,
                room: activeLectures.first.room,
                lectureDate: activeLectures.first.lectureDate,
                onEdit: () => _showEditLectureDialog(
                  context,
                  batchId: _selectedBatchId,
                  lectureId: activeLectures.first.id,
                  subject: activeLectures.first.subjectName,
                  teacher: activeLectures.first.teacherName,
                  startTime: activeLectures.first.startTime,
                  endTime: activeLectures.first.endTime,
                  lectureDate: activeLectures.first.lectureDate,
                  room: activeLectures.first.room,
                ),
              ),
            )
          : SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: activeLectures.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final lecture = activeLectures[index];
                  return SizedBox(
                    width: cardWidth,
                    child: _UpcomingLectureCard(
                      isDark: isDark,
                      isLoading: false,
                      subject: lecture.subjectName,
                      teacher: lecture.teacherName,
                      startTime: lecture.startTime,
                      endTime: lecture.endTime,
                      dayOfWeek: lecture.dayOfWeek,
                      room: lecture.room,
                      lectureDate: lecture.lectureDate,
                      onEdit: () => _showEditLectureDialog(
                        context,
                        batchId: _selectedBatchId,
                        lectureId: lecture.id,
                        subject: lecture.subjectName,
                        teacher: lecture.teacherName,
                        startTime: lecture.startTime,
                        endTime: lecture.endTime,
                        lectureDate: lecture.lectureDate,
                        room: lecture.room,
                      ),
                    ),
                  );
                },
              ),
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Lectures (${activeLectures.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_selectedBatchId != null && _selectedBatchId!.isNotEmpty) {
                      context.push('/admin/batch/$_selectedBatchId');
                    }
                  },
                  child: const Row(
                    children: [
                      Text(
                        'All Lectures',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          lectureContent,
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 40,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming lecture',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTestCard(BuildContext context, BatchDetailState details, bool isDark, String batchId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final upcomingExams = details.exams.where((e) {
      if (e.isCancelled) return false;
      try {
        final date = DateTime.parse(e.examDate);
        final examDay = DateTime(date.year, date.month, date.day);
        return examDay.isAfter(today) || examDay.isAtSameMomentAs(today);
      } catch (_) {
        return false;
      }
    }).toList();
    
    // Sort upcoming exams: closest date first
    upcomingExams.sort((a, b) => a.examDate.compareTo(b.examDate));

    final cardWidth = (MediaQuery.of(context).size.width - 42) / 2;

    if (upcomingExams.isNotEmpty) {
      if (upcomingExams.length == 1) {
        final exam = upcomingExams.first;
        return SizedBox(
          width: cardWidth,
          child: _UpcomingTestCard(
            isDark: isDark,
            subject: exam.subjectName,
            topic: exam.name,
            date: _formatDbDateToDisplay(exam.examDate),
            time: _getStartTimeOnly(exam.examTime),
            marks: "${exam.maxMarks} Marks",
            isPlaceholder: false,
            onEdit: () => _showEditTestDialog(
              context,
              exam: exam,
              batchId: batchId,
            ),
          ),
        );
      }

      // Horizontal sliding window displaying 2 cards side-by-side per screen view
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Tests (${upcomingExams.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/admin/previous-tests');
                  },
                  child: const Row(
                    children: [
                      Text(
                        'All Tests',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 228,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: upcomingExams.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final exam = upcomingExams[index];
                return SizedBox(
                  width: cardWidth,
                  child: _UpcomingTestCard(
                    isDark: isDark,
                    subject: exam.subjectName,
                    topic: exam.name,
                    date: _formatDbDateToDisplay(exam.examDate),
                    time: _getStartTimeOnly(exam.examTime),
                    marks: "${exam.maxMarks} Marks",
                    isPlaceholder: false,
                    onEdit: () => _showEditTestDialog(
                      context,
                      exam: exam,
                      batchId: batchId,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_rounded,
            size: 40,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming test',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchSelector(BuildContext context, List<BatchModel> batches) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceTile1 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Active Batch',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.ink,
                    letterSpacing: -0.374,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                    color:
                        isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: batches.length,
                    itemBuilder: (ctx, index) {
                      final batch = batches[index];
                      final isSelected = batch.id == _selectedBatchId;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFF5F5F7)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary),
                          ),
                        ),
                        title: Text(
                          batch.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white : AppColors.ink),
                          ),
                        ),
                        subtitle: Text(
                          '${batch.classLevel} • ${batch.examType}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          setState(() => _selectedBatchId = batch.id);
                          Navigator.pop(sheetCtx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Converts DateTime.weekday (1=Mon … 7=Sun) to a full day name.
  String _dayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1).clamp(0, 6)];
  }
  /// Converts a month number (1–12) to an abbreviated month name.
  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  int? _parseTimeToMinutes(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty) return null;

    final isPm = timeStr.contains('PM');
    final isAm = timeStr.contains('AM');

    var cleanStr = timeStr.replaceAll(RegExp(r'[AP]M'), '').trim();
    
    final parts = cleanStr.split(':');
    if (parts.isEmpty) return null;

    try {
      var hour = int.parse(parts[0]);
      var minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime d1, String dateStr) {
    final now = DateTime.now();
    if (dateStr.toLowerCase().trim() == 'today') {
      return d1.year == now.year && d1.month == now.month && d1.day == now.day;
    }
    if (dateStr.toLowerCase().trim() == 'tomorrow') {
      final tom = now.add(const Duration(days: 1));
      return d1.year == tom.year && d1.month == tom.month && d1.day == tom.day;
    }
    try {
      final d2 = DateTime.parse(dateStr);
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (_) {
      final clean = dateStr.replaceAll(',', '').toLowerCase();
      final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3) {
        final monthStr = parts[0];
        final dayVal = int.tryParse(parts[1]);
        final yearVal = int.tryParse(parts[2]);

        const months = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
        const shortMonths = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        
        var m = months.indexOf(monthStr) + 1;
        if (m == 0) m = shortMonths.indexOf(monthStr) + 1;

        if (dayVal != null && yearVal != null && m > 0) {
          return d1.year == yearVal && d1.month == m && d1.day == dayVal;
        }
      }
    }
    return false;
  }

  void _showScheduleLectureDialog(
      BuildContext context, String batchId) {
    // Force a reload of the batch details to get fresh teacher/subject data
    ref.read(batchDetailControllerProvider(batchId).notifier).loadAllDetails();

    final roomController = TextEditingController(text: 'Room 101');
    final startTimeController = TextEditingController(text: '09:00 AM');
    final endTimeController = TextEditingController(text: '10:30 AM');

    String selectedSubject = '';
    String selectedTeacherName = '';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? dialogError;
        return Consumer(
          builder: (context, ref, child) {
            final details = ref.watch(batchDetailControllerProvider(batchId));
            final batchesState = ref.watch(batchControllerProvider);
            final batches = batchesState.valueOrNull ?? [];
            final currentBatch = batches.firstWhere(
              (b) => b.id == batchId,
              orElse: () => BatchModel(
                id: '',
                courseId: '',
                name: '',
                capacity: 0,
                examType: '',
                classLevel: '',
                medium: '',
                lectureDays: const [],
                status: '',
              ),
            );

            return StatefulBuilder(
              builder: (context, setState) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                // Generate list of subject options dynamically from the teachers list
                final subjectOptions = {'Physics', 'Chemistry', 'Mathematics', 'Biology', 'Other'};
                if (currentBatch.name.toLowerCase() == 'veera' || currentBatch.examType.toUpperCase() == 'JEE') {
                  subjectOptions.remove('Biology');
                }
                 for (final t in details.teachers) {
                  final s = t['subject'] as String?;
                  if (s != null && s.isNotEmpty) {
                    final subs = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                    for (final sub in subs) {
                      if (sub.toLowerCase() == 'maths' || sub.toLowerCase() == 'mathematics') {
                        subjectOptions.add('Mathematics');
                      } else {
                        subjectOptions.add(sub[0].toUpperCase() + sub.substring(1).toLowerCase());
                      }
                    }
                  }
                }
                final subjectList = subjectOptions.toList();

                final subjectItems = [
                  AppDropdownItem(value: '', label: 'Select Subject'),
                  ...subjectList.map((s) => AppDropdownItem(value: s, label: s)),
                ];

                // Filter teachers based on selected subject
                final filteredTeachers = details.teachers.where((t) {
                  if (selectedSubject.isEmpty) return false;
                  final teacherSubjects = (t['subject'] as String? ?? '')
                      .toLowerCase()
                      .split(',')
                      .map((s) => s.trim())
                      .toList();
                  final selSub = selectedSubject.toLowerCase();
                  if (selSub == 'maths' || selSub == 'mathematics') {
                    return teacherSubjects.contains('maths') || teacherSubjects.contains('mathematics');
                  }
                  return teacherSubjects.contains(selSub);
                }).toList();

                // If the selected teacher is no longer in the filtered list, reset it
                if (selectedTeacherName.isNotEmpty &&
                    !filteredTeachers.any((t) => (t['full_name'] as String? ?? '') == selectedTeacherName)) {
                  selectedTeacherName = '';
                }

                final List<AppDropdownItem<String>> teacherItems;
                if (selectedSubject.isEmpty) {
                  teacherItems = [
                    AppDropdownItem(value: '', label: 'Choose Subject First'),
                  ];
                } else if (filteredTeachers.isEmpty) {
                  teacherItems = [
                    AppDropdownItem(value: '', label: 'No Teachers Found'),
                  ];
                } else {
                  teacherItems = [
                    AppDropdownItem(value: '', label: 'Select Teacher'),
                    ...filteredTeachers.map((t) {
                      final name = t['full_name'] as String? ?? 'Unknown';
                      return AppDropdownItem(value: name, label: name);
                    }),
                  ];
                }

                return AlertDialog(
                  backgroundColor: isDark ? AppColors.surfaceTile1 : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  title: Text(
                    'Schedule Lecture',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subject Dropdown
                        AppDropdown<String>(
                          value: selectedSubject,
                          hintText: 'Select Subject',
                          items: subjectItems,
                          onChanged: (val) {
                            setState(() {
                              selectedSubject = val;
                              selectedTeacherName = ''; // Reset teacher on subject change
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Teacher Dropdown
                        AppDropdown<String>(
                          value: selectedTeacherName,
                          hintText: selectedSubject.isEmpty 
                              ? 'Choose Subject First' 
                              : filteredTeachers.isEmpty
                                  ? 'No Teachers Found'
                                  : 'Select Teacher',
                          items: teacherItems,
                          onChanged: selectedSubject.isEmpty || filteredTeachers.isEmpty
                              ? (_) {}
                              : (val) {
                                  setState(() {
                                    selectedTeacherName = val;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: roomController,
                          decoration:
                              const InputDecoration(labelText: 'Room Number'),
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.ink),
                        ),
                        const SizedBox(height: 12),
                        // Date Picker Field
                        GestureDetector(
                          onTap: () async {
                            final now = DateTime.now();
                            final tomorrow = now.add(const Duration(days: 1));
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tomorrow,
                              firstDate: tomorrow,
                              lastDate: now.add(const Duration(days: 365)),
                              helpText: 'Select Lecture Date',
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      surface: isDark ? AppColors.surfaceTile1 : Colors.white,
                                      onSurface: isDark ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedDate == null
                                      ? 'Select Date'
                                      : '${_dayName(selectedDate!.weekday)}, ${selectedDate!.day} ${_monthName(selectedDate!.month)} ${selectedDate!.year}',
                                  style: TextStyle(
                                      color: selectedDate == null
                                          ? (isDark
                                              ? Colors.white54
                                              : Colors.black54)
                                          : (isDark
                                              ? Colors.white
                                              : AppColors.ink)),
                                ),
                                Icon(Icons.calendar_today,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.ink),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: startTimeController,
                          decoration:
                              const InputDecoration(labelText: 'Start Time'),
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.ink),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: endTimeController,
                          decoration:
                              const InputDecoration(labelText: 'End Time'),
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.ink),
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dialogError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (selectedSubject.isEmpty || selectedTeacherName.isEmpty) {
                          setState(() {
                            dialogError = 'Please select Subject and Teacher';
                          });
                          return;
                        }
                        if (selectedDate == null) {
                          setState(() {
                            dialogError = 'Please select a lecture date';
                          });
                          return;
                        }

                        // Check conflict with scheduled test in database
                        final batchDetail = ref.read(batchDetailControllerProvider(batchId));
                        for (final exam in batchDetail.exams) {
                          if (exam.isCancelled) continue;
                          final selectedDateStr = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                          if (selectedDateStr == exam.examDate) {
                            final lecStart = _parseTimeToMinutes(startTimeController.text.trim());
                            final lecEnd = _parseTimeToMinutes(endTimeController.text.trim());
                            
                            // Parse exam time range: e.g. "02:00 PM - 03:30 PM"
                            String examStartStr = exam.examTime;
                            String examEndStr = '';
                            if (exam.examTime.contains(' - ')) {
                              final parts = exam.examTime.split(' - ');
                              if (parts.length >= 2) {
                                examStartStr = parts[0];
                                examEndStr = parts[1];
                              }
                            }
                            
                            final testStart = _parseTimeToMinutes(examStartStr);
                            final testEnd = examEndStr.isNotEmpty 
                                ? _parseTimeToMinutes(examEndStr) 
                                : (testStart != null ? testStart + 90 : null);
                            
                            if (lecStart != null && lecEnd != null && testStart != null && testEnd != null) {
                              if (lecStart < testEnd && lecEnd > testStart) {
                                setState(() {
                                  dialogError = 'Time Conflict: This slot overlaps with a scheduled test (${exam.subjectName}: ${exam.examTime}).';
                                });
                                return;
                              }
                            }
                          }
                        }

                        try {
                          setState(() {
                            dialogError = null;
                          });
                          await ref
                              .read(
                                  batchDetailControllerProvider(batchId).notifier)
                              .addLecture(
                                subjectName: selectedSubject,
                                teacherName: selectedTeacherName,
                                room: roomController.text.trim(),
                                dayOfWeek: _dayName(selectedDate!.weekday),
                                startTime: startTimeController.text.trim(),
                                endTime: endTimeController.text.trim(),
                                lectureDate: selectedDate != null
                                    ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                                    : null,
                              );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (context.mounted) {
                            ToastUtils.showSuccess(context, 'Lecture scheduled successfully!', aboveNavBar: true);
                          }
                        } catch (e) {
                          String displayError = e.toString();
                          if (displayError.contains('AuthException:')) {
                            displayError = displayError.split('AuthException:').last.trim();
                          }
                          if (displayError.contains('Exception:')) {
                            displayError = displayError.split('Exception:').last.trim();
                          }
                          if (displayError.contains('Failed to add lecture:')) {
                            displayError = displayError.split('Failed to add lecture:').last.trim();
                          }
                          setState(() {
                            dialogError = displayError;
                          });
                        }
                      },
                      child: const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showScheduleTestDialog(BuildContext context, BatchModel batch) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjects = ['Physics', 'Chemistry', 'Maths', 'Biology'];
    if (batch.examType.toUpperCase() == 'JEE') {
      subjects.remove('Biology');
    }
    String selectedSubject = subjects.contains('Chemistry') ? 'Chemistry' : subjects.first;
    final topicController = TextEditingController();
    final dateController = TextEditingController(text: _getTodayFormatted());
    final startTimeController = TextEditingController(text: '02:00 PM');
    final endTimeController = TextEditingController(text: '03:30 PM');
    final marksController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceTile1 : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(
                'Schedule Test',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppDropdown<String>(
                      value: selectedSubject,
                      label: 'Subject Name',
                      items: subjects
                          .map((s) => AppDropdownItem<String>(value: s, label: s))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedSubject = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(
                          labelText: 'Topic / Syllabus'),
                      style: TextStyle(
                          color: isDark ? Colors.white : AppColors.ink),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      style: TextStyle(
                          color: isDark ? Colors.white : AppColors.ink),
                      onTap: () async {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: today,
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          final formatted = "${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}";
                          dateController.text = formatted;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              suffixIcon: Icon(Icons.access_time_rounded),
                            ),
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.ink),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 14, minute: 0),
                              );
                              if (picked != null) {
                                final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                final minute = picked.minute.toString().padLeft(2, '0');
                                final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                                startTimeController.text = "${hour.toString().padLeft(2, '0')}:$minute $period";
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              suffixIcon: Icon(Icons.access_time_rounded),
                            ),
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.ink),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 15, minute: 30),
                              );
                              if (picked != null) {
                                final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                final minute = picked.minute.toString().padLeft(2, '0');
                                final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                                endTimeController.text = "${hour.toString().padLeft(2, '0')}:$minute $period";
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: marksController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Max Marks'),
                      style: TextStyle(
                          color: isDark ? Colors.white : AppColors.ink),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (topicController.text.trim().isEmpty) {
                      ToastUtils.showError(context, 'Please fill out Topic / Syllabus field', aboveNavBar: true);
                      return;
                    }
                    if (marksController.text.trim().isEmpty) {
                      ToastUtils.showError(context, 'Please enter Max Marks', aboveNavBar: true);
                      return;
                    }
                    
                    final lecStart = _parseTimeToMinutes(startTimeController.text.trim());
                    final lecEnd = _parseTimeToMinutes(endTimeController.text.trim());
                    if (lecStart != null && lecEnd != null && lecStart >= lecEnd) {
                      ToastUtils.showError(context, 'End Time must be after Start Time', aboveNavBar: true);
                      return;
                    }

                    // Check conflict with other scheduled tests on the same day
                    final targetDateStr = _formatDisplayDateToDb(dateController.text.trim());
                    final details = ref.read(batchDetailControllerProvider(batch.id));
                    for (final exam in details.exams) {
                      if (exam.isCancelled) continue;
                      if (targetDateStr == exam.examDate) {
                          String examStartStr = exam.examTime;
                          String examEndStr = '';
                          if (exam.examTime.contains(' - ')) {
                            final parts = exam.examTime.split(' - ');
                            if (parts.length >= 2) {
                              examStartStr = parts[0];
                              examEndStr = parts[1];
                            }
                          }
                          
                          final testStart = _parseTimeToMinutes(examStartStr);
                          final testEnd = examEndStr.isNotEmpty 
                              ? _parseTimeToMinutes(examEndStr) 
                              : (testStart != null ? testStart + 90 : null);
                          
                          if (lecStart != null && lecEnd != null && testStart != null && testEnd != null) {
                            if (lecStart < testEnd && lecEnd > testStart) {
                              showDialog(
                                context: context,
                                builder: (BuildContext ctx) => AlertDialog(
                                  title: const Text('Conflict'),
                                  content: Text('Already test schedule of ${exam.subjectName} from $examStartStr to ${examEndStr.isNotEmpty ? examEndStr : "03:30 PM"} time'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                          }
                        }
                      }
                    try {
                      final subId = await _getSubjectId(selectedSubject);
                      final newExam = ExamModel(
                        id: '',
                        batchId: batch.id,
                        subjectId: subId,
                        subjectName: selectedSubject,
                        name: topicController.text.trim(),
                        examDate: _formatDisplayDateToDb(dateController.text.trim()),
                        maxMarks: int.tryParse(marksController.text.trim()) ?? 100,
                        examTime: "${startTimeController.text.trim()} - ${endTimeController.text.trim()}",
                        isCancelled: false,
                      );
                      await ref.read(batchDetailControllerProvider(batch.id).notifier).addExam(newExam);
                      if (!dialogContext.mounted || !context.mounted) return;
                      Navigator.pop(dialogContext);
                      ToastUtils.showSuccess(context, 'Test scheduled successfully!', aboveNavBar: true);
                    } catch (e) {
                      ToastUtils.showError(context, 'Failed to schedule test: $e', aboveNavBar: true);
                    }
                  },
                  child: const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEditLectureDialog(
    BuildContext context, {
    required String? batchId,
    required String? lectureId,
    required String subject,
    required String teacher,
    required String startTime,
    required String endTime,
    required String? lectureDate,
    required String room,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectController = TextEditingController(text: subject);
    final teacherController = TextEditingController(text: teacher);
    final roomController = TextEditingController(text: room);
    final dateController = TextEditingController(text: lectureDate);
    final startTimeController = TextEditingController(text: startTime);
    final endTimeController = TextEditingController(text: endTime);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceTile1 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Edit Lecture Details',
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(labelText: 'Teacher Name'),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                  onTap: () async {
                    final initialDate = DateTime.tryParse(dateController.text) ?? DateTime.now();
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final firstVal = initialDate.isBefore(today) ? initialDate : today;
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: firstVal,
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      final formatted = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      dateController.text = formatted;
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          suffixIcon: Icon(Icons.access_time_rounded),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                        onTap: () async {
                          TimeOfDay initial = TimeOfDay.now();
                          try {
                            final parts = startTimeController.text.split(':');
                            if (parts.length >= 2) {
                              initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                            }
                          } catch (_) {}
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                            startTimeController.text = formatted;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          suffixIcon: Icon(Icons.access_time_rounded),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                        onTap: () async {
                          TimeOfDay initial = TimeOfDay.now();
                          try {
                            final parts = endTimeController.text.split(':');
                            if (parts.length >= 2) {
                              initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                            }
                          } catch (_) {}
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                            endTimeController.text = formatted;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel Lecture'),
                    content: const Text('Are you sure you want to cancel this scheduled lecture?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes, Cancel It', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (lectureId != null && batchId != null) {
                    try {
                      await ref
                          .read(batchDetailControllerProvider(batchId).notifier)
                          .deleteLecture(lectureId);
                      if (!dialogContext.mounted || !context.mounted) return;
                      Navigator.pop(dialogContext);
                      ToastUtils.showSuccess(context, 'Lecture cancelled successfully!', aboveNavBar: true);
                    } catch (e) {
                      if (!dialogContext.mounted || !context.mounted) return;
                      ToastUtils.showError(context, 'Error cancelling lecture: $e', aboveNavBar: true);
                    }
                  } else {
                    if (!dialogContext.mounted || !context.mounted) return;
                    setState(() {
                      _lectureSubject = 'Physics';
                      _lectureTeacher = 'Mr. R. Sharma';
                      _lectureRoom = 'Room 101';
                      _lectureDate = '2026-07-16';
                      _lectureStartTime = '09:00 AM';
                      _lectureEndTime = '10:30 AM';
                    });
                    Navigator.pop(dialogContext);
                    ToastUtils.showSuccess(context, 'Lecture cancelled successfully!', aboveNavBar: true);
                  }
                }
              },
              child: const Text('Cancel Lecture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (subjectController.text.trim().isEmpty ||
                    teacherController.text.trim().isEmpty) {
                  ToastUtils.showError(context, 'Please fill out Subject and Teacher fields', aboveNavBar: true);
                  return;
                }
                
                if (lectureId != null && batchId != null) {
                  try {
                    final client = Supabase.instance.client;
                    await client.from('timetable').update({
                      'room': roomController.text.trim(),
                      'lecture_date': dateController.text.trim(),
                      'start_time': startTimeController.text.trim(),
                      'end_time': endTimeController.text.trim(),
                    }).eq('id', lectureId);
                    
                    // Refresh the admin dashboard/details state
                    ref.read(batchDetailControllerProvider(batchId).notifier).loadAllDetails();
                    
                    if (!dialogContext.mounted || !context.mounted) return;
                    Navigator.pop(dialogContext);
                    ToastUtils.showSuccess(context, 'Lecture updated successfully!', aboveNavBar: true);
                  } catch (e) {
                    if (!dialogContext.mounted || !context.mounted) return;
                    ToastUtils.showError(context, 'Error updating lecture: $e', aboveNavBar: true);
                  }
                } else {
                  setState(() {
                    _lectureSubject = subjectController.text.trim();
                    _lectureTeacher = teacherController.text.trim();
                    _lectureRoom = roomController.text.trim();
                    _lectureDate = dateController.text.trim();
                    _lectureStartTime = startTimeController.text.trim();
                    _lectureEndTime = endTimeController.text.trim();
                  });
                  Navigator.pop(dialogContext);
                  ToastUtils.showSuccess(context, 'Upcoming lecture updated successfully!', aboveNavBar: true);
                }
              },
              child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditTestDialog(
    BuildContext context, {
    required ExamModel exam,
    required String batchId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final topicController = TextEditingController(text: exam.name);
    final dateController = TextEditingController(text: _formatDbDateToDisplay(exam.examDate));
    final cleanMarks = exam.maxMarks.toString();
    final marksController = TextEditingController(text: cleanMarks);

    String startTime = '02:00 PM';
    String endTime = '03:30 PM';
    if (exam.examTime.contains(' - ')) {
      final parts = exam.examTime.split(' - ');
      if (parts.length >= 2) {
        startTime = parts[0].trim();
        endTime = parts[1].trim();
      }
    } else if (exam.examTime.isNotEmpty) {
      startTime = exam.examTime.trim();
    }

    final startTimeController = TextEditingController(text: startTime);
    final endTimeController = TextEditingController(text: endTime);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final batchesState = ref.watch(batchControllerProvider);
            final batches = batchesState.valueOrNull ?? [];
            final currentBatch = batches.firstWhere(
              (b) => b.id == batchId,
              orElse: () => BatchModel(
                id: '',
                courseId: '',
                name: '',
                capacity: 0,
                examType: '',
                classLevel: '',
                medium: '',
                lectureDays: const [],
                status: '',
              ),
            );
            
            final validSubjects = ['Physics', 'Chemistry', 'Maths', 'Biology'];
            if (currentBatch.examType.toUpperCase() == 'JEE') {
              validSubjects.remove('Biology');
            }
            String selectedSubject = validSubjects.contains(exam.subjectName) ? exam.subjectName : (validSubjects.contains('Chemistry') ? 'Chemistry' : validSubjects.first);

            return StatefulBuilder(
              builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceTile1 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                'Edit Test Details',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppDropdown<String>(
                      value: selectedSubject,
                      label: 'Subject Name',
                      items: validSubjects
                          .map((s) => AppDropdownItem<String>(value: s, label: s))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedSubject = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(labelText: 'Topic / Syllabus'),
                      style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                      onTap: () async {
                        DateTime initialDate = DateTime.now();
                        try {
                          final parts = dateController.text.split(' ');
                          if (parts.length >= 3) {
                            final day = int.tryParse(parts[0]) ?? 1;
                            final monthStr = parts[1];
                            final year = int.tryParse(parts[2]) ?? DateTime.now().year;
                            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            final month = months.indexOf(monthStr) + 1;
                            if (month > 0) {
                              initialDate = DateTime(year, month, day);
                            }
                          }
                        } catch (_) {}

                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final firstVal = initialDate.isBefore(today) ? initialDate : today;
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: firstVal,
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          final formatted = "${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}";
                          dateController.text = formatted;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              suffixIcon: Icon(Icons.access_time_rounded),
                            ),
                            style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                            onTap: () async {
                              TimeOfDay initial = const TimeOfDay(hour: 14, minute: 0);
                              try {
                                final cleaned = startTimeController.text.replaceFirst(' AM', '').replaceFirst(' PM', '').trim();
                                final parts = cleaned.split(':');
                                if (parts.length >= 2) {
                                  int hr = int.parse(parts[0]);
                                  final min = int.parse(parts[1]);
                                  final isPm = startTimeController.text.contains('PM');
                                  if (isPm && hr != 12) hr += 12;
                                  if (!isPm && hr == 12) hr = 0;
                                  initial = TimeOfDay(hour: hr, minute: min);
                                }
                              } catch (_) {}

                              final picked = await showTimePicker(
                                context: context,
                                initialTime: initial,
                              );
                              if (picked != null) {
                                final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                final minute = picked.minute.toString().padLeft(2, '0');
                                final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                                startTimeController.text = "${hour.toString().padLeft(2, '0')}:$minute $period";
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              suffixIcon: Icon(Icons.access_time_rounded),
                            ),
                            style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                            onTap: () async {
                              TimeOfDay initial = const TimeOfDay(hour: 15, minute: 30);
                              try {
                                final cleaned = endTimeController.text.replaceFirst(' AM', '').replaceFirst(' PM', '').trim();
                                final parts = cleaned.split(':');
                                if (parts.length >= 2) {
                                  int hr = int.parse(parts[0]);
                                  final min = int.parse(parts[1]);
                                  final isPm = endTimeController.text.contains('PM');
                                  if (isPm && hr != 12) hr += 12;
                                  if (!isPm && hr == 12) hr = 0;
                                  initial = TimeOfDay(hour: hr, minute: min);
                                }
                              } catch (_) {}

                              final picked = await showTimePicker(
                                context: context,
                                initialTime: initial,
                              );
                              if (picked != null) {
                                final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                final minute = picked.minute.toString().padLeft(2, '0');
                                final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                                endTimeController.text = "${hour.toString().padLeft(2, '0')}:$minute $period";
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: marksController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Max Marks'),
                      style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Test'),
                        content: const Text('Are you sure you want to cancel this scheduled test?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Yes, Cancel It', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        final updated = exam.copyWith(isCancelled: true);
                        await ref.read(batchDetailControllerProvider(batchId).notifier).updateExam(updated);
                        if (!dialogContext.mounted || !context.mounted) return;
                        Navigator.pop(dialogContext);
                        ToastUtils.showSuccess(context, 'Test cancelled successfully!', aboveNavBar: true);
                      } catch (e) {
                        ToastUtils.showError(context, 'Failed to cancel test: $e', aboveNavBar: true);
                      }
                    }
                  },
                  child: const Text('Cancel Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (topicController.text.trim().isEmpty) {
                      ToastUtils.showError(context, 'Please fill out Topic / Syllabus field', aboveNavBar: true);
                      return;
                    }
                    if (marksController.text.trim().isEmpty) {
                      ToastUtils.showError(context, 'Please enter Max Marks', aboveNavBar: true);
                      return;
                    }
                    
                    final lecStart = _parseTimeToMinutes(startTimeController.text.trim());
                    final lecEnd = _parseTimeToMinutes(endTimeController.text.trim());
                    if (lecStart != null && lecEnd != null && lecStart >= lecEnd) {
                      ToastUtils.showError(context, 'End Time must be after Start Time', aboveNavBar: true);
                      return;
                    }

                    // Check conflict with other scheduled tests on the same day (excluding this exam)
                    final targetDateStr = _formatDisplayDateToDb(dateController.text.trim());
                    final details = ref.read(batchDetailControllerProvider(batchId));
                    for (final otherExam in details.exams) {
                      if (otherExam.isCancelled) continue;
                      if (otherExam.id == exam.id) continue; // Exclude current exam itself
                      if (targetDateStr == otherExam.examDate) {
                          String examStartStr = otherExam.examTime;
                          String examEndStr = '';
                          if (otherExam.examTime.contains(' - ')) {
                            final parts = otherExam.examTime.split(' - ');
                            if (parts.length >= 2) {
                              examStartStr = parts[0];
                              examEndStr = parts[1];
                            }
                          }
                          
                          final testStart = _parseTimeToMinutes(examStartStr);
                          final testEnd = examEndStr.isNotEmpty 
                              ? _parseTimeToMinutes(examEndStr) 
                              : (testStart != null ? testStart + 90 : null);
                          
                          if (lecStart != null && lecEnd != null && testStart != null && testEnd != null) {
                            if (lecStart < testEnd && lecEnd > testStart) {
                              showDialog(
                                context: context,
                                builder: (BuildContext ctx) => AlertDialog(
                                  title: const Text('Conflict'),
                                  content: Text('Already test schedule of ${otherExam.subjectName} from $examStartStr to ${examEndStr.isNotEmpty ? examEndStr : "03:30 PM"} time'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                          }
                        }
                      }
                    try {
                      final subId = await _getSubjectId(selectedSubject);
                      final updated = exam.copyWith(
                        subjectId: subId,
                        subjectName: selectedSubject,
                        name: topicController.text.trim(),
                        examDate: _formatDisplayDateToDb(dateController.text.trim()),
                        maxMarks: int.tryParse(marksController.text.trim()) ?? 100,
                        examTime: "${startTimeController.text.trim()} - ${endTimeController.text.trim()}",
                      );
                      await ref.read(batchDetailControllerProvider(batchId).notifier).updateExam(updated);
                      if (!dialogContext.mounted || !context.mounted) return;
                      Navigator.pop(dialogContext);
                      ToastUtils.showSuccess(context, 'Upcoming test updated successfully!', aboveNavBar: true);
                    } catch (e) {
                      ToastUtils.showError(context, 'Failed to update test: $e', aboveNavBar: true);
                    }
                  },
                  child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyBatchesView extends StatelessWidget {
  const _EmptyBatchesView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.school_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No Batches Available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.ink,
                letterSpacing: -0.374,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first batch to get started',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TactileButton(
              onTap: () => context.push('/admin/batches'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'Go to Batch Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.isDark, required this.activeBatchName});
  final bool isDark;
  final String activeBatchName;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_greeting()}, ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color:
                          isDark ? Colors.white60 : AppColors.textSecondary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Yash Sir',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          iconSize: 44,
          padding: EdgeInsets.zero,
          tooltip: 'Menu Options',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'Previous Lecture') {
              context.push('/admin/previous-lectures?batch=$activeBatchName');
            } else if (value == 'Previous Test') {
              context.push('/admin/previous-tests?batch=$activeBatchName');
            } else if (value == 'Attendance') {
              context.push('/admin/attendance-record?batch=$activeBatchName');
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'Previous Lecture',
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Previous Lecture',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'Previous Test',
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Previous Test',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'Attendance',
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Attendance Record',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BatchSelectorCard extends StatelessWidget {
  const _BatchSelectorCard({
    required this.activeBatch,
    required this.isDark,
    required this.onTap,
  });

  final BatchModel activeBatch;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceTile1 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeBatch.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.ink,
                      letterSpacing: -0.374,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activeBatch.classLevel} • ${activeBatch.examType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.bgIcon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final IconData bgIcon;
  final String label;
  final String description;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final startColor = isDark
        ? Color.lerp(accentColor, Colors.black, 0.82)!
        : Color.lerp(accentColor, Colors.white, 0.93)!;
    final endColor = isDark
        ? Color.lerp(accentColor, Colors.black, 0.95)!
        : Color.lerp(accentColor, Colors.white, 0.98)!;

    return AspectRatio(
      aspectRatio: 1.0,
      child: TactileButton(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, endColor],
            ),
            border: Border.all(
              color: isDark ? accentColor.withOpacity(0.3) : accentColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: accentColor.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Faint background illustration
                Positioned(
                  right: -20,
                  top: 10,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Icon(
                      bgIcon,
                      size: 95,
                      color: isDark
                          ? accentColor.withOpacity(0.05)
                          : accentColor.withOpacity(0.04),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon Container
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withOpacity(isDark ? 0.4 : 0.25),
                            width: 1.5,
                          ),
                          boxShadow: isDark ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.25),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          icon,
                          color: isDark ? Colors.white : accentColor,
                          size: 20,
                        ),
                      ),
                      
                      // Title & Bottom row
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.ink,
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
                                  border: Border.all(
                                    color: accentColor.withOpacity(isDark ? 0.25 : 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: isDark ? Colors.white.withOpacity(0.9) : accentColor,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingLectureCard extends StatelessWidget {
  const _UpcomingLectureCard({
    required this.isDark,
    required this.isLoading,
    required this.subject,
    required this.teacher,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.room,
    this.lectureDate,
    this.isPlaceholder = false,
    this.onEdit,
  });

  final bool isDark;
  final bool isLoading;
  final String subject;
  final String teacher;
  final String startTime;
  final String endTime;
  final String dayOfWeek;
  final String room;
  final String? lectureDate;
  final bool isPlaceholder;
  final VoidCallback? onEdit;

  String _formatLectureDate(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  String get displayDateOrDay {
    if (lectureDate != null && lectureDate!.isNotEmpty) {
      return _formatLectureDate(lectureDate!);
    }
    return dayOfWeek;
  }

  String _getStartTimeOnly(String timeStr) {
    if (timeStr.isEmpty) return timeStr;
    final splitters = [' - ', ' – ', '-'];
    for (final splitter in splitters) {
      if (timeStr.contains(splitter)) {
        return timeStr.split(splitter).first.trim();
      }
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _SubjectTheme.forSubject(subject);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          // Ambient light diffuse shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
          // Key directional light colored shadow
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -1,
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(theme.icon, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming Lecture',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.374,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isPlaceholder)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        color: Colors.white70,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: onEdit,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 6),
                _InfoChip(
                  icon: Icons.person_outline_rounded,
                  label: 'Teacher',
                  value: teacher,
                  isDark: isDark,
                  compact: true,
                  onGradient: true,
                ),
                const SizedBox(height: 5),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: 'Time & Room',
                  value: '${_getStartTimeOnly(startTime)} • $room',
                  isDark: isDark,
                  compact: true,
                  onGradient: true,
                ),
                const SizedBox(height: 5),
                _InfoChip(
                  icon: Icons.today_rounded,
                  label: 'Date',
                  value: displayDateOrDay,
                  isDark: isDark,
                  compact: true,
                  onGradient: true,
                ),
              ],
            ),
    );
  }
}

class _UpcomingTestCard extends StatelessWidget {
  const _UpcomingTestCard({
    required this.isDark,
    required this.subject,
    required this.topic,
    required this.date,
    required this.time,
    required this.marks,
    this.isPlaceholder = false,
    this.onEdit,
  });

  final bool isDark;
  final String subject;
  final String topic;
  final String date;
  final String time;
  final String marks;
  final bool isPlaceholder;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = _SubjectTheme.forSubject(subject);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          // Ambient light diffuse shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
          // Key directional light colored shadow
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(theme.icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Test',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.374,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isPlaceholder)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    'Scheduled',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              if (onEdit != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  color: Colors.white70,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: onEdit,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 12,
                    color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(
              color: Colors.white24,
              height: 1),
          const SizedBox(height: 6),
          _InfoChip(
              icon: Icons.today_rounded,
              label: 'Date & Time',
              value: '$date • $time',
              isDark: isDark,
              compact: true,
              onGradient: true),
          const SizedBox(height: 6),
          _InfoChip(
              icon: Icons.emoji_events_outlined,
              label: 'Marks',
              value: marks,
              isDark: isDark,
              compact: true,
              onGradient: true),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.compact = false,
    this.onGradient = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool compact;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final bgColor = onGradient
        ? Colors.white.withValues(alpha: 0.15)
        : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF5F5F7));
    final iconColor = onGradient
        ? Colors.white70
        : (isDark ? Colors.white38 : AppColors.textSecondary);
    final labelColor = onGradient
        ? Colors.white70
        : (isDark ? Colors.white38 : AppColors.textSecondary);
    final valueColor = onGradient
        ? Colors.white
        : (isDark ? Colors.white : AppColors.ink);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: iconColor,
          ),
          SizedBox(width: compact ? 4 : 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    color: labelColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTheme {
  final Color accent;
  final Gradient gradient;
  final IconData icon;

  const _SubjectTheme({
    required this.accent,
    required this.gradient,
    required this.icon,
  });

  factory _SubjectTheme.forSubject(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('physic')) {
      return const _SubjectTheme(
        accent: Color(0xFF0284C7),
        gradient: LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0369A1)], // Light Sky Blue -> Dark Ocean Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.blur_on_rounded,
      );
    } else if (lower.contains('math') || lower.contains('algebra') || lower.contains('calculus')) {
      return const _SubjectTheme(
        accent: Color(0xFF8B5CF6),
        gradient: LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF5B21B6)], // Light Violet -> Dark Royal Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.functions_rounded,
      );
    } else if (lower.contains('chem')) {
      return const _SubjectTheme(
        accent: Color(0xFF10B981),
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF047857)], // Light Emerald -> Dark Forest Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.science_rounded,
      );
    } else if (lower.contains('bio') || lower.contains('botany') || lower.contains('zoology')) {
      return const _SubjectTheme(
        accent: Color(0xFFEF4444),
        gradient: LinearGradient(
          colors: [Color(0xFFF87171), Color(0xFF991B1B)], // Light Coral -> Dark Ruby Red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.coronavirus_rounded,
      );
    }

    return const _SubjectTheme(
      accent: Color(0xFF3B82F6),
      gradient: LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)], // Light Indigo -> Dark Royal Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.assignment_rounded,
    );
  }
}
