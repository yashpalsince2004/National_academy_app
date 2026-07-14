import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/grid_background.dart';
import '../widgets/home_tab.dart';
import '../widgets/attendance_tab.dart';
import '../widgets/lectures_tab.dart';
import '../widgets/management_tab.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    AttendanceTab(),
    LecturesTab(),
    ManagementTab(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Attendance',
    'Lectures',
    'Management',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showQuickActionsBottomSheet(context),
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          FloatingNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          FloatingNavBarItem(
            icon: Icons.checklist_rtl_outlined,
            activeIcon: Icons.checklist_rtl_rounded,
            label: 'Attendance',
          ),
          FloatingNavBarItem(
            icon: Icons.class_outlined,
            activeIcon: Icons.class_rounded,
            label: 'Lectures',
          ),
          FloatingNavBarItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Management',
          ),
        ],
      ),
    );
  }

  void _showQuickActionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _buildQuickActionItem(
                      context,
                      label: 'Add Student',
                      icon: Icons.person_add_alt_1_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/register-student');
                      },
                    ),
                    _buildQuickActionItem(
                      context,
                      label: 'Add Teacher',
                      icon: Icons.assignment_ind_rounded,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _showUnderConstructionToast('Add Teacher');
                      },
                    ),
                    _buildQuickActionItem(
                      context,
                      label: 'Mark Attendance',
                      icon: Icons.checklist_rtl_rounded,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _buildQuickActionItem(
                      context,
                      label: 'Create Batch',
                      icon: Icons.grid_view_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/batches');
                      },
                    ),
                    _buildQuickActionItem(
                      context,
                      label: 'Add Notice',
                      icon: Icons.campaign_rounded,
                      color: Colors.pink,
                      onTap: () {
                        Navigator.pop(context);
                        _showUnderConstructionToast('Add Notice');
                      },
                    ),
                    _buildQuickActionItem(
                      context,
                      label: 'Schedule Class',
                      icon: Icons.class_rounded,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _buildQuickActionItem(
                      context,
                      label: 'Smart DPP',
                      icon: Icons.psychology_rounded,
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/dpp');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.08),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
          ),
        ],
      ),
    );
  }

  void _showUnderConstructionToast(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName will be implemented in subsequent phases.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
