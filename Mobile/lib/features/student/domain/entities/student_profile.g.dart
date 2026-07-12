// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentProfileImpl _$$StudentProfileImplFromJson(Map<String, dynamic> json) =>
    _$StudentProfileImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      gender: json['gender'] as String,
      phoneNumber: json['phoneNumber'] as String,
      parentPhoneNumber: json['parentPhoneNumber'] as String,
      registeredClass: json['registeredClass'] as String,
      targetExams: (json['targetExams'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      profileCompleted: json['profileCompleted'] as bool? ?? true,
      status: json['status'] as String? ?? 'Active',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$StudentProfileImplToJson(
  _$StudentProfileImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'name': instance.name,
  'email': instance.email,
  'gender': instance.gender,
  'phoneNumber': instance.phoneNumber,
  'parentPhoneNumber': instance.parentPhoneNumber,
  'registeredClass': instance.registeredClass,
  'targetExams': instance.targetExams,
  'profileCompleted': instance.profileCompleted,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
