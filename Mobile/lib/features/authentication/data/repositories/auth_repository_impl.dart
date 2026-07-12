import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/exceptions.dart' as app_exceptions;
import '../../../../core/services/supabase_providers.dart';
import '../../../../main.dart';
import 'mock_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isSupabaseReady = ref.watch(supabaseInitializedProvider);
  if (isSupabaseReady) {
    return SupabaseAuthRepositoryImpl(
      supabaseClient: ref.watch(supabaseClientProvider),
    );
  } else {
    return MockAuthRepository();
  }
});

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final supabase.SupabaseClient supabaseClient;

  SupabaseAuthRepositoryImpl({required this.supabaseClient});

  @override
  Stream<AppUser?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null) return null;
      final user = session.user;
      return await _getUserFromDatabase(user.id, user.email ?? '');
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return await _getUserFromDatabase(user.id, user.email ?? '');
  }

  @override
  Future<AppUser?> refreshCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return await _getUserFromDatabase(user.id, user.email ?? '');
  }

  @override
  Future<AppUser?> loginWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    try {
      final emailTrimmed = email.trim().toLowerCase();

      final supabase.AuthResponse response = await supabaseClient.auth.signInWithPassword(
        email: emailTrimmed,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw app_exceptions.AuthException('Login failed: Authentication returned null user.');
      }

      final appUser = await _getUserFromDatabase(user.id, emailTrimmed);
      if (appUser == null) {
        await logout();
        throw app_exceptions.AuthException('Access Denied: User profile not found.');
      }

      // Check role mapping
      bool isAuthorized = false;
      if (expectedRole == UserRole.admin) {
        isAuthorized = appUser.role == UserRole.admin || appUser.role == UserRole.superAdmin;
      } else {
        isAuthorized = appUser.role == expectedRole;
      }

      if (!isAuthorized) {
        await logout();
        throw app_exceptions.UnauthorizedRoleException('Access Denied: You do not have permission to log in with this role.');
      }

      return appUser;
    } on supabase.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      if (e is app_exceptions.AuthException || e is app_exceptions.UnauthorizedRoleException) {
        rethrow;
      }
      throw app_exceptions.AuthException('Authentication Error: ${e.toString()}');
    }
  }

  @override
  Future<AppUser?> loginStudentWithRollNumber({
    required String rollNumber,
    required String password,
  }) async {
    try {
      final rollClean = rollNumber.trim().toUpperCase();

      // 1. Resolve email, profile_id, and status using the RPC function (bypasses RLS)
      final List<dynamic> rpcRes = await supabaseClient.rpc(
        'get_student_email_by_roll',
        params: {'entered_roll_no': rollClean},
      );

      if (rpcRes.isEmpty) {
        throw app_exceptions.AuthException('Invalid Student Roll Number.');
      }

      final studentMap = rpcRes.first as Map<String, dynamic>;
      final email = studentMap['email'] as String?;
      final status = studentMap['status'] as String?;
      
      if (email == null || email.isEmpty) {
        throw app_exceptions.AuthException('Invalid Student Roll Number.');
      }

      if (status != 'active') {
        throw app_exceptions.AuthException('Student account is inactive.');
      }

      // 2. Log in via Supabase Auth
      final supabase.AuthResponse response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw app_exceptions.AuthException('Login failed: Authentication returned null user.');
      }

      // 3. Retrieve complete AppUser object
      final appUser = await _getUserFromDatabase(user.id, email);
      if (appUser == null) {
        await logout();
        throw app_exceptions.AuthException('Access Denied: User profile not found.');
      }

      if (appUser.role != UserRole.student) {
        await logout();
        throw app_exceptions.UnauthorizedRoleException('Access Denied: You do not have permission to log in with this role.');
      }

      return appUser;
    } on supabase.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      if (e is app_exceptions.AuthException || e is app_exceptions.UnauthorizedRoleException) {
        rethrow;
      }
      throw app_exceptions.AuthException('Authentication Error: ${e.toString()}');
    }
  }

  @override
  Future<void> activateStudent({
    required String rollNumber,
    required String email,
    required String password,
  }) async {
    try {
      // In direct Supabase flow, we can invoke the Edge Function for student registration activation
      final response = await supabaseClient.functions.invoke(
        'activate-student',
        body: {
          'roll_number': rollNumber.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final status = response.status;
      if (status != 200) {
        final data = response.data;
        String errorMessage = 'Activation failed. Please try again.';
        if (data is Map<String, dynamic>) {
          errorMessage = data['error'] as String? ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }
        throw app_exceptions.AuthException(errorMessage);
      }
    } on supabase.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      if (e is app_exceptions.AuthException) rethrow;
      throw app_exceptions.AuthException('Activation Error: ${e.toString()}');
    }
  }

  @override
  Future<AppUser?> loginWithGoogle({required UserRole expectedRole}) async {
    throw UnimplementedError('Google sign in is not supported yet.');
  }

  @override
  Future<AppUser?> loginWithApple({required UserRole expectedRole}) async {
    throw UnimplementedError('Apple sign in is not supported yet.');
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email.trim());
    } on supabase.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    }
  }

  @override
  Future<void> sendPasswordResetForRollNumber(String rollNumber) async {
    try {
      final rollClean = rollNumber.trim().toUpperCase();

      // 1. Resolve email using RPC (bypasses RLS)
      final List<dynamic> rpcRes = await supabaseClient.rpc(
        'get_student_email_by_roll',
        params: {'entered_roll_no': rollClean},
      );

      if (rpcRes.isEmpty) {
        throw app_exceptions.AuthException('Invalid Student Roll Number.');
      }

      final studentMap = rpcRes.first as Map<String, dynamic>;
      final email = studentMap['email'] as String?;
      final status = studentMap['status'] as String?;

      if (email == null || email.isEmpty) {
        throw app_exceptions.AuthException('Invalid Student Roll Number.');
      }

      if (status != 'active') {
        throw app_exceptions.AuthException('Student account is inactive.');
      }

      // 2. Send reset email
      await sendPasswordResetEmail(email);
    } catch (e) {
      if (e is app_exceptions.AuthException) rethrow;
      throw app_exceptions.AuthException(e.toString());
    }
  }

  Future<AppUser?> _getUserFromDatabase(String uid, String email) async {
    try {
      debugPrint("UID = $uid");

      final profileDoc = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      debugPrint("PROFILE = $profileDoc");

      if (profileDoc == null) {
        return null;
      }

      final roleStr = profileDoc['role'] as String?;
      final role = UserRole.fromString(roleStr);
      final fullName = profileDoc['full_name'] as String? ?? '';
      final phone = profileDoc['phone'] as String?;

      // Check if student profile exists and status is active
      bool profileCompleted = false;
      bool passwordChanged = false;
      if (role == UserRole.student) {
        final studentDoc = await supabaseClient
            .from('students')
            .select()
            .eq('profile_id', uid)
            .maybeSingle();
        if (studentDoc != null) {
          profileCompleted = true;
          passwordChanged = studentDoc['password_changed'] as bool? ?? false;
          final status = studentDoc['status'] as String?;
          if (status != 'active') {
            return null; // student not active
          }
        }
      } else {
        profileCompleted = true;
        passwordChanged = true;
      }

      return AppUser(
        uid: uid,
        email: email,
        role: role,
        createdAt: DateTime.tryParse(profileDoc['created_at'] as String? ?? '') ?? DateTime.now(),
        fullName: fullName,
        phone: phone,
        profileCompleted: profileCompleted,
        passwordChanged: passwordChanged,
      );
    } catch (e, stackTrace) {
      debugPrint('==============================');
      debugPrint('PROFILE FETCH ERROR');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('==============================');
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw app_exceptions.AuthException('No authenticated user found.');
      }

      // 1. Update Supabase Auth user password
      await supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword.trim()),
      );

      // 2. Set password_changed = true in public.students
      await supabaseClient
          .from('students')
          .update({'password_changed': true})
          .eq('profile_id', user.id);
    } on supabase.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      throw app_exceptions.AuthException('Failed to change password: ${e.toString()}');
    }
  }
}

