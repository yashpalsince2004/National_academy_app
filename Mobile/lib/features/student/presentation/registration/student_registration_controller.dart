import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/student_repository.dart';
import 'student_registration_state.dart';

class StudentRegistrationController extends StateNotifier<StudentRegistrationState> {
  final StudentRepository _studentRepository;

  StudentRegistrationController({required this._studentRepository})
      : super(const StudentRegistrationState.initial());

  Future<void> registerStudent({
    required String uid,
    required String email,
    required String name,
    required String gender,
    required String phoneNumber,
    required String parentPhoneNumber,
    required String registeredClass,
    required List<String> targetExams,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    state = const StudentRegistrationState.submitting();
    try {
      final profile = StudentProfile(
        uid: uid,
        email: email,
        name: name,
        gender: gender,
        phoneNumber: phoneNumber,
        parentPhoneNumber: parentPhoneNumber,
        registeredClass: registeredClass,
        targetExams: targetExams,
        profileCompleted: true,
        status: 'Active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _studentRepository.saveStudentProfile(profile);
      state = const StudentRegistrationState.success();
      onSuccess();
    } catch (e) {
      state = StudentRegistrationState.error(e.toString());
      onError(e.toString());
    }
  }
}

final studentRegistrationControllerProvider =
    StateNotifierProvider<StudentRegistrationController, StudentRegistrationState>((ref) {
  return StudentRegistrationController(
    studentRepository: ref.watch(studentRepositoryProvider),
  );
});
