// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  email: json['email'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  profileCompleted: json['profileCompleted'] as bool? ?? false,
  passwordChanged: json['passwordChanged'] as bool? ?? false,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'role': _$UserRoleEnumMap[instance.role]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'fullName': instance.fullName,
  'phone': instance.phone,
  'profileCompleted': instance.profileCompleted,
  'passwordChanged': instance.passwordChanged,
};

const _$UserRoleEnumMap = {
  UserRole.superAdmin: 'super_admin',
  UserRole.admin: 'admin',
  UserRole.teacher: 'teacher',
  UserRole.student: 'student',
  UserRole.parent: 'parent',
  UserRole.unknown: 'unknown',
};
