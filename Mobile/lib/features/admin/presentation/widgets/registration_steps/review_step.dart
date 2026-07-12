import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import '../../controllers/student_registration_controller.dart';

class ReviewStep extends ConsumerWidget {
  final Function(int) onJumpToStep;

  const ReviewStep({
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
    final parents = state.parents;
    final additional = state.additional;

    final father = parents['father'] as Map<String, dynamic>? ?? {};
    final mother = parents['mother'] as Map<String, dynamic>? ?? {};
    final siblings = parents['siblings'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Header
        Text(
          'Review & Verify Admission',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Please review the student profile details before finalizing the admission.',
          style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Personal Details Card
        _buildSectionCard(
          context: context,
          title: 'Personal Information',
          stepIndex: 0,
          children: [
            if (personal['photoUrl'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(personal['photoUrl'] as String),
                  ),
                ),
              ),
            _buildDetailRow('Full Name', '${personal['firstName'] ?? ''} ${personal['middleName'] ?? ''} ${personal['lastName'] ?? ''}'.trim()),
            _buildDetailRow('Email', personal['email'] ?? 'Not provided'),
            _buildDetailRow('Mobile Number', personal['phone'] ?? 'Not provided'),
            _buildDetailRow('Gender', personal['gender'] ?? 'Not provided'),
            _buildDetailRow('Date of Birth', personal['dob'] ?? 'Not provided'),
            _buildDetailRow('Blood Group', personal['bloodGroup'] ?? 'Not provided'),
            _buildDetailRow('Address', '${personal['address'] ?? ''}, ${personal['city'] ?? ''}, ${personal['state'] ?? ''} - ${personal['pinCode'] ?? ''}'),
          ],
        ),
        const SizedBox(height: 16),

        // Academic Details Card
        _buildSectionCard(
          context: context,
          title: 'Academic Details',
          stepIndex: 1,
          children: [
            _buildDetailRow('Target Class', academic['classLevel'] ?? 'Not provided'),
            _buildDetailRow('Course Stream', academic['course'] ?? 'Not provided'),
            _buildDetailRow('Assigned Batch', academic['batch'] ?? 'Not provided'),
            _buildDetailRow('Study Medium', academic['medium'] ?? 'Not provided'),
            _buildDetailRow('Previous School', academic['previousSchoolName'] ?? 'Not provided'),
            _buildDetailRow('Education Board', academic['board'] ?? 'Not provided'),
            _buildDetailRow('Passing Year', academic['passingYear']?.toString() ?? 'Not provided'),
            _buildDetailRow('Seat Number', academic['seatNumber'] ?? 'Not provided'),
            _buildDetailRow('Roll Number', academic['rollNumber'] ?? 'Not provided'),
            _buildDetailRow('10th Marks', '${academic['obtainedMarks'] ?? '0'} / ${academic['totalMarks'] ?? '0'} (${academic['previousPercentage'] ?? '0'}%)'),
            _buildDetailRow('Obtained CGPA', academic['cgpa']?.toString() ?? 'Not provided'),
          ],
        ),
        const SizedBox(height: 16),

        // Parents & Siblings Card
        _buildSectionCard(
          context: context,
          title: 'Family Information',
          stepIndex: 2,
          children: [
            _buildDetailSubHeader('Father details'),
            _buildDetailRow('Father\'s Name', father['name'] ?? 'Not provided'),
            _buildDetailRow('Father\'s Phone', father['mobile'] ?? 'Not provided'),
            _buildDetailRow('Occupation', father['occupation'] ?? 'Not provided'),
            _buildDetailRow('Annual Income', father['annualIncome'] != null ? 'INR ${father['annualIncome']}' : 'Not provided'),

            _buildDetailSubHeader('Mother details'),
            _buildDetailRow('Mother\'s Name', mother['name'] ?? 'Not provided'),
            _buildDetailRow('Mother\'s Phone', mother['mobile'] ?? 'Not provided'),
            _buildDetailRow('Occupation', mother['occupation'] ?? 'Not provided'),

            if (parents['guardianName'] != null && (parents['guardianName'] as String).trim().isNotEmpty) ...[
              _buildDetailSubHeader('Guardian details'),
              _buildDetailRow('Guardian Name', parents['guardianName']),
              _buildDetailRow('Guardian Phone', parents['guardianMobile']),
              _buildDetailRow('Relationship', parents['guardianRelationship']),
            ],

            if (siblings.isNotEmpty) ...[
              _buildDetailSubHeader('Siblings Details (${siblings.length})'),
              for (var sib in siblings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '• ${sib['name'] ?? ''} - Class: ${sib['class'] ?? ''}, Age: ${sib['age'] ?? ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Additional Info & Documents Card
        _buildSectionCard(
          context: context,
          title: 'Additional Info & Documents',
          stepIndex: 3,
          children: [
            _buildDetailRow('Medical Conditions', additional['medicalConditions'] ?? 'None reported'),
            _buildDetailRow('Allergies', additional['allergies'] ?? 'None reported'),
            _buildDetailRow('Current Medications', additional['currentMedications'] ?? 'None'),
            _buildDetailRow('Transport Required', (additional['transportRequired'] as bool? ?? false) ? 'Yes' : 'No'),
            _buildDetailRow('Hostel Required', (additional['hostelRequired'] as bool? ?? false) ? 'Yes' : 'No'),
            _buildDetailRow('Scholarship Request', (additional['scholarship'] as bool? ?? false) ? 'Yes' : 'No'),
            _buildDetailRow('Referenced By', additional['reference'] ?? 'Direct'),

            _buildDetailSubHeader('Attached Documents'),
            _buildDocumentStatusRow('10th Marksheet', academic['marksheetUrl']),
            _buildDocumentStatusRow('Leaving Certificate', academic['leavingCertificateUrl']),
            _buildDocumentStatusRow('Birth Certificate', additional['birthCertificateUrl']),
            _buildDocumentStatusRow('Income Certificate', additional['incomeCertificateUrl']),
            _buildDocumentStatusRow('Caste Certificate', additional['casteCertificateUrl']),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required int stepIndex,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title + Edit Trigger
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 13)),
                  onPressed: () => onJumpToStep(stepIndex),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDocumentStatusRow(String label, String? fileUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(
            fileUrl != null ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: fileUrl != null ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: fileUrl != null ? FontWeight.bold : FontWeight.normal,
              color: fileUrl != null ? null : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
