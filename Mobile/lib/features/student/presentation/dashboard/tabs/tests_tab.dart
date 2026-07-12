import 'package:flutter/material.dart';
import 'package:national_academy/core/constants/app_colors.dart';

enum TestFilter { upcoming, today, completed, missed }

class TestsTab extends StatefulWidget {
  const TestsTab({super.key});

  @override
  State<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<TestsTab> {
  TestFilter _activeFilter = TestFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

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
              child: _buildFilteredList(cardColor, textColor, mutedTextColor),
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
          _buildFilterButton(TestFilter.missed, 'Missed'),
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

  Widget _buildFilteredList(Color cardColor, Color textColor, Color mutedTextColor) {
    // Mock Data for the filter lists
    switch (_activeFilter) {
      case TestFilter.upcoming:
        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
          children: [
            _buildTestCard(
              cardColor: cardColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              subject: 'Physics',
              examName: 'Electrostatics & Gauss Law',
              date: 'July 12, 2026',
              time: '10:00 AM',
              duration: '3 Hours',
              syllabus: 'Electric Charge, Fields, Potential, Gauss Theorem and Capacitance.',
              marks: '100 Marks',
              status: 'Upcoming',
              statusColor: AppColors.primary,
            ),
            const SizedBox(height: 14),
            _buildTestCard(
              cardColor: cardColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              subject: 'Mathematics',
              examName: 'Calculus Mock Test 1',
              date: 'July 15, 2026',
              time: '02:00 PM',
              duration: '3.5 Hours',
              syllabus: 'Limits, Continuity, Derivatives and Applications of Derivatives.',
              marks: '120 Marks',
              status: 'Upcoming',
              statusColor: AppColors.primary,
            ),
          ],
        );
      case TestFilter.today:
        // No tests scheduled today demo
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 64, color: mutedTextColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No Tests Today',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                'All clear! Use today to revise your notes.',
                style: TextStyle(fontSize: 14, color: mutedTextColor),
              ),
            ],
          ),
        );
      case TestFilter.completed:
        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
          children: [
            _buildTestCard(
              cardColor: cardColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              subject: 'Chemistry',
              examName: 'Organic Chemistry Revision',
              date: 'July 09, 2026',
              time: '11:00 AM',
              duration: '2 Hours',
              syllabus: 'Hydrocarbons, Alcohols, Phenols, and Ethers reaction chains.',
              marks: '80 Marks',
              status: 'Completed',
              statusColor: AppColors.success,
              scoreObtained: '74 / 80',
            ),
            const SizedBox(height: 14),
            _buildTestCard(
              cardColor: cardColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              subject: 'Physics',
              examName: 'Mechanics & Dynamics Test 5',
              date: 'July 05, 2026',
              time: '09:00 AM',
              duration: '3 Hours',
              syllabus: 'Rotational Motion, System of Particles, Friction, Circular Motion.',
              marks: '100 Marks',
              status: 'Completed',
              statusColor: AppColors.success,
              scoreObtained: '82 / 100',
            ),
          ],
        );
      case TestFilter.missed:
        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
          children: [
            _buildTestCard(
              cardColor: cardColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              subject: 'Mathematics',
              examName: 'Vectors & 3D Geometry Quiz',
              date: 'July 01, 2026',
              time: '04:00 PM',
              duration: '1 Hour',
              syllabus: 'Vector Algebra, Dot/Cross Product, Lines & Planes in 3D Space.',
              marks: '50 Marks',
              status: 'Missed',
              statusColor: AppColors.error,
            ),
          ],
        );
    }
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Subject + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Exam Name
          Text(
            examName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          // Date & Time
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: mutedTextColor),
              const SizedBox(width: 6),
              Text(
                '$date • $time ($duration)',
                style: TextStyle(fontSize: 13, color: mutedTextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
          const SizedBox(height: 12),
          // Syllabus
          Text(
            'Syllabus:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            syllabus,
            style: TextStyle(fontSize: 13, color: mutedTextColor, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Bottom Row: Marks info + Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scoreObtained != null ? 'Score Obtained' : 'Total Marks',
                    style: TextStyle(fontSize: 11, color: mutedTextColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scoreObtained ?? marks,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: scoreObtained != null ? AppColors.success : textColor,
                    ),
                  ),
                ],
              ),
              // Button (Apple rounded style)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: Text(
                  scoreObtained != null ? 'View Analytics' : 'View Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
