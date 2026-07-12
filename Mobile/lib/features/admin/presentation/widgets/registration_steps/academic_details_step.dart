import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/utils/validators.dart';
import '../../controllers/student_registration_controller.dart';
import '../reg_input_field.dart';

class AcademicDetailsStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const AcademicDetailsStep({
    super.key,
    required this.formKey,
  });

  @override
  ConsumerState<AcademicDetailsStep> createState() => _AcademicDetailsStepState();
}

class _AcademicDetailsStepState extends ConsumerState<AcademicDetailsStep> {
  late TextEditingController _classController;
  late TextEditingController _schoolNameController;
  late TextEditingController _scoreController;
  late TextEditingController _boardController;
  late TextEditingController _yearController;

  // Multi-select exam chips
  final List<String> _allExams = ['JEE', 'NEET', 'NDA', 'MHT-CET', 'Boards'];
  List<String> _selectedExams = [];

  @override
  void initState() {
    super.initState();
    final academic = ref.read(studentRegistrationControllerProvider).academic;

    _classController = TextEditingController(text: academic['classLevel'] as String? ?? '');
    _schoolNameController = TextEditingController(text: academic['previousSchoolName'] as String? ?? '');
    _scoreController = TextEditingController(text: academic['previousPercentage']?.toString() ?? '');
    _boardController = TextEditingController(text: academic['board'] as String? ?? '');
    _yearController = TextEditingController(text: academic['passingYear']?.toString() ?? '');

    // Restore selected exams
    final savedExams = academic['targetExams'];
    if (savedExams is List) {
      _selectedExams = List<String>.from(savedExams);
    }
  }

  @override
  void dispose() {
    _classController.dispose();
    _schoolNameController.dispose();
    _scoreController.dispose();
    _boardController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(studentRegistrationControllerProvider.notifier).updateAcademic({
      'classLevel': _classController.text.trim(),
      'previousSchoolName': _schoolNameController.text.trim(),
      'previousPercentage': _scoreController.text.trim(),
      'board': _boardController.text.trim(),
      'passingYear': _yearController.text.trim(),
      'targetExams': _selectedExams,
      'course': _selectedExams.isNotEmpty ? _selectedExams.join(', ') : '',
    });
  }

  void _toggleExam(String exam) {
    setState(() {
      if (_selectedExams.contains(exam)) {
        _selectedExams.remove(exam);
      } else {
        _selectedExams.add(exam);
      }
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final fillColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F2F5);
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF333333);
    final textColor = isDark ? Colors.white : const Color(0xFF111111);

    return Form(
      key: widget.formKey,
      onChanged: _saveData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Title
          Text(
            'Academic Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 28),

          // Class field
          RegInputField(
            label: 'Class (e.g. 11, 12)',
            controller: _classController,
            hintText: 'e.g. 11 or 12',
            keyboardType: TextInputType.text,
            validator: (v) => Validators.validateRequired(v, 'Class'),
          ),
          const SizedBox(height: 20),

          // Target Exams — Multi-select chips
          Text(
            'Target Exam(s) — multi-select',
            style: theme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allExams.map((exam) {
              final isSelected = _selectedExams.contains(exam);
              return GestureDetector(
                onTap: () => _toggleExam(exam),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    exam,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade300 : const Color(0xFF444444)),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // School Name
          RegInputField(
            label: 'School Name',
            controller: _schoolNameController,
            hintText: 'Previous school name',
          ),
          const SizedBox(height: 20),

          // 10th Score Details
          Text(
            '10th Score Details',
            style: theme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // % Score
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '% Score',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _scoreController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _saveData(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '00.00',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Board
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Board',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _boardController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => _saveData(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'CBSE',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Year
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Year',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _saveData(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '2024',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
