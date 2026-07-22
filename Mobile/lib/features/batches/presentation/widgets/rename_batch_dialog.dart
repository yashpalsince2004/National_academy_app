import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/batch_model.dart';
import '../../../../core/utils/toast_utils.dart';
import '../controllers/batch_controller.dart';

class RenameBatchDialog extends ConsumerStatefulWidget {
  final BatchModel batch;

  const RenameBatchDialog({
    super.key,
    required this.batch,
  });

  @override
  ConsumerState<RenameBatchDialog> createState() => _RenameBatchDialogState();
}

class _RenameBatchDialogState extends ConsumerState<RenameBatchDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late String _selectedClass;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.batch.name);
    // Default to existing class level, ensuring it is sanitized ('11' or '12')
    _selectedClass = widget.batch.classLevel == '11' ? '11' : '12';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Form(
        key: _formKey,
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
              'Manage Batch',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Update details for "${widget.batch.name}".',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Batch Name',
                hintText: 'e.g. JEE Advanced 2026',
                prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0066CC), width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Batch name cannot be empty';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Class Level Toggle Header
            Text(
              'Class Level',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // Segment Toggle
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedClass = '11'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedClass == '11'
                              ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Center(
                          child: Text(
                            '11th Class',
                            style: TextStyle(
                              fontWeight: _selectedClass == '11' ? FontWeight.w600 : FontWeight.w500,
                              color: _selectedClass == '11'
                                  ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedClass = '12'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedClass == '12'
                              ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Center(
                          child: Text(
                            '12th Class',
                            style: TextStyle(
                              fontWeight: _selectedClass == '12' ? FontWeight.w600 : FontWeight.w500,
                              color: _selectedClass == '12'
                                  ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _saving = true);
                        final navigator = Navigator.of(context);
                        try {
                          final updated = widget.batch.copyWith(
                            name: _controller.text.trim(),
                            classLevel: _selectedClass,
                          );
                          await ref
                              .read(batchControllerProvider.notifier)
                              .updateBatch(updated);
                          if (mounted) {
                            navigator.pop();
                            ToastUtils.showSuccess(context, 'Batch updated successfully.', aboveNavBar: true);
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _saving = false);
                            ToastUtils.showError(context, 'Error: $e');
                          }
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
