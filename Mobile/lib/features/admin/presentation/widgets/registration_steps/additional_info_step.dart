import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:national_academy/core/constants/app_colors.dart';
import '../../controllers/student_registration_controller.dart';

class AdditionalInfoStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const AdditionalInfoStep({
    super.key,
    required this.formKey,
  });

  @override
  ConsumerState<AdditionalInfoStep> createState() => _AdditionalInfoStepState();
}

class _AdditionalInfoStepState extends ConsumerState<AdditionalInfoStep> {
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _medicalController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _specialNeedsController;
  late TextEditingController _referenceController;
  late TextEditingController _counsellorController;
  late TextEditingController _remarksController;
  late TextEditingController _notesController;

  bool _transportRequired = false;
  bool _hostelRequired = false;
  bool _scholarship = false;

  String? _birthCertUrl;
  String? _incomeCertUrl;
  String? _casteCertUrl;
  String? _anyOtherDocUrl;

  final Map<String, bool> _uploadingStates = {};

  @override
  void initState() {
    super.initState();
    final additional = ref.read(studentRegistrationControllerProvider).additional;

    _medicalController = TextEditingController(text: additional['medicalConditions']);
    _allergiesController = TextEditingController(text: additional['allergies']);
    _medicationsController = TextEditingController(text: additional['currentMedications']);
    _specialNeedsController = TextEditingController(text: additional['specialNeeds']);
    _referenceController = TextEditingController(text: additional['reference'] ?? 'Direct Walk-in');
    _counsellorController = TextEditingController(text: additional['counsellorName']);
    _remarksController = TextEditingController(text: additional['remarks']);
    _notesController = TextEditingController(text: additional['optionalNotes']);

    _transportRequired = additional['transportRequired'] as bool? ?? false;
    _hostelRequired = additional['hostelRequired'] as bool? ?? false;
    _scholarship = additional['scholarship'] as bool? ?? false;

    _birthCertUrl = additional['birthCertificateUrl'] as String?;
    _incomeCertUrl = additional['incomeCertificateUrl'] as String?;
    _casteCertUrl = additional['casteCertificateUrl'] as String?;
    _anyOtherDocUrl = additional['anyOtherDocUrl'] as String?;
  }

  @override
  void dispose() {
    _medicalController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _specialNeedsController.dispose();
    _referenceController.dispose();
    _counsellorController.dispose();
    _remarksController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(studentRegistrationControllerProvider.notifier).updateAdditional({
      'medicalConditions': _medicalController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'currentMedications': _medicationsController.text.trim(),
      'specialNeeds': _specialNeedsController.text.trim(),
      'reference': _referenceController.text.trim(),
      'counsellorName': _counsellorController.text.trim(),
      'remarks': _remarksController.text.trim(),
      'optionalNotes': _notesController.text.trim(),
      'transportRequired': _transportRequired,
      'hostelRequired': _hostelRequired,
      'scholarship': _scholarship,
      'birthCertificateUrl': _birthCertUrl,
      'incomeCertificateUrl': _incomeCertUrl,
      'casteCertificateUrl': _casteCertUrl,
      'anyOtherDocUrl': _anyOtherDocUrl,
    });
  }

