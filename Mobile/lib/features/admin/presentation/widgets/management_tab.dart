import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/tactile_button.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> userSection = [
      {
        'title': 'Students',
        'subtitle': 'View & manage registered students',
        'icon': Icons.people_alt_outlined,
        'color': const Color(0xFF0284C7),
        'route': '/admin/students',
      },
      {
        'title': 'Add Student',
        'subtitle': 'Register a new student account',
        'icon': Icons.school_outlined,
        'color': const Color(0xFF0369A1),
        'route': '/admin/register-student',
      },
      {
        'title': 'Teachers',
        'subtitle': 'Manage teaching faculty & staff',
        'icon': Icons.assignment_ind_outlined,
        'color': const Color(0xFF8B5CF6),
        'route': '/admin/teachers',
      },
      {
        'title': 'Add Teacher',
        'subtitle': 'Onboard a new teacher',
        'icon': Icons.person_add_alt_1_rounded,
        'color': const Color(0xFF6D28D9),
        'route': '/admin/register-teacher',
      },
      {
        'title': 'Add Admin',
        'subtitle': 'Create new administrator credentials',
        'icon': Icons.admin_panel_settings_outlined,
        'color': const Color(0xFFEF4444),
        'route': '/admin/register-admin',
      },
    ];

    final List<Map<String, dynamic>> academicSection = [
      {
        'title': 'Batches',
        'subtitle': 'Manage class sections & timetables',
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFFF59E0B),
        'route': '/admin/batches',
      },
      {
        'title': 'Courses',
        'subtitle': 'Manage academic subjects & curriculum',
        'icon': Icons.book_outlined,
        'color': const Color(0xFF10B981),
        'route': '/admin/courses',
      },
      {
        'title': 'Exams',
        'subtitle': 'Schedule & monitor test series',
        'icon': Icons.description_outlined,
        'color': const Color(0xFFE11D48),
        'route': '/admin/exams',
      },
      {
        'title': 'Study Material',
        'subtitle': 'Upload notes & learning resources',
        'icon': Icons.folder_open_outlined,
        'color': const Color(0xFF6366F1),
        'route': '/admin/materials',
      },
    ];

    final List<Map<String, dynamic>> opsSection = [
      {
        'title': 'Fees',
        'subtitle': 'Fee structures & payment records',
        'icon': Icons.monetization_on_outlined,
        'color': const Color(0xFF10B981),
        'route': '/admin/fees',
      },
      {
        'title': 'Notices',
        'subtitle': 'Publish announcements & alerts',
        'icon': Icons.campaign_outlined,
        'color': const Color(0xFFEC4899),
        'route': '/admin/notices',
      },
      {
        'title': 'Settings',
        'subtitle': 'App configuration & system control',
        'icon': Icons.settings_outlined,
        'color': const Color(0xFF64748B),
        'route': '/admin/settings',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management Hub',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin modules and database settings control.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(context, 'User & Staff Management'),
          const SizedBox(height: 10),
          _buildSectionGroup(context, userSection, isDark),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Academic & Batches'),
          const SizedBox(height: 10),
          _buildSectionGroup(context, academicSection, isDark),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Operations & Settings'),
          const SizedBox(height: 10),
          _buildSectionGroup(context, opsSection, isDark),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSectionGroup(BuildContext context, List<Map<String, dynamic>> items, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildListTile(context, item, isDark),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : const Color(0xFFE5E5EA),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, Map<String, dynamic> item, bool isDark) {
    final theme = Theme.of(context);
    final color = item['color'] as Color;

    return TactileButton(
      scaleFactor: 0.97,
      onTap: () {
        final route = item['route'] as String;
        if (route == '/admin/register-student' ||
            route == '/admin/register-admin' ||
            route == '/admin/students' ||
            route == '/admin/batches' ||
            route == '/admin/teachers' ||
            route == '/admin/register-teacher') {
          context.push(route);
        } else {
          ToastUtils.showInfo(
            context,
            '${item['title']} module will be implemented in subsequent phases.',
            aboveNavBar: true,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
