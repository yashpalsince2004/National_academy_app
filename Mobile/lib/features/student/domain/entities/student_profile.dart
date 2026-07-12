import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile.freezed.dart';
part 'student_profile.g.dart';

@freezed
class StudentProfile with _$StudentProfile {
  const factory StudentProfile({
    required String uid,
    required String name,
    required String email,
    required String gender,
    required String phoneNumber,
    required String parentPhoneNumber,
    required String registeredClass, // '11th', '12th', '11th + 12th'
    required List<String> targetExams, // 'JEE', 'NEET', 'NDA', 'Boards Only'
    @Default(true) bool profileCompleted,
    @Default('Active') String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StudentProfile;

  factory StudentProfile.fromJson(Map<String, dynamic> json) => _$StudentProfileFromJson(json);
}
