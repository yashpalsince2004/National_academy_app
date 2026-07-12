import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/services/supabase_providers.dart';
import '../../../../core/utils/exceptions.dart' as app_exceptions;
import '../../../../main.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final isSupabaseReady = ref.watch(supabaseInitializedProvider);
  if (isSupabaseReady) {
    return StudentRepositoryImpl(
      supabaseClient: ref.watch(supabaseClientProvider),
    );
  } else {
    return MockStudentRepository();
  }
});

class StudentRepositoryImpl implements StudentRepository {
  final supabase.SupabaseClient supabaseClient;

  StudentRepositoryImpl({
    required this.supabaseClient,
  });

  @override
  Future<StudentProfile?> getStudentProfile(String uid) async {
    try {
      final data = await supabaseClient
          .from('students')
          .select()
          .eq('auth_user_id', uid)
          .maybeSingle();

      if (data == null) return null;

      final targetExamsStr = data['target_exam'] as String? ?? '';
      final targetExams = targetExamsStr.isNotEmpty
          ? targetExamsStr.split(',').map((e) => e.trim()).toList()
          : <String>[];

      return StudentProfile(
        uid: uid,
        name: data['full_name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        gender: data['gender'] as String? ?? '',
        phoneNumber: data['phone'] as String? ?? '',
        parentPhoneNumber: data['parent_phone'] as String? ?? '',
        registeredClass: data['class'] as String? ?? '',
        targetExams: targetExams,
        profileCompleted: data['profile_completed'] as bool? ?? false,
        status: data['status'] as String? ?? 'Active',
        createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
      throw app_exceptions.AuthException('Failed to retrieve student profile: ${e.toString()}');
    }
  }

  @override
  Future<void> saveStudentProfile(StudentProfile profile) async {
    try {
      await supabaseClient
          .from('students')
          .update({
            'full_name': profile.name,
            'phone': profile.phoneNumber,
            'parent_phone': profile.parentPhoneNumber,
            'gender': profile.gender,
            'class': profile.registeredClass,
            'target_exam': profile.targetExams.join(', '),
            'profile_completed': true,
          })
          .eq('auth_user_id', profile.uid);
    } catch (e) {
      debugPrint('Error saving student profile: $e');
      throw app_exceptions.AuthException('Failed to save student profile: ${e.toString()}');
    }
  }
}

class MockStudentRepository implements StudentRepository {
  final Map<String, StudentProfile> _mockProfiles = {};

  @override
  Future<StudentProfile?> getStudentProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockProfiles[uid];
  }

  @override
  Future<void> saveStudentProfile(StudentProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _mockProfiles[profile.uid] = profile;
    debugPrint('--- [MOCK STUDENT REGISTRATION SAVED] ---');
    debugPrint('UID: ${profile.uid}');
    debugPrint('Name: ${profile.name}');
    debugPrint('Registered Class: ${profile.registeredClass}');
    debugPrint('Target Exams: ${profile.targetExams}');
    debugPrint('-----------------------------------------');
  }
}
