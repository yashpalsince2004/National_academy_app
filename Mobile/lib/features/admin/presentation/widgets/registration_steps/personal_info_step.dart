import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/core/utils/validators.dart';
import '../../controllers/student_registration_controller.dart';
import '../reg_input_field.dart';

class PersonalInfoStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const PersonalInfoStep({
    super.key,
    required this.formKey,
  });

  @override
  ConsumerState<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends ConsumerState<PersonalInfoStep> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  String _gender = 'Male';
  String? _bloodGroup;
  String? _photoUrl;
  Uint8List? _localPhotoBytes;

  @override
  void initState() {
    super.initState();
    final personal = ref.read(studentRegistrationControllerProvider).personal;

    // Combine first + middle + last name into full name for display
    final first = personal['firstName'] as String? ?? '';
    final middle = personal['middleName'] as String? ?? '';
    final last = personal['lastName'] as String? ?? '';
    final fullName = [first, middle, last].where((s) => s.isNotEmpty).join(' ');

    _fullNameController = TextEditingController(text: fullName);
    _emailController = TextEditingController(text: personal['email'] as String? ?? '');
    _phoneController = TextEditingController(text: personal['phone'] as String? ?? '');
    _dobController = TextEditingController(text: personal['dob'] as String? ?? '');

    _gender = personal['gender'] as String? ?? 'Male';
    _bloodGroup = personal['bloodGroup'] as String?;
    _photoUrl = personal['photoUrl'] as String?;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _saveData() {
    // Split full name back into parts
    final parts = _fullNameController.text.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.last : '';
    final middleName = parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : '';

    ref.read(studentRegistrationControllerProvider.notifier).updatePersonal({
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dob': _dobController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'gender': _gender,
      'bloodGroup': _bloodGroup,
      'photoUrl': _photoUrl,
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _localPhotoBytes = bytes;
          _isUploadingPhoto = true;
        });
        final url = await ref.read(studentRegistrationControllerProvider.notifier).uploadFile(image.name, bytes);
        setState(() {
          _photoUrl = url;
          _isUploadingPhoto = false;
        });
        _saveData();
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  void _showSourceSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Student Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      firstDate: DateTime(1995),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Form(
      key: widget.formKey,
      onChanged: _saveData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Title
          Text(
            'Personal Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 28),

          // Dashed Photo Picker Circle
          Center(
            child: GestureDetector(
              onTap: _showSourceSelectionSheet,
              child: Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dashed border circle
                        CustomPaint(
                          size: const Size(96, 96),
                          painter: _DashedCirclePainter(color: primaryColor),
                        ),
                        // Photo or camera icon
                        if (_localPhotoBytes != null)
                          ClipOval(
                            child: Image.memory(
                              _localPhotoBytes!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (_photoUrl != null)
                          ClipOval(
                            child: Image.network(
                              _photoUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (_isUploadingPhoto)
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 32,
                            color: primaryColor,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add photo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Full Name
          RegInputField(
            label: 'Full Name *',
            controller: _fullNameController,
            hintText: 'Enter student full name',
            validator: (v) => Validators.validateRequired(v, 'Full Name'),
          ),
          const SizedBox(height: 16),

          // Email
          RegInputField(
            label: 'Email (optional, auto if blank)',
            controller: _emailController,
            hintText: 'student@example.com',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.validateEmail(v);
            },
          ),
          const SizedBox(height: 16),

          // Mobile
          RegInputField(
            label: 'Mobile Number *',
            controller: _phoneController,
            hintText: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            textCapitalization: TextCapitalization.none,
            validator: (v) => Validators.validatePhone(v),
          ),
          const SizedBox(height: 16),

          // Date of Birth
          RegInputField(
            label: 'Date of Birth (YYYY-MM-DD)',
            controller: _dobController,
            hintText: 'YYYY-MM-DD',
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            textCapitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 20),

          // Gender Chips
          Text(
            'Gender',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF333333),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['Male', 'Female', 'Other'].map((option) {
              final isSelected = _gender == option;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _gender = option);
                    _saveData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? primaryColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      option,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey.shade300 : const Color(0xFF444444)),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Paints a dashed circle border
class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    const dashCount = 20;
    const dashAngle = 2 * 3.14159265358979 / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}
