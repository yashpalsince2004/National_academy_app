import 'dart:async';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/exceptions.dart';

class MockAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  MockAuthRepository();

  @override
  Stream<AppUser?> get authStateChanges => _emitInitialAndListen();

  Stream<AppUser?> _emitInitialAndListen() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<AppUser?> loginWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network latency

    final normalizedEmail = email.trim().toLowerCase();
    
    if (expectedRole == UserRole.admin) {
      if (normalizedEmail == 'admin@academy.com' && password == 'admin123') {
        _currentUser = AppUser(
          uid: 'mock-admin-uid-123',
          email: 'admin@academy.com',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          fullName: 'Mock Admin',
        );
        _authStateController.add(_currentUser);
        return _currentUser;
      } else {
        throw AuthException('Invalid admin credentials. Use admin@academy.com / admin123');
      }
    } else if (expectedRole == UserRole.student) {
      if (normalizedEmail == 'student@academy.com' && password == 'student123') {
        _currentUser = AppUser(
          uid: 'mock-student-uid-456',
          email: 'student@academy.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
          fullName: 'Mock Student',
        );
        _authStateController.add(_currentUser);
        return _currentUser;
      } else {
        throw AuthException('Invalid student credentials. Use student@academy.com / student123');
      }
    }
    
    throw AuthException('Unsupported login role.');
  }

  @override
  Future<AppUser?> loginStudentWithRollNumber({
    required String rollNumber,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final roll = rollNumber.trim().toUpperCase();
    if (roll == 'NA-2026-0001' && password == 'student123') {
      _currentUser = AppUser(
        uid: 'mock-student-uid-456',
        email: 'student@academy.com',
        role: UserRole.student,
        createdAt: DateTime.now(),
        fullName: 'Mock Student',
        passwordChanged: false,
      );
      _authStateController.add(_currentUser);
      return _currentUser;
    } else if (roll == 'NA-2026-0002' && password == 'student123') {
      _currentUser = AppUser(
        uid: 'mock-student-uid-789',
        email: 'student2@academy.com',
        role: UserRole.student,
        createdAt: DateTime.now(),
        fullName: 'Mock Student (Changed)',
        passwordChanged: true,
      );
      _authStateController.add(_currentUser);
      return _currentUser;
    } else {
      throw AuthException('Invalid Student Roll Number or Password.');
    }
  }

  @override
  Future<void> activateStudent({
    required String rollNumber,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulate successful activation for mock users
    if (rollNumber.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      throw AuthException('Roll number, email, and password must not be empty.');
    }
  }

  @override
  Future<AppUser?> loginWithGoogle({required UserRole expectedRole}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = AppUser(
      uid: 'mock-google-${expectedRole.name}-uid',
      email: '${expectedRole.name}.google@academy.com',
      role: expectedRole,
      createdAt: DateTime.now(),
      fullName: 'Mock Google User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AppUser?> loginWithApple({required UserRole expectedRole}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = AppUser(
      uid: 'mock-apple-${expectedRole.name}-uid',
      email: '${expectedRole.name}.apple@academy.com',
      role: expectedRole,
      createdAt: DateTime.now(),
      fullName: 'Mock Apple User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AppUser?> refreshCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> sendPasswordResetForRollNumber(String rollNumber) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final roll = rollNumber.trim().toUpperCase();
    if (roll != 'NA-2026-0001' && roll != 'NA-2026-0002') {
      throw AuthException('Invalid Student Roll Number.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(profileCompleted: true, passwordChanged: true);
      _authStateController.add(_currentUser);
    }
  }
}
