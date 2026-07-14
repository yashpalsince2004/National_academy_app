import '../../domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> loginWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole expectedRole,
  });

  Future<AppUser?> loginStudentWithRollNumber({
    required String rollNumber,
    required String password,
  });

  Future<void> activateStudent({
    required String rollNumber,
    required String email,
    required String password,
  });

  Future<AppUser?> loginWithGoogle({required UserRole expectedRole});

  Future<AppUser?> loginWithApple({required UserRole expectedRole});

  Future<AppUser?> getCurrentUser();

  Future<AppUser?> refreshCurrentUser();

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendPasswordResetForRollNumber(String rollNumber);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> registerAdmin({
    required String email,
    required String username,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<void> registerTeacher({
    required String email,
    required String username,
    required String password,
    required String fullName,
    String? phone,
    String? subject,
  });

  Stream<AppUser?> get authStateChanges;
}
