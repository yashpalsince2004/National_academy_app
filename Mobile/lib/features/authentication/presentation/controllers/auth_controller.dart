import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authStateSubscription;

  AuthController({required this._authRepository})
      : super(const AuthState.initial()) {
    _init();
  }

  void _init() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  Future<void> login({
    required String email,
    required String password,
    required UserRole expectedRole,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.loginWithEmailAndPassword(
        email: email,
        password: password,
        expectedRole: expectedRole,
      );
      if (user != null) {
        state = AuthState.authenticated(user);
        onSuccess();
      } else {
        state = const AuthState.unauthenticated();
        onError('Authentication failed.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      onError(e.toString());
    }
  }

  Future<void> loginStudentWithRollNumber({
    required String rollNumber,
    required String password,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.loginStudentWithRollNumber(
        rollNumber: rollNumber,
        password: password,
      );
      if (user != null) {
        state = AuthState.authenticated(user);
        onSuccess();
      } else {
        state = const AuthState.unauthenticated();
        onError('Authentication failed.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      onError(e.toString());
    }
  }

  Future<void> activateStudent({
    required String rollNumber,
    required String email,
    required String password,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.activateStudent(
        rollNumber: rollNumber,
        email: email,
        password: password,
      );
      // Automatically log in the student after successful activation
      await login(
        email: email,
        password: password,
        expectedRole: UserRole.student,
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      state = const AuthState.unauthenticated();
      onError(e.toString());
    }
  }

  Future<void> loginWithGoogle({
    required UserRole expectedRole,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.loginWithGoogle(expectedRole: expectedRole);
      if (user != null) {
        state = AuthState.authenticated(user);
        onSuccess();
      } else {
        state = const AuthState.unauthenticated();
        onError('Google authentication failed.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      onError(e.toString());
    }
  }

  Future<void> loginWithApple({
    required UserRole expectedRole,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.loginWithApple(expectedRole: expectedRole);
      if (user != null) {
        state = AuthState.authenticated(user);
        onSuccess();
      } else {
        state = const AuthState.unauthenticated();
        onError('Apple authentication failed.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      onError(e.toString());
    }
  }

  Future<void> refreshUser() async {
    final user = await _authRepository.refreshCurrentUser();
    if (user != null) {
      state = AuthState.authenticated(user);
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    await _authRepository.logout();
    state = const AuthState.unauthenticated();
  }

  Future<void> forgotPassword(
    String email, {
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = const AuthState.unauthenticated();
      onSuccess();
    } catch (e) {
      state = const AuthState.unauthenticated();
      onError(e.toString());
    }
  }

  Future<void> forgotPasswordForRollNumber(
    String rollNumber, {
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.sendPasswordResetForRollNumber(rollNumber);
      state = const AuthState.unauthenticated();
      onSuccess();
    } catch (e) {
      state = const AuthState.unauthenticated();
      onError(e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await refreshUser();
      onSuccess();
    } catch (e) {
      state = AuthState.error(e.toString());
      onError(e.toString());
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
  );
});
