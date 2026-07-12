import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/batch_model.dart';

class BatchCard extends StatefulWidget {
  final BatchModel batch;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const BatchCard({
    super.key,
    required this.batch,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<BatchCard> {
  /// Prevents rapid double/triple taps from pushing duplicate routes.
  bool _isNavigating = false;

  Future<void> _pushRoute(String path) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    await context.push(path);
    if (mounted) setState(() => _isNavigating = false);
  }

  Color _getExamColor(String examType) {
    switch (examType.toUpperCase()) {
      case 'JEE':
        return const Color(0xFF0066CC);
      case 'NEET':
        return const Color(0xFF34C759);
      case 'FOUNDATION':
        return const Color(0xFFFF9500);
      case 'NDA':
        return const Color(0xFFAF52DE);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final examColor = _getExamColor(batch.examType);
    final isCompleted = batch.status == 'completed';
    final activeColor = isCompleted ? const Color(0xFF8E8E93) : examColor;

    final cardBgColor = isDark ? const Color(0xFF222224) : Colors.white;
    final hairlineColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final inkColor = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final mutedInkColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF68686E);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Exam Badge + Status + Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: activeColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        batch.examType.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF8E8E93).withOpacity(0.1)
                            : const Color(0xFF34C759).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isCompleted ? const Color(0xFF8E8E93) : const Color(0xFF34C759),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'Completed' : 'Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isCompleted ? const Color(0xFF8E8E93) : const Color(0xFF34C759),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Edit + Delete buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF0066CC)),
                      onPressed: widget.onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Rename Batch',
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Batch Name
            Text(
              batch.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: inkColor,
                fontSize: 18,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),

            // Row 3: Class & Medium Info
            Text(
              'Class ${batch.classLevel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedInkColor,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Container(
                height: 1,
                color: hairlineColor,
              ),
            ),

            // Stats details
            _buildStatItem(
              context,
              icon: Icons.people_outline_rounded,
              label: 'Students Enrolled',
              value: '${batch.studentCount}/${batch.capacity}',
              mutedInkColor: mutedInkColor,
              inkColor: inkColor,
            ),
            


            const SizedBox(height: 18),

            // Row 6: Actions Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC), // Action Blue (Primary)
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999), // Pill shape
                      ),
                    ),
                    onPressed: _isNavigating ? null : () => _pushRoute('/admin/batches/${batch.id}'),
                    child: const Text(
                      'Manage Batch',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: hairlineColor),
                      backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFAFAFC),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999), // Pill shape
                      ),
                    ),
                    onPressed: _isNavigating ? null : () => _pushRoute('/admin/batches/${batch.id}?tab=2'),
                    child: Text(
                      'Attendance',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color mutedInkColor,
    required Color inkColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: mutedInkColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: mutedInkColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: inkColor,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
