import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Scrollable Content Area ───────────────────────────────────────
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: paddingTop + 84.0, // Space to clear the pinned greeting header
                bottom: 110.0, // Space for floating bottom nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Live Lecture Card (Highest Priority) ──────────────────────────
                  _buildLiveLectureCard(cardColor, textColor, mutedTextColor),
                  const SizedBox(height: 16),

                  // ── Next Lecture Card ───────────────────────────────────────────
                  _buildNextLectureCard(cardColor, textColor, mutedTextColor),
                  const SizedBox(height: 16),

                  // ── Upcoming Test Card ──────────────────────────────────────────
                  _buildUpcomingTestCard(cardColor, textColor, mutedTextColor),
                  const SizedBox(height: 16),

                  // ── Portion Completion Card ─────────────────────────────────────
                  _buildPortionCompletionCard(cardColor, textColor, mutedTextColor),
                  const SizedBox(height: 16),

                  // ── Recent Test Results Card ────────────────────────────────────
                  _buildRecentTestResultsCard(cardColor, textColor, mutedTextColor),
                  const SizedBox(height: 16),

                  // ── Attendance Streak Card ──────────────────────────────────────
                  _buildAttendanceStreakCard(cardColor, textColor, mutedTextColor),
                  const SizedBox(height: 16),

                  // ── Announcements Card ──────────────────────────────────────────
                  _buildAnnouncementsCard(cardColor, textColor, mutedTextColor),
                ],
              ),
            ),
          ),

          // ── Pinned Gradient Blur Header (iOS 26 Style) ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.only(
                    top: paddingTop + 12,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.75),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: _buildGreetingHeader(textColor, mutedTextColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Greeting Header
  Widget _buildGreetingHeader(Color textColor, Color mutedTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👋 Good Morning, Yash',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Batch: Alpha JEE Pro • July 11, 2026',
              style: TextStyle(
                fontSize: 14,
                color: mutedTextColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        // Notification bell button
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: textColor, size: 26),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Current Live Lecture Card
  Widget _buildLiveLectureCard(Color cardColor, Color textColor, Color mutedTextColor) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: AppColors.error, size: 10),
                    SizedBox(width: 6),
                    Text(
                      'LIVE LECTURE',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Physics • Mechanics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Teacher: Prof. H.C. Verma',
            style: TextStyle(fontSize: 14, color: mutedTextColor),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLectureMetaItem(Icons.access_time_rounded, '08:00 AM - 09:30 AM', mutedTextColor),
              _buildLectureMetaItem(Icons.room_rounded, 'Classroom A-102', mutedTextColor),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Next Lecture Card
  Widget _buildNextLectureCard(Color cardColor, Color textColor, Color mutedTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⏰ Next Lecture',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mutedTextColor,
                      ),
                    ),
                    const Text(
                      'in 35 min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chemistry • Organic Mechanics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Starts: 10:00 AM • Prof. Sudha Murthy',
                  style: TextStyle(fontSize: 13, color: mutedTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Upcoming Test Card
  Widget _buildUpcomingTestCard(Color cardColor, Color textColor, Color mutedTextColor) {
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
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                '📝 Upcoming Test',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Physics Unit Test • Electrostatics',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tomorrow • 10:00 AM (Duration: 3 hrs)',
            style: TextStyle(fontSize: 14, color: mutedTextColor),
          ),
        ],
      ),
    );
  }

  // 5. Portion Completion Progress Card
  Widget _buildPortionCompletionCard(Color cardColor, Color textColor, Color mutedTextColor) {
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
          Text(
            '📚 Portion Completion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubjectProgressRow('Physics', 0.82, '82%', textColor),
          const SizedBox(height: 12),
          _buildSubjectProgressRow('Chemistry', 0.64, '64%', textColor),
          const SizedBox(height: 12),
          _buildSubjectProgressRow('Maths', 0.91, '91%', textColor),
          const SizedBox(height: 12),
          _buildSubjectProgressRow('Biology', 0.70, '70% (Bio only)', textColor, isBio: true),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressRow(String subject, double value, String label, Color textColor, {bool isBio = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isBio ? textColor.withValues(alpha: 0.6) : textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isBio ? textColor.withValues(alpha: 0.6) : AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.hairline,
            valueColor: AlwaysStoppedAnimation<Color>(
              isBio ? Colors.grey : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // 6. Recent Test Results Card
  Widget _buildRecentTestResultsCard(Color cardColor, Color textColor, Color mutedTextColor) {
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
          Text(
            '🎯 Recent Test Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreRow('Physics Test 5', '82 / 100', textColor),
          const SizedBox(height: 10),
          _buildScoreRow('Chemistry Test 3', '74 / 100', textColor),
          const SizedBox(height: 10),
          _buildScoreRow('Maths Test 8', '91 / 100', textColor),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String testName, String score, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          testName,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
        Text(
          score,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // 7. Attendance Streak Card (Duolingo-style tracker)
  Widget _buildAttendanceStreakCard(Color cardColor, Color textColor, Color mutedTextColor) {
    // Mock attendance types for past 10 days
    // 1: present, 2: late, 3: absent, 4: holiday
    final mockStreak = [1, 1, 1, 1, 2, 4, 1, 3, 1, 1];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 Attendance Streak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
              const Text(
                '94% Attendance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Circular streak dots row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mockStreak.map((status) => _buildStreakDot(status)).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Current Streak: 4 days • Longest Streak: 18 days',
            style: TextStyle(fontSize: 13, color: mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDot(int status) {
    Color dotColor;
    switch (status) {
      case 1:
        dotColor = AppColors.success; // Present (Green)
        break;
      case 2:
        dotColor = Colors.orange; // Late (Orange)
        break;
      case 3:
        dotColor = AppColors.error; // Absent (Red)
        break;
      case 4:
      default:
        dotColor = Colors.grey.shade400; // Holiday (Grey)
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: dotColor, width: 2),
      ),
      child: Center(
        child: Icon(
          status == 3
              ? Icons.close_rounded
              : status == 2
                  ? Icons.priority_high_rounded
                  : status == 4
                      ? Icons.event_busy_rounded
                      : Icons.check_rounded,
          size: 12,
          color: dotColor,
        ),
      ),
    );
  }

  // 8. Announcements Card
  Widget _buildAnnouncementsCard(Color cardColor, Color textColor, Color mutedTextColor) {
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
          Text(
            '📢 Announcements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnnouncementItem('• Sunday Extra Class (Physics)', 'July 14 • 09:00 AM', textColor, mutedTextColor),
          const SizedBox(height: 10),
          _buildAnnouncementItem('• JEE Main Mock Test Schedule Updated', 'July 10 • Exam Cell', textColor, mutedTextColor),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String subtitle, Color textColor, Color mutedTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: mutedTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLectureMetaItem(IconData icon, String label, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: textColor),
        ),
      ],
    );
  }
}
