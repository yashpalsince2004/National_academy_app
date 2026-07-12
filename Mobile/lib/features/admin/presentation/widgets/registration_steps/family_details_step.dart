import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/utils/validators.dart';
import '../../controllers/student_registration_controller.dart';
import '../reg_input_field.dart';

class FamilyDetailsStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const FamilyDetailsStep({
    super.key,
    required this.formKey,
  });

  @override
  ConsumerState<FamilyDetailsStep> createState() => _FamilyDetailsStepState();
}

class _FamilyDetailsStepState extends ConsumerState<FamilyDetailsStep> {
  // Father
  late TextEditingController _fatherNameController;
  late TextEditingController _fatherMobileController;
  late TextEditingController _fatherEmailController;
  late TextEditingController _fatherOccController;

  // Mother
  late TextEditingController _motherNameController;
  late TextEditingController _motherMobileController;
  late TextEditingController _motherEmailController;
  late TextEditingController _motherOccController;

  @override
  void initState() {
    super.initState();
    final parents = ref.read(studentRegistrationControllerProvider).parents;
    final father = parents['father'] as Map<String, dynamic>? ?? {};
    final mother = parents['mother'] as Map<String, dynamic>? ?? {};

    _fatherNameController = TextEditingController(text: father['name'] as String? ?? '');
    _fatherMobileController = TextEditingController(text: father['mobile'] as String? ?? '');
    _fatherEmailController = TextEditingController(text: father['email'] as String? ?? '');
    _fatherOccController = TextEditingController(text: father['occupation'] as String? ?? '');

    _motherNameController = TextEditingController(text: mother['name'] as String? ?? '');
    _motherMobileController = TextEditingController(text: mother['mobile'] as String? ?? '');
    _motherEmailController = TextEditingController(text: mother['email'] as String? ?? '');
    _motherOccController = TextEditingController(text: mother['occupation'] as String? ?? '');
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _fatherMobileController.dispose();
    _fatherEmailController.dispose();
    _fatherOccController.dispose();
    _motherNameController.dispose();
    _motherMobileController.dispose();
    _motherEmailController.dispose();
    _motherOccController.dispose();
    super.dispose();
  }

  void _saveData() {
    final parents = ref.read(studentRegistrationControllerProvider).parents;
    ref.read(studentRegistrationControllerProvider.notifier).updateParents({
      ...parents,
      'father': {
        'name': _fatherNameController.text.trim(),
        'mobile': _fatherMobileController.text.trim(),
        'email': _fatherEmailController.text.trim(),
        'occupation': _fatherOccController.text.trim(),
      },
      'mother': {
        'name': _motherNameController.text.trim(),
        'mobile': _motherMobileController.text.trim(),
        'email': _motherEmailController.text.trim(),
        'occupation': _motherOccController.text.trim(),
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      onChanged: _saveData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Title
          Text(
            'Parents',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 28),

          // Father Section
          _buildSectionHeader(context, 'Father\'s Details'),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Father\'s Name *',
            controller: _fatherNameController,
            hintText: 'Full name',
            validator: (v) => Validators.validateRequired(v, 'Father\'s Name'),
          ),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Father\'s Mobile *',
            controller: _fatherMobileController,
            hintText: '10-digit mobile',
            keyboardType: TextInputType.phone,
            textCapitalization: TextCapitalization.none,
            validator: (v) => Validators.validatePhone(v),
          ),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Father\'s Email',
            controller: _fatherEmailController,
            hintText: 'Optional email',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.validateEmail(v);
            },
          ),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Occupation',
            controller: _fatherOccController,
            hintText: 'e.g. Engineer, Teacher',
          ),
          const SizedBox(height: 28),

          // Mother Section
          _buildSectionHeader(context, 'Mother\'s Details'),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Mother\'s Name *',
            controller: _motherNameController,
            hintText: 'Full name',
            validator: (v) => Validators.validateRequired(v, 'Mother\'s Name'),
          ),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Mother\'s Mobile',
            controller: _motherMobileController,
            hintText: '10-digit mobile (optional)',
            keyboardType: TextInputType.phone,
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.validatePhone(v);
            },
          ),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Mother\'s Email',
            controller: _motherEmailController,
            hintText: 'Optional email',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.validateEmail(v);
            },
          ),
          const SizedBox(height: 14),

          RegInputField(
            label: 'Occupation',
            controller: _motherOccController,
            hintText: 'e.g. Homemaker, Doctor',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
      ),
    );
  }
}
