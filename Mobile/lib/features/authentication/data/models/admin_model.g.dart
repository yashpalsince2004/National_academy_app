// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminModel _$AdminModelFromJson(Map<String, dynamic> json) => _AdminModel(
  adminId: json['adminId'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$AdminModelToJson(_AdminModel instance) =>
    <String, dynamic>{
      'adminId': instance.adminId,
      'name': instance.name,
      'email': instance.email,
    };
