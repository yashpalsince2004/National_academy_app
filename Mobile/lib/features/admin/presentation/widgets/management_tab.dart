import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> modules = [
      {'title': 'Students', 'icon': Icons.people_alt_outlined, 'color': Colors.blue, 'route': '/admin/students'},
      {'title': '+ Add Student', 'icon': Icons.school_outlined, 'color': Colors.blue, 'route': '/admin/register-student'},
      {'title': '+ Add Admin', 'icon': Icons.admin_panel_settings_outlined, 'color': Colors.redAccent, 'route': '/admin/register-admin'},
      {'title': 'Teachers', 'icon': Icons.assignment_ind_outlined, 'color': Colors.purple, 'route': '/admin/register-teacher'},
      {'title': 'Batches', 'icon': Icons.grid_view_rounded, 'color': Colors.orange, 'route': '/admin/batches'},
      {'title': 'Courses', 'icon': Icons.book_outlined, 'color': Colors.teal, 'route': '/admin/courses'},
      {'title': 'Fees', 'icon': Icons.monetization_on_outlined, 'color': Colors.green, 'route': '/admin/fees'},
      {'title': 'Exams', 'icon': Icons.description_outlined, 'color': Colors.red, 'route': '/admin/exams'},
      {'title': 'Notices', 'icon': Icons.campaign_outlined, 'color': Colors.pink, 'route': '/admin/notices'},
      {'title': 'Study Material', 'icon': Icons.folder_open_outlined, 'color': Colors.indigo, 'route': '/admin/materials'},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'color': Colors.blueGrey, 'route': '/admin/settings'},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management Hub',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Admin modules and database settings control.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Modules Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final mod = modules[index];
              return _buildModuleTile(context, mod);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, Map<String, dynamic> mod) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = mod['color'] as Color;

    return InkWell(
      onTap: () {
        if (mod['route'] == '/admin/register-student' ||
            mod['route'] == '/admin/register-admin' ||
            mod['route'] == '/admin/students' ||
            mod['route'] == '/admin/batches') {
          context.push(mod['route'] as String);
        } else {
          // Fallback feedback for features in planning / subsequent phases
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${mod['title']} module will be implemented in subsequent phases.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceTile1 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF333335) : AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.08),
                child: Icon(mod['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                mod['title'] as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
