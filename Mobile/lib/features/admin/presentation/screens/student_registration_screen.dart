import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import '../controllers/student_registration_controller.dart';
import '../controllers/student_registration_state.dart';

// Import individual steps
import '../widgets/registration_steps/personal_info_step.dart';
import '../widgets/registration_steps/academic_details_step.dart';
import '../widgets/registration_steps/family_details_step.dart';
import '../widgets/registration_steps/address_step.dart';
import '../widgets/registration_steps/login_review_step.dart';
import '../widgets/registration_steps/success_screen.dart';

/// Step metadata for the pill tabs
class _StepInfo {
  final String label;
  final IconData icon;

  const _StepInfo(this.label, this.icon);
}

const List<_StepInfo> _steps = [
  _StepInfo('Personal', Icons.person_rounded),
  _StepInfo('Academic', Icons.school_rounded),
  _StepInfo('Parents', Icons.group_rounded),
  _StepInfo('Address', Icons.home_rounded),
  _StepInfo('Login', Icons.key_rounded),
];

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends ConsumerState<StudentRegistrationScreen> {
  // One form key per step (steps 0–3 have forms; step 4 is review-only)
  final List<GlobalKey<FormState>> _stepFormKeys = [
    GlobalKey<FormState>(), // 0 Personal
    GlobalKey<FormState>(), // 1 Academic
    GlobalKey<FormState>(), // 2 Parents
    GlobalKey<FormState>(), // 3 Address
  ];

  bool _isValidatingUniqueness = false;

  // ScrollController for tab strip
  final ScrollController _tabScrollController = ScrollController();

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  // ─── Scrolls the tab strip so the active tab is visible ─────────────────
  void _scrollTabToVisible(int step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabScrollController.hasClients) {
        // Each tab is roughly 110px wide; scroll to keep active centred
        final targetOffset = (step * 110.0) - 60.0;
        _tabScrollController.animateTo(
          targetOffset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ─── Navigation ──────────────────────────────────────────────────────────
  Future<void> _handleNext() async {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final state = ref.read(studentRegistrationControllerProvider);
    final step = state.currentStep;

    if (step < 4) {
      // Validate the form for steps 0–3
      final formKey = _stepFormKeys[step];
      if (formKey.currentState == null || !formKey.currentState!.validate()) return;

      // Step 0: uniqueness check + photo check
      if (step == 0) {
        final email = state.personal['email'] as String? ?? '';
        final phone = state.personal['phone'] as String? ?? '';

        setState(() => _isValidatingUniqueness = true);
        final duplicateMsg =
            await controller.checkUniqueness(email: email, phone: phone);
        setState(() => _isValidatingUniqueness = false);

        if (duplicateMsg != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(duplicateMsg), backgroundColor: Colors.red),
          );
          return;
        }
      }

      // Autosave
      await controller.saveStepDraft();
      controller.setStep(step + 1);
      _scrollTabToVisible(step + 1);
    } else if (step == 4) {
      // Final step → submit
      _showConfirmDialog();
    }
  }

  void _handleBack() {
    final step = ref.read(studentRegistrationControllerProvider).currentStep;
    if (step > 0) {
      ref.read(studentRegistrationControllerProvider.notifier).setStep(step - 1);
      _scrollTabToVisible(step - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Confirm Admission'),
          content: const Text('Are you sure you want to submit? A Student ID (Roll Number) and temporary password will be auto-generated for the student.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitAdmission('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAdmission(String password) async {
    final success =
        await ref.read(studentRegistrationControllerProvider.notifier).submitAdmission(password);
    if (success && mounted) {
      ref.read(studentRegistrationControllerProvider.notifier).setStep(5);
    } else if (mounted) {
      final error = ref.read(studentRegistrationControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Registration failed.'), backgroundColor: Colors.red),
      );
    }
  }

  // ─── Step Widget Builder ─────────────────────────────────────────────────
  Widget _buildStepWidget(int step) {
    switch (step) {
      case 0:
        return PersonalInfoStep(formKey: _stepFormKeys[0]);
      case 1:
        return AcademicDetailsStep(formKey: _stepFormKeys[1]);
      case 2:
        return FamilyDetailsStep(formKey: _stepFormKeys[2]);
      case 3:
        return AddressStep(formKey: _stepFormKeys[3]);
      case 4:
        return LoginReviewStep(
          onJumpToStep: (idx) {
            ref.read(studentRegistrationControllerProvider.notifier).setStep(idx);
            _scrollTabToVisible(idx);
          },
        );
      case 5:
        return const SuccessScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Pill Tab Strip ──────────────────────────────────────────────────────
  Widget _buildPillTabStrip(int currentStep) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _buildPillTab(context, index, currentStep);
        },
      ),
    );
  }

  Widget _buildPillTab(BuildContext context, int index, int currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final step = _steps[index];

    final isActive = index == currentStep;
    final isCompleted = index < currentStep;

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;

    if (isActive) {
      bgColor = primaryColor;
      borderColor = primaryColor;
      textColor = Colors.white;
      iconColor = Colors.white;
    } else if (isCompleted) {
      bgColor = Colors.transparent;
      borderColor = const Color(0xFF34A853); // Google green
      textColor = const Color(0xFF34A853);
      iconColor = const Color(0xFF34A853);
    } else {
      bgColor = Colors.transparent;
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
      textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
      iconColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    }

    return GestureDetector(
      onTap: isCompleted
          ? () {
              ref.read(studentRegistrationControllerProvider.notifier).setStep(index);
              _scrollTabToVisible(index);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : step.icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              step.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRegistrationControllerProvider);
    final currentStep = state.currentStep;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isSuccessStep = currentStep == 5;
    final isReviewStep = currentStep == 4;
    final isLoading = state.status == RegistrationStatus.loading;

    return PopScope(
      canPop: !state.hasUnsavedChanges || isSuccessStep,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved registration data. Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && mounted) {
          ref.read(studentRegistrationControllerProvider.notifier).reset();
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E0E0F) : Colors.white,
        // ── App Bar ────────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0E0E0F) : Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: isSuccessStep
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : const Color(0xFF111111),
                  ),
                  onPressed: () {
                    if (currentStep > 0) {
                      _handleBack();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
          title: Text(
            isSuccessStep ? 'Registration Complete' : 'Add Student',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          // Autosave indicator
          actions: [
            if (!isSuccessStep && state.isAutosaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              ),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              // ── Pill Tab Strip ──────────────────────────────────────────
              if (!isSuccessStep) ...[
                const SizedBox(height: 8),
                _buildPillTabStrip(currentStep),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
                ),
              ],

              // ── Step Content ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: isLoading && !isSuccessStep
                      ? const SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Processing admission...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey<int>(currentStep),
                            child: _buildStepWidget(currentStep),
                          ),
                        ),
                ),
              ),

              // ── Bottom Navigation Bar ───────────────────────────────────
              if (!isSuccessStep) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
                ),
                Container(
                  color: isDark ? const Color(0xFF0E0E0F) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Row(
                    children: [
                      // BACK button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _handleBack,
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                          label: const Text('BACK'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isReviewStep
                                ? AppColors.primary
                                : (isDark ? Colors.grey.shade300 : const Color(0xFF333333)),
                            side: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // NEXT / CREATE STUDENT button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (isLoading || _isValidatingUniqueness) ? null : _handleNext,
                          icon: _isValidatingUniqueness
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(
                                  isReviewStep ? Icons.check_rounded : Icons.chevron_right_rounded,
                                  size: 20,
                                ),
                          iconAlignment: isReviewStep ? IconAlignment.start : IconAlignment.end,
                          label: Text(isReviewStep ? 'CREATE STUDENT' : 'NEXT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReviewStep
                                ? const Color(0xFF34A853) // Green for final step
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
