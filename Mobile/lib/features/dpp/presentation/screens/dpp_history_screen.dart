import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/utils/toast_utils.dart';
import '../controllers/dpp_history_controller.dart';
import '../controllers/dpp_generator_controller.dart';
import '../../data/models/dpp_model.dart';

class DppHistoryScreen extends ConsumerWidget {
  const DppHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(dppHistoryControllerProvider);

    final scaffoldBgColor = isDark ? const Color(0xFF151516) : const Color(0xFFF5F5F7);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Generated DPPs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(dppHistoryControllerProvider.notifier).loadHistory(),
          )
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: isDark ? AppColors.surfaceTile1 : Colors.white,
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                      hintText: 'Search by title, chapter or topics...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) =>
                        ref.read(dppHistoryControllerProvider.notifier).updateSearchQuery(val),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        value: state.selectedDifficulty,
                        headerText: 'Difficulty',
                        items: [
                          AppDropdownItem(value: 'All', label: 'All Difficulties'),
                          AppDropdownItem(value: 'Easy', label: 'Easy'),
                          AppDropdownItem(value: 'Medium', label: 'Medium'),
                          AppDropdownItem(value: 'Advanced', label: 'Advanced'),
                        ],
                        onChanged: (val) {
                          ref.read(dppHistoryControllerProvider.notifier).updateFilterDifficulty(val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Body
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)))
                : state.dpps.isEmpty
                    ? _buildEmptyState(theme, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.dpps.length,
                        itemBuilder: (ctx, index) {
                          final dpp = state.dpps[index];
                          return _buildDppHistoryCard(ctx, ref, dpp, cardBg, borderColor, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF0066CC).withOpacity(0.06),
              child: const Icon(Icons.description_outlined, size: 40, color: Color(0xFF0066CC)),
            ),
            const SizedBox(height: 20),
            Text(
              'No DPPs Generated Yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Specify test criteria in the generator dashboard to formulate your first AI smart DPP.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDppHistoryCard(
    BuildContext context,
    WidgetRef ref,
    DppModel dpp,
    Color cardBg,
    Color borderColor,
    ThemeData theme,
  ) {
    final statusColor = dpp.status == 'published' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            dpp.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.3),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Text(
                  '${dpp.subjectName ?? dpp.subjectId} • ${dpp.examType}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dpp.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailRow('Class', dpp.classLevel),
                      _buildDetailRow('Questions', '${dpp.configQuestions}'),
                      _buildDetailRow('Difficulty', dpp.difficulty),
                    ],
                  ),
                  if (dpp.chapterName != null) ...[
                    const SizedBox(height: 8),
                    Text('Chapter: ${dpp.chapterName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // View/Edit
                      TextButton.icon(
                        icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                        label: const Text('Preview'),
                        onPressed: () {
                          ref.read(dppGeneratorControllerProvider.notifier).updateGeneratedDpp(dpp);
                          context.push('/admin/dpp/preview');
                        },
                      ),
                      const SizedBox(width: 4),
                      // PDF
                      TextButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text('PDF'),
                        onPressed: () => PdfService.exportDppToPdf(dpp),
                      ),
                      const SizedBox(width: 4),
                      // Duplicate
                      TextButton.icon(
                        icon: const Icon(Icons.copy_all_rounded, size: 16),
                        label: const Text('Copy'),
                        onPressed: () async {
                          final duplicated = await ref
                              .read(dppHistoryControllerProvider.notifier)
                              .duplicateDpp(dpp);
                          if (duplicated != null && context.mounted) {
                            ToastUtils.showSuccess(context, 'DPP duplicated as Draft.');
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => _confirmDelete(context, ref, dpp),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DppModel dpp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete DPP'),
        content: Text('Are you sure you want to permanently delete "${dpp.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(dppHistoryControllerProvider.notifier).deleteDpp(dpp.id);
              if (context.mounted) {
                ToastUtils.showSuccess(context, 'DPP deleted successfully.');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
