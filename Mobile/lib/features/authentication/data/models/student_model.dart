import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_model.freezed.dart';
part 'student_model.g.dart';

@freezed
abstract class PersonalInformation with _$PersonalInformation {
  const factory PersonalInformation({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required String dob,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String emergencyContact,
  }) = _PersonalInformation;

  factory PersonalInformation.fromJson(Map<String, dynamic> json) =>
      _$PersonalInformationFromJson(json);
}

@freezed
abstract class AcademicInformation with _$AcademicInformation {
  const factory AcademicInformation({
    required String admissionNumber,
    required String enrollmentDate,
    @JsonKey(name: 'class') required String classLevel,
    required String courseType,
    required String targetExam,
    required String batchName,
    required String rollNumber,
    required String previousSchool,
  }) = _AcademicInformation;

  factory AcademicInformation.fromJson(Map<String, dynamic> json) =>
      _$AcademicInformationFromJson(json);
}

@freezed
abstract class ParentInformation with _$ParentInformation {
  const factory ParentInformation({
    required String parentName,
    required String parentPhone,
  }) = _ParentInformation;

  factory ParentInformation.fromJson(Map<String, dynamic> json) =>
      _$ParentInformationFromJson(json);
}

@freezed
abstract class StudentModel with _$StudentModel {
  const factory StudentModel({
    required String studentId,
    @JsonKey(name: 'personal_information') required PersonalInformation personalInformation,
    @JsonKey(name: 'academic_information') required AcademicInformation academicInformation,
    @JsonKey(name: 'parent_information') required ParentInformation parentInformation,
    @JsonKey(name: 'profile_image') required String profileImage,
    required String status, // 'active' or 'inactive'
  }) = _StudentModel;

  factory StudentModel.fromJson(Map<String, dynamic> json) =>
      _$StudentModelFromJson(json);
}
