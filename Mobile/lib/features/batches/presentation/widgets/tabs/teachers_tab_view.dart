import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/features/batches/presentation/controllers/batch_detail_controller.dart';

class TeachersTabView extends ConsumerStatefulWidget {
  final String batchId;
  final String courseId;

  const TeachersTabView({
    super.key,
    required this.batchId,
    required this.courseId,
  });

  @override
  ConsumerState<TeachersTabView> createState() => _TeachersTabViewState();
}

class _TeachersTabViewState extends ConsumerState<TeachersTabView> {
  String? _selectedTeacherId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batchDetailControllerProvider(widget.batchId).notifier).loadSubjects(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailState = ref.watch(batchDetailControllerProvider(widget.batchId));
    final controller = ref.read(batchDetailControllerProvider(widget.batchId).notifier);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Faculty & Subjects',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Teachers List Card
            if (detailState.teachers.isEmpty) ...[
              const Center(child: Text('No teachers found.'))
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detailState.teachers.length.clamp(0, 3), // show first few as assigned teachers
                itemBuilder: (context, index) {
                  final teacher = detailState.teachers[index];
                  // mock assigning subjects for layout representation
                  final String subject = index == 0 ? 'Physics' : (index == 1 ? 'Chemistry' : 'Mathematics');
                  final bool isPrimary = index == 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isPrimary ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                            child: Text(teacher['full_name']?[0] ?? 'T'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      teacher['full_name'] ?? 'Teacher',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isPrimary)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Primary',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Subject: $subject',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded),
                            tooltip: 'Reassign Subject',
                            onPressed: () => _showReassignDialog(context, controller, teacher['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Form to assign teacher
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceTile1 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF333335) : AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Faculty to Subject',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Select Teacher Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Teacher',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: detailState.teachers.map((t) {
                      return DropdownMenuItem(
                        value: t['id'] as String,
                        child: Text(t['full_name'] as String),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTeacherId = val),
                  ),
                  const SizedBox(height: 16),

                  // Select Subject Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Subject',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: detailState.subjects.map((s) {
                      return DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name'] as String),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_selectedTeacherId == null || _selectedSubjectId == null)
                          ? null
                          : () => _assignTeacher(controller),
                      child: const Text(
                        'Assign Faculty',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTeacher(BatchDetailController controller) async {
    try {
      await controller.assignTeacher(
        teacherId: _selectedTeacherId!,
        subjectId: _selectedSubjectId!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty assigned successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReassignDialog(BuildContext context, BatchDetailController controller, String teacherId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Faculty'),
        content: const Text('Would you like to reassign this faculty to another subject or remove their assignments?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Reassign'),
            onPressed: () {
              Navigator.pop(ctx);
              // prompt subject selection or general assign
            },
          ),
        ],
      ),
    );
  }
}
