import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/widgets/app_pull_to_refresh.dart';
import 'package:national_academy/features/batches/data/models/exam_model.dart';
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

    final profileAsync = ref.watch(studentFullProfileProvider);
    final batchAsync = ref.watch(studentEnrolledBatchProvider);
    final examsAsync = ref.watch(studentExamsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AppPullToRefresh(
          onRefresh: () async {
            ref.invalidate(studentFullProfileProvider);
            ref.invalidate(studentEnrolledBatchProvider);
            ref.invalidate(studentExamsListProvider);
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 20),

                // ── Profile Information Card (Live Data) ─────────────────────────
                profileAsync.when(
                  data: (profile) => _buildProfileHeaderCard(
                    profile,
                    cardColor,
                    textColor,
                    mutedTextColor,
                  ),
                  loading: () => _buildLoadingCard(cardColor),
                  error: (_, __) => _buildProfileHeaderCard(
                    null,
                    cardColor,
                    textColor,
                    mutedTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Performance Metrics Row (Live Stats) ────────────────────────
                examsAsync.when(
                  data: (exams) => _buildMetricsRow(
                    exams,
                    batchAsync.value,
                    cardColor,
                    textColor,
                    mutedTextColor,
                  ),
                  loading: () => _buildMetricsRow(
                    [],
                    batchAsync.value,
                    cardColor,
                    textColor,
                    mutedTextColor,
                  ),
                  error: (_, __) => _buildMetricsRow(
                    [],
                    batchAsync.value,
                    cardColor,
                    textColor,
                    mutedTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Academic Info Card (Live Batch Data) ──────────────────────────
                _buildAcademicInfoCard(
                  profileAsync.value,
                  batchAsync.value,
                  cardColor,
                  textColor,
                  mutedTextColor,
                ),
                const SizedBox(height: 24),

                // ── Streak Calendar Card ─────────────────────────────────────────
                const StreakCalendar(streakCount: 61),
                const SizedBox(height: 24),

                // ── Account Settings & Actions Menu ─────────────────────────────
                _buildSettingsList(context, ref, cardColor, textColor, mutedTextColor),
                const SizedBox(height: 28),

                // ── Play Store & App Info Footer ──────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'National Academy • Version 1.0.4',
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/playstore.png',
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
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

  Widget _buildLoadingCard(Color cardColor) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProfileHeaderCard(
    StudentFullProfileData? profile,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    final name = profile?.name ?? 'Student';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final rollNo = profile?.rollNo ?? 'NA-2026';
    final email = profile?.email ?? 'student@nationalacademy.com';
    final phone = profile?.phone ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Circular Gradient Avatar with Initial
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Enrolled',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: $rollNo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: mutedTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Phone: $phone',
                    style: TextStyle(fontSize: 12, color: mutedTextColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(
    List<ExamModel> exams,
    StudentEnrolledBatch? batch,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    final activeExams = exams.where((e) => !e.isCancelled).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            cardColor: cardColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            icon: Icons.assignment_rounded,
            iconColor: AppColors.primary,
            title: 'Exams Listed',
            value: '$activeExams Tests',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            cardColor: cardColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            icon: Icons.school_rounded,
            iconColor: AppColors.success,
            title: 'Enrolled Batch',
            value: batch != null ? '1 Active' : '0 Batches',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            cardColor: cardColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            title: 'Daily Streak',
            value: '61 Days',
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: mutedTextColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard(
    StudentFullProfileData? profile,
    StudentEnrolledBatch? batch,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    final batchName = batch?.name.isNotEmpty == true ? batch!.name : 'Primary Batch';
    final rawLevel = batch?.classLevel.isNotEmpty == true ? batch!.classLevel : (profile?.registeredClass ?? '12th');
    final classLevel = rawLevel.toLowerCase().contains('th') ? rawLevel : '${rawLevel}th Standard';
    final targetExam = batch?.examType.isNotEmpty == true ? batch!.examType : (profile?.targetExams ?? 'JEE / NEET');

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Academic Enrolment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Batch Name', batchName, textColor, mutedTextColor),
          const SizedBox(height: 10),
          _buildInfoRow('Standard Class', classLevel, textColor, mutedTextColor),
          const SizedBox(height: 10),
          _buildInfoRow('Target Entrance', targetExam, textColor, mutedTextColor),
          if (profile?.parentPhone != null && profile!.parentPhone.isNotEmpty && profile.parentPhone != 'Not provided') ...[
            const SizedBox(height: 10),
            _buildInfoRow('Emergency Contact', profile.parentPhone, textColor, mutedTextColor),
          ],
          const SizedBox(height: 10),
          _buildInfoRow('Account Status', profile?.status ?? 'Active Subscriptions', textColor, mutedTextColor),
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
          style: TextStyle(fontSize: 13, color: mutedTextColor),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Sign Out Account',
            textColor: AppColors.error,
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of National Academy?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ref.read(authControllerProvider.notifier).logout();
                        context.goNamed('role-selection');
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
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
