import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../batches/presentation/controllers/batch_controller.dart';
import '../../../batches/presentation/controllers/batch_detail_controller.dart';
import '../../../batches/data/models/batch_model.dart';
import '../../../batches/data/models/timetable_lecture_model.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String? _selectedBatchId;
  Map<String, String>? _mockScheduledTest;

  // Overrideable lecture data (editable by admin)
  String _lectureSubject = 'Physics — Chapter 12';
  String _lectureTeacher = 'Mr. R. Sharma';
  String _lectureStartTime = '09:00 AM';
  String _lectureEndTime = '10:30 AM';
  String _lectureDayOfWeek = 'Monday';
  String _lectureRoom = 'Room 101';

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
                _GreetingSection(isDark: isDark),
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
                        label: 'Schedule\nLecture',
                        description: "Create today's class",
                        accentColor: AppColors.primary,
                        isDark: isDark,
                        onTap: () => _showScheduleLectureDialog(
                            context, _selectedBatchId!, batchDetails),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.assignment_rounded,
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
                _buildUpcomingTestCard(context, isDark),
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

    if (details.lectures.isNotEmpty) {
      final TimetableLectureModel lecture = details.lectures.first;
      return _UpcomingLectureCard(
        isDark: isDark,
        isLoading: false,
        subject: lecture.subjectName,
        teacher: lecture.teacherName,
        startTime: lecture.startTime,
        endTime: lecture.endTime,
        dayOfWeek: lecture.dayOfWeek,
        room: lecture.room,
        onEdit: () => _showEditLectureDialog(
          context,
          subject: lecture.subjectName,
          teacher: lecture.teacherName,
          startTime: lecture.startTime,
          endTime: lecture.endTime,
          dayOfWeek: lecture.dayOfWeek,
          room: lecture.room,
        ),
      );
    }

    return _UpcomingLectureCard(
      isDark: isDark,
      isLoading: false,
      subject: _lectureSubject,
      teacher: _lectureTeacher,
      startTime: _lectureStartTime,
      endTime: _lectureEndTime,
      dayOfWeek: _lectureDayOfWeek,
      room: _lectureRoom,
      isPlaceholder: true,
      onEdit: () => _showEditLectureDialog(
        context,
        subject: _lectureSubject,
        teacher: _lectureTeacher,
        startTime: _lectureStartTime,
        endTime: _lectureEndTime,
        dayOfWeek: _lectureDayOfWeek,
        room: _lectureRoom,
      ),
    );
  }

  Widget _buildUpcomingTestCard(BuildContext context, bool isDark) {
    if (_mockScheduledTest != null) {
      return _UpcomingTestCard(
        isDark: isDark,
        subject: _mockScheduledTest!['subject'] ?? '',
        topic: _mockScheduledTest!['topic'] ?? '',
        date: _mockScheduledTest!['date'] ?? '',
        time: _mockScheduledTest!['time'] ?? '',
        marks: _mockScheduledTest!['marks'] ?? '',
        isPlaceholder: false,
        onEdit: () => _showEditTestDialog(
          context,
          subject: _mockScheduledTest!['subject'] ?? '',
          topic: _mockScheduledTest!['topic'] ?? '',
          date: _mockScheduledTest!['date'] ?? '',
          time: _mockScheduledTest!['time'] ?? '',
          marks: _mockScheduledTest!['marks'] ?? '',
        ),
      );
    }

    return _UpcomingTestCard(
      isDark: isDark,
      subject: 'Chemistry',
      topic: 'Organic Reactions & Mechanisms',
      date: 'Tomorrow',
      time: '02:00 PM',
      marks: '100 Marks',
      isPlaceholder: true,
      onEdit: () => _showEditTestDialog(
        context,
        subject: 'Chemistry',
        topic: 'Organic Reactions & Mechanisms',
        date: 'Tomorrow',
        time: '02:00 PM',
        marks: '100 Marks',
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

  void _showScheduleLectureDialog(
      BuildContext context, String batchId, BatchDetailState details) {
    final roomController = TextEditingController(text: 'Room 101');
    final startTimeController = TextEditingController(text: '09:00 AM');
    final endTimeController = TextEditingController(text: '10:30 AM');

    String selectedSubject = '';
    String selectedTeacherName = '';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            // Generate list of subject options dynamically from the teachers list
            final subjectOptions = {'Physics', 'Chemistry', 'Mathematics', 'Biology', 'Other'};
            for (final t in details.teachers) {
              final s = t['subject'] as String?;
              if (s != null && s.isNotEmpty) {
                if (s.toLowerCase() == 'maths' || s.toLowerCase() == 'mathematics') {
                  subjectOptions.add('Mathematics');
                } else {
                  subjectOptions.add(s[0].toUpperCase() + s.substring(1).toLowerCase());
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
              final teacherSubject = (t['subject'] as String? ?? '').toLowerCase();
              final selSub = selectedSubject.toLowerCase();
              if (selSub == 'maths' || selSub == 'mathematics') {
                return teacherSubject == 'maths' || teacherSubject == 'mathematics';
              }
              return teacherSubject == selSub;
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedDate == null
                                ? Colors.grey.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: selectedDate == null
                                  ? Colors.grey
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedDate == null
                                    ? 'Select Date'
                                    : '${_dayName(selectedDate!.weekday)}, '
                                      '${selectedDate!.day} '
                                      '${_monthName(selectedDate!.month)} '
                                      '${selectedDate!.year}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: selectedDate == null
                                      ? Colors.grey
                                      : (isDark ? Colors.white : AppColors.ink),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Colors.grey.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            decoration: const InputDecoration(
                                labelText: 'Start Time'),
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            decoration:
                                const InputDecoration(labelText: 'End Time'),
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                TactileButton(
                  onTap: () async {
                    if (selectedSubject.isEmpty || selectedTeacherName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Please select Subject and Teacher')));
                      return;
                    }
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please select a lecture date')));
                      return;
                    }
                    try {
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
                          );
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Lecture scheduled successfully!')));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Error scheduling lecture: $e')));
                    }
                  },
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Schedule'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScheduleTestDialog(BuildContext context, BatchModel batch) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectController = TextEditingController();
    final topicController = TextEditingController();
    final dateController = TextEditingController(text: 'July 15, 2026');
    final timeController = TextEditingController(text: '02:00 PM');
    final marksController = TextEditingController(text: '100 Marks');

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                TextField(
                  controller: subjectController,
                  decoration:
                      const InputDecoration(labelText: 'Subject Name'),
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.ink),
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
                  decoration: const InputDecoration(labelText: 'Date'),
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: timeController,
                        decoration:
                            const InputDecoration(labelText: 'Time'),
                        style: TextStyle(
                            color: isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: marksController,
                        decoration: const InputDecoration(
                            labelText: 'Max Marks'),
                        style: TextStyle(
                            color: isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TactileButton(
              onTap: () {
                if (subjectController.text.trim().isEmpty ||
                    topicController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Please fill out Subject and Topic fields')));
                  return;
                }
                setState(() {
                  _mockScheduledTest = {
                    'subject': subjectController.text.trim(),
                    'topic': topicController.text.trim(),
                    'date': dateController.text.trim(),
                    'time': timeController.text.trim(),
                    'marks': marksController.text.trim(),
                  };
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Test scheduled successfully!')));
              },
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Schedule'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditLectureDialog(
    BuildContext context, {
    required String subject,
    required String teacher,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
    required String room,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectController = TextEditingController(text: subject);
    final teacherController = TextEditingController(text: teacher);
    final roomController = TextEditingController(text: room);
    final dayController = TextEditingController(text: dayOfWeek);
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
                  controller: dayController,
                  decoration: const InputDecoration(labelText: 'Day of Week'),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: const InputDecoration(labelText: 'End Time'),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TactileButton(
              onTap: () {
                if (subjectController.text.trim().isEmpty ||
                    teacherController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please fill out Subject and Teacher fields')));
                  return;
                }
                setState(() {
                  _lectureSubject = subjectController.text.trim();
                  _lectureTeacher = teacherController.text.trim();
                  _lectureRoom = roomController.text.trim();
                  _lectureDayOfWeek = dayController.text.trim();
                  _lectureStartTime = startTimeController.text.trim();
                  _lectureEndTime = endTimeController.text.trim();
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Upcoming lecture updated successfully!')));
              },
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditTestDialog(
    BuildContext context, {
    required String subject,
    required String topic,
    required String date,
    required String time,
    required String marks,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectController = TextEditingController(text: subject);
    final topicController = TextEditingController(text: topic);
    final dateController = TextEditingController(text: date);
    final timeController = TextEditingController(text: time);
    final marksController = TextEditingController(text: marks);

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
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
                  decoration: const InputDecoration(labelText: 'Date'),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: timeController,
                        decoration: const InputDecoration(labelText: 'Time'),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: marksController,
                        decoration: const InputDecoration(labelText: 'Max Marks'),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TactileButton(
              onTap: () {
                if (subjectController.text.trim().isEmpty ||
                    topicController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please fill out Subject and Topic fields')));
                  return;
                }
                setState(() {
                  _mockScheduledTest = {
                    'subject': subjectController.text.trim(),
                    'topic': topicController.text.trim(),
                    'date': dateController.text.trim(),
                    'time': timeController.text.trim(),
                    'marks': marksController.text.trim(),
                  };
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Upcoming test updated successfully!')));
              },
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
          ],
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
  const _GreetingSection({required this.isDark});
  final bool isDark;

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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: AppColors.primary, size: 22),
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
    required this.label,
    required this.description,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.ink,
                letterSpacing: -0.2,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : const Color(0xFFF0F0F0),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: accentColor),
              ],
            ),
          ],
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
  final bool isPlaceholder;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: isLoading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Lecture',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.ink,
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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                    color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                    height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                          icon: Icons.person_outline_rounded,
                          label: 'Teacher',
                          value: teacher,
                          isDark: isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoChip(
                          icon: Icons.meeting_room_outlined,
                          label: 'Room',
                          value: room,
                          isDark: isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: '$startTime – $endTime',
                          isDark: isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoChip(
                          icon: Icons.today_rounded,
                          label: 'Day',
                          value: dayOfWeek,
                          isDark: isDark),
                    ),
                  ],
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

  static const Color _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Test',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.ink,
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
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    'Scheduled',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _accent),
                  ),
                ),
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    topic,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
              color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
              height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                    icon: Icons.today_rounded,
                    label: 'Date',
                    value: date,
                    isDark: isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: time,
                    isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                    icon: Icons.emoji_events_outlined,
                    label: 'Marks',
                    value: marks,
                    isDark: isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChip(
                    icon: Icons.bar_chart_rounded,
                    label: 'Difficulty',
                    value: 'Medium',
                    isDark: isDark),
              ),
            ],
          ),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: isDark ? Colors.white38 : AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.ink,
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
