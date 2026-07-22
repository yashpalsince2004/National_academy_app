import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:national_academy/core/widgets/app_dropdown.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/utils/toast_utils.dart';
import '../controllers/dpp_generator_controller.dart';
import '../../data/models/dpp_model.dart';

class DppPreviewScreen extends ConsumerStatefulWidget {
  const DppPreviewScreen({super.key});

  @override
  ConsumerState<DppPreviewScreen> createState() => _DppPreviewScreenState();
}

class _DppPreviewScreenState extends ConsumerState<DppPreviewScreen> {
  final Map<int, bool> _expandedQuestions = {};
  bool _isAllExpanded = false;
  bool _isLoadingDialogShowing = false;

  void _showLoadingDialog() {
    if (_isLoadingDialogShowing || !mounted) return;
    _isLoadingDialogShowing = true;

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final borderC = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/Animation/sparkles_loop_loader_ai.lottie',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Regenerating Smart DPP...',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Formulating a fresh set of questions and detailed solutions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isLoadingDialogShowing = false;
    });
  }

  void _hideLoadingDialog() {
    if (_isLoadingDialogShowing && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isLoadingDialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(dppGeneratorControllerProvider);
    final dpp = state.generatedDpp;

    ref.listen(dppGeneratorControllerProvider, (previous, next) {
      if (next.isGenerating) {
        _showLoadingDialog();
      } else {
        _hideLoadingDialog();
      }
    });

    if (dpp == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smart DPP Preview')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No DPP generated yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF151516) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Smart DPP Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate DPP',
            onPressed: state.isGenerating ? null : () => _regenerate(context),
          ),
          IconButton(
            icon: Icon(_isAllExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded),
            tooltip: _isAllExpanded ? 'Collapse All' : 'Expand All',
            onPressed: () {
              setState(() {
                _isAllExpanded = !_isAllExpanded;
                for (int i = 0; i < dpp.questions.length; i++) {
                  _expandedQuestions[i] = _isAllExpanded;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: () => _exportPdf(dpp),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              // Statistics Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066CC).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dpp.examType,
                            style: const TextStyle(color: Color(0xFF0066CC), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dpp.classLevel,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dpp.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    if (dpp.chapterName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chapter: ${dpp.chapterName}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    // Grid stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Questions', '${dpp.configQuestions}'),
                        _buildStat('Total Marks', '${dpp.configTotalMarks}'),
                        _buildStat('Time Limit', '${dpp.configTimeMinutes}m'),
                        _buildStat('Difficulty', dpp.difficulty, color: _getDifficultyColor(dpp.difficulty)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Questions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Formulated Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${dpp.questions.length} Items',
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Question Cards
              ...dpp.questions.asMap().entries.map((entry) {
                final index = entry.key;
                final q = entry.value;
                final isExpanded = _expandedQuestions[index] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Header / Text
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    q.questionType,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                             const SizedBox(height: 10),
                             MathText(
                               q.questionText,
                               style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                             ),
                             if (q.options != null && q.options!.isNotEmpty) ...[
                               const SizedBox(height: 16),
                               ...q.options!.asMap().entries.map((opt) {
                                 final label = String.fromCharCode((65 + opt.key).toInt()); // A, B, C, D
                                 return Container(
                                   width: double.infinity,
                                   margin: const EdgeInsets.only(bottom: 8),
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                     borderRadius: BorderRadius.circular(10),
                                   ),
                                   child: Row(
                                     children: [
                                       CircleAvatar(
                                         radius: 12,
                                         backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                         child: Text(
                                           label,
                                           style: TextStyle(
                                             fontSize: 11,
                                             fontWeight: FontWeight.bold,
                                             color: theme.colorScheme.primary,
                                           ),
                                         ),
                                       ),
                                       const SizedBox(width: 12),
                                       Expanded(
                                         child: MathText(
                                           opt.value,
                                           style: theme.textTheme.bodyMedium,
                                         ),
                                       ),
                                     ],
                                   ),
                                 );
                               }),
                             ]
                          ],
                        ),
                      ),

                      // Expandable Answer / Explanation Footer
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF232325) : const Color(0xFFFAFAFC),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Column(
                          children: [
                            // Material wrapper required: ListTile paints ink on the nearest
                            // Material ancestor; without it the DecoratedBox background hides splashes.
                            Material(
                              color: Colors.transparent,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              child: ListTile(
                                dense: true,
                                title: const Text('View Answer & Detailed Solution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                trailing: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                                onTap: () {
                                  setState(() {
                                    _expandedQuestions[index] = !isExpanded;
                                  });
                                },
                              ),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            'Correct Answer: ',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              q.correctAnswer,
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text('Detailed Solution:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        MathText(
                                          q.explanation!,
                                          style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.4),
                                        ),
                                      ],
                                      if (q.learningOutcome != null && q.learningOutcome!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Learning Outcome: ${q.learningOutcome}',
                                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ],
                                  ),
                                ),
                              )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),
            ],
          ),

          // Floating Pill Bottom Action Panel
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton.outlined(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: const CircleBorder(),
                      side: const BorderSide(color: Color(0xFF0066CC)),
                    ),
                    onPressed: state.isGenerating ? null : () => _regenerate(context),
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0066CC), size: 20),
                    tooltip: 'Regenerate Questions',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: borderColor),
                      ),
                      onPressed: state.isGenerating ? null : () => _saveDraft(context),
                      icon: const Icon(Icons.save_as_rounded, size: 18),
                      label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: state.isGenerating ? null : () => _showAssignDialog(context, dpp, state.batches, state.students),
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                      label: const Text('Assign DPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }

  Color _getDifficultyColor(String diff) {
    if (diff.toLowerCase() == 'easy') return Colors.green;
    if (diff.toLowerCase() == 'advanced') return Colors.red;
    return Colors.orange;
  }

  void _regenerate(BuildContext context) async {
    try {
      await ref.read(dppGeneratorControllerProvider.notifier).regenerateDpp();
      if (!mounted) return;
      final err = ref.read(dppGeneratorControllerProvider).error;
      if (err != null) {
        ToastUtils.showError(context, err);
      } else {
        ToastUtils.showSuccess(context, 'DPP regenerated with fresh questions!');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Failed to regenerate: $e');
      }
    }
  }

  void _exportPdf(DppModel dpp) async {
    try {
      await PdfService.exportDppToPdf(dpp);
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Error exporting PDF: $e');
      }
    }
  }

  void _saveDraft(BuildContext context) async {
    try {
      await ref.read(dppGeneratorControllerProvider.notifier).saveDppDraft();
      if (context.mounted) {
        ToastUtils.showSuccess(context, 'DPP draft saved successfully.');
        context.pop(); // return to dashboard
      }
    } catch (e) {
      ToastUtils.showError(context, 'Error: $e');
    }
  }

  void _showAssignDialog(
    BuildContext context,
    DppModel dpp,
    List<Map<String, dynamic>> batches,
    List<Map<String, dynamic>> students,
  ) {
    String assigneeType = 'batch';
    String? selectedBatchId = batches.isNotEmpty ? batches.first['id'] as String? : null;
    String? selectedStudentId = students.isNotEmpty ? students.first['id'] as String? : null;
    DateTime scheduledDate = DateTime.now();
    DateTime dueDatePicker = DateTime.now().add(const Duration(days: 2));
    bool notify = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setInnerState) {
          final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
          final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

          return Material(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  Text(
                    'Assign DPP Set',
                    style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Toggle batch vs student
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Entire Batch'),
                          selected: assigneeType == 'batch',
                          onSelected: (val) {
                            if (val) setInnerState(() => assigneeType = 'batch');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Selected Student'),
                          selected: assigneeType == 'student',
                          onSelected: (val) {
                            if (val) setInnerState(() => assigneeType = 'student');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selectors
                  if (assigneeType == 'batch') ...[
                    const Text('Select Target Batch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: selectedBatchId ?? '',
                      headerText: 'Select Batch',
                      items: batches.map((b) => AppDropdownItem(
                        value: b['id'] as String,
                        label: b['name'] as String,
                      )).toList(),
                      onChanged: (val) => setInnerState(() => selectedBatchId = val),
                    ),
                  ] else ...[
                    const Text('Select Target Student', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: selectedStudentId ?? '',
                      headerText: 'Select Student',
                      items: students.map((s) => AppDropdownItem(
                        value: s['id'] as String,
                        label: s['name'] as String,
                      )).toList(),
                      onChanged: (val) => setInnerState(() => selectedStudentId = val),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Due date selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${dueDatePicker.day}/${dueDatePicker.month}/${dueDatePicker.year}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: sheetCtx,
                            initialDate: dueDatePicker,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setInnerState(() => dueDatePicker = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notification toggle
                  SwitchListTile(
                    title: const Text('Send notification to students', style: TextStyle(fontSize: 14)),
                    value: notify,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setInnerState(() => notify = val),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await ref.read(dppGeneratorControllerProvider.notifier).assignDpp(
                                assigneeType: assigneeType,
                                batchId: assigneeType == 'batch' ? selectedBatchId : null,
                                studentId: assigneeType == 'student' ? selectedStudentId : null,
                                scheduledAt: scheduledDate,
                                dueAt: dueDatePicker,
                                notify: notify,
                              );
                          if (context.mounted) {
                            ToastUtils.showSuccess(context, 'DPP assigned successfully.');
                            context.pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ToastUtils.showError(context, 'Error: $e');
                          }
                        }
                      },
                      child: const Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? mathStyle;

  const MathText(this.text, {super.key, this.style, this.mathStyle});

  @override
  Widget build(BuildContext context) {
    if (!text.contains('\$')) {
      return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: style,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Split text by block math delimiter ($$)
    final blockParts = text.split('\$\$');
    final List<Widget> children = [];

    for (int i = 0; i < blockParts.length; i++) {
      final part = blockParts[i];
      if (part.isEmpty) continue;

      if (i % 2 == 1) {
        // Block Math Formula
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  part.trim(),
                  mathStyle: MathStyle.display,
                  textStyle: mathStyle ?? style?.copyWith(
                    fontSize: (style?.fontSize ?? 14) + 2,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onErrorFallback: (err) => Text('\$\$$part\$\$', style: style),
                ),
              ),
            ),
          ),
        );
      } else {
        // Text containing potential inline math formulas ($)
        final inlineParts = part.split('\$');
        if (inlineParts.length == 1) {
          if (part.trim().isNotEmpty) {
            children.add(MarkdownBody(
              data: part,
              styleSheet: MarkdownStyleSheet(p: style),
            ));
          }
        } else {
          // Mixed inline text and inline math
          final List<InlineSpan> spans = [];
          for (int j = 0; j < inlineParts.length; j++) {
            final subPart = inlineParts[j];
            if (subPart.isEmpty) continue;

            if (j % 2 == 1) {
              // Inline math formula
              spans.add(
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Math.tex(
                    subPart.trim(),
                    mathStyle: MathStyle.text,
                    textStyle: mathStyle ?? style?.copyWith(
                      fontSize: style?.fontSize ?? 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onErrorFallback: (err) => Text('\$$subPart\$', style: style),
                  ),
                ),
              );
            } else {
              // Plain text segment
              spans.add(TextSpan(text: subPart, style: style));
            }
          }
          children.add(
            RichText(
              text: TextSpan(
                children: spans,
                style: style ?? DefaultTextStyle.of(context).style,
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
