import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole {
  @JsonValue('super_admin')
  superAdmin,
  @JsonValue('admin')
  admin,
  @JsonValue('teacher')
  teacher,
  @JsonValue('student')
  student,
  @JsonValue('parent')
  parent,
  @JsonValue('unknown')
  unknown;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      default:
        return UserRole.unknown;
    }
  }

  String get name {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
      default:
        return 'unknown';
    }
  }
}

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    required UserRole role,
    required DateTime createdAt,
    required String fullName,
    String? phone,
    @Default(false) bool profileCompleted,
    @Default(false) bool passwordChanged,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

