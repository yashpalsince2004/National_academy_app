import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/widgets/app_pull_to_refresh.dart';
import 'package:national_academy/features/batches/data/models/exam_model.dart';

enum TestFilter { upcoming, today, completed, cancelled }

class TestsTab extends ConsumerStatefulWidget {
  const TestsTab({super.key});

  @override
  ConsumerState<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends ConsumerState<TestsTab> {
  TestFilter _activeFilter = TestFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final examsAsync = ref.watch(studentExamsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
              child: Text(
                'Tests & Exams',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Custom iOS-style Segmented Filter Bar ──────────────────────────
            _buildSegmentedFilterBar(isDark),
            const SizedBox(height: 12),

            // ── Tests List ───────────────────────────────────────────────────
            Expanded(
              child: examsAsync.when(
                data: (exams) => _buildFilteredList(exams, cardColor, textColor, mutedTextColor),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildFilteredList([], cardColor, textColor, mutedTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedFilterBar(bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile2 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildFilterButton(TestFilter.upcoming, 'Upcoming'),
          _buildFilterButton(TestFilter.today, 'Today'),
          _buildFilterButton(TestFilter.completed, 'Completed'),
          _buildFilterButton(TestFilter.cancelled, 'Cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(TestFilter filter, String label) {
    final isSelected = _activeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceTile1
                    : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList(List<ExamModel> exams, Color cardColor, Color textColor, Color mutedTextColor) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    List<ExamModel> filteredExams = [];
    String emptyTitle = 'No Tests Found';
    String emptySubtitle = 'There are no tests in this category.';

    switch (_activeFilter) {
      case TestFilter.upcoming:
        filteredExams = exams.where((e) {
          if (e.isCancelled) return false;
          final d = DateTime.tryParse(e.examDate) ?? now;
          final dMidnight = DateTime(d.year, d.month, d.day);
          return dMidnight.isAfter(todayMidnight);
        }).toList();
        emptyTitle = 'No Upcoming Tests';
        emptySubtitle = 'No future tests have been scheduled by your admin yet.';
        break;

      case TestFilter.today:
        filteredExams = exams.where((e) {
          if (e.isCancelled) return false;
          final d = DateTime.tryParse(e.examDate) ?? now;
          final dMidnight = DateTime(d.year, d.month, d.day);
          return dMidnight.isAtSameMomentAs(todayMidnight);
        }).toList();
        emptyTitle = 'No Tests Today';
        emptySubtitle = 'All clear! Use today to revise your notes.';
        break;

      case TestFilter.completed:
        filteredExams = exams.where((e) {
          if (e.isCancelled) return false;
          final d = DateTime.tryParse(e.examDate) ?? now;
          final dMidnight = DateTime(d.year, d.month, d.day);
          return dMidnight.isBefore(todayMidnight);
        }).toList();
        emptyTitle = 'No Completed Tests';
        emptySubtitle = 'Completed tests will appear here once submitted.';
        break;

      case TestFilter.cancelled:
        filteredExams = exams.where((e) => e.isCancelled).toList();
        emptyTitle = 'No Cancelled Tests';
        emptySubtitle = 'No tests have been cancelled by your admin.';
        break;
    }

    return AppPullToRefresh(
      onRefresh: () async {
        ref.invalidate(studentExamsListProvider);
        ref.invalidate(studentUpcomingTestProvider);
        await Future.delayed(const Duration(milliseconds: 700));
      },
      child: filteredExams.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 64, color: mutedTextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      emptyTitle,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emptySubtitle,
                      style: TextStyle(fontSize: 14, color: mutedTextColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
              itemCount: filteredExams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final exam = filteredExams[index];
        Color statusColor = AppColors.primary;
        String statusText = 'Upcoming';
        if (exam.isCancelled) {
          statusColor = AppColors.error;
          statusText = 'Test Cancelled';
        } else if (_activeFilter == TestFilter.today) {
          statusColor = const Color(0xFFF59E0B);
          statusText = 'Today';
        } else if (_activeFilter == TestFilter.completed) {
          statusColor = AppColors.success;
          statusText = 'Completed';
        }

        return _buildTestCard(
          cardColor: cardColor,
          textColor: textColor,
          mutedTextColor: mutedTextColor,
          subject: exam.subjectName,
          examName: exam.name.isEmpty ? 'Scheduled Exam' : exam.name,
          date: exam.examDate,
          time: exam.examTime.isEmpty ? '10:00 AM' : exam.examTime,
          duration: 'Scheduled Exam',
          syllabus: exam.name.isEmpty ? 'Covers full batch syllabus' : exam.name,
          marks: '${exam.maxMarks} Marks',
          status: statusText,
          statusColor: statusColor,
          isCancelled: exam.isCancelled,
        );
      },
    ),
  );
}

  Widget _buildSubjectHeaderIcon(String subject, IconData defaultIcon) {
    final lower = subject.toLowerCase();
    if (lower.contains('chem')) {
      return Image.asset(
        'assets/icons8-benzene-ring-ios-27-outlined/icons8-benzene-ring-50.png',
        width: 15,
        height: 15,
        color: Colors.white,
        colorBlendMode: BlendMode.srcIn,
      );
    }
    if (lower.contains('math') || lower.contains('algebra') || lower.contains('calculus')) {
      return Image.asset(
        'assets/icons8-pi-ios-27-filled/icons8-pi-50.png',
        width: 15,
        height: 15,
        color: Colors.white,
        colorBlendMode: BlendMode.srcIn,
      );
    }
    return Icon(defaultIcon, size: 15, color: Colors.white);
  }

  Widget _buildSubjectWatermark(String subject, IconData defaultIcon) {
    final lower = subject.toLowerCase();
    if (lower.contains('physic')) {
      return const _ProjectileDiagramWidget();
    }
    if (lower.contains('chem')) {
      return Opacity(
        opacity: 0.20,
        child: Image.asset(
          'assets/icons8-benzene-ring-ios-27-outlined/icons8-benzene-ring-100.png',
          width: 96,
          height: 96,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
      );
    }
    if (lower.contains('math') || lower.contains('algebra') || lower.contains('calculus')) {
      return Opacity(
        opacity: 0.18,
        child: Image.asset(
          'assets/icons8-pi-ios-27-filled/icons8-pi-100.png',
          width: 96,
          height: 96,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
      );
    }
    return Opacity(
      opacity: 0.18,
      child: Icon(
        defaultIcon,
        size: 96,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTestCard({
    required Color cardColor,
    required Color textColor,
    required Color mutedTextColor,
    required String subject,
    required String examName,
    required String date,
    required String time,
    required String duration,
    required String syllabus,
    required String marks,
    required String status,
    required Color statusColor,
    String? scoreObtained,
    bool isCancelled = false,
  }) {
    final theme = _SubjectThemeData.forSubject(subject);
    final cardGradient = isCancelled
        ? const LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : theme.gradient;

    return Container(
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background Watermark Diagram Icon / Projectile Motion / Benzene Ring
            Positioned(
              right: subject.toLowerCase().contains('physic') ? 4 : -10,
              bottom: subject.toLowerCase().contains('physic') ? 2 : -10,
              child: _buildSubjectWatermark(subject, theme.diagramIcon),
            ),

            // Card Content (Crisp White Typography on Solid Gradient)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Subject Icon + Title + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildSubjectHeaderIcon(subject, theme.diagramIcon),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                subject,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Exam Name
                  Text(
                    examName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Date & Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '$date • $time',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 8),
                  // Bottom Row: Marks & Syllabus Info
                  Text(
                    '${scoreObtained != null ? "Score: $scoreObtained" : "Marks: $marks"}${syllabus.isNotEmpty ? " • $syllabus" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectThemeData {
  final Gradient gradient;
  final IconData diagramIcon;

  const _SubjectThemeData({
    required this.gradient,
    required this.diagramIcon,
  });

  factory _SubjectThemeData.forSubject(String subject) {
    final lower = subject.toLowerCase();

    if (lower.contains('physic')) {
      return const _SubjectThemeData(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)], // Solid Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        diagramIcon: Icons.blur_on_rounded, // Physics orbit / atom
      );
    } else if (lower.contains('math') || lower.contains('algebra') || lower.contains('calculus')) {
      return const _SubjectThemeData(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Solid Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        diagramIcon: Icons.functions_rounded, // Maths formula
      );
    } else if (lower.contains('chem')) {
      return const _SubjectThemeData(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)], // Solid Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        diagramIcon: Icons.science_outlined, // Chemistry flask / molecule
      );
    } else if (lower.contains('bio') || lower.contains('botany') || lower.contains('zoology')) {
      return const _SubjectThemeData(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Solid Red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        diagramIcon: Icons.coronavirus_rounded, // Biology DNA / organism
      );
    }

    return const _SubjectThemeData(
      gradient: LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Solid Indigo Default
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      diagramIcon: Icons.assignment_outlined,
    );
  }
}

class _ProjectileDiagramWidget extends StatelessWidget {
  const _ProjectileDiagramWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 65),
      painter: _ProjectileMotionPainter(),
    );
  }
}

class _ProjectileMotionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Horizontal Ground Axis Line
    final yGround = size.height * 0.85;
    canvas.drawLine(Offset(0, yGround), Offset(size.width, yGround), arcPaint);

    // Parabolic Projectile Motion Arc Path
    final path = Path();
    final startX = size.width * 0.08;
    final endX = size.width * 0.92;
    final controlX = size.width * 0.50;
    final peakY = size.height * 0.18;

    path.moveTo(startX, yGround);
    path.quadraticBezierTo(controlX, peakY - (size.height * 0.16), endX, yGround);
    canvas.drawPath(path, arcPaint);

    // Launch Velocity Vector Arrow (v_0)
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(startX, yGround),
      Offset(startX + 22, yGround - 22),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(startX + 22, yGround - 22),
      Offset(startX + 14, yGround - 20),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(startX + 22, yGround - 22),
      Offset(startX + 20, yGround - 14),
      arrowPaint,
    );

    // Projectile Particle at Maximum Height Peak (H_max)
    final particlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(controlX, peakY), 3.5, particlePaint);

    // Vertical Height Marker Line (H)
    double curY = peakY;
    while (curY < yGround) {
      canvas.drawLine(Offset(controlX, curY), Offset(controlX, math.min(curY + 3, yGround)), dashPaint);
      curY += 7;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
