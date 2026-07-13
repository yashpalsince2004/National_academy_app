// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_registration_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StudentRegistrationState {

 int get currentStep; Map<String, dynamic> get personal; Map<String, dynamic> get academic; Map<String, dynamic> get parents; Map<String, dynamic> get additional; RegistrationStatus get status; String? get errorMessage; bool get isAutosaving; bool get hasUnsavedChanges; Map<String, dynamic>? get finalAdmissionData;
/// Create a copy of StudentRegistrationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentRegistrationStateCopyWith<StudentRegistrationState> get copyWith => _$StudentRegistrationStateCopyWithImpl<StudentRegistrationState>(this as StudentRegistrationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentRegistrationState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&const DeepCollectionEquality().equals(other.personal, personal)&&const DeepCollectionEquality().equals(other.academic, academic)&&const DeepCollectionEquality().equals(other.parents, parents)&&const DeepCollectionEquality().equals(other.additional, additional)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isAutosaving, isAutosaving) || other.isAutosaving == isAutosaving)&&(identical(other.hasUnsavedChanges, hasUnsavedChanges) || other.hasUnsavedChanges == hasUnsavedChanges)&&const DeepCollectionEquality().equals(other.finalAdmissionData, finalAdmissionData));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,const DeepCollectionEquality().hash(personal),const DeepCollectionEquality().hash(academic),const DeepCollectionEquality().hash(parents),const DeepCollectionEquality().hash(additional),status,errorMessage,isAutosaving,hasUnsavedChanges,const DeepCollectionEquality().hash(finalAdmissionData));

@override
String toString() {
  return 'StudentRegistrationState(currentStep: $currentStep, personal: $personal, academic: $academic, parents: $parents, additional: $additional, status: $status, errorMessage: $errorMessage, isAutosaving: $isAutosaving, hasUnsavedChanges: $hasUnsavedChanges, finalAdmissionData: $finalAdmissionData)';
}


}

/// @nodoc
abstract mixin class $StudentRegistrationStateCopyWith<$Res>  {
  factory $StudentRegistrationStateCopyWith(StudentRegistrationState value, $Res Function(StudentRegistrationState) _then) = _$StudentRegistrationStateCopyWithImpl;
@useResult
$Res call({
 int currentStep, Map<String, dynamic> personal, Map<String, dynamic> academic, Map<String, dynamic> parents, Map<String, dynamic> additional, RegistrationStatus status, String? errorMessage, bool isAutosaving, bool hasUnsavedChanges, Map<String, dynamic>? finalAdmissionData
});




}
/// @nodoc
class _$StudentRegistrationStateCopyWithImpl<$Res>
    implements $StudentRegistrationStateCopyWith<$Res> {
  _$StudentRegistrationStateCopyWithImpl(this._self, this._then);

  final StudentRegistrationState _self;
  final $Res Function(StudentRegistrationState) _then;

/// Create a copy of StudentRegistrationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? personal = null,Object? academic = null,Object? parents = null,Object? additional = null,Object? status = null,Object? errorMessage = freezed,Object? isAutosaving = null,Object? hasUnsavedChanges = null,Object? finalAdmissionData = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,personal: null == personal ? _self.personal : personal // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,academic: null == academic ? _self.academic : academic // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,parents: null == parents ? _self.parents : parents // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,additional: null == additional ? _self.additional : additional // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegistrationStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isAutosaving: null == isAutosaving ? _self.isAutosaving : isAutosaving // ignore: cast_nullable_to_non_nullable
as bool,hasUnsavedChanges: null == hasUnsavedChanges ? _self.hasUnsavedChanges : hasUnsavedChanges // ignore: cast_nullable_to_non_nullable
as bool,finalAdmissionData: freezed == finalAdmissionData ? _self.finalAdmissionData : finalAdmissionData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentRegistrationState].
extension StudentRegistrationStatePatterns on StudentRegistrationState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentRegistrationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentRegistrationState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentRegistrationState value)  $default,){
final _that = this;
switch (_that) {
case _StudentRegistrationState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentRegistrationState value)?  $default,){
final _that = this;
switch (_that) {
case _StudentRegistrationState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStep,  Map<String, dynamic> personal,  Map<String, dynamic> academic,  Map<String, dynamic> parents,  Map<String, dynamic> additional,  RegistrationStatus status,  String? errorMessage,  bool isAutosaving,  bool hasUnsavedChanges,  Map<String, dynamic>? finalAdmissionData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentRegistrationState() when $default != null:
return $default(_that.currentStep,_that.personal,_that.academic,_that.parents,_that.additional,_that.status,_that.errorMessage,_that.isAutosaving,_that.hasUnsavedChanges,_that.finalAdmissionData);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStep,  Map<String, dynamic> personal,  Map<String, dynamic> academic,  Map<String, dynamic> parents,  Map<String, dynamic> additional,  RegistrationStatus status,  String? errorMessage,  bool isAutosaving,  bool hasUnsavedChanges,  Map<String, dynamic>? finalAdmissionData)  $default,) {final _that = this;
switch (_that) {
case _StudentRegistrationState():
return $default(_that.currentStep,_that.personal,_that.academic,_that.parents,_that.additional,_that.status,_that.errorMessage,_that.isAutosaving,_that.hasUnsavedChanges,_that.finalAdmissionData);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStep,  Map<String, dynamic> personal,  Map<String, dynamic> academic,  Map<String, dynamic> parents,  Map<String, dynamic> additional,  RegistrationStatus status,  String? errorMessage,  bool isAutosaving,  bool hasUnsavedChanges,  Map<String, dynamic>? finalAdmissionData)?  $default,) {final _that = this;
switch (_that) {
case _StudentRegistrationState() when $default != null:
return $default(_that.currentStep,_that.personal,_that.academic,_that.parents,_that.additional,_that.status,_that.errorMessage,_that.isAutosaving,_that.hasUnsavedChanges,_that.finalAdmissionData);case _:
  return null;

}
}

}

