import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_registration_state.freezed.dart';

enum RegistrationStatus { initial, loading, success, error }

@freezed
class StudentRegistrationState with _$StudentRegistrationState {
  const factory StudentRegistrationState({
    @Default(0) int currentStep,
    @Default({}) Map<String, dynamic> personal,
    @Default({}) Map<String, dynamic> academic,
    @Default({}) Map<String, dynamic> parents,
    @Default({}) Map<String, dynamic> additional,
    @Default(RegistrationStatus.initial) RegistrationStatus status,
    String? errorMessage,
    @Default(false) bool isAutosaving,
    @Default(false) bool hasUnsavedChanges,
    Map<String, dynamic>? finalAdmissionData,
  }) = _StudentRegistrationState;
}
