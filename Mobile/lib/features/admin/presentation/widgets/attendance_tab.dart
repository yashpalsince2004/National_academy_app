import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import 'package:national_academy/core/widgets/app_dropdown.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  String? selectedBatch = 'Batch XII-A';
  String? selectedSubject = 'Physics';

  final List<String> batches = ['Batch XII-A', 'Batch XII-B', 'Batch XI-A', 'Batch XI-B'];
  final List<String> subjects = ['Physics', 'Chemistry', 'Maths', 'Biology'];

  final List<Map<String, dynamic>> mockStudents = [
    {'rollNo': 'NA-2026-0001', 'name': 'Aditya Sharma', 'status': 'present'},
    {'rollNo': 'NA-2026-0002', 'name': 'Bhavna Patel', 'status': 'present'},
    {'rollNo': 'NA-2026-0003', 'name': 'Chirag Gupta', 'status': 'absent'},
    {'rollNo': 'NA-2026-0004', 'name': 'Divya Reddy', 'status': 'present'},
    {'rollNo': 'NA-2026-0005', 'name': 'Eshwar Iyer', 'status': 'late'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Center',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),

          // Attendance Quick Actions Hub
          _buildQuickActionsHub(context),
          const SizedBox(height: 24),

          // Marking Panel Header
          Text(
            'Mark Session Attendance',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Class Filters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showRow = constraints.maxWidth > 400;
                  final batchDropdown = AppDropdown<String>(
                    label: 'Batch',
                    headerText: 'Select Batch',
                    value: selectedBatch ?? '',
                    items: batches.map((batch) {
                      return AppDropdownItem(value: batch, label: batch);
                    }).toList(),
                    onChanged: (val) => setState(() => selectedBatch = val),
                  );

                  final subjectDropdown = AppDropdown<String>(
                    label: 'Subject',
                    headerText: 'Select Subject',
                    value: selectedSubject ?? '',
                    items: subjects.map((subj) {
                      return AppDropdownItem(value: subj, label: subj);
                    }).toList(),
                    onChanged: (val) => setState(() => selectedSubject = val),
                  );

                  if (showRow) {
                    return Row(
                      children: [
                        Expanded(child: batchDropdown),
                        const SizedBox(width: 12),
                        Expanded(child: subjectDropdown),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        batchDropdown,
                        const SizedBox(height: 12),
                        subjectDropdown,
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Students Attendance List Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student List (${mockStudents.length})',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            for (var s in mockStudents) {
                              s['status'] = 'present';
                            }
                          });
                        },
                        child: const Text('Mark All Present'),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mockStudents.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final student = mockStudents[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student['rollNo'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusToggle(index),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ToastUtils.showSuccess(context, 'Attendance saved successfully!', aboveNavBar: true);
                    },
                    child: const Text('Submit Attendance'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHub(BuildContext context) {

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildActionTile(
          context,
          title: 'Defaulter List',
          subtitle: 'Attendance < 75%',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        ),
        _buildActionTile(
          context,
          title: 'Monthly Analytics',
          subtitle: 'Monthly class stats',
          icon: Icons.bar_chart_rounded,
          color: Colors.blue,
        ),
        _buildActionTile(
          context,
          title: 'Daily Reports',
          subtitle: 'Today\'s marked list',
          icon: Icons.article_outlined,
          color: Colors.orange,
        ),
        _buildActionTile(
          context,
          title: 'Export Data',
          subtitle: 'PDF/Excel Sheets',
          icon: Icons.sim_card_download_outlined,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceTile1 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF333335) : AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontSize: 10,
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

  Widget _buildStatusToggle(int index) {
    final student = mockStudents[index];
    final status = student['status'] as String;

    return Row(
      children: [
        _buildStatusButton('P', 'present', Colors.green, status, index),
        const SizedBox(width: 6),
        _buildStatusButton('A', 'absent', Colors.red, status, index),
        const SizedBox(width: 6),
        _buildStatusButton('L', 'late', Colors.orange, status, index),
      ],
    );
  }

  Widget _buildStatusButton(String label, String value, Color color, String currentStatus, int index) {
    final active = currentStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          mockStudents[index]['status'] = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : color.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
