import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/batch_controller.dart';
import '../widgets/tabs/students_tab_view.dart';
import '../widgets/tabs/attendance_tab_view.dart';
import '../widgets/tabs/timetable_tab_view.dart';
import '../widgets/tabs/performance_tab_view.dart';
import '../widgets/rename_batch_dialog.dart';
import '../../data/models/batch_model.dart';

class BatchDetailsScreen extends ConsumerStatefulWidget {
  final String batchId;

  const BatchDetailsScreen({
    super.key,
    required this.batchId,
  });

  @override
  ConsumerState<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends ConsumerState<BatchDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 1. Resolve batch details
    final batchesState = ref.watch(batchControllerProvider);
    final batch = batchesState.maybeWhen(
      data: (list) {
        final matches = list.where((b) => b.id == widget.batchId);
        return matches.isNotEmpty ? matches.first : null;
      },
      orElse: () => null,
    );

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(batch.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Batch Name',
            onPressed: () => _showEditNameSheet(context, batch),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive Batch',
            onPressed: () => _confirmArchive(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete Batch',
            onPressed: () => _confirmDelete(context, batch.studentCount),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header details block
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            color: isDark ? AppColors.surfaceTile1 : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        batch.examType.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Class ${batch.classLevel}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniHeaderStat(context, 'Strength', '${batch.studentCount}/${batch.capacity}'),
                    _buildMiniHeaderStat(context, 'Att. Rate', '90%'),
                    _buildMiniHeaderStat(context, 'Syllabus', '45%'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: isDark ? AppColors.surfaceTile1 : Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Students'),
                Tab(text: 'Attendance'),
                Tab(text: 'Timetable'),
                Tab(text: 'Performance'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StudentsTabView(
                  batchId: batch.id,
                  classLevel: batch.classLevel,
                  examType: batch.examType,
                ),
                AttendanceTabView(batchId: batch.id),
                TimetableTabView(batchId: batch.id),
                PerformanceTabView(batchId: batch.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHeaderStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showEditNameSheet(BuildContext context, BatchModel batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: RenameBatchDialog(batch: batch),
      ),
    );
  }

  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Batch'),
        content: const Text('Are you sure you want to complete and archive this batch? Enrolled students will still retain read-only histories.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Archive'),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(batchControllerProvider.notifier).archiveBatch(widget.batchId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch archived successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error archiving: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int studentCount) {
    if (studentCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deletion Prevented'),
          content: const Text('Cannot delete a batch while students are still assigned to it. Please remove all students or archive the batch instead.'),
          actions: [
            TextButton(
              child: const Text('Okay'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text('Archive Instead'),
              onPressed: () {
                Navigator.pop(ctx);
                _confirmArchive(context);
              },
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Batch'),
        content: const Text('Are you sure you want to permanently delete this batch? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(batchControllerProvider.notifier).deleteBatch(widget.batchId);
                if (context.mounted) {
                  context.pop(); // return to dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch deleted successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
