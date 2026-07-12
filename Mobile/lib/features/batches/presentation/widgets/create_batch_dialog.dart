import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/features/admin/presentation/widgets/custom_dropdown_field.dart';
import '../controllers/batch_controller.dart';

class CreateBatchDialog extends ConsumerStatefulWidget {
  const CreateBatchDialog({super.key});

  @override
  ConsumerState<CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends ConsumerState<CreateBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedExam = 'JEE';
  String _selectedClass = '12'; // '11' or '12'
  bool _isLoading = false;

  final List<String> _exams = const ['JEE', 'NEET', 'Foundation', 'NDA', 'Boards'];

  String _getCourseIdForExam(String exam) {
    switch (exam.toUpperCase()) {
      case 'JEE':
        return 'd1a3b5c7-e9f1-4a3b-8c5d-7e9f1a3b5c7d';
      case 'NEET':
        return 'e2b4c6d8-f0a2-5b4c-9d6e-8f0a2b4c6d8e';
      case 'NDA':
        return 'f3c5d7e9-f1a3-6b5c-0d7f-9f1a3b5c7d9e';
      case 'BOARDS':
      default:
        return 'a4d6e8f0-a2b4-7b6c-1d8f-0a2b4c6d8e0f';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF222224) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7C7CC),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),

                  Text(
                    'Create New Batch',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Batch Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Batch Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Batch name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Exam Type (Using custom dropdown field)
                  CustomDropdownField<String>(
                    labelText: 'Exam Stream',
                    value: _selectedExam,
                    items: _exams,
                    itemLabelBuilder: (item) => item,
                    prefixIcon: Icons.workspace_premium_rounded,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExam = val);
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
                  const SizedBox(height: 32),

                  // Save & Cancel Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066CC), // Action Blue
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          ),
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'Create Batch',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final courseId = _getCourseIdForExam(_selectedExam);

      await ref.read(batchControllerProvider.notifier).createBatch(
            name: name,
            courseId: courseId,
            examType: _selectedExam,
            classLevel: _selectedClass,
            medium: 'English',
            lectureDays: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
            capacity: 40,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 365)),
            startTime: '09:00:00',
            endTime: '11:00:00',
            roomNumber: 'Room 101',
            color: _selectedExam == 'JEE'
                ? 'blue'
                : (_selectedExam == 'NEET'
                    ? 'green'
                    : (_selectedExam == 'Foundation' ? 'orange' : 'purple')),
            remarks: 'Default creation',
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch "$name" created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
