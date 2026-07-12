import '../entities/student_profile.dart';

abstract class StudentRepository {
  Future<StudentProfile?> getStudentProfile(String uid);
  Future<void> saveStudentProfile(StudentProfile profile);
}
