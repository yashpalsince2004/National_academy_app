import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_providers.dart';
import '../dashboard/controllers/dashboard_controller.dart';
import '../dashboard/tabs/home_tab.dart';
import '../dashboard/tabs/student_dpp_tab.dart';
import '../dashboard/tabs/profile_tab.dart';
import '../dashboard/tabs/tests_tab.dart';


class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAssignedAsync = ref.watch(studentBatchAssignedProvider);

    return batchAssignedAsync.when(
      loading: () => const _LoadingGate(),
      error: (_, __) => const _NoBatchScreen(isError: true),
      data: (isAssigned) {
        if (!isAssigned) return const _NoBatchScreen(isError: false);
        return const _StudentDashboard();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Dashboard (only shown when batch is assigned)
// ─────────────────────────────────────────────────────────────────────────────
class _StudentDashboard extends ConsumerWidget {
  const _StudentDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(dashboardTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Content Area with lazy loading index stack
            Positioned.fill(
              child: IndexedStack(
                index: activeTab.index,
                children: const [
                  HomeTab(),
                  TestsTab(),
                  StudentDppTab(),
                  ProfileTab(),
                ],

              ),
            ),

            // Floating Frosted Glass Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                bottom: true,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 32,
                        spreadRadius: 1,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.50),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tabWidth = constraints.maxWidth / 4;

                            return Stack(
                              children: [
                                // Sliding Liquid Glass Selection Bubble
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutBack,
                                  left: activeTab.index * tabWidth,
                                  width: tabWidth,
                                  top: 6,
                                  bottom: 6,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.18),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                ),

                                // Tab Items
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildNavItem(
                                        ref: ref,
                                        tab: StudentDashboardTab.home,
                                        activeTab: activeTab,
                                        icon: Icons.home_rounded,
                                        activeIcon: Icons.home_rounded,
                                        label: 'Home',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildNavItem(
                                        ref: ref,
                                        tab: StudentDashboardTab.tests,
                                        activeTab: activeTab,
                                        icon: Icons.assignment_outlined,
                                        activeIcon: Icons.assignment_rounded,
                                        label: 'Tests',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildNavItem(
                                        ref: ref,
                                        tab: StudentDashboardTab.dpp,
                                        activeTab: activeTab,
                                        icon: Icons.quiz_outlined,
                                        activeIcon: Icons.quiz_rounded,
                                        label: 'DPP',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildNavItem(
                                        ref: ref,
                                        tab: StudentDashboardTab.profile,
                                        activeTab: activeTab,
                                        icon: Icons.person_outline_rounded,
                                        activeIcon: Icons.person_rounded,
                                        label: 'Profile',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required StudentDashboardTab tab,
    required StudentDashboardTab activeTab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = tab == activeTab;
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textSecondary;

    return InkWell(
      onTap: () => ref.read(dashboardTabProvider.notifier).setTab(tab),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading Gate
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingGate extends StatelessWidget {
  const _LoadingGate();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Batch Assigned — Premium Pending Screen
// ─────────────────────────────────────────────────────────────────────────────
class _NoBatchScreen extends ConsumerWidget {
  final bool isError;
  const _NoBatchScreen({required this.isError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F11) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      textStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () async {
                      // Sign out via supabase
                      final client = ref.read(supabaseClientProvider);
                      await client.auth.signOut();
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustration container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 52,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    isError ? 'Something went wrong' : 'Awaiting Batch\nAssignment',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isError
                        ? 'We could not verify your batch status. Please sign out and try again, or contact your academy.'
                        : 'Your account is active but you haven\'t been assigned to a batch yet.\n\nPlease contact your academy admin to get enrolled in a batch.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF68686E),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Check Again'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFD1D1D6),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => ref.invalidate(studentBatchAssignedProvider),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer info pill
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Contact admin for batch enrollment',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
