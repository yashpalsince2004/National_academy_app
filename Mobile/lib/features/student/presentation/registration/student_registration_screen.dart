import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import 'package:national_academy/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:national_academy/features/student/presentation/registration/student_registration_controller.dart';

// ─── Circle Diagonal Painter for right side icon ─────────────────────────────
class CircleDiagonalPainter extends CustomPainter {
  final Color color;
  CircleDiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw outer circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width / 2) - 0.75,
      paint,
    );

    // Draw diagonal line inside (bottom-left to top-right)
    final double radius = (size.width / 2) * 0.707;
    final Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      Offset(center.dx - radius + 0.8, center.dy + radius - 0.8),
      Offset(center.dx + radius - 0.8, center.dy - radius + 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CircleDiagonalPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ─── custom menu row ────────────────────────────────────────────────────────
Widget _buildMenuItem({
  required BuildContext context,
  required String label,
  required bool isSelected,
  required bool isDisabled,
  required bool showDivider,
  Widget Function(Color color)? rightIconBuilder,
}) {
  final textColor = isDisabled
      ? Colors.black.withValues(alpha: 0.3)
      : isSelected
          ? const Color(0xFFFF3B30) // iOS System Red
          : Colors.black.withValues(alpha: 0.9);

  final iconColor = isDisabled
      ? Colors.black.withValues(alpha: 0.3)
      : isSelected
          ? const Color(0xFFFF3B30) // iOS System Red
          : Colors.black.withValues(alpha: 0.9);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: isDisabled ? null : () => Navigator.of(context).pop(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // Checkmark left (width 20)
                SizedBox(
                  width: 20,
                  child: isSelected
                      ? const Text(
                          '✓',
                          style: TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                // Option Label (lowercase to match screenshot)
                Expanded(
                  child: Text(
                    label.toLowerCase(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                // Right Icon
                rightIconBuilder?.call(iconColor) ?? CustomPaint(
                  size: const Size(18, 18),
                  painter: CircleDiagonalPainter(color: iconColor),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0x1A000000),
              indent: 16,
              endIndent: 16,
            ),
        ],
      ),
    ),
  );
}

// ─── iOS-style blur glass dropdown menu ──────────────────────────────────────
Future<String?> _showInlineMenu({
  required BuildContext context,
  required GlobalKey anchorKey,
  required List<String> options,
  required String current,
  required String title,
  Map<String, Widget Function(Color color)>? optionRightIcons,
  List<String> disabledOptions = const [],
}) async {
  final renderBox =
      anchorKey.currentContext!.findRenderObject() as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  final screenSize = MediaQuery.of(context).size;

  final width = size.width;

  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.08), // Soft dimming shadow
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      double top = offset.dy + size.height + 6;
      final menuHeight = 40.0 + (50.0 * options.length);
      
      if (top + menuHeight > screenSize.height - 20) {
        top = offset.dy - menuHeight - 6;
      }

      return Stack(
        children: [
          Positioned(
            left: offset.dx,
            top: top,
            width: width,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              alignment: top > offset.dy ? Alignment.topCenter : Alignment.bottomCenter,
              child: FadeTransition(
                opacity: animation,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Container(
                                height: 40,
                                alignment: Alignment.center,
                                child: Text(
                                  title.toLowerCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Color(0x1F000000),
                              ),
                              // Options
                              for (int i = 0; i < options.length; i++) ...[
                                _buildMenuItem(
                                  context: context,
                                  label: options[i],
                                  isSelected: options[i] == current,
                                  isDisabled: disabledOptions.contains(options[i]),
                                  showDivider: i < options.length - 1,
                                  rightIconBuilder: optionRightIcons?[options[i]],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ─── Main Widget ─────────────────────────────────────────────────────────────
class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  // Anchor keys so the popup knows where to appear
  final _genderKey = GlobalKey();
  final _classKey = GlobalKey();

  String _selectedGender = 'Male';
  String _selectedClass = '11th';
  final List<String> _selectedExams = [];
  final List<String> _availableExams = ['JEE', 'NEET', 'MHT-CET', 'NDA', 'Boards Only'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedExams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one target exam')),
        );
        return;
      }

      final user = ref.read(authControllerProvider).maybeMap(
            authenticated: (u) => u.user,
            orElse: () => null,
          );

      if (user == null) return;

      ref.read(studentRegistrationControllerProvider.notifier).registerStudent(
            uid: user.uid,
            email: user.email,
            name: _nameController.text.trim(),
            gender: _selectedGender,
            phoneNumber: _phoneController.text.trim(),
            parentPhoneNumber: _parentPhoneController.text.trim(),
            registeredClass: _selectedClass,
            targetExams: _selectedExams,
            onSuccess: () async {
              await ref.read(authControllerProvider.notifier).refreshUser();
              if (mounted) {
                context.go('/student/dashboard');
              }
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(error), backgroundColor: AppColors.error),
              );
            },
          );
    }
  }

  // ── Circular liquid glass back button ────────────────────────────────────
  Widget _buildLiquidGlassBackButton({required VoidCallback onPressed}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.ink,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── iOS-style selector tile (anchored with GlobalKey) ─────────────────────
  Widget _buildSelectorTile({
    required GlobalKey tileKey,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRegistrationControllerProvider);
    final isSubmitting = state.maybeWhen(
      submitting: () => true,
      orElse: () => false,
    );

    final userEmail = ref.read(authControllerProvider).maybeMap(
          authenticated: (u) => u.user.email,
          orElse: () => '',
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildLiquidGlassBackButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login/student');
              }
            },
          ),
        ),
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 40.0,
              top: kToolbarHeight + 48.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────
                  const Text(
                    'Welcome to National Academy!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please provide your details to get started with your learning journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Glassmorphic form card ─────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Personal Information'),
                              const SizedBox(height: 20),

                              // Email (read-only)
                              _buildTextField(
                                controller:
                                    TextEditingController(text: userEmail),
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),

                              // Full Name
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                validator: (v) => (v == null || v.length < 3)
                                    ? 'Enter your full name (min 3 chars)'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Gender & Class — stacked on mobile, side-by-side on tablet
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final isMobile = constraints.maxWidth < 500;

                                  final genderTile = _buildSelectorTile(
                                    tileKey: _genderKey,
                                    icon: Icons.wc_rounded,
                                    label: 'Gender',
                                    value: _selectedGender,
                                    onTap: () async {
                                      final result = await _showInlineMenu(
                                        context: context,
                                        anchorKey: _genderKey,
                                        options: ['Male', 'Female'],
                                        current: _selectedGender,
                                        title: 'Gender',
                                        optionRightIcons: {
                                          'Male': (color) => Icon(Icons.male_rounded, color: color, size: 20),
                                          'Female': (color) => Icon(Icons.female_rounded, color: color, size: 20),
                                        },
                                      );
                                      if (result != null) {
                                        setState(
                                            () => _selectedGender = result);
                                      }
                                    },
                                  );

                                  final classTile = _buildSelectorTile(
                                    tileKey: _classKey,
                                    icon: Icons.school_outlined,
                                    label: 'Registered Class',
                                    value: _selectedClass,
                                    onTap: () async {
                                      final result = await _showInlineMenu(
                                        context: context,
                                        anchorKey: _classKey,
                                        options: [
                                          '11th',
                                          '12th',
                                          '11th + 12th'
                                        ],
                                        current: _selectedClass,
                                        title: 'Class',
                                        optionRightIcons: {
                                          '11th': (color) => Icon(Icons.school_outlined, color: color, size: 20),
                                          '12th': (color) => Icon(Icons.school_outlined, color: color, size: 20),
                                          '11th + 12th': (color) => Icon(Icons.menu_book_outlined, color: color, size: 20),
                                        },
                                      );
                                      if (result != null) {
                                        setState(() => _selectedClass = result);
                                      }
                                    },
                                  );

                                  if (isMobile) {
                                    return Column(
                                      children: [
                                        genderTile,
                                        const SizedBox(height: 16),
                                        classTile,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: genderTile),
                                      const SizedBox(width: 16),
                                      Expanded(child: classTile),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    (v == null || v.length != 10)
                                        ? 'Enter a valid 10-digit phone number'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Parent Phone
                              _buildTextField(
                                controller: _parentPhoneController,
                                label: 'Parent Phone Number',
                                icon: Icons.family_restroom_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    (v == null || v.length != 10)
                                        ? 'Enter a valid 10-digit parent number'
                                        : null,
                              ),
                              const SizedBox(height: 28),

                              // ── Target Exams ─────────────────────────
                              _buildSectionHeader('Target Exams'),
                              const SizedBox(height: 4),
                              const Text(
                                'Select all that apply',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 14),

                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _availableExams.map((exam) {
                                  final isSelected =
                                      _selectedExams.contains(exam);
                                  return AnimatedScale(
                                    scale: isSelected ? 1.05 : 1.0,
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        if (isSelected) {
                                          _selectedExams.remove(exam);
                                        } else {
                                          _selectedExams.add(exam);
                                        }
                                      }),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 11),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.white
                                                  .withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.hairline,
                                            width: 1.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(0, 4),
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          exam,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 36),

                              // ── Submit button ─────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Complete Registration',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}