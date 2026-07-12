// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StudentProfile _$StudentProfileFromJson(Map<String, dynamic> json) {
  return _StudentProfile.fromJson(json);
}

/// @nodoc
mixin _$StudentProfile {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String get phoneNumber => throw _privateConstructorUsedError;
  String get parentPhoneNumber => throw _privateConstructorUsedError;
  String get registeredClass =>
      throw _privateConstructorUsedError; // '11th', '12th', '11th + 12th'
  List<String> get targetExams =>
      throw _privateConstructorUsedError; // 'JEE', 'NEET', 'NDA', 'Boards Only'
  bool get profileCompleted => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this StudentProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudentProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentProfileCopyWith<StudentProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentProfileCopyWith<$Res> {
  factory $StudentProfileCopyWith(
    StudentProfile value,
    $Res Function(StudentProfile) then,
  ) = _$StudentProfileCopyWithImpl<$Res, StudentProfile>;
  @useResult
  $Res call({
    String uid,
    String name,
    String email,
    String gender,
    String phoneNumber,
    String parentPhoneNumber,
    String registeredClass,
    List<String> targetExams,
    bool profileCompleted,
    String status,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$StudentProfileCopyWithImpl<$Res, $Val extends StudentProfile>
    implements $StudentProfileCopyWith<$Res> {
  _$StudentProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudentProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? gender = null,
    Object? phoneNumber = null,
    Object? parentPhoneNumber = null,
    Object? registeredClass = null,
    Object? targetExams = null,
    Object? profileCompleted = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            parentPhoneNumber: null == parentPhoneNumber
                ? _value.parentPhoneNumber
                : parentPhoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            registeredClass: null == registeredClass
                ? _value.registeredClass
                : registeredClass // ignore: cast_nullable_to_non_nullable
                      as String,
            targetExams: null == targetExams
                ? _value.targetExams
                : targetExams // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            profileCompleted: null == profileCompleted
                ? _value.profileCompleted
                : profileCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudentProfileImplCopyWith<$Res>
    implements $StudentProfileCopyWith<$Res> {
  factory _$$StudentProfileImplCopyWith(
    _$StudentProfileImpl value,
    $Res Function(_$StudentProfileImpl) then,
  ) = __$$StudentProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String name,
    String email,
    String gender,
    String phoneNumber,
    String parentPhoneNumber,
    String registeredClass,
    List<String> targetExams,
    bool profileCompleted,
    String status,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$StudentProfileImplCopyWithImpl<$Res>
    extends _$StudentProfileCopyWithImpl<$Res, _$StudentProfileImpl>
    implements _$$StudentProfileImplCopyWith<$Res> {
  __$$StudentProfileImplCopyWithImpl(
    _$StudentProfileImpl _value,
    $Res Function(_$StudentProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudentProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? gender = null,
    Object? phoneNumber = null,
    Object? parentPhoneNumber = null,
    Object? registeredClass = null,
    Object? targetExams = null,
    Object? profileCompleted = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$StudentProfileImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        parentPhoneNumber: null == parentPhoneNumber
            ? _value.parentPhoneNumber
            : parentPhoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        registeredClass: null == registeredClass
            ? _value.registeredClass
            : registeredClass // ignore: cast_nullable_to_non_nullable
                  as String,
        targetExams: null == targetExams
            ? _value._targetExams
            : targetExams // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        profileCompleted: null == profileCompleted
            ? _value.profileCompleted
            : profileCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentProfileImpl implements _StudentProfile {
  const _$StudentProfileImpl({
    required this.uid,
    required this.name,
    required this.email,
    required this.gender,
    required this.phoneNumber,
    required this.parentPhoneNumber,
    required this.registeredClass,
    required final List<String> targetExams,
    this.profileCompleted = true,
    this.status = 'Active',
    required this.createdAt,
    required this.updatedAt,
  }) : _targetExams = targetExams;

  factory _$StudentProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentProfileImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  final String email;
  @override
  final String gender;
  @override
  final String phoneNumber;
  @override
  final String parentPhoneNumber;
  @override
  final String registeredClass;
  // '11th', '12th', '11th + 12th'
  final List<String> _targetExams;
  // '11th', '12th', '11th + 12th'
  @override
  List<String> get targetExams {
    if (_targetExams is EqualUnmodifiableListView) return _targetExams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_targetExams);
  }

  // 'JEE', 'NEET', 'NDA', 'Boards Only'
  @override
  @JsonKey()
  final bool profileCompleted;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'StudentProfile(uid: $uid, name: $name, email: $email, gender: $gender, phoneNumber: $phoneNumber, parentPhoneNumber: $parentPhoneNumber, registeredClass: $registeredClass, targetExams: $targetExams, profileCompleted: $profileCompleted, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentProfileImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.parentPhoneNumber, parentPhoneNumber) ||
                other.parentPhoneNumber == parentPhoneNumber) &&
            (identical(other.registeredClass, registeredClass) ||
                other.registeredClass == registeredClass) &&
            const DeepCollectionEquality().equals(
              other._targetExams,
              _targetExams,
            ) &&
            (identical(other.profileCompleted, profileCompleted) ||
                other.profileCompleted == profileCompleted) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    name,
    email,
    gender,
    phoneNumber,
    parentPhoneNumber,
    registeredClass,
    const DeepCollectionEquality().hash(_targetExams),
    profileCompleted,
    status,
    createdAt,
    updatedAt,
  );

  /// Create a copy of StudentProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentProfileImplCopyWith<_$StudentProfileImpl> get copyWith =>
      __$$StudentProfileImplCopyWithImpl<_$StudentProfileImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentProfileImplToJson(this);
  }
}

abstract class _StudentProfile implements StudentProfile {
  const factory _StudentProfile({
    required final String uid,
    required final String name,
    required final String email,
    required final String gender,
    required final String phoneNumber,
    required final String parentPhoneNumber,
    required final String registeredClass,
    required final List<String> targetExams,
    final bool profileCompleted,
    final String status,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$StudentProfileImpl;

  factory _StudentProfile.fromJson(Map<String, dynamic> json) =
      _$StudentProfileImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  String get email;
  @override
  String get gender;
  @override
  String get phoneNumber;
  @override
  String get parentPhoneNumber;
  @override
  String get registeredClass; // '11th', '12th', '11th + 12th'
  @override
  List<String> get targetExams; // 'JEE', 'NEET', 'NDA', 'Boards Only'
  @override
  bool get profileCompleted;
  @override
  String get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of StudentProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentProfileImplCopyWith<_$StudentProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
