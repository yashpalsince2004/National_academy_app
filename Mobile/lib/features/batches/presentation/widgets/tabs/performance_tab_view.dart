import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/features/batches/presentation/controllers/batch_detail_controller.dart';

class PerformanceTabView extends ConsumerWidget {
  final String batchId;

  const PerformanceTabView({
    super.key,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailState = ref.watch(batchDetailControllerProvider(batchId));

    final stats = detailState.performanceStats;
    final avgMarks = stats['average_marks'] as double? ?? 72.5;
    final syllabus = stats['completed_syllabus'] as double? ?? 45.0;
    final topPerformers = stats['top_performers'] as List? ?? [];
    final weakStudents = stats['weak_students'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: KPI Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildKPIValueCard(
                  context,
                  label: 'Average Marks',
                  value: '${avgMarks.toStringAsFixed(1)}%',
                  subText: 'Batch average score',
                  color: Colors.blue,
                  icon: Icons.star_border_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPIValueCard(
                  context,
                  label: 'Syllabus Progress',
                  value: '${syllabus.toStringAsFixed(0)}%',
                  subText: 'Completed modules',
                  color: Colors.purple,
                  icon: Icons.donut_large_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Syllabus Progress Bar
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
                  'Syllabus Completion Status',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: syllabus / 100,
                    minHeight: 12,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.purple),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '45% of Syllabus (18 chapters out of 40) completed. Expected completion by Oct 2026.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Row 2: Top Performers & Weak Students
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Performers Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌟 Top Performers',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...topPerformers.map((item) {
                      final name = item['name'] as String? ?? 'Student';
                      final score = item['score'] as String? ?? '90%';
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Score: $score'),
                          dense: true,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Weak Students Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Needs Attention',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...weakStudents.map((item) {
                      final name = item['name'] as String? ?? 'Student';
                      final score = item['score'] as String? ?? '45%';
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Score: $score', style: const TextStyle(color: Colors.redAccent)),
                          dense: true,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIValueCard(
    BuildContext context, {
    required String label,
    required String value,
    required String subText,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceTile1 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF333335) : AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            subText,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
