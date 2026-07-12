import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_registration_state.freezed.dart';

@freezed
class StudentRegistrationState with _$StudentRegistrationState {
  const factory StudentRegistrationState.initial() = _Initial;
  const factory StudentRegistrationState.submitting() = _Submitting;
  const factory StudentRegistrationState.success() = _Success;
  const factory StudentRegistrationState.error(String message) = _Error;
}