  Future<void> _pickAndUploadDocument(String docKey, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _uploadingStates[docKey] = true);
        final bytes = await image.readAsBytes();
        final url = await ref.read(studentRegistrationControllerProvider.notifier).uploadFile(image.name, bytes);
        setState(() {
          if (docKey == 'birth') _birthCertUrl = url;
          if (docKey == 'income') _incomeCertUrl = url;
          if (docKey == 'caste') _casteCertUrl = url;
          if (docKey == 'other') _anyOtherDocUrl = url;
          _uploadingStates[docKey] = false;
        });
        _saveData();
      }
    } catch (e) {
      setState(() => _uploadingStates[docKey] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload document: $e')),
      );
    }
  }

  void _showUploadSourceSelector(String docKey) {
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
                'Upload Document Copy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadDocument(docKey, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadDocument(docKey, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
          // Step Header
          Text(
            'Additional Information',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Register medical constraints, logistics setup, and verify document checklists.',
            style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Medical & Health Details
          Text('Medical Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildResponsiveGrid([
            TextFormField(
              controller: _medicalController,
              decoration: const InputDecoration(labelText: 'Medical Conditions / Illness', prefixIcon: Icon(Icons.medical_services_outlined)),
            ),
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(labelText: 'Allergies Details', prefixIcon: Icon(Icons.warning_amber_outlined)),
            ),
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(labelText: 'Current Medications', prefixIcon: Icon(Icons.healing_outlined)),
            ),
            TextFormField(
              controller: _specialNeedsController,
              decoration: const InputDecoration(labelText: 'Special Needs / Remarks', prefixIcon: Icon(Icons.accessibility_new_rounded)),
            ),
          ]),
          const SizedBox(height: 24),

          // Logistics Switches
          Text('Logistics & Facility Requirements', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Transport Required', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Enroll student in the academy bus/shuttle service'),
            value: _transportRequired,
            onChanged: (val) {
              setState(() => _transportRequired = val);
              _saveData();
            },
          ),
          SwitchListTile(
            title: const Text('Hostel / Accommodation Required', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Request allocation in academy associated hostels'),
            value: _hostelRequired,
            onChanged: (val) {
              setState(() => _hostelRequired = val);
              _saveData();
            },
          ),
          SwitchListTile(
            title: const Text('Scholarship Allocation Request', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Evaluate student profile for concession eligibility'),
            value: _scholarship,
            onChanged: (val) {
              setState(() => _scholarship = val);
              _saveData();
            },
          ),
          const SizedBox(height: 24),

          // Reference Details
          Text('Reference & Remarks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildResponsiveGrid([
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: 'How did you hear about us?', prefixIcon: Icon(Icons.campaign_outlined)),
            ),
            TextFormField(
              controller: _counsellorController,
              decoration: const InputDecoration(labelText: 'Assigned Counsellor Name', prefixIcon: Icon(Icons.support_agent_rounded)),
            ),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'General Remarks / Notes', prefixIcon: Icon(Icons.description_outlined)),
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Optional Admin Notes', prefixIcon: Icon(Icons.note_add_outlined)),
            ),
          ]),
          const SizedBox(height: 28),

          // Document Checklist
          Text('Documents Checklist & Verify', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _buildUploadTile('Birth Certificate', 'birth', _birthCertUrl),
          const SizedBox(height: 12),
          _buildUploadTile('Income Certificate', 'income', _incomeCertUrl),
          const SizedBox(height: 12),
          _buildUploadTile('Caste Certificate', 'caste', _casteCertUrl),
          const SizedBox(height: 12),
          _buildUploadTile('Any Other Document', 'other', _anyOtherDocUrl),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUploadTile(String label, String docKey, String? fileUrl) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUploading = _uploadingStates[docKey] ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: fileUrl != null
              ? Colors.green.withOpacity(0.4)
              : (isDark ? const Color(0xFF333335) : AppColors.hairline),
        ),
      ),
      color: fileUrl != null
          ? Colors.green.withOpacity(0.04)
          : (isDark ? AppColors.surfaceTile1 : Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: fileUrl != null
                  ? Colors.green.withOpacity(0.1)
                  : theme.colorScheme.primary.withOpacity(0.08),
              child: Icon(
                fileUrl != null ? Icons.check_circle_rounded : Icons.description_outlined,
                color: fileUrl != null ? Colors.green : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (fileUrl != null)
                    const Text(
                      'Successfully uploaded',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    )
                  else if (isUploading)
                    const Text(
                      'Uploading to Supabase...',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    )
                  else
                    Text(
                      'Attach copy of document',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
            if (fileUrl != null) ...[
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                onPressed: () => _showPreviewDialog(label, fileUrl),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                onPressed: () {
                  setState(() {
                    if (docKey == 'birth') _birthCertUrl = null;
                    if (docKey == 'income') _incomeCertUrl = null;
                    if (docKey == 'caste') _casteCertUrl = null;
                    if (docKey == 'other') _anyOtherDocUrl = null;
                  });
                  _saveData();
                },
              ),
            ] else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isUploading ? null : () => _showUploadSourceSelector(docKey),
                child: isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                      )
                    : const Text('Add', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  void _showPreviewDialog(String title, String fileUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              elevation: 0,
              title: Text(title, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fileUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Widget> children) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 600;

    if (isWide) {
      List<Widget> rows = [];
      for (int i = 0; i < children.length; i += 2) {
        if (i + 1 < children.length) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: 16),
                  Expanded(child: children[i + 1]),
                ],
              ),
            ),
          );
        } else {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          );
        }
      }
      return Column(children: rows);
    } else {
      return Column(
        children: children
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: w,
                ))
            .toList(),
      );
    }
  }
}
