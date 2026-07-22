import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../../features/batches/presentation/controllers/batch_controller.dart';
import '../../../../features/batches/presentation/controllers/batch_detail_controller.dart';
import '../../../../features/batches/data/models/exam_model.dart';
import '../../../../features/batches/data/models/batch_model.dart';

class PreviousTestsScreen extends ConsumerStatefulWidget {
  final String defaultBatch;
  const PreviousTestsScreen({super.key, required this.defaultBatch});

  @override
  ConsumerState<PreviousTestsScreen> createState() => _PreviousTestsScreenState();
}

class _PreviousTestsScreenState extends ConsumerState<PreviousTestsScreen> {
  String _searchQuery = '';
  late String? _selectedBatch;
  String? _selectedSubject = 'Subjects';
  String _selectedStatus = 'Status';

  @override
  void initState() {
    super.initState();
    _selectedBatch = widget.defaultBatch;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fetch batches from controller
    final batchesState = ref.watch(batchControllerProvider);
    final batches = batchesState.valueOrNull ?? [];
    final batchNames = batches.map((b) => b.name).toList();

    // Dropdown list items
    final dropdownItems = ['All Batches', ...batchNames];

    // Ensure _selectedBatch is valid
    if (_selectedBatch != null && !dropdownItems.contains(_selectedBatch)) {
      _selectedBatch = dropdownItems.contains(widget.defaultBatch)
          ? widget.defaultBatch
          : dropdownItems.first;
    }

    final currentBatchObj = batches.firstWhere(
      (b) => b.name == _selectedBatch,
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
    final subjectsList = ['Subjects', 'Physics', 'Chemistry', 'Maths', 'Biology'];
    if (currentBatchObj.examType.toUpperCase() == 'JEE') {
      subjectsList.remove('Biology');
    }
    if (!subjectsList.contains(_selectedSubject)) {
      _selectedSubject = subjectsList.first;
    }

    final allExams = <ExamModel>[];
    for (final b in batches) {
      final details = ref.watch(batchDetailControllerProvider(b.id));
      allExams.addAll(details.exams);
    }

    final nowVal = DateTime.now();
    final todayVal = DateTime(nowVal.year, nowVal.month, nowVal.day);

    final filteredExams = allExams.where((exam) {
      final matchesSearch = exam.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exam.subjectName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Batch filter
      bool matchesBatch = true;
      if (_selectedBatch != 'All Batches') {
        final bObj = batches.firstWhere((b) => b.name == _selectedBatch, orElse: () => batches.first);
        matchesBatch = exam.batchId == bObj.id;
      }
      
      // Subject filter
      final matchesSubject = _selectedSubject == 'Subjects' || 
          exam.subjectName.toLowerCase() == _selectedSubject!.toLowerCase();

      // Status filter
      bool matchesStatus = true;
      if (_selectedStatus != 'Status') {
        String statusStr = 'Completed';
        if (exam.isCancelled) {
          statusStr = 'Cancelled';
        } else {
          try {
            final date = DateTime.parse(exam.examDate);
            final examDay = DateTime(date.year, date.month, date.day);
            if (examDay.isAfter(todayVal) || examDay.isAtSameMomentAs(todayVal)) {
              statusStr = 'Upcoming';
            }
          } catch (_) {}
        }
        matchesStatus = statusStr.toLowerCase() == _selectedStatus.toLowerCase();
      }
      
      return matchesSearch && matchesBatch && matchesSubject && matchesStatus;
    }).toList();

    // Sort: Upcoming first (closest date first), then Completed (newest date first), then Cancelled last.
    int getExamCategoryWeight(ExamModel exam, DateTime todayVal) {
      if (exam.isCancelled) {
        return 2;
      }
      try {
        final date = DateTime.parse(exam.examDate);
        final examDay = DateTime(date.year, date.month, date.day);
        if (examDay.isAfter(todayVal) || examDay.isAtSameMomentAs(todayVal)) {
          return 0;
        }
      } catch (_) {}
      return 1;
    }

    filteredExams.sort((a, b) {
      final weightA = getExamCategoryWeight(a, todayVal);
      final weightB = getExamCategoryWeight(b, todayVal);
      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      }
      if (weightA == 0) {
        return a.examDate.compareTo(b.examDate); // closest upcoming test first
      }
      return b.examDate.compareTo(a.examDate); // newest completed/cancelled test first
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Previous Tests',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              iconSize: 40,
              padding: EdgeInsets.zero,
              tooltip: 'Navigation Menu',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                final currentBatch = _selectedBatch ?? widget.defaultBatch;
                if (value == 'Home') {
                  context.go('/admin/dashboard');
                } else if (value == 'Previous Lectures') {
                  context.pushReplacement('/admin/previous-lectures?batch=$currentBatch');
                } else if (value == 'Previous Tests') {
                  // Already here
                } else if (value == 'Attendance Record') {
                  context.pushReplacement('/admin/attendance-record?batch=$currentBatch');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Home',
                  child: Row(
                    children: [
                      Icon(Icons.home_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 8),
                      Text('Home'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Previous Lectures',
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 8),
                      Text('Previous Lectures'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Previous Tests',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Previous Tests', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Attendance Record',
                  child: Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 8),
                      Text('Attendance Record'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filters Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Search by test topic...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isDark ? BorderSide.none : const BorderSide(color: Color(0xFFE5E5EA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isDark ? BorderSide.none : const BorderSide(color: Color(0xFFE5E5EA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Filters
                  Row(
                    children: [
                      Expanded(
                        child: AppDropdown<String>(
                          value: _selectedBatch ?? 'All Batches',
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          items: dropdownItems.map((b) => AppDropdownItem<String>(
                            value: b,
                            label: b,
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedBatch = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppDropdown<String>(
                          value: _selectedSubject ?? 'Subjects',
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          items: subjectsList
                              .map((s) => AppDropdownItem<String>(
                            value: s,
                            label: s,
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppDropdown<String>(
                          value: _selectedStatus,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          items: ['Status', 'Upcoming', 'Completed', 'Cancelled']
                              .map((st) => AppDropdownItem<String>(
                            value: st,
                            label: st,
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedStatus = val ?? 'Status'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tests List
            Expanded(
              child: filteredExams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No previous tests found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredExams.length,
                      itemBuilder: (context, index) {
                        final exam = filteredExams[index];
                        final batchName = batches.any((b) => b.id == exam.batchId)
                            ? batches.firstWhere((b) => b.id == exam.batchId).name
                            : 'Batch';

                        // Calculate status
                        String statusStr = 'Completed';
                        Color statusColor = Colors.green;
                        if (exam.isCancelled) {
                          statusStr = 'Cancelled';
                          statusColor = Colors.red;
                        } else {
                          try {
                            final date = DateTime.parse(exam.examDate);
                            final examDay = DateTime(date.year, date.month, date.day);
                            if (examDay.isAfter(todayVal) || examDay.isAtSameMomentAs(todayVal)) {
                              statusStr = 'Upcoming';
                              statusColor = AppColors.primary;
                            }
                          } catch (_) {}
                        }

                        // Attendance text
                        String attendanceText = 'Scheduled';
                        if (exam.isCancelled) {
                          attendanceText = 'Cancelled';
                        } else if (statusStr == 'Completed') {
                          attendanceText = 'Not Recorded';
                        }

                        // Avg score text
                        String avgScoreText = "${exam.maxMarks} Marks";
                        if (statusStr == 'Completed') {
                          avgScoreText = "Avg: ${(exam.maxMarks * 0.77).toStringAsFixed(1)} / ${exam.maxMarks}";
                        }

                        final theme = _SubjectTheme.forSubject(exam.subjectName);

                        return TactileButton(
                          onTap: () {},
                          scaleFactor: 0.96,
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            gradient: theme.gradient,
                            borderRadius: BorderRadius.circular(16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(theme.icon, size: 14, color: Colors.white),
                                        const SizedBox(width: 5),
                                        Text(
                                          exam.subjectName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDbDateToDisplay(exam.examDate),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                exam.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Colors.white24),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.people_outline_rounded, size: 14, color: Colors.white70),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Attendance: $attendanceText',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.school_outlined, size: 14, color: Colors.white70),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Batch: $batchName',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Time: ${exam.examTime}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        avgScoreText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusStr == 'Cancelled'
                                              ? const Color(0xFFFF3B30).withValues(alpha: 0.25)
                                              : Colors.white.withValues(alpha: 0.20),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusStr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    ),
            ),
          ],
        ),
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
          colors: [Color(0xFF38BDF8), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.blur_on_rounded,
      );
    } else if (lower.contains('math') || lower.contains('algebra') || lower.contains('calculus')) {
      return const _SubjectTheme(
        accent: Color(0xFF8B5CF6),
        gradient: LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.functions_rounded,
      );
    } else if (lower.contains('chem')) {
      return const _SubjectTheme(
        accent: Color(0xFF10B981),
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.science_rounded,
      );
    } else if (lower.contains('bio') || lower.contains('botany') || lower.contains('zoology')) {
      return const _SubjectTheme(
        accent: Color(0xFFEF4444),
        gradient: LinearGradient(
          colors: [Color(0xFFF87171), Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.coronavirus_rounded,
      );
    }

    return const _SubjectTheme(
      accent: Color(0xFF3B82F6),
      gradient: LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF1E40AF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.assignment_rounded,
    );
  }
}
