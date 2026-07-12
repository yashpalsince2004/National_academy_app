import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:national_academy/core/services/supabase_providers.dart';
import 'package:national_academy/core/utils/exceptions.dart';
import 'package:national_academy/main.dart';
import 'package:national_academy/features/authentication/data/models/student_model.dart';
import 'package:national_academy/features/admin/domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final isSupabaseReady = ref.watch(supabaseInitializedProvider);
  if (isSupabaseReady) {
    return SupabaseAdminRepositoryImpl(
      supabaseClient: ref.watch(supabaseClientProvider),
    );
  } else {
    return MockAdminRepository();
  }
});

class SupabaseAdminRepositoryImpl implements AdminRepository {
  final supabase.SupabaseClient supabaseClient;

  SupabaseAdminRepositoryImpl({
    required this.supabaseClient,
  });

  @override
  Future<void> registerStudent({
    required StudentModel student,
    required String password,
    required dynamic profileImageFile,
  }) async {
    // Legacy method, routed to Supabase registration
    throw UnimplementedError('Use registerStudentSupabase instead.');
  }

  @override
  Future<void> saveDraft({
    required String email,
    required int step,
    required Map<String, dynamic> data,
  }) async {
    try {
      final emailClean = email.trim().toLowerCase();
      await supabaseClient.from('student_registration_drafts').upsert({
        'email': emailClean,
        'step': step,
        'data': data,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'email');
    } catch (e) {
      throw AuthException('Failed to save registration draft: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getDraft({required String email}) async {
    try {
      final emailClean = email.trim().toLowerCase();
      final res = await supabaseClient
          .from('student_registration_drafts')
          .select('step, data')
          .eq('email', emailClean)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error retrieving draft: $e');
      return null;
    }
  }

  @override
  Future<void> deleteDraft({required String email}) async {
    try {
      final emailClean = email.trim().toLowerCase();
      await supabaseClient
          .from('student_registration_drafts')
          .delete()
          .eq('email', emailClean);
    } catch (e) {
      debugPrint('Error deleting draft: $e');
    }
  }

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final fileExtension = fileName.split('.').last;
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}.$fileExtension';
      final path = 'registration_docs/$uniqueName';

      await supabaseClient.storage.from('student-documents').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const supabase.FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = supabaseClient.storage.from('student-documents').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw AuthException('Failed to upload document: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> registerStudentSupabase({
    required Map<String, dynamic> registrationData,
    required String password,
  }) async {
    try {
      // Call the 'create-student' Edge Function.
      // The Edge Function runs server-side with the Service Role Key, which
      // means it uses auth.admin.createUser() — NOT signUp() — so there is
      // NO PKCE flow and NO asyncStorage requirement.
      //
      // The function verifies the caller is an authenticated admin and then:
      //   1. Creates the Auth user (email_confirm: true — no confirmation email)
      //   2. Updates the profiles table
      //   3. Inserts into the students table
      //   4. Returns roll_no and registration date
      final response = await supabaseClient.functions.invoke(
        'create-student',
        body: {
          'registrationData': registrationData,
          'password': password,
        },
      );

      if (response.status != 200) {
        final errorBody = response.data;
        final errorMsg = errorBody is Map ? errorBody['error'] ?? 'Unknown error' : 'Unknown error';
        throw AuthException('Registration failed: $errorMsg');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw AuthException(data['error'] ?? 'Registration failed.');
      }

      // Also delete the draft if an email was provided
      final personal = registrationData['personal'] as Map<String, dynamic>? ?? {};
      final email = (personal['email'] as String? ?? '').trim();
      if (email.isNotEmpty) {
        await deleteDraft(email: email);
      }

      return {
        'roll_number': data['rollNumber'] ?? 'TBD',
        'registration_date': data['registrationDate'] ?? DateTime.now().toIso8601String(),
        'admission_number': data['admissionNumber'] ?? 'TBD',
        'temporary_password': data['temporaryPassword'] ?? '',
      };
    } catch (e) {
      throw AuthException('Final registration failed: $e');
    }
  }


  @override
  Future<bool> checkEmailExists({required String email}) async {
    try {
      final res = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> checkPhoneExists({required String phone}) async {
    try {
      final res = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('phone', phone.trim())
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> checkAadhaarExists({required String aadhaar}) async {
    try {
      final res = await supabaseClient
          .from('students')
          .select('id')
          .eq('additional_info->>aadhaar_number', aadhaar.trim())
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }
}

class MockAdminRepository implements AdminRepository {
  final Map<String, Map<String, dynamic>> _drafts = {};

  @override
  Future<void> registerStudent({
    required StudentModel student,
    required String password,
    required dynamic profileImageFile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> saveDraft({
    required String email,
    required int step,
    required Map<String, dynamic> data,
  }) async {
    _drafts[email.trim().toLowerCase()] = {
      'step': step,
      'data': data,
    };
  }

  @override
  Future<Map<String, dynamic>?> getDraft({required String email}) async {
    return _drafts[email.trim().toLowerCase()];
  }

  @override
  Future<void> deleteDraft({required String email}) async {
    _drafts.remove(email.trim().toLowerCase());
  }

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'https://mockstorage.supabase.co/student-documents/mock_${DateTime.now().millisecondsSinceEpoch}_$fileName';
  }

  @override
  Future<Map<String, dynamic>> registerStudentSupabase({
    required Map<String, dynamic> registrationData,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final randId = '${DateTime.now().year}${UniqueKey().hashCode.toString().substring(0, 4)}';
    return {
      'roll_number': 'NA-2026-$randId',
      'registration_date': DateTime.now().toIso8601String(),
      'admission_number': 'ADM-$randId',
      'temporary_password': 'Student@$randId',
    };
  }

  @override
  Future<bool> checkEmailExists({required String email}) async => false;

  @override
  Future<bool> checkPhoneExists({required String phone}) async => false;

  @override
  Future<bool> checkAadhaarExists({required String aadhaar}) async => false;
}
