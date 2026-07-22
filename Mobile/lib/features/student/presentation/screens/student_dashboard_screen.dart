import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/grid_background.dart';
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

    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return batchAssignedAsync.when(
            loading: () => const _LoadingGate(),
            error: (_, __) => const _NoBatchScreen(isError: true),
            data: (isAssigned) {
              if (!isAssigned) return const _NoBatchScreen(isError: false);
              return const _StudentDashboard();
            },
          );
        },
      ),
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
        child: GridBackground(
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

            // Floating Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                currentIndex: activeTab.index,
                onTap: (index) {
                  ref.read(dashboardTabProvider.notifier).setTab(StudentDashboardTab.values[index]);
                },
                items: const [
                  FloatingNavBarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  FloatingNavBarItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment_rounded,
                    label: 'Tests',
                  ),
                  FloatingNavBarItem(
                    icon: Icons.quiz_outlined,
                    activeIcon: Icons.quiz_rounded,
                    label: 'DPP',
                  ),
                  FloatingNavBarItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
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
