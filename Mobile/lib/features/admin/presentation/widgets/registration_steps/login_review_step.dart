import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/student_registration_controller.dart';

class LoginReviewStep extends ConsumerWidget {
  final Function(int) onJumpToStep;

  const LoginReviewStep({
    super.key,
    required this.onJumpToStep,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentRegistrationControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final personal = state.personal;
    final academic = state.academic;

    final fullName = [
      personal['firstName'] as String? ?? '',
      personal['middleName'] as String? ?? '',
      personal['lastName'] as String? ?? '',
    ].where((s) => s.isNotEmpty).join(' ');
    final mobile = personal['phone'] as String? ?? '—';
    final classLevel = academic['classLevel'] as String? ?? '—';
    final exams = (academic['targetExams'] as List?)?.join(', ') ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Title
        Text(
          'Login Credentials',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 24),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2B4A) : const Color(0xFFEBF1FF),
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.primary,
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'A unique Student ID (e.g. '),
                      TextSpan(
                        text: 'NA2026-XXXX',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ') and temporary password will be auto-generated when you submit. The student can log in using either the Student ID OR the email.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Review Before Submit header
        Text(
          'REVIEW BEFORE SUBMIT',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Review table
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E20) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildReviewRow(
                context: context,
                label: 'Name',
                value: fullName.isEmpty ? '—' : fullName,
                isFirst: true,
              ),
              _buildReviewRow(
                context: context,
                label: 'Mobile',
                value: mobile,
              ),
              _buildReviewRow(
                context: context,
                label: 'Class',
                value: classLevel,
              ),
              _buildReviewRow(
                context: context,
                label: 'Exams',
                value: exams,
              ),
              _buildReviewRow(
                context: context,
                label: 'Total Fee',
                value: '—',
              ),
              _buildReviewRow(
                context: context,
                label: 'Payable',
                value: '—',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildReviewRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
