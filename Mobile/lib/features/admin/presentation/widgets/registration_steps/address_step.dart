import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/utils/validators.dart';
import '../../controllers/student_registration_controller.dart';
import '../reg_input_field.dart';

class AddressStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const AddressStep({
    super.key,
    required this.formKey,
  });

  @override
  ConsumerState<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<AddressStep> {
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    final personal = ref.read(studentRegistrationControllerProvider).personal;
    _addressLineController = TextEditingController(text: personal['address'] as String? ?? '');
    _cityController = TextEditingController(text: personal['city'] as String? ?? '');
    _stateController = TextEditingController(text: personal['state'] as String? ?? '');
    _pincodeController = TextEditingController(text: personal['pinCode'] as String? ?? '');
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _saveData() {
    final personal = ref.read(studentRegistrationControllerProvider).personal;
    ref.read(studentRegistrationControllerProvider.notifier).updatePersonal({
      ...personal,
      'address': _addressLineController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pinCode': _pincodeController.text.trim(),
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
            'Address',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 28),

          // Address Line — full width
          RegInputField(
            label: 'Address Line (House, Area)',
            controller: _addressLineController,
            hintText: 'House no, Area, Street',
            validator: (v) => Validators.validateRequired(v, 'Address'),
          ),
          const SizedBox(height: 16),

          // City + State — side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RegInputField(
                  label: 'City',
                  controller: _cityController,
                  hintText: 'City',
                  validator: (v) => Validators.validateRequired(v, 'City'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: RegInputField(
                  label: 'State',
                  controller: _stateController,
                  hintText: 'State',
                  validator: (v) => Validators.validateRequired(v, 'State'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pincode
          RegInputField(
            label: 'Pincode',
            controller: _pincodeController,
            hintText: '6-digit pincode',
            keyboardType: TextInputType.number,
            textCapitalization: TextCapitalization.none,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Pincode is required';
              if (v.trim().length != 6) return 'Pincode must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
