import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import '../../../../authentication/presentation/controllers/auth_controller.dart';
import '../widgets/streak_calendar.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 16.0,
            bottom: 110.0, // Space for floating bottom nav
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Title ────────────────────────────────────────────────
              Text(
                'Student Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 24),

              // ── Profile Information Card ─────────────────────────────────────
              _buildProfileHeaderCard(cardColor, textColor, mutedTextColor),
              const SizedBox(height: 16),

              // ── Performance Metrics Row ──────────────────────────────────────
              _buildMetricsRow(cardColor, textColor, mutedTextColor),
              const SizedBox(height: 16),

              // ── Academic Info Card ───────────────────────────────────────────
              _buildAcademicInfoCard(cardColor, textColor, mutedTextColor),
              const SizedBox(height: 24),

              // ── Streak Calendar Card ─────────────────────────────────────────
              const StreakCalendar(streakCount: 61),
              const SizedBox(height: 24),

              // ── Settings Action Menu ─────────────────────────────────────────
              _buildSettingsList(context, ref, cardColor, textColor, mutedTextColor),
              const SizedBox(height: 32),

              // ── Play Store Badge ──────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'Get the app on Google Play Store',
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          // Optional: Launch Play Store URL if needed
                        },
                        child: Image.asset(
                          'assets/images/playstore.png',
                          height: 44,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(Color cardColor, Color textColor, Color mutedTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Circular Avatar with Letter Initials
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Center(
              child: Text(
                'Y',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yash Vardhan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: NA-2026-0894',
                  style: TextStyle(fontSize: 14, color: mutedTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'yash.vardhan@nationalacademy.com',
                  style: TextStyle(fontSize: 13, color: mutedTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(Color cardColor, Color textColor, Color mutedTextColor) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            cardColor: cardColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            icon: Icons.percent_rounded,
            iconColor: AppColors.primary,
            title: 'Attendance',
            value: '94%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            cardColor: cardColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            icon: Icons.grade_rounded,
            iconColor: AppColors.success,
            title: 'Avg Marks',
            value: '82.6%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            cardColor: cardColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            icon: Icons.assignment_turned_in_rounded,
            iconColor: Colors.orange,
            title: 'Exams Taken',
            value: '16 / 18',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required Color cardColor,
    required Color textColor,
    required Color mutedTextColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: mutedTextColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard(Color cardColor, Color textColor, Color mutedTextColor) {
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
            'Academic Enrolment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Batch Name', 'Alpha JEE Pro', textColor, mutedTextColor),
          const SizedBox(height: 12),
          _buildInfoRow('Standard Class', '12th (Senior Secondary)', textColor, mutedTextColor),
          const SizedBox(height: 12),
          _buildInfoRow('Target Entrance', 'JEE Advanced & MHT-CET', textColor, mutedTextColor),
          const SizedBox(height: 12),
          _buildInfoRow('Access Status', 'Active Subscriptions', textColor, mutedTextColor),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color mutedTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: mutedTextColor),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    return Material(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.local_library_rounded,
            iconColor: Colors.deepOrange,
            title: 'My Library',
            textColor: textColor,
            onTap: () {
              // TODO: Navigate to library screen
            },
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
          _buildMenuItem(
            icon: Icons.edit_rounded,
            iconColor: AppColors.primary,
            title: 'Edit Personal Details',
            textColor: textColor,
            onTap: () {},
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
          _buildMenuItem(
            icon: Icons.notifications_active_rounded,
            iconColor: Colors.deepPurple,
            title: 'Push Notifications Settings',
            textColor: textColor,
            onTap: () {},
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.success,
            title: 'Contact Academy Helpdesk',
            textColor: textColor,
            onTap: () {},
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Sign Out Account',
            textColor: AppColors.error,
            onTap: () {
              ref.read(authControllerProvider.notifier).logout();
              context.goNamed('role-selection');
            },
          ),
        ],
      ),
    );

  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
