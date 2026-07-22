import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/screens/admin_login_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/role_selection_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/student_login_screen.dart';
import '../../features/authentication/presentation/screens/change_password_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/student_registration_screen.dart';
import '../../features/admin/presentation/screens/admin_registration_screen.dart';
import '../../features/admin/presentation/screens/admin_students_data_screen.dart';
import '../../features/admin/presentation/screens/teacher_registration_screen.dart';
import '../../features/admin/presentation/screens/admin_teachers_data_screen.dart';
import '../../features/admin/presentation/screens/previous_lectures_screen.dart';
import '../../features/admin/presentation/screens/previous_tests_screen.dart';
import '../../features/admin/presentation/screens/attendance_record_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../../features/student/presentation/registration/student_registration_screen.dart' as student_reg;
import '../../features/batches/presentation/screens/batch_dashboard_screen.dart';
import '../../features/batches/presentation/screens/batch_details_screen.dart';

import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../features/authentication/presentation/controllers/auth_state.dart';
import '../../features/authentication/domain/entities/app_user.dart';
import '../../features/dpp/presentation/screens/dpp_dashboard_screen.dart';
import '../../features/dpp/presentation/screens/dpp_preview_screen.dart';
import '../../features/dpp/presentation/screens/dpp_history_screen.dart';
import '../../features/dpp/presentation/screens/dpp_attempt_screen.dart';


class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(authControllerProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authController.stream),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      
      final isSplash = location == '/';
      final isRoleSelection = location == '/role-selection';
      final isLogin = location.startsWith('/login');
      final isForgotPassword = location == '/forgot-password';
      
      final isPublicPage = isSplash || isRoleSelection || isLogin || isForgotPassword;

      return authState.maybeWhen(
        authenticated: (user) {
          final isAdmin = user.role == UserRole.admin || user.role == UserRole.superAdmin;

          if (isPublicPage) {
            if (isAdmin) return '/admin/dashboard';
            if (user.role == UserRole.student) {
              if (!user.passwordChanged) return '/student/change-password';
              return user.profileCompleted ? '/student/dashboard' : '/student/complete-profile';
            }
            return '/role-selection';
          }

          if (user.role == UserRole.student) {
            if (!user.passwordChanged) {
              if (location == '/student/change-password') return null;
              return '/student/change-password';
            }
            if (location == '/student/change-password') {
              return user.profileCompleted ? '/student/dashboard' : '/student/complete-profile';
            }

            if (!user.profileCompleted) {
              if (location == '/student/complete-profile') return null;
              return '/student/complete-profile';
            }
            if (location == '/student/complete-profile') {
              return '/student/dashboard';
            }
          }

          // Secure route namespaces based on user roles
          if (location.startsWith('/admin') && !isAdmin) {
            return user.role == UserRole.student ? '/student/dashboard' : '/role-selection';
          }
          if (location.startsWith('/student') && user.role != UserRole.student) {
            return isAdmin ? '/admin/dashboard' : '/role-selection';
          }

          return null;
        },
        unauthenticated: () {
          // If on a private page or on the splash screen itself, redirect to role selection
          if (!isPublicPage || isSplash) {
            return '/role-selection';
          }
          return null;
        },
        orElse: () => null,
      );
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login/admin',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/login/student',
        name: 'student-login',
        builder: (context, state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/register-student',
        name: 'register-student',
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: '/admin/register-admin',
        name: 'register-admin',
        builder: (context, state) => const AdminRegistrationScreen(),
      ),
      GoRoute(
        path: '/admin/students',
        name: 'admin-students',
        builder: (context, state) => const AdminStudentsDataScreen(),
      ),
      GoRoute(
        path: '/admin/register-teacher',
        name: 'register-teacher',
        builder: (context, state) => const TeacherRegistrationScreen(),
      ),
      GoRoute(
        path: '/admin/teachers',
        name: 'admin-teachers',
        builder: (context, state) => const AdminTeachersDataScreen(),
      ),
      GoRoute(
        path: '/admin/batches',
        name: 'admin-batches',
        builder: (context, state) => const BatchDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/batches/:id',
        name: 'admin-batch-details',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BatchDetailsScreen(batchId: id);
        },
      ),
      GoRoute(
        path: '/student/dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/student/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const student_reg.StudentRegistrationScreen(),
      ),
      GoRoute(
        path: '/student/change-password',
        name: 'student-change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/student/dpp/attempt/:assignmentId',
        name: 'student-dpp-attempt',
        builder: (context, state) {
          final assignmentId = state.pathParameters['assignmentId'] ?? '';
          return DppAttemptScreen(assignmentId: assignmentId);
        },
      ),

      GoRoute(
        path: '/admin/dpp',
        name: 'admin-dpp',
        builder: (context, state) => const DppDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dpp/preview',
        name: 'admin-dpp-preview',
        builder: (context, state) => const DppPreviewScreen(),
      ),
      GoRoute(
        path: '/admin/dpp/history',
        name: 'admin-dpp-history',
        builder: (context, state) => const DppHistoryScreen(),
      ),
      GoRoute(
        path: '/admin/previous-lectures',
        name: 'admin-previous-lectures',
        builder: (context, state) {
          final defaultBatch = state.uri.queryParameters['batch'] ?? 'Veera';
          return PreviousLecturesScreen(defaultBatch: defaultBatch);
        },
      ),
      GoRoute(
        path: '/admin/previous-tests',
        name: 'admin-previous-tests',
        builder: (context, state) {
          final defaultBatch = state.uri.queryParameters['batch'] ?? 'Veera';
          return PreviousTestsScreen(defaultBatch: defaultBatch);
        },
      ),
      GoRoute(
        path: '/admin/attendance-record',
        name: 'admin-attendance-record',
        builder: (context, state) {
          final defaultBatch = state.uri.queryParameters['batch'] ?? 'Veera';
          return AttendanceRecordScreen(defaultBatch: defaultBatch);
        },
      ),
    ],
  );
});
