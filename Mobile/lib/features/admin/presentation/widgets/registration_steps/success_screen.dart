import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import '../../controllers/student_registration_controller.dart';

class SuccessScreen extends ConsumerWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentRegistrationControllerProvider);
    final details = state.finalAdmissionData ?? {};
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rollNumber = details['roll_number'] as String? ?? 'NA-2026-0001';
    final regDate = details['registration_date'] as String? ?? DateTime.now().toIso8601String();
    final admissionNumber = details['admission_number'] as String? ?? 'ADM-2026-0001';
    final tempPassword = details['temporary_password'] as String? ?? 'NA@8245';

    // Parse clean date
    String formattedDate = 'TBD';
    try {
      final parsed = DateTime.parse(regDate);
      formattedDate = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      formattedDate = regDate;
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Confetti Icon Circle
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, val, child) => Transform.scale(
                scale: val,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 72,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Success Titles
            Text(
              'Admission Successful!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The student profile has been registered and credentials created successfully.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Enrollment Details Card
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E1E20) : const Color(0xFFF9FBF9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Colors.green.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildAdmissionDetailRow('Student ID / Roll No', rollNumber, theme, isImportant: true),
                    const Divider(height: 24, thickness: 0.8),
                    _buildAdmissionDetailRow('Temporary Password', tempPassword, theme, isPassword: true),
                    const Divider(height: 24, thickness: 0.8),
                    _buildAdmissionDetailRow('Admission Number', admissionNumber, theme),
                    const Divider(height: 24, thickness: 0.8),
                    _buildAdmissionDetailRow('Registration Date', formattedDate, theme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Copy Credentials Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'Copy Credentials',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: 'Student ID: $rollNumber\nTemporary Password: $tempPassword',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Credentials copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Primary Document Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 20),
                    label: const Text('Print Form', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preparing print spooler...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading PDF...')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Communication Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366), // WhatsApp Green
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: const Color(0xFF25D366).withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text('Send WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sending credentials via WhatsApp...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.email_outlined, size: 20),
                    label: const Text('Send Email', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sending credentials via Email...')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Back to Dashboard
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                onPressed: () {
                  ref.read(studentRegistrationControllerProvider.notifier).reset();
                  context.goNamed('admin-dashboard');
                },
                child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdmissionDetailRow(
    String label,
    String value,
    ThemeData theme, {
    bool isImportant = false,
    bool isPassword = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isImportant ? 16 : 14,
            fontWeight: FontWeight.bold,
            fontFamily: isPassword ? 'monospace' : null,
            color: isImportant
                ? theme.colorScheme.primary
                : (isPassword
                    ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                    : (isDark ? Colors.white : const Color(0xFF111111))),
          ),
        ),
      ],
    );
  }
}
