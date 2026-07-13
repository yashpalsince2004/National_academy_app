// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PersonalInformation _$PersonalInformationFromJson(Map<String, dynamic> json) =>
    _PersonalInformation(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      gender: json['gender'] as String,
      dob: json['dob'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pinCode: json['pinCode'] as String,
      emergencyContact: json['emergencyContact'] as String,
    );

Map<String, dynamic> _$PersonalInformationToJson(
  _PersonalInformation instance,
) => <String, dynamic>{
  'fullName': instance.fullName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'gender': instance.gender,
  'dob': instance.dob,
  'address': instance.address,
  'city': instance.city,
  'state': instance.state,
  'pinCode': instance.pinCode,
  'emergencyContact': instance.emergencyContact,
};

_AcademicInformation _$AcademicInformationFromJson(Map<String, dynamic> json) =>
    _AcademicInformation(
      admissionNumber: json['admissionNumber'] as String,
      enrollmentDate: json['enrollmentDate'] as String,
      classLevel: json['class'] as String,
      courseType: json['courseType'] as String,
      targetExam: json['targetExam'] as String,
      batchName: json['batchName'] as String,
      rollNumber: json['rollNumber'] as String,
      previousSchool: json['previousSchool'] as String,
    );

Map<String, dynamic> _$AcademicInformationToJson(
  _AcademicInformation instance,
) => <String, dynamic>{
  'admissionNumber': instance.admissionNumber,
  'enrollmentDate': instance.enrollmentDate,
  'class': instance.classLevel,
  'courseType': instance.courseType,
  'targetExam': instance.targetExam,
  'batchName': instance.batchName,
  'rollNumber': instance.rollNumber,
  'previousSchool': instance.previousSchool,
};

_ParentInformation _$ParentInformationFromJson(Map<String, dynamic> json) =>
    _ParentInformation(
      parentName: json['parentName'] as String,
      parentPhone: json['parentPhone'] as String,
    );

Map<String, dynamic> _$ParentInformationToJson(_ParentInformation instance) =>
    <String, dynamic>{
      'parentName': instance.parentName,
      'parentPhone': instance.parentPhone,
    };

_StudentModel _$StudentModelFromJson(Map<String, dynamic> json) =>
    _StudentModel(
      studentId: json['studentId'] as String,
      personalInformation: PersonalInformation.fromJson(
        json['personal_information'] as Map<String, dynamic>,
      ),
      academicInformation: AcademicInformation.fromJson(
        json['academic_information'] as Map<String, dynamic>,
      ),
      parentInformation: ParentInformation.fromJson(
        json['parent_information'] as Map<String, dynamic>,
      ),
      profileImage: json['profile_image'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$StudentModelToJson(_StudentModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'personal_information': instance.personalInformation,
      'academic_information': instance.academicInformation,
      'parent_information': instance.parentInformation,
      'profile_image': instance.profileImage,
      'status': instance.status,
    };
