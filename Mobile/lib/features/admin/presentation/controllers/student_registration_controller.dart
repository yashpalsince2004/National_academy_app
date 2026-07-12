import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:national_academy/features/admin/domain/repositories/admin_repository.dart';
import 'package:national_academy/features/admin/data/repositories/admin_repository_impl.dart';
import 'student_registration_state.dart';

class StudentRegistrationController extends StateNotifier<StudentRegistrationState> {
  final AdminRepository _adminRepository;

  StudentRegistrationController({
    required AdminRepository adminRepository,
  })  : _adminRepository = adminRepository,
        super(const StudentRegistrationState());

  void updatePersonal(Map<String, dynamic> data) {
    state = state.copyWith(
      personal: {...state.personal, ...data},
      hasUnsavedChanges: true,
    );
  }

  void updateAcademic(Map<String, dynamic> data) {
    state = state.copyWith(
      academic: {...state.academic, ...data},
      hasUnsavedChanges: true,
    );
  }

  void updateParents(Map<String, dynamic> data) {
    state = state.copyWith(
      parents: {...state.parents, ...data},
      hasUnsavedChanges: true,
    );
  }

  void updateAdditional(Map<String, dynamic> data) {
    state = state.copyWith(
      additional: {...state.additional, ...data},
      hasUnsavedChanges: true,
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  // Autosave current step draft
  Future<bool> saveStepDraft() async {
    final email = state.personal['email'] as String?;
    if (email == null || email.trim().isEmpty) return false;

    state = state.copyWith(isAutosaving: true);
    try {
      final Map<String, dynamic> draftPayload = {
        'personal': state.personal,
        'academic': state.academic,
        'parents': state.parents,
        'additional': state.additional,
      };

      await _adminRepository.saveDraft(
        email: email.trim().toLowerCase(),
        step: state.currentStep,
        data: draftPayload,
      );
      state = state.copyWith(isAutosaving: false, hasUnsavedChanges: false);
      return true;
    } catch (e) {
      state = state.copyWith(isAutosaving: false);
      return false;
    }
  }

  // Restore/Load draft from database
  Future<bool> loadDraft(String email) async {
    if (email.trim().isEmpty) return false;

    state = state.copyWith(status: RegistrationStatus.loading);
    try {
      final draft = await _adminRepository.getDraft(email: email.trim().toLowerCase());
      if (draft != null) {
        final step = draft['step'] as int? ?? 0;
        final data = draft['data'] as Map<String, dynamic>? ?? {};

        state = state.copyWith(
          currentStep: step,
          personal: Map<String, dynamic>.from(data['personal'] ?? {}),
          academic: Map<String, dynamic>.from(data['academic'] ?? {}),
          parents: Map<String, dynamic>.from(data['parents'] ?? {}),
          additional: Map<String, dynamic>.from(data['additional'] ?? {}),
          status: RegistrationStatus.initial,
          hasUnsavedChanges: false,
        );
        return true;
      }
      state = state.copyWith(status: RegistrationStatus.initial);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: 'Failed to restore draft: $e',
      );
      return false;
    }
  }

  // Check unique constraints
  Future<String?> checkUniqueness({
    required String email,
    required String phone,
  }) async {
    try {
      final emailExists = await _adminRepository.checkEmailExists(email: email);
      if (emailExists) return 'A student with this Email already exists.';

      final phoneExists = await _adminRepository.checkPhoneExists(phone: phone);
      if (phoneExists) return 'A student with this Mobile Number already exists.';

      return null;
    } catch (e) {
      return null; // ignore constraint error in check phase to prevent blockages
    }
  }

  // Upload file
  Future<String?> uploadFile(String fileName, List<int> bytes) async {
    try {
      final url = await _adminRepository.uploadDocument(fileName: fileName, bytes: bytes);
      return url;
    } catch (e) {
      return null;
    }
  }

  // Submit Final Admission
  Future<bool> submitAdmission(String password) async {
    state = state.copyWith(status: RegistrationStatus.loading, errorMessage: null);
    try {
      final Map<String, dynamic> registrationData = {
        'personal': state.personal,
        'academic': state.academic,
        'parents': state.parents,
        'additional': state.additional,
      };

      final response = await _adminRepository.registerStudentSupabase(
        registrationData: registrationData,
        password: password,
      );

      state = state.copyWith(
        status: RegistrationStatus.success,
        finalAdmissionData: response,
        hasUnsavedChanges: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const StudentRegistrationState();
  }
}

final studentRegistrationControllerProvider =
    StateNotifierProvider<StudentRegistrationController, StudentRegistrationState>((ref) {
  return StudentRegistrationController(
    adminRepository: ref.watch(adminRepositoryProvider),
  );
});