/// @nodoc


class _StudentRegistrationState implements StudentRegistrationState {
  const _StudentRegistrationState({this.currentStep = 0, final  Map<String, dynamic> personal = const {}, final  Map<String, dynamic> academic = const {}, final  Map<String, dynamic> parents = const {}, final  Map<String, dynamic> additional = const {}, this.status = RegistrationStatus.initial, this.errorMessage, this.isAutosaving = false, this.hasUnsavedChanges = false, final  Map<String, dynamic>? finalAdmissionData}): _personal = personal,_academic = academic,_parents = parents,_additional = additional,_finalAdmissionData = finalAdmissionData;
  

@override@JsonKey() final  int currentStep;
 final  Map<String, dynamic> _personal;
@override@JsonKey() Map<String, dynamic> get personal {
  if (_personal is EqualUnmodifiableMapView) return _personal;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_personal);
}

 final  Map<String, dynamic> _academic;
@override@JsonKey() Map<String, dynamic> get academic {
  if (_academic is EqualUnmodifiableMapView) return _academic;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_academic);
}

 final  Map<String, dynamic> _parents;
@override@JsonKey() Map<String, dynamic> get parents {
  if (_parents is EqualUnmodifiableMapView) return _parents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_parents);
}

 final  Map<String, dynamic> _additional;
@override@JsonKey() Map<String, dynamic> get additional {
  if (_additional is EqualUnmodifiableMapView) return _additional;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_additional);
}

@override@JsonKey() final  RegistrationStatus status;
@override final  String? errorMessage;
@override@JsonKey() final  bool isAutosaving;
@override@JsonKey() final  bool hasUnsavedChanges;
 final  Map<String, dynamic>? _finalAdmissionData;
@override Map<String, dynamic>? get finalAdmissionData {
  final value = _finalAdmissionData;
  if (value == null) return null;
  if (_finalAdmissionData is EqualUnmodifiableMapView) return _finalAdmissionData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of StudentRegistrationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentRegistrationStateCopyWith<_StudentRegistrationState> get copyWith => __$StudentRegistrationStateCopyWithImpl<_StudentRegistrationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentRegistrationState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&const DeepCollectionEquality().equals(other._personal, _personal)&&const DeepCollectionEquality().equals(other._academic, _academic)&&const DeepCollectionEquality().equals(other._parents, _parents)&&const DeepCollectionEquality().equals(other._additional, _additional)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isAutosaving, isAutosaving) || other.isAutosaving == isAutosaving)&&(identical(other.hasUnsavedChanges, hasUnsavedChanges) || other.hasUnsavedChanges == hasUnsavedChanges)&&const DeepCollectionEquality().equals(other._finalAdmissionData, _finalAdmissionData));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,const DeepCollectionEquality().hash(_personal),const DeepCollectionEquality().hash(_academic),const DeepCollectionEquality().hash(_parents),const DeepCollectionEquality().hash(_additional),status,errorMessage,isAutosaving,hasUnsavedChanges,const DeepCollectionEquality().hash(_finalAdmissionData));

@override
String toString() {
  return 'StudentRegistrationState(currentStep: $currentStep, personal: $personal, academic: $academic, parents: $parents, additional: $additional, status: $status, errorMessage: $errorMessage, isAutosaving: $isAutosaving, hasUnsavedChanges: $hasUnsavedChanges, finalAdmissionData: $finalAdmissionData)';
}


}

/// @nodoc
abstract mixin class _$StudentRegistrationStateCopyWith<$Res> implements $StudentRegistrationStateCopyWith<$Res> {
  factory _$StudentRegistrationStateCopyWith(_StudentRegistrationState value, $Res Function(_StudentRegistrationState) _then) = __$StudentRegistrationStateCopyWithImpl;
@override @useResult
$Res call({
 int currentStep, Map<String, dynamic> personal, Map<String, dynamic> academic, Map<String, dynamic> parents, Map<String, dynamic> additional, RegistrationStatus status, String? errorMessage, bool isAutosaving, bool hasUnsavedChanges, Map<String, dynamic>? finalAdmissionData
});




}
/// @nodoc
class __$StudentRegistrationStateCopyWithImpl<$Res>
    implements _$StudentRegistrationStateCopyWith<$Res> {
  __$StudentRegistrationStateCopyWithImpl(this._self, this._then);

  final _StudentRegistrationState _self;
  final $Res Function(_StudentRegistrationState) _then;

/// Create a copy of StudentRegistrationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? personal = null,Object? academic = null,Object? parents = null,Object? additional = null,Object? status = null,Object? errorMessage = freezed,Object? isAutosaving = null,Object? hasUnsavedChanges = null,Object? finalAdmissionData = freezed,}) {
  return _then(_StudentRegistrationState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,personal: null == personal ? _self._personal : personal // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,academic: null == academic ? _self._academic : academic // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,parents: null == parents ? _self._parents : parents // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,additional: null == additional ? _self._additional : additional // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegistrationStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isAutosaving: null == isAutosaving ? _self.isAutosaving : isAutosaving // ignore: cast_nullable_to_non_nullable
as bool,hasUnsavedChanges: null == hasUnsavedChanges ? _self.hasUnsavedChanges : hasUnsavedChanges // ignore: cast_nullable_to_non_nullable
as bool,finalAdmissionData: freezed == finalAdmissionData ? _self._finalAdmissionData : finalAdmissionData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
