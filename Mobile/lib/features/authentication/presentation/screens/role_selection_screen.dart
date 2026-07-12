import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceTile3 : AppColors.canvasParchment,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Brand Logo & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    width: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.school_rounded,
                      size: 36,
                      color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'National Academy',
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.ink,
                          letterSpacing: -0.28,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Select your portal to continue',
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),

              // Admin Card
              _buildRoleCard(
                context: context,
                title: 'Admin Portal',
                subtitle: 'Manage classes, student records, admissions, fees, and results.',
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => context.pushNamed('admin-login'),
              ),

              const SizedBox(height: 20),

              // Student Card
              _buildRoleCard(
                context: context,
                title: 'Student Portal',
                subtitle: 'Check class schedules, homework, report cards, fees, and notices.',
                icon: Icons.backpack_rounded,
                onTap: () => context.pushNamed('student-login'),
              ),

              const Spacer(),
              
              // Footer
              Text(
                '© 2026 National Academy. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textLight,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? AppColors.surfaceTile1 : AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0xFF333335) : AppColors.hairline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 21,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            height: 1.3,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.primaryOnDark : AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
