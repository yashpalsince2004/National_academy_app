// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PersonalInformation {

 String get fullName; String get email; String get phoneNumber; String get gender; String get dob; String get address; String get city; String get state; String get pinCode; String get emergencyContact;
/// Create a copy of PersonalInformation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalInformationCopyWith<PersonalInformation> get copyWith => _$PersonalInformationCopyWithImpl<PersonalInformation>(this as PersonalInformation, _$identity);

  /// Serializes this PersonalInformation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalInformation&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pinCode, pinCode) || other.pinCode == pinCode)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,email,phoneNumber,gender,dob,address,city,state,pinCode,emergencyContact);

@override
String toString() {
  return 'PersonalInformation(fullName: $fullName, email: $email, phoneNumber: $phoneNumber, gender: $gender, dob: $dob, address: $address, city: $city, state: $state, pinCode: $pinCode, emergencyContact: $emergencyContact)';
}


}

/// @nodoc
abstract mixin class $PersonalInformationCopyWith<$Res>  {
  factory $PersonalInformationCopyWith(PersonalInformation value, $Res Function(PersonalInformation) _then) = _$PersonalInformationCopyWithImpl;
@useResult
$Res call({
 String fullName, String email, String phoneNumber, String gender, String dob, String address, String city, String state, String pinCode, String emergencyContact
});




}
/// @nodoc
class _$PersonalInformationCopyWithImpl<$Res>
    implements $PersonalInformationCopyWith<$Res> {
  _$PersonalInformationCopyWithImpl(this._self, this._then);

  final PersonalInformation _self;
  final $Res Function(PersonalInformation) _then;

/// Create a copy of PersonalInformation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? email = null,Object? phoneNumber = null,Object? gender = null,Object? dob = null,Object? address = null,Object? city = null,Object? state = null,Object? pinCode = null,Object? emergencyContact = null,}) {
  return _then(_self.copyWith(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,dob: null == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pinCode: null == pinCode ? _self.pinCode : pinCode // ignore: cast_nullable_to_non_nullable
as String,emergencyContact: null == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalInformation].
extension PersonalInformationPatterns on PersonalInformation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalInformation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalInformation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalInformation value)  $default,){
final _that = this;
switch (_that) {
case _PersonalInformation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalInformation value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalInformation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String email,  String phoneNumber,  String gender,  String dob,  String address,  String city,  String state,  String pinCode,  String emergencyContact)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalInformation() when $default != null:
return $default(_that.fullName,_that.email,_that.phoneNumber,_that.gender,_that.dob,_that.address,_that.city,_that.state,_that.pinCode,_that.emergencyContact);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String email,  String phoneNumber,  String gender,  String dob,  String address,  String city,  String state,  String pinCode,  String emergencyContact)  $default,) {final _that = this;
switch (_that) {
case _PersonalInformation():
return $default(_that.fullName,_that.email,_that.phoneNumber,_that.gender,_that.dob,_that.address,_that.city,_that.state,_that.pinCode,_that.emergencyContact);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String email,  String phoneNumber,  String gender,  String dob,  String address,  String city,  String state,  String pinCode,  String emergencyContact)?  $default,) {final _that = this;
switch (_that) {
case _PersonalInformation() when $default != null:
return $default(_that.fullName,_that.email,_that.phoneNumber,_that.gender,_that.dob,_that.address,_that.city,_that.state,_that.pinCode,_that.emergencyContact);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalInformation implements PersonalInformation {
  const _PersonalInformation({required this.fullName, required this.email, required this.phoneNumber, required this.gender, required this.dob, required this.address, required this.city, required this.state, required this.pinCode, required this.emergencyContact});
  factory _PersonalInformation.fromJson(Map<String, dynamic> json) => _$PersonalInformationFromJson(json);

@override final  String fullName;
@override final  String email;
@override final  String phoneNumber;
@override final  String gender;
@override final  String dob;
@override final  String address;
@override final  String city;
@override final  String state;
@override final  String pinCode;
@override final  String emergencyContact;

/// Create a copy of PersonalInformation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalInformationCopyWith<_PersonalInformation> get copyWith => __$PersonalInformationCopyWithImpl<_PersonalInformation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalInformationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalInformation&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pinCode, pinCode) || other.pinCode == pinCode)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,email,phoneNumber,gender,dob,address,city,state,pinCode,emergencyContact);

@override
String toString() {
  return 'PersonalInformation(fullName: $fullName, email: $email, phoneNumber: $phoneNumber, gender: $gender, dob: $dob, address: $address, city: $city, state: $state, pinCode: $pinCode, emergencyContact: $emergencyContact)';
}


}

/// @nodoc
abstract mixin class _$PersonalInformationCopyWith<$Res> implements $PersonalInformationCopyWith<$Res> {
  factory _$PersonalInformationCopyWith(_PersonalInformation value, $Res Function(_PersonalInformation) _then) = __$PersonalInformationCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String email, String phoneNumber, String gender, String dob, String address, String city, String state, String pinCode, String emergencyContact
});




}
/// @nodoc
class __$PersonalInformationCopyWithImpl<$Res>
    implements _$PersonalInformationCopyWith<$Res> {
  __$PersonalInformationCopyWithImpl(this._self, this._then);

  final _PersonalInformation _self;
  final $Res Function(_PersonalInformation) _then;

/// Create a copy of PersonalInformation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? email = null,Object? phoneNumber = null,Object? gender = null,Object? dob = null,Object? address = null,Object? city = null,Object? state = null,Object? pinCode = null,Object? emergencyContact = null,}) {
  return _then(_PersonalInformation(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,dob: null == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pinCode: null == pinCode ? _self.pinCode : pinCode // ignore: cast_nullable_to_non_nullable
as String,emergencyContact: null == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AcademicInformation {

 String get admissionNumber; String get enrollmentDate;@JsonKey(name: 'class') String get classLevel; String get courseType; String get targetExam; String get batchName; String get rollNumber; String get previousSchool;
/// Create a copy of AcademicInformation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademicInformationCopyWith<AcademicInformation> get copyWith => _$AcademicInformationCopyWithImpl<AcademicInformation>(this as AcademicInformation, _$identity);

  /// Serializes this AcademicInformation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcademicInformation&&(identical(other.admissionNumber, admissionNumber) || other.admissionNumber == admissionNumber)&&(identical(other.enrollmentDate, enrollmentDate) || other.enrollmentDate == enrollmentDate)&&(identical(other.classLevel, classLevel) || other.classLevel == classLevel)&&(identical(other.courseType, courseType) || other.courseType == courseType)&&(identical(other.targetExam, targetExam) || other.targetExam == targetExam)&&(identical(other.batchName, batchName) || other.batchName == batchName)&&(identical(other.rollNumber, rollNumber) || other.rollNumber == rollNumber)&&(identical(other.previousSchool, previousSchool) || other.previousSchool == previousSchool));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,admissionNumber,enrollmentDate,classLevel,courseType,targetExam,batchName,rollNumber,previousSchool);

@override
String toString() {
  return 'AcademicInformation(admissionNumber: $admissionNumber, enrollmentDate: $enrollmentDate, classLevel: $classLevel, courseType: $courseType, targetExam: $targetExam, batchName: $batchName, rollNumber: $rollNumber, previousSchool: $previousSchool)';
}


}

/// @nodoc
abstract mixin class $AcademicInformationCopyWith<$Res>  {
  factory $AcademicInformationCopyWith(AcademicInformation value, $Res Function(AcademicInformation) _then) = _$AcademicInformationCopyWithImpl;
@useResult
$Res call({
 String admissionNumber, String enrollmentDate,@JsonKey(name: 'class') String classLevel, String courseType, String targetExam, String batchName, String rollNumber, String previousSchool
});




}
/// @nodoc
class _$AcademicInformationCopyWithImpl<$Res>
    implements $AcademicInformationCopyWith<$Res> {
  _$AcademicInformationCopyWithImpl(this._self, this._then);

  final AcademicInformation _self;
  final $Res Function(AcademicInformation) _then;

/// Create a copy of AcademicInformation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? admissionNumber = null,Object? enrollmentDate = null,Object? classLevel = null,Object? courseType = null,Object? targetExam = null,Object? batchName = null,Object? rollNumber = null,Object? previousSchool = null,}) {
  return _then(_self.copyWith(
admissionNumber: null == admissionNumber ? _self.admissionNumber : admissionNumber // ignore: cast_nullable_to_non_nullable
as String,enrollmentDate: null == enrollmentDate ? _self.enrollmentDate : enrollmentDate // ignore: cast_nullable_to_non_nullable
as String,classLevel: null == classLevel ? _self.classLevel : classLevel // ignore: cast_nullable_to_non_nullable
as String,courseType: null == courseType ? _self.courseType : courseType // ignore: cast_nullable_to_non_nullable
as String,targetExam: null == targetExam ? _self.targetExam : targetExam // ignore: cast_nullable_to_non_nullable
as String,batchName: null == batchName ? _self.batchName : batchName // ignore: cast_nullable_to_non_nullable
as String,rollNumber: null == rollNumber ? _self.rollNumber : rollNumber // ignore: cast_nullable_to_non_nullable
as String,previousSchool: null == previousSchool ? _self.previousSchool : previousSchool // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AcademicInformation].
extension AcademicInformationPatterns on AcademicInformation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcademicInformation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcademicInformation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcademicInformation value)  $default,){
final _that = this;
switch (_that) {
case _AcademicInformation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcademicInformation value)?  $default,){
final _that = this;
switch (_that) {
case _AcademicInformation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String admissionNumber,  String enrollmentDate, @JsonKey(name: 'class')  String classLevel,  String courseType,  String targetExam,  String batchName,  String rollNumber,  String previousSchool)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcademicInformation() when $default != null:
return $default(_that.admissionNumber,_that.enrollmentDate,_that.classLevel,_that.courseType,_that.targetExam,_that.batchName,_that.rollNumber,_that.previousSchool);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String admissionNumber,  String enrollmentDate, @JsonKey(name: 'class')  String classLevel,  String courseType,  String targetExam,  String batchName,  String rollNumber,  String previousSchool)  $default,) {final _that = this;
switch (_that) {
case _AcademicInformation():
return $default(_that.admissionNumber,_that.enrollmentDate,_that.classLevel,_that.courseType,_that.targetExam,_that.batchName,_that.rollNumber,_that.previousSchool);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String admissionNumber,  String enrollmentDate, @JsonKey(name: 'class')  String classLevel,  String courseType,  String targetExam,  String batchName,  String rollNumber,  String previousSchool)?  $default,) {final _that = this;
switch (_that) {
case _AcademicInformation() when $default != null:
return $default(_that.admissionNumber,_that.enrollmentDate,_that.classLevel,_that.courseType,_that.targetExam,_that.batchName,_that.rollNumber,_that.previousSchool);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcademicInformation implements AcademicInformation {
  const _AcademicInformation({required this.admissionNumber, required this.enrollmentDate, @JsonKey(name: 'class') required this.classLevel, required this.courseType, required this.targetExam, required this.batchName, required this.rollNumber, required this.previousSchool});
  factory _AcademicInformation.fromJson(Map<String, dynamic> json) => _$AcademicInformationFromJson(json);

@override final  String admissionNumber;
@override final  String enrollmentDate;
@override@JsonKey(name: 'class') final  String classLevel;
@override final  String courseType;
@override final  String targetExam;
@override final  String batchName;
@override final  String rollNumber;
@override final  String previousSchool;

/// Create a copy of AcademicInformation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademicInformationCopyWith<_AcademicInformation> get copyWith => __$AcademicInformationCopyWithImpl<_AcademicInformation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcademicInformationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcademicInformation&&(identical(other.admissionNumber, admissionNumber) || other.admissionNumber == admissionNumber)&&(identical(other.enrollmentDate, enrollmentDate) || other.enrollmentDate == enrollmentDate)&&(identical(other.classLevel, classLevel) || other.classLevel == classLevel)&&(identical(other.courseType, courseType) || other.courseType == courseType)&&(identical(other.targetExam, targetExam) || other.targetExam == targetExam)&&(identical(other.batchName, batchName) || other.batchName == batchName)&&(identical(other.rollNumber, rollNumber) || other.rollNumber == rollNumber)&&(identical(other.previousSchool, previousSchool) || other.previousSchool == previousSchool));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,admissionNumber,enrollmentDate,classLevel,courseType,targetExam,batchName,rollNumber,previousSchool);

@override
String toString() {
  return 'AcademicInformation(admissionNumber: $admissionNumber, enrollmentDate: $enrollmentDate, classLevel: $classLevel, courseType: $courseType, targetExam: $targetExam, batchName: $batchName, rollNumber: $rollNumber, previousSchool: $previousSchool)';
}


}

/// @nodoc
abstract mixin class _$AcademicInformationCopyWith<$Res> implements $AcademicInformationCopyWith<$Res> {
  factory _$AcademicInformationCopyWith(_AcademicInformation value, $Res Function(_AcademicInformation) _then) = __$AcademicInformationCopyWithImpl;
@override @useResult
$Res call({
 String admissionNumber, String enrollmentDate,@JsonKey(name: 'class') String classLevel, String courseType, String targetExam, String batchName, String rollNumber, String previousSchool
});




}
/// @nodoc
class __$AcademicInformationCopyWithImpl<$Res>
    implements _$AcademicInformationCopyWith<$Res> {
  __$AcademicInformationCopyWithImpl(this._self, this._then);

  final _AcademicInformation _self;
  final $Res Function(_AcademicInformation) _then;

/// Create a copy of AcademicInformation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? admissionNumber = null,Object? enrollmentDate = null,Object? classLevel = null,Object? courseType = null,Object? targetExam = null,Object? batchName = null,Object? rollNumber = null,Object? previousSchool = null,}) {
  return _then(_AcademicInformation(
admissionNumber: null == admissionNumber ? _self.admissionNumber : admissionNumber // ignore: cast_nullable_to_non_nullable
as String,enrollmentDate: null == enrollmentDate ? _self.enrollmentDate : enrollmentDate // ignore: cast_nullable_to_non_nullable
as String,classLevel: null == classLevel ? _self.classLevel : classLevel // ignore: cast_nullable_to_non_nullable
as String,courseType: null == courseType ? _self.courseType : courseType // ignore: cast_nullable_to_non_nullable
as String,targetExam: null == targetExam ? _self.targetExam : targetExam // ignore: cast_nullable_to_non_nullable
as String,batchName: null == batchName ? _self.batchName : batchName // ignore: cast_nullable_to_non_nullable
as String,rollNumber: null == rollNumber ? _self.rollNumber : rollNumber // ignore: cast_nullable_to_non_nullable
as String,previousSchool: null == previousSchool ? _self.previousSchool : previousSchool // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ParentInformation {

 String get parentName; String get parentPhone;
/// Create a copy of ParentInformation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParentInformationCopyWith<ParentInformation> get copyWith => _$ParentInformationCopyWithImpl<ParentInformation>(this as ParentInformation, _$identity);

  /// Serializes this ParentInformation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParentInformation&&(identical(other.parentName, parentName) || other.parentName == parentName)&&(identical(other.parentPhone, parentPhone) || other.parentPhone == parentPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,parentName,parentPhone);

@override
String toString() {
  return 'ParentInformation(parentName: $parentName, parentPhone: $parentPhone)';
}


}

/// @nodoc
abstract mixin class $ParentInformationCopyWith<$Res>  {
  factory $ParentInformationCopyWith(ParentInformation value, $Res Function(ParentInformation) _then) = _$ParentInformationCopyWithImpl;
@useResult
$Res call({
 String parentName, String parentPhone
});




}
/// @nodoc
class _$ParentInformationCopyWithImpl<$Res>
    implements $ParentInformationCopyWith<$Res> {
  _$ParentInformationCopyWithImpl(this._self, this._then);

  final ParentInformation _self;
  final $Res Function(ParentInformation) _then;

/// Create a copy of ParentInformation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? parentName = null,Object? parentPhone = null,}) {
  return _then(_self.copyWith(
parentName: null == parentName ? _self.parentName : parentName // ignore: cast_nullable_to_non_nullable
as String,parentPhone: null == parentPhone ? _self.parentPhone : parentPhone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ParentInformation].
extension ParentInformationPatterns on ParentInformation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParentInformation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParentInformation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParentInformation value)  $default,){
final _that = this;
switch (_that) {
case _ParentInformation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParentInformation value)?  $default,){
final _that = this;
switch (_that) {
case _ParentInformation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String parentName,  String parentPhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParentInformation() when $default != null:
return $default(_that.parentName,_that.parentPhone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String parentName,  String parentPhone)  $default,) {final _that = this;
switch (_that) {
case _ParentInformation():
return $default(_that.parentName,_that.parentPhone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String parentName,  String parentPhone)?  $default,) {final _that = this;
switch (_that) {
case _ParentInformation() when $default != null:
return $default(_that.parentName,_that.parentPhone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParentInformation implements ParentInformation {
  const _ParentInformation({required this.parentName, required this.parentPhone});
  factory _ParentInformation.fromJson(Map<String, dynamic> json) => _$ParentInformationFromJson(json);

@override final  String parentName;
@override final  String parentPhone;

/// Create a copy of ParentInformation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParentInformationCopyWith<_ParentInformation> get copyWith => __$ParentInformationCopyWithImpl<_ParentInformation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParentInformationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParentInformation&&(identical(other.parentName, parentName) || other.parentName == parentName)&&(identical(other.parentPhone, parentPhone) || other.parentPhone == parentPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,parentName,parentPhone);

@override
String toString() {
  return 'ParentInformation(parentName: $parentName, parentPhone: $parentPhone)';
}


}

/// @nodoc
abstract mixin class _$ParentInformationCopyWith<$Res> implements $ParentInformationCopyWith<$Res> {
  factory _$ParentInformationCopyWith(_ParentInformation value, $Res Function(_ParentInformation) _then) = __$ParentInformationCopyWithImpl;
@override @useResult
$Res call({
 String parentName, String parentPhone
});




}
/// @nodoc
class __$ParentInformationCopyWithImpl<$Res>
    implements _$ParentInformationCopyWith<$Res> {
  __$ParentInformationCopyWithImpl(this._self, this._then);

  final _ParentInformation _self;
  final $Res Function(_ParentInformation) _then;

/// Create a copy of ParentInformation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? parentName = null,Object? parentPhone = null,}) {
  return _then(_ParentInformation(
parentName: null == parentName ? _self.parentName : parentName // ignore: cast_nullable_to_non_nullable
as String,parentPhone: null == parentPhone ? _self.parentPhone : parentPhone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StudentModel {

 String get studentId;@JsonKey(name: 'personal_information') PersonalInformation get personalInformation;@JsonKey(name: 'academic_information') AcademicInformation get academicInformation;@JsonKey(name: 'parent_information') ParentInformation get parentInformation;@JsonKey(name: 'profile_image') String get profileImage; String get status;
/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentModelCopyWith<StudentModel> get copyWith => _$StudentModelCopyWithImpl<StudentModel>(this as StudentModel, _$identity);

  /// Serializes this StudentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentModel&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.personalInformation, personalInformation) || other.personalInformation == personalInformation)&&(identical(other.academicInformation, academicInformation) || other.academicInformation == academicInformation)&&(identical(other.parentInformation, parentInformation) || other.parentInformation == parentInformation)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,studentId,personalInformation,academicInformation,parentInformation,profileImage,status);

@override
String toString() {
  return 'StudentModel(studentId: $studentId, personalInformation: $personalInformation, academicInformation: $academicInformation, parentInformation: $parentInformation, profileImage: $profileImage, status: $status)';
}


}

/// @nodoc
abstract mixin class $StudentModelCopyWith<$Res>  {
  factory $StudentModelCopyWith(StudentModel value, $Res Function(StudentModel) _then) = _$StudentModelCopyWithImpl;
@useResult
$Res call({
 String studentId,@JsonKey(name: 'personal_information') PersonalInformation personalInformation,@JsonKey(name: 'academic_information') AcademicInformation academicInformation,@JsonKey(name: 'parent_information') ParentInformation parentInformation,@JsonKey(name: 'profile_image') String profileImage, String status
});


$PersonalInformationCopyWith<$Res> get personalInformation;$AcademicInformationCopyWith<$Res> get academicInformation;$ParentInformationCopyWith<$Res> get parentInformation;

}
/// @nodoc
class _$StudentModelCopyWithImpl<$Res>
    implements $StudentModelCopyWith<$Res> {
  _$StudentModelCopyWithImpl(this._self, this._then);

  final StudentModel _self;
  final $Res Function(StudentModel) _then;

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? studentId = null,Object? personalInformation = null,Object? academicInformation = null,Object? parentInformation = null,Object? profileImage = null,Object? status = null,}) {
  return _then(_self.copyWith(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,personalInformation: null == personalInformation ? _self.personalInformation : personalInformation // ignore: cast_nullable_to_non_nullable
as PersonalInformation,academicInformation: null == academicInformation ? _self.academicInformation : academicInformation // ignore: cast_nullable_to_non_nullable
as AcademicInformation,parentInformation: null == parentInformation ? _self.parentInformation : parentInformation // ignore: cast_nullable_to_non_nullable
as ParentInformation,profileImage: null == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonalInformationCopyWith<$Res> get personalInformation {
  
  return $PersonalInformationCopyWith<$Res>(_self.personalInformation, (value) {
    return _then(_self.copyWith(personalInformation: value));
  });
}/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AcademicInformationCopyWith<$Res> get academicInformation {
  
  return $AcademicInformationCopyWith<$Res>(_self.academicInformation, (value) {
    return _then(_self.copyWith(academicInformation: value));
  });
}/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParentInformationCopyWith<$Res> get parentInformation {
  
  return $ParentInformationCopyWith<$Res>(_self.parentInformation, (value) {
    return _then(_self.copyWith(parentInformation: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudentModel].
extension StudentModelPatterns on StudentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentModel value)  $default,){
final _that = this;
switch (_that) {
case _StudentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentModel value)?  $default,){
final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String studentId, @JsonKey(name: 'personal_information')  PersonalInformation personalInformation, @JsonKey(name: 'academic_information')  AcademicInformation academicInformation, @JsonKey(name: 'parent_information')  ParentInformation parentInformation, @JsonKey(name: 'profile_image')  String profileImage,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
return $default(_that.studentId,_that.personalInformation,_that.academicInformation,_that.parentInformation,_that.profileImage,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String studentId, @JsonKey(name: 'personal_information')  PersonalInformation personalInformation, @JsonKey(name: 'academic_information')  AcademicInformation academicInformation, @JsonKey(name: 'parent_information')  ParentInformation parentInformation, @JsonKey(name: 'profile_image')  String profileImage,  String status)  $default,) {final _that = this;
switch (_that) {
case _StudentModel():
return $default(_that.studentId,_that.personalInformation,_that.academicInformation,_that.parentInformation,_that.profileImage,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String studentId, @JsonKey(name: 'personal_information')  PersonalInformation personalInformation, @JsonKey(name: 'academic_information')  AcademicInformation academicInformation, @JsonKey(name: 'parent_information')  ParentInformation parentInformation, @JsonKey(name: 'profile_image')  String profileImage,  String status)?  $default,) {final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
return $default(_that.studentId,_that.personalInformation,_that.academicInformation,_that.parentInformation,_that.profileImage,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentModel implements StudentModel {
  const _StudentModel({required this.studentId, @JsonKey(name: 'personal_information') required this.personalInformation, @JsonKey(name: 'academic_information') required this.academicInformation, @JsonKey(name: 'parent_information') required this.parentInformation, @JsonKey(name: 'profile_image') required this.profileImage, required this.status});
  factory _StudentModel.fromJson(Map<String, dynamic> json) => _$StudentModelFromJson(json);

@override final  String studentId;
@override@JsonKey(name: 'personal_information') final  PersonalInformation personalInformation;
@override@JsonKey(name: 'academic_information') final  AcademicInformation academicInformation;
@override@JsonKey(name: 'parent_information') final  ParentInformation parentInformation;
@override@JsonKey(name: 'profile_image') final  String profileImage;
@override final  String status;

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentModelCopyWith<_StudentModel> get copyWith => __$StudentModelCopyWithImpl<_StudentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentModel&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.personalInformation, personalInformation) || other.personalInformation == personalInformation)&&(identical(other.academicInformation, academicInformation) || other.academicInformation == academicInformation)&&(identical(other.parentInformation, parentInformation) || other.parentInformation == parentInformation)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,studentId,personalInformation,academicInformation,parentInformation,profileImage,status);

@override
String toString() {
  return 'StudentModel(studentId: $studentId, personalInformation: $personalInformation, academicInformation: $academicInformation, parentInformation: $parentInformation, profileImage: $profileImage, status: $status)';
}


}

/// @nodoc
abstract mixin class _$StudentModelCopyWith<$Res> implements $StudentModelCopyWith<$Res> {
  factory _$StudentModelCopyWith(_StudentModel value, $Res Function(_StudentModel) _then) = __$StudentModelCopyWithImpl;
@override @useResult
$Res call({
 String studentId,@JsonKey(name: 'personal_information') PersonalInformation personalInformation,@JsonKey(name: 'academic_information') AcademicInformation academicInformation,@JsonKey(name: 'parent_information') ParentInformation parentInformation,@JsonKey(name: 'profile_image') String profileImage, String status
});


@override $PersonalInformationCopyWith<$Res> get personalInformation;@override $AcademicInformationCopyWith<$Res> get academicInformation;@override $ParentInformationCopyWith<$Res> get parentInformation;

}
/// @nodoc
class __$StudentModelCopyWithImpl<$Res>
    implements _$StudentModelCopyWith<$Res> {
  __$StudentModelCopyWithImpl(this._self, this._then);

  final _StudentModel _self;
  final $Res Function(_StudentModel) _then;

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? studentId = null,Object? personalInformation = null,Object? academicInformation = null,Object? parentInformation = null,Object? profileImage = null,Object? status = null,}) {
  return _then(_StudentModel(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,personalInformation: null == personalInformation ? _self.personalInformation : personalInformation // ignore: cast_nullable_to_non_nullable
as PersonalInformation,academicInformation: null == academicInformation ? _self.academicInformation : academicInformation // ignore: cast_nullable_to_non_nullable
as AcademicInformation,parentInformation: null == parentInformation ? _self.parentInformation : parentInformation // ignore: cast_nullable_to_non_nullable
as ParentInformation,profileImage: null == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonalInformationCopyWith<$Res> get personalInformation {
  
  return $PersonalInformationCopyWith<$Res>(_self.personalInformation, (value) {
    return _then(_self.copyWith(personalInformation: value));
  });
}/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AcademicInformationCopyWith<$Res> get academicInformation {
  
  return $AcademicInformationCopyWith<$Res>(_self.academicInformation, (value) {
    return _then(_self.copyWith(academicInformation: value));
  });
}/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParentInformationCopyWith<$Res> get parentInformation {
  
  return $ParentInformationCopyWith<$Res>(_self.parentInformation, (value) {
    return _then(_self.copyWith(parentInformation: value));
  });
}
}

// dart format on
