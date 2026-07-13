// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudentProfile {

 String get uid; String get name; String get email; String get gender; String get phoneNumber; String get parentPhoneNumber; String get registeredClass;// '11th', '12th', '11th + 12th'
 List<String> get targetExams;// 'JEE', 'NEET', 'NDA', 'Boards Only'
 bool get profileCompleted; String get status; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentProfileCopyWith<StudentProfile> get copyWith => _$StudentProfileCopyWithImpl<StudentProfile>(this as StudentProfile, _$identity);

  /// Serializes this StudentProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.parentPhoneNumber, parentPhoneNumber) || other.parentPhoneNumber == parentPhoneNumber)&&(identical(other.registeredClass, registeredClass) || other.registeredClass == registeredClass)&&const DeepCollectionEquality().equals(other.targetExams, targetExams)&&(identical(other.profileCompleted, profileCompleted) || other.profileCompleted == profileCompleted)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,name,email,gender,phoneNumber,parentPhoneNumber,registeredClass,const DeepCollectionEquality().hash(targetExams),profileCompleted,status,createdAt,updatedAt);

@override
String toString() {
  return 'StudentProfile(uid: $uid, name: $name, email: $email, gender: $gender, phoneNumber: $phoneNumber, parentPhoneNumber: $parentPhoneNumber, registeredClass: $registeredClass, targetExams: $targetExams, profileCompleted: $profileCompleted, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StudentProfileCopyWith<$Res>  {
  factory $StudentProfileCopyWith(StudentProfile value, $Res Function(StudentProfile) _then) = _$StudentProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String name, String email, String gender, String phoneNumber, String parentPhoneNumber, String registeredClass, List<String> targetExams, bool profileCompleted, String status, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$StudentProfileCopyWithImpl<$Res>
    implements $StudentProfileCopyWith<$Res> {
  _$StudentProfileCopyWithImpl(this._self, this._then);

  final StudentProfile _self;
  final $Res Function(StudentProfile) _then;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? name = null,Object? email = null,Object? gender = null,Object? phoneNumber = null,Object? parentPhoneNumber = null,Object? registeredClass = null,Object? targetExams = null,Object? profileCompleted = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,parentPhoneNumber: null == parentPhoneNumber ? _self.parentPhoneNumber : parentPhoneNumber // ignore: cast_nullable_to_non_nullable
as String,registeredClass: null == registeredClass ? _self.registeredClass : registeredClass // ignore: cast_nullable_to_non_nullable
as String,targetExams: null == targetExams ? _self.targetExams : targetExams // ignore: cast_nullable_to_non_nullable
as List<String>,profileCompleted: null == profileCompleted ? _self.profileCompleted : profileCompleted // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentProfile].
extension StudentProfilePatterns on StudentProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentProfile value)  $default,){
final _that = this;
switch (_that) {
case _StudentProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentProfile value)?  $default,){
final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String name,  String email,  String gender,  String phoneNumber,  String parentPhoneNumber,  String registeredClass,  List<String> targetExams,  bool profileCompleted,  String status,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.uid,_that.name,_that.email,_that.gender,_that.phoneNumber,_that.parentPhoneNumber,_that.registeredClass,_that.targetExams,_that.profileCompleted,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String name,  String email,  String gender,  String phoneNumber,  String parentPhoneNumber,  String registeredClass,  List<String> targetExams,  bool profileCompleted,  String status,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StudentProfile():
return $default(_that.uid,_that.name,_that.email,_that.gender,_that.phoneNumber,_that.parentPhoneNumber,_that.registeredClass,_that.targetExams,_that.profileCompleted,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String name,  String email,  String gender,  String phoneNumber,  String parentPhoneNumber,  String registeredClass,  List<String> targetExams,  bool profileCompleted,  String status,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.uid,_that.name,_that.email,_that.gender,_that.phoneNumber,_that.parentPhoneNumber,_that.registeredClass,_that.targetExams,_that.profileCompleted,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentProfile implements StudentProfile {
  const _StudentProfile({required this.uid, required this.name, required this.email, required this.gender, required this.phoneNumber, required this.parentPhoneNumber, required this.registeredClass, required final  List<String> targetExams, this.profileCompleted = true, this.status = 'Active', required this.createdAt, required this.updatedAt}): _targetExams = targetExams;
  factory _StudentProfile.fromJson(Map<String, dynamic> json) => _$StudentProfileFromJson(json);

@override final  String uid;
@override final  String name;
@override final  String email;
@override final  String gender;
@override final  String phoneNumber;
@override final  String parentPhoneNumber;
@override final  String registeredClass;
// '11th', '12th', '11th + 12th'
 final  List<String> _targetExams;
// '11th', '12th', '11th + 12th'
@override List<String> get targetExams {
  if (_targetExams is EqualUnmodifiableListView) return _targetExams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetExams);
}

// 'JEE', 'NEET', 'NDA', 'Boards Only'
@override@JsonKey() final  bool profileCompleted;
@override@JsonKey() final  String status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentProfileCopyWith<_StudentProfile> get copyWith => __$StudentProfileCopyWithImpl<_StudentProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.parentPhoneNumber, parentPhoneNumber) || other.parentPhoneNumber == parentPhoneNumber)&&(identical(other.registeredClass, registeredClass) || other.registeredClass == registeredClass)&&const DeepCollectionEquality().equals(other._targetExams, _targetExams)&&(identical(other.profileCompleted, profileCompleted) || other.profileCompleted == profileCompleted)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,name,email,gender,phoneNumber,parentPhoneNumber,registeredClass,const DeepCollectionEquality().hash(_targetExams),profileCompleted,status,createdAt,updatedAt);

@override
String toString() {
  return 'StudentProfile(uid: $uid, name: $name, email: $email, gender: $gender, phoneNumber: $phoneNumber, parentPhoneNumber: $parentPhoneNumber, registeredClass: $registeredClass, targetExams: $targetExams, profileCompleted: $profileCompleted, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StudentProfileCopyWith<$Res> implements $StudentProfileCopyWith<$Res> {
  factory _$StudentProfileCopyWith(_StudentProfile value, $Res Function(_StudentProfile) _then) = __$StudentProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String name, String email, String gender, String phoneNumber, String parentPhoneNumber, String registeredClass, List<String> targetExams, bool profileCompleted, String status, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$StudentProfileCopyWithImpl<$Res>
    implements _$StudentProfileCopyWith<$Res> {
  __$StudentProfileCopyWithImpl(this._self, this._then);

  final _StudentProfile _self;
  final $Res Function(_StudentProfile) _then;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? name = null,Object? email = null,Object? gender = null,Object? phoneNumber = null,Object? parentPhoneNumber = null,Object? registeredClass = null,Object? targetExams = null,Object? profileCompleted = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_StudentProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,parentPhoneNumber: null == parentPhoneNumber ? _self.parentPhoneNumber : parentPhoneNumber // ignore: cast_nullable_to_non_nullable
as String,registeredClass: null == registeredClass ? _self.registeredClass : registeredClass // ignore: cast_nullable_to_non_nullable
as String,targetExams: null == targetExams ? _self._targetExams : targetExams // ignore: cast_nullable_to_non_nullable
as List<String>,profileCompleted: null == profileCompleted ? _self.profileCompleted : profileCompleted // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
