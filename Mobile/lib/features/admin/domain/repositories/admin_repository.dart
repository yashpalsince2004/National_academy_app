import 'package:national_academy/features/authentication/data/models/student_model.dart';

abstract class AdminRepository {
  Future<void> registerStudent({
    required StudentModel student,
    required String password,
    required dynamic profileImageFile,
  });

  // Draft Management
  Future<void> saveDraft({
    required String email,
    required int step,
    required Map<String, dynamic> data,
  });

  Future<Map<String, dynamic>?> getDraft({
    required String email,
  });

  Future<void> deleteDraft({
    required String email,
  });

  // File Upload
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  });

  // Supabase Final Registration
  Future<Map<String, dynamic>> registerStudentSupabase({
    required Map<String, dynamic> registrationData,
    required String password,
  });

  // Check uniqueness constraints
  Future<bool> checkEmailExists({required String email});
  Future<bool> checkPhoneExists({required String phone});
  Future<bool> checkAadhaarExists({required String aadhaar});
}
