// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'college.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CollegeListItem _$CollegeListItemFromJson(Map<String, dynamic> json) {
  return _CollegeListItem.fromJson(json);
}

/// @nodoc
mixin _$CollegeListItem {
  String get slug => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'short_name')
  String? get shortName => throw _privateConstructorUsedError;
  @JsonKey(name: 'college_type')
  String get collegeType => throw _privateConstructorUsedError;
  @JsonKey(name: 'state_name')
  String get stateName => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_name')
  String? get cityName => throw _privateConstructorUsedError;
  @JsonKey(name: 'nirf_rank_latest')
  int? get nirfRank => throw _privateConstructorUsedError;
  @JsonKey(name: 'programme_count')
  int get programmeCount => throw _privateConstructorUsedError;

  /// Serializes this CollegeListItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeListItemCopyWith<CollegeListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeListItemCopyWith<$Res> {
  factory $CollegeListItemCopyWith(
    CollegeListItem value,
    $Res Function(CollegeListItem) then,
  ) = _$CollegeListItemCopyWithImpl<$Res, CollegeListItem>;
  @useResult
  $Res call({
    String slug,
    String name,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'college_type') String collegeType,
    @JsonKey(name: 'state_name') String stateName,
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    @JsonKey(name: 'programme_count') int programmeCount,
  });
}

/// @nodoc
class _$CollegeListItemCopyWithImpl<$Res, $Val extends CollegeListItem>
    implements $CollegeListItemCopyWith<$Res> {
  _$CollegeListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? collegeType = null,
    Object? stateName = null,
    Object? cityName = freezed,
    Object? nirfRank = freezed,
    Object? programmeCount = null,
  }) {
    return _then(
      _value.copyWith(
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            shortName: freezed == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                      as String?,
            collegeType: null == collegeType
                ? _value.collegeType
                : collegeType // ignore: cast_nullable_to_non_nullable
                      as String,
            stateName: null == stateName
                ? _value.stateName
                : stateName // ignore: cast_nullable_to_non_nullable
                      as String,
            cityName: freezed == cityName
                ? _value.cityName
                : cityName // ignore: cast_nullable_to_non_nullable
                      as String?,
            nirfRank: freezed == nirfRank
                ? _value.nirfRank
                : nirfRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            programmeCount: null == programmeCount
                ? _value.programmeCount
                : programmeCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollegeListItemImplCopyWith<$Res>
    implements $CollegeListItemCopyWith<$Res> {
  factory _$$CollegeListItemImplCopyWith(
    _$CollegeListItemImpl value,
    $Res Function(_$CollegeListItemImpl) then,
  ) = __$$CollegeListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String slug,
    String name,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'college_type') String collegeType,
    @JsonKey(name: 'state_name') String stateName,
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    @JsonKey(name: 'programme_count') int programmeCount,
  });
}

/// @nodoc
class __$$CollegeListItemImplCopyWithImpl<$Res>
    extends _$CollegeListItemCopyWithImpl<$Res, _$CollegeListItemImpl>
    implements _$$CollegeListItemImplCopyWith<$Res> {
  __$$CollegeListItemImplCopyWithImpl(
    _$CollegeListItemImpl _value,
    $Res Function(_$CollegeListItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? collegeType = null,
    Object? stateName = null,
    Object? cityName = freezed,
    Object? nirfRank = freezed,
    Object? programmeCount = null,
  }) {
    return _then(
      _$CollegeListItemImpl(
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        shortName: freezed == shortName
            ? _value.shortName
            : shortName // ignore: cast_nullable_to_non_nullable
                  as String?,
        collegeType: null == collegeType
            ? _value.collegeType
            : collegeType // ignore: cast_nullable_to_non_nullable
                  as String,
        stateName: null == stateName
            ? _value.stateName
            : stateName // ignore: cast_nullable_to_non_nullable
                  as String,
        cityName: freezed == cityName
            ? _value.cityName
            : cityName // ignore: cast_nullable_to_non_nullable
                  as String?,
        nirfRank: freezed == nirfRank
            ? _value.nirfRank
            : nirfRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        programmeCount: null == programmeCount
            ? _value.programmeCount
            : programmeCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeListItemImpl implements _CollegeListItem {
  const _$CollegeListItemImpl({
    required this.slug,
    required this.name,
    @JsonKey(name: 'short_name') this.shortName,
    @JsonKey(name: 'college_type') required this.collegeType,
    @JsonKey(name: 'state_name') required this.stateName,
    @JsonKey(name: 'city_name') this.cityName,
    @JsonKey(name: 'nirf_rank_latest') this.nirfRank,
    @JsonKey(name: 'programme_count') required this.programmeCount,
  });

  factory _$CollegeListItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeListItemImplFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  @JsonKey(name: 'short_name')
  final String? shortName;
  @override
  @JsonKey(name: 'college_type')
  final String collegeType;
  @override
  @JsonKey(name: 'state_name')
  final String stateName;
  @override
  @JsonKey(name: 'city_name')
  final String? cityName;
  @override
  @JsonKey(name: 'nirf_rank_latest')
  final int? nirfRank;
  @override
  @JsonKey(name: 'programme_count')
  final int programmeCount;

  @override
  String toString() {
    return 'CollegeListItem(slug: $slug, name: $name, shortName: $shortName, collegeType: $collegeType, stateName: $stateName, cityName: $cityName, nirfRank: $nirfRank, programmeCount: $programmeCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeListItemImpl &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.collegeType, collegeType) ||
                other.collegeType == collegeType) &&
            (identical(other.stateName, stateName) ||
                other.stateName == stateName) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.nirfRank, nirfRank) ||
                other.nirfRank == nirfRank) &&
            (identical(other.programmeCount, programmeCount) ||
                other.programmeCount == programmeCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    slug,
    name,
    shortName,
    collegeType,
    stateName,
    cityName,
    nirfRank,
    programmeCount,
  );

  /// Create a copy of CollegeListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeListItemImplCopyWith<_$CollegeListItemImpl> get copyWith =>
      __$$CollegeListItemImplCopyWithImpl<_$CollegeListItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeListItemImplToJson(this);
  }
}

abstract class _CollegeListItem implements CollegeListItem {
  const factory _CollegeListItem({
    required final String slug,
    required final String name,
    @JsonKey(name: 'short_name') final String? shortName,
    @JsonKey(name: 'college_type') required final String collegeType,
    @JsonKey(name: 'state_name') required final String stateName,
    @JsonKey(name: 'city_name') final String? cityName,
    @JsonKey(name: 'nirf_rank_latest') final int? nirfRank,
    @JsonKey(name: 'programme_count') required final int programmeCount,
  }) = _$CollegeListItemImpl;

  factory _CollegeListItem.fromJson(Map<String, dynamic> json) =
      _$CollegeListItemImpl.fromJson;

  @override
  String get slug;
  @override
  String get name;
  @override
  @JsonKey(name: 'short_name')
  String? get shortName;
  @override
  @JsonKey(name: 'college_type')
  String get collegeType;
  @override
  @JsonKey(name: 'state_name')
  String get stateName;
  @override
  @JsonKey(name: 'city_name')
  String? get cityName;
  @override
  @JsonKey(name: 'nirf_rank_latest')
  int? get nirfRank;
  @override
  @JsonKey(name: 'programme_count')
  int get programmeCount;

  /// Create a copy of CollegeListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeListItemImplCopyWith<_$CollegeListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CollegeProgramme _$CollegeProgrammeFromJson(Map<String, dynamic> json) {
  return _CollegeProgramme.fromJson(json);
}

/// @nodoc
mixin _$CollegeProgramme {
  @JsonKey(name: 'college_branch_id')
  String get collegeBranchId => throw _privateConstructorUsedError;
  @JsonKey(name: 'program_name')
  String get programName => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_code')
  String get branchCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_name')
  String get branchName => throw _privateConstructorUsedError;
  String get degree => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_years')
  String? get durationYears => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_intake')
  int? get totalIntake => throw _privateConstructorUsedError;

  /// 'rank' or 'score'. Null when nothing has been published for this
  /// programme yet.
  String? get measure => throw _privateConstructorUsedError;

  /// The latest published cut-off, as a string because Postgres sends
  /// NUMERIC that way. A rank when [measure] is 'rank', a score out of
  /// [latestMaxScore] when it is 'score'.
  @JsonKey(name: 'latest_closing')
  String? get latestClosing => throw _privateConstructorUsedError;
  @JsonKey(name: 'latest_max_score')
  String? get latestMaxScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'latest_year')
  int? get latestYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'years_available')
  int? get yearsAvailable => throw _privateConstructorUsedError;

  /// Serializes this CollegeProgramme to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeProgramme
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeProgrammeCopyWith<CollegeProgramme> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeProgrammeCopyWith<$Res> {
  factory $CollegeProgrammeCopyWith(
    CollegeProgramme value,
    $Res Function(CollegeProgramme) then,
  ) = _$CollegeProgrammeCopyWithImpl<$Res, CollegeProgramme>;
  @useResult
  $Res call({
    @JsonKey(name: 'college_branch_id') String collegeBranchId,
    @JsonKey(name: 'program_name') String programName,
    @JsonKey(name: 'branch_code') String branchCode,
    @JsonKey(name: 'branch_name') String branchName,
    String degree,
    @JsonKey(name: 'duration_years') String? durationYears,
    @JsonKey(name: 'total_intake') int? totalIntake,
    String? measure,
    @JsonKey(name: 'latest_closing') String? latestClosing,
    @JsonKey(name: 'latest_max_score') String? latestMaxScore,
    @JsonKey(name: 'latest_year') int? latestYear,
    @JsonKey(name: 'years_available') int? yearsAvailable,
  });
}

/// @nodoc
class _$CollegeProgrammeCopyWithImpl<$Res, $Val extends CollegeProgramme>
    implements $CollegeProgrammeCopyWith<$Res> {
  _$CollegeProgrammeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeProgramme
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collegeBranchId = null,
    Object? programName = null,
    Object? branchCode = null,
    Object? branchName = null,
    Object? degree = null,
    Object? durationYears = freezed,
    Object? totalIntake = freezed,
    Object? measure = freezed,
    Object? latestClosing = freezed,
    Object? latestMaxScore = freezed,
    Object? latestYear = freezed,
    Object? yearsAvailable = freezed,
  }) {
    return _then(
      _value.copyWith(
            collegeBranchId: null == collegeBranchId
                ? _value.collegeBranchId
                : collegeBranchId // ignore: cast_nullable_to_non_nullable
                      as String,
            programName: null == programName
                ? _value.programName
                : programName // ignore: cast_nullable_to_non_nullable
                      as String,
            branchCode: null == branchCode
                ? _value.branchCode
                : branchCode // ignore: cast_nullable_to_non_nullable
                      as String,
            branchName: null == branchName
                ? _value.branchName
                : branchName // ignore: cast_nullable_to_non_nullable
                      as String,
            degree: null == degree
                ? _value.degree
                : degree // ignore: cast_nullable_to_non_nullable
                      as String,
            durationYears: freezed == durationYears
                ? _value.durationYears
                : durationYears // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalIntake: freezed == totalIntake
                ? _value.totalIntake
                : totalIntake // ignore: cast_nullable_to_non_nullable
                      as int?,
            measure: freezed == measure
                ? _value.measure
                : measure // ignore: cast_nullable_to_non_nullable
                      as String?,
            latestClosing: freezed == latestClosing
                ? _value.latestClosing
                : latestClosing // ignore: cast_nullable_to_non_nullable
                      as String?,
            latestMaxScore: freezed == latestMaxScore
                ? _value.latestMaxScore
                : latestMaxScore // ignore: cast_nullable_to_non_nullable
                      as String?,
            latestYear: freezed == latestYear
                ? _value.latestYear
                : latestYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            yearsAvailable: freezed == yearsAvailable
                ? _value.yearsAvailable
                : yearsAvailable // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollegeProgrammeImplCopyWith<$Res>
    implements $CollegeProgrammeCopyWith<$Res> {
  factory _$$CollegeProgrammeImplCopyWith(
    _$CollegeProgrammeImpl value,
    $Res Function(_$CollegeProgrammeImpl) then,
  ) = __$$CollegeProgrammeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'college_branch_id') String collegeBranchId,
    @JsonKey(name: 'program_name') String programName,
    @JsonKey(name: 'branch_code') String branchCode,
    @JsonKey(name: 'branch_name') String branchName,
    String degree,
    @JsonKey(name: 'duration_years') String? durationYears,
    @JsonKey(name: 'total_intake') int? totalIntake,
    String? measure,
    @JsonKey(name: 'latest_closing') String? latestClosing,
    @JsonKey(name: 'latest_max_score') String? latestMaxScore,
    @JsonKey(name: 'latest_year') int? latestYear,
    @JsonKey(name: 'years_available') int? yearsAvailable,
  });
}

/// @nodoc
class __$$CollegeProgrammeImplCopyWithImpl<$Res>
    extends _$CollegeProgrammeCopyWithImpl<$Res, _$CollegeProgrammeImpl>
    implements _$$CollegeProgrammeImplCopyWith<$Res> {
  __$$CollegeProgrammeImplCopyWithImpl(
    _$CollegeProgrammeImpl _value,
    $Res Function(_$CollegeProgrammeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeProgramme
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collegeBranchId = null,
    Object? programName = null,
    Object? branchCode = null,
    Object? branchName = null,
    Object? degree = null,
    Object? durationYears = freezed,
    Object? totalIntake = freezed,
    Object? measure = freezed,
    Object? latestClosing = freezed,
    Object? latestMaxScore = freezed,
    Object? latestYear = freezed,
    Object? yearsAvailable = freezed,
  }) {
    return _then(
      _$CollegeProgrammeImpl(
        collegeBranchId: null == collegeBranchId
            ? _value.collegeBranchId
            : collegeBranchId // ignore: cast_nullable_to_non_nullable
                  as String,
        programName: null == programName
            ? _value.programName
            : programName // ignore: cast_nullable_to_non_nullable
                  as String,
        branchCode: null == branchCode
            ? _value.branchCode
            : branchCode // ignore: cast_nullable_to_non_nullable
                  as String,
        branchName: null == branchName
            ? _value.branchName
            : branchName // ignore: cast_nullable_to_non_nullable
                  as String,
        degree: null == degree
            ? _value.degree
            : degree // ignore: cast_nullable_to_non_nullable
                  as String,
        durationYears: freezed == durationYears
            ? _value.durationYears
            : durationYears // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalIntake: freezed == totalIntake
            ? _value.totalIntake
            : totalIntake // ignore: cast_nullable_to_non_nullable
                  as int?,
        measure: freezed == measure
            ? _value.measure
            : measure // ignore: cast_nullable_to_non_nullable
                  as String?,
        latestClosing: freezed == latestClosing
            ? _value.latestClosing
            : latestClosing // ignore: cast_nullable_to_non_nullable
                  as String?,
        latestMaxScore: freezed == latestMaxScore
            ? _value.latestMaxScore
            : latestMaxScore // ignore: cast_nullable_to_non_nullable
                  as String?,
        latestYear: freezed == latestYear
            ? _value.latestYear
            : latestYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        yearsAvailable: freezed == yearsAvailable
            ? _value.yearsAvailable
            : yearsAvailable // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeProgrammeImpl extends _CollegeProgramme {
  const _$CollegeProgrammeImpl({
    @JsonKey(name: 'college_branch_id') required this.collegeBranchId,
    @JsonKey(name: 'program_name') required this.programName,
    @JsonKey(name: 'branch_code') required this.branchCode,
    @JsonKey(name: 'branch_name') required this.branchName,
    required this.degree,
    @JsonKey(name: 'duration_years') this.durationYears,
    @JsonKey(name: 'total_intake') this.totalIntake,
    this.measure,
    @JsonKey(name: 'latest_closing') this.latestClosing,
    @JsonKey(name: 'latest_max_score') this.latestMaxScore,
    @JsonKey(name: 'latest_year') this.latestYear,
    @JsonKey(name: 'years_available') this.yearsAvailable,
  }) : super._();

  factory _$CollegeProgrammeImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeProgrammeImplFromJson(json);

  @override
  @JsonKey(name: 'college_branch_id')
  final String collegeBranchId;
  @override
  @JsonKey(name: 'program_name')
  final String programName;
  @override
  @JsonKey(name: 'branch_code')
  final String branchCode;
  @override
  @JsonKey(name: 'branch_name')
  final String branchName;
  @override
  final String degree;
  @override
  @JsonKey(name: 'duration_years')
  final String? durationYears;
  @override
  @JsonKey(name: 'total_intake')
  final int? totalIntake;

  /// 'rank' or 'score'. Null when nothing has been published for this
  /// programme yet.
  @override
  final String? measure;

  /// The latest published cut-off, as a string because Postgres sends
  /// NUMERIC that way. A rank when [measure] is 'rank', a score out of
  /// [latestMaxScore] when it is 'score'.
  @override
  @JsonKey(name: 'latest_closing')
  final String? latestClosing;
  @override
  @JsonKey(name: 'latest_max_score')
  final String? latestMaxScore;
  @override
  @JsonKey(name: 'latest_year')
  final int? latestYear;
  @override
  @JsonKey(name: 'years_available')
  final int? yearsAvailable;

  @override
  String toString() {
    return 'CollegeProgramme(collegeBranchId: $collegeBranchId, programName: $programName, branchCode: $branchCode, branchName: $branchName, degree: $degree, durationYears: $durationYears, totalIntake: $totalIntake, measure: $measure, latestClosing: $latestClosing, latestMaxScore: $latestMaxScore, latestYear: $latestYear, yearsAvailable: $yearsAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeProgrammeImpl &&
            (identical(other.collegeBranchId, collegeBranchId) ||
                other.collegeBranchId == collegeBranchId) &&
            (identical(other.programName, programName) ||
                other.programName == programName) &&
            (identical(other.branchCode, branchCode) ||
                other.branchCode == branchCode) &&
            (identical(other.branchName, branchName) ||
                other.branchName == branchName) &&
            (identical(other.degree, degree) || other.degree == degree) &&
            (identical(other.durationYears, durationYears) ||
                other.durationYears == durationYears) &&
            (identical(other.totalIntake, totalIntake) ||
                other.totalIntake == totalIntake) &&
            (identical(other.measure, measure) || other.measure == measure) &&
            (identical(other.latestClosing, latestClosing) ||
                other.latestClosing == latestClosing) &&
            (identical(other.latestMaxScore, latestMaxScore) ||
                other.latestMaxScore == latestMaxScore) &&
            (identical(other.latestYear, latestYear) ||
                other.latestYear == latestYear) &&
            (identical(other.yearsAvailable, yearsAvailable) ||
                other.yearsAvailable == yearsAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    collegeBranchId,
    programName,
    branchCode,
    branchName,
    degree,
    durationYears,
    totalIntake,
    measure,
    latestClosing,
    latestMaxScore,
    latestYear,
    yearsAvailable,
  );

  /// Create a copy of CollegeProgramme
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeProgrammeImplCopyWith<_$CollegeProgrammeImpl> get copyWith =>
      __$$CollegeProgrammeImplCopyWithImpl<_$CollegeProgrammeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeProgrammeImplToJson(this);
  }
}

abstract class _CollegeProgramme extends CollegeProgramme {
  const factory _CollegeProgramme({
    @JsonKey(name: 'college_branch_id') required final String collegeBranchId,
    @JsonKey(name: 'program_name') required final String programName,
    @JsonKey(name: 'branch_code') required final String branchCode,
    @JsonKey(name: 'branch_name') required final String branchName,
    required final String degree,
    @JsonKey(name: 'duration_years') final String? durationYears,
    @JsonKey(name: 'total_intake') final int? totalIntake,
    final String? measure,
    @JsonKey(name: 'latest_closing') final String? latestClosing,
    @JsonKey(name: 'latest_max_score') final String? latestMaxScore,
    @JsonKey(name: 'latest_year') final int? latestYear,
    @JsonKey(name: 'years_available') final int? yearsAvailable,
  }) = _$CollegeProgrammeImpl;
  const _CollegeProgramme._() : super._();

  factory _CollegeProgramme.fromJson(Map<String, dynamic> json) =
      _$CollegeProgrammeImpl.fromJson;

  @override
  @JsonKey(name: 'college_branch_id')
  String get collegeBranchId;
  @override
  @JsonKey(name: 'program_name')
  String get programName;
  @override
  @JsonKey(name: 'branch_code')
  String get branchCode;
  @override
  @JsonKey(name: 'branch_name')
  String get branchName;
  @override
  String get degree;
  @override
  @JsonKey(name: 'duration_years')
  String? get durationYears;
  @override
  @JsonKey(name: 'total_intake')
  int? get totalIntake;

  /// 'rank' or 'score'. Null when nothing has been published for this
  /// programme yet.
  @override
  String? get measure;

  /// The latest published cut-off, as a string because Postgres sends
  /// NUMERIC that way. A rank when [measure] is 'rank', a score out of
  /// [latestMaxScore] when it is 'score'.
  @override
  @JsonKey(name: 'latest_closing')
  String? get latestClosing;
  @override
  @JsonKey(name: 'latest_max_score')
  String? get latestMaxScore;
  @override
  @JsonKey(name: 'latest_year')
  int? get latestYear;
  @override
  @JsonKey(name: 'years_available')
  int? get yearsAvailable;

  /// Create a copy of CollegeProgramme
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeProgrammeImplCopyWith<_$CollegeProgrammeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CollegeAuthority _$CollegeAuthorityFromJson(Map<String, dynamic> json) {
  return _CollegeAuthority.fromJson(json);
}

/// @nodoc
mixin _$CollegeAuthority {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<int> get years => throw _privateConstructorUsedError;
  int get rows => throw _privateConstructorUsedError;

  /// Serializes this CollegeAuthority to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeAuthority
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeAuthorityCopyWith<CollegeAuthority> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeAuthorityCopyWith<$Res> {
  factory $CollegeAuthorityCopyWith(
    CollegeAuthority value,
    $Res Function(CollegeAuthority) then,
  ) = _$CollegeAuthorityCopyWithImpl<$Res, CollegeAuthority>;
  @useResult
  $Res call({String code, String name, List<int> years, int rows});
}

/// @nodoc
class _$CollegeAuthorityCopyWithImpl<$Res, $Val extends CollegeAuthority>
    implements $CollegeAuthorityCopyWith<$Res> {
  _$CollegeAuthorityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeAuthority
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? years = null,
    Object? rows = null,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            years: null == years
                ? _value.years
                : years // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            rows: null == rows
                ? _value.rows
                : rows // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollegeAuthorityImplCopyWith<$Res>
    implements $CollegeAuthorityCopyWith<$Res> {
  factory _$$CollegeAuthorityImplCopyWith(
    _$CollegeAuthorityImpl value,
    $Res Function(_$CollegeAuthorityImpl) then,
  ) = __$$CollegeAuthorityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String name, List<int> years, int rows});
}

/// @nodoc
class __$$CollegeAuthorityImplCopyWithImpl<$Res>
    extends _$CollegeAuthorityCopyWithImpl<$Res, _$CollegeAuthorityImpl>
    implements _$$CollegeAuthorityImplCopyWith<$Res> {
  __$$CollegeAuthorityImplCopyWithImpl(
    _$CollegeAuthorityImpl _value,
    $Res Function(_$CollegeAuthorityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeAuthority
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? years = null,
    Object? rows = null,
  }) {
    return _then(
      _$CollegeAuthorityImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        years: null == years
            ? _value._years
            : years // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        rows: null == rows
            ? _value.rows
            : rows // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeAuthorityImpl implements _CollegeAuthority {
  const _$CollegeAuthorityImpl({
    required this.code,
    required this.name,
    required final List<int> years,
    required this.rows,
  }) : _years = years;

  factory _$CollegeAuthorityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeAuthorityImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  final List<int> _years;
  @override
  List<int> get years {
    if (_years is EqualUnmodifiableListView) return _years;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_years);
  }

  @override
  final int rows;

  @override
  String toString() {
    return 'CollegeAuthority(code: $code, name: $name, years: $years, rows: $rows)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeAuthorityImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._years, _years) &&
            (identical(other.rows, rows) || other.rows == rows));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    name,
    const DeepCollectionEquality().hash(_years),
    rows,
  );

  /// Create a copy of CollegeAuthority
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeAuthorityImplCopyWith<_$CollegeAuthorityImpl> get copyWith =>
      __$$CollegeAuthorityImplCopyWithImpl<_$CollegeAuthorityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeAuthorityImplToJson(this);
  }
}

abstract class _CollegeAuthority implements CollegeAuthority {
  const factory _CollegeAuthority({
    required final String code,
    required final String name,
    required final List<int> years,
    required final int rows,
  }) = _$CollegeAuthorityImpl;

  factory _CollegeAuthority.fromJson(Map<String, dynamic> json) =
      _$CollegeAuthorityImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  List<int> get years;
  @override
  int get rows;

  /// Create a copy of CollegeAuthority
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeAuthorityImplCopyWith<_$CollegeAuthorityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CollegeInfo _$CollegeInfoFromJson(Map<String, dynamic> json) {
  return _CollegeInfo.fromJson(json);
}

/// @nodoc
mixin _$CollegeInfo {
  String get slug => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'short_name')
  String? get shortName => throw _privateConstructorUsedError;
  String? get about => throw _privateConstructorUsedError;
  @JsonKey(name: 'college_type')
  String get collegeType => throw _privateConstructorUsedError;
  String get ownership => throw _privateConstructorUsedError;
  @JsonKey(name: 'affiliated_university')
  String? get affiliatedUniversity => throw _privateConstructorUsedError;
  @JsonKey(name: 'established_year')
  int? get establishedYear => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_hostel')
  bool? get hasHostel => throw _privateConstructorUsedError;
  @JsonKey(name: 'nirf_rank_latest')
  int? get nirfRank => throw _privateConstructorUsedError;
  @JsonKey(name: 'nirf_year_latest')
  int? get nirfYear => throw _privateConstructorUsedError;
  Map<String, dynamic> get states => throw _privateConstructorUsedError;
  Map<String, dynamic>? get cities => throw _privateConstructorUsedError;

  /// Serializes this CollegeInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeInfoCopyWith<CollegeInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeInfoCopyWith<$Res> {
  factory $CollegeInfoCopyWith(
    CollegeInfo value,
    $Res Function(CollegeInfo) then,
  ) = _$CollegeInfoCopyWithImpl<$Res, CollegeInfo>;
  @useResult
  $Res call({
    String slug,
    String name,
    @JsonKey(name: 'short_name') String? shortName,
    String? about,
    @JsonKey(name: 'college_type') String collegeType,
    String ownership,
    @JsonKey(name: 'affiliated_university') String? affiliatedUniversity,
    @JsonKey(name: 'established_year') int? establishedYear,
    String? website,
    @JsonKey(name: 'has_hostel') bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    @JsonKey(name: 'nirf_year_latest') int? nirfYear,
    Map<String, dynamic> states,
    Map<String, dynamic>? cities,
  });
}

/// @nodoc
class _$CollegeInfoCopyWithImpl<$Res, $Val extends CollegeInfo>
    implements $CollegeInfoCopyWith<$Res> {
  _$CollegeInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? about = freezed,
    Object? collegeType = null,
    Object? ownership = null,
    Object? affiliatedUniversity = freezed,
    Object? establishedYear = freezed,
    Object? website = freezed,
    Object? hasHostel = freezed,
    Object? nirfRank = freezed,
    Object? nirfYear = freezed,
    Object? states = null,
    Object? cities = freezed,
  }) {
    return _then(
      _value.copyWith(
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            shortName: freezed == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                      as String?,
            about: freezed == about
                ? _value.about
                : about // ignore: cast_nullable_to_non_nullable
                      as String?,
            collegeType: null == collegeType
                ? _value.collegeType
                : collegeType // ignore: cast_nullable_to_non_nullable
                      as String,
            ownership: null == ownership
                ? _value.ownership
                : ownership // ignore: cast_nullable_to_non_nullable
                      as String,
            affiliatedUniversity: freezed == affiliatedUniversity
                ? _value.affiliatedUniversity
                : affiliatedUniversity // ignore: cast_nullable_to_non_nullable
                      as String?,
            establishedYear: freezed == establishedYear
                ? _value.establishedYear
                : establishedYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasHostel: freezed == hasHostel
                ? _value.hasHostel
                : hasHostel // ignore: cast_nullable_to_non_nullable
                      as bool?,
            nirfRank: freezed == nirfRank
                ? _value.nirfRank
                : nirfRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            nirfYear: freezed == nirfYear
                ? _value.nirfYear
                : nirfYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            states: null == states
                ? _value.states
                : states // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            cities: freezed == cities
                ? _value.cities
                : cities // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollegeInfoImplCopyWith<$Res>
    implements $CollegeInfoCopyWith<$Res> {
  factory _$$CollegeInfoImplCopyWith(
    _$CollegeInfoImpl value,
    $Res Function(_$CollegeInfoImpl) then,
  ) = __$$CollegeInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String slug,
    String name,
    @JsonKey(name: 'short_name') String? shortName,
    String? about,
    @JsonKey(name: 'college_type') String collegeType,
    String ownership,
    @JsonKey(name: 'affiliated_university') String? affiliatedUniversity,
    @JsonKey(name: 'established_year') int? establishedYear,
    String? website,
    @JsonKey(name: 'has_hostel') bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    @JsonKey(name: 'nirf_year_latest') int? nirfYear,
    Map<String, dynamic> states,
    Map<String, dynamic>? cities,
  });
}

/// @nodoc
class __$$CollegeInfoImplCopyWithImpl<$Res>
    extends _$CollegeInfoCopyWithImpl<$Res, _$CollegeInfoImpl>
    implements _$$CollegeInfoImplCopyWith<$Res> {
  __$$CollegeInfoImplCopyWithImpl(
    _$CollegeInfoImpl _value,
    $Res Function(_$CollegeInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? about = freezed,
    Object? collegeType = null,
    Object? ownership = null,
    Object? affiliatedUniversity = freezed,
    Object? establishedYear = freezed,
    Object? website = freezed,
    Object? hasHostel = freezed,
    Object? nirfRank = freezed,
    Object? nirfYear = freezed,
    Object? states = null,
    Object? cities = freezed,
  }) {
    return _then(
      _$CollegeInfoImpl(
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        shortName: freezed == shortName
            ? _value.shortName
            : shortName // ignore: cast_nullable_to_non_nullable
                  as String?,
        about: freezed == about
            ? _value.about
            : about // ignore: cast_nullable_to_non_nullable
                  as String?,
        collegeType: null == collegeType
            ? _value.collegeType
            : collegeType // ignore: cast_nullable_to_non_nullable
                  as String,
        ownership: null == ownership
            ? _value.ownership
            : ownership // ignore: cast_nullable_to_non_nullable
                  as String,
        affiliatedUniversity: freezed == affiliatedUniversity
            ? _value.affiliatedUniversity
            : affiliatedUniversity // ignore: cast_nullable_to_non_nullable
                  as String?,
        establishedYear: freezed == establishedYear
            ? _value.establishedYear
            : establishedYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasHostel: freezed == hasHostel
            ? _value.hasHostel
            : hasHostel // ignore: cast_nullable_to_non_nullable
                  as bool?,
        nirfRank: freezed == nirfRank
            ? _value.nirfRank
            : nirfRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        nirfYear: freezed == nirfYear
            ? _value.nirfYear
            : nirfYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        states: null == states
            ? _value._states
            : states // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        cities: freezed == cities
            ? _value._cities
            : cities // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeInfoImpl extends _CollegeInfo {
  const _$CollegeInfoImpl({
    required this.slug,
    required this.name,
    @JsonKey(name: 'short_name') this.shortName,
    this.about,
    @JsonKey(name: 'college_type') required this.collegeType,
    required this.ownership,
    @JsonKey(name: 'affiliated_university') this.affiliatedUniversity,
    @JsonKey(name: 'established_year') this.establishedYear,
    this.website,
    @JsonKey(name: 'has_hostel') this.hasHostel,
    @JsonKey(name: 'nirf_rank_latest') this.nirfRank,
    @JsonKey(name: 'nirf_year_latest') this.nirfYear,
    required final Map<String, dynamic> states,
    final Map<String, dynamic>? cities,
  }) : _states = states,
       _cities = cities,
       super._();

  factory _$CollegeInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeInfoImplFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  @JsonKey(name: 'short_name')
  final String? shortName;
  @override
  final String? about;
  @override
  @JsonKey(name: 'college_type')
  final String collegeType;
  @override
  final String ownership;
  @override
  @JsonKey(name: 'affiliated_university')
  final String? affiliatedUniversity;
  @override
  @JsonKey(name: 'established_year')
  final int? establishedYear;
  @override
  final String? website;
  @override
  @JsonKey(name: 'has_hostel')
  final bool? hasHostel;
  @override
  @JsonKey(name: 'nirf_rank_latest')
  final int? nirfRank;
  @override
  @JsonKey(name: 'nirf_year_latest')
  final int? nirfYear;
  final Map<String, dynamic> _states;
  @override
  Map<String, dynamic> get states {
    if (_states is EqualUnmodifiableMapView) return _states;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_states);
  }

  final Map<String, dynamic>? _cities;
  @override
  Map<String, dynamic>? get cities {
    final value = _cities;
    if (value == null) return null;
    if (_cities is EqualUnmodifiableMapView) return _cities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'CollegeInfo(slug: $slug, name: $name, shortName: $shortName, about: $about, collegeType: $collegeType, ownership: $ownership, affiliatedUniversity: $affiliatedUniversity, establishedYear: $establishedYear, website: $website, hasHostel: $hasHostel, nirfRank: $nirfRank, nirfYear: $nirfYear, states: $states, cities: $cities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeInfoImpl &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.about, about) || other.about == about) &&
            (identical(other.collegeType, collegeType) ||
                other.collegeType == collegeType) &&
            (identical(other.ownership, ownership) ||
                other.ownership == ownership) &&
            (identical(other.affiliatedUniversity, affiliatedUniversity) ||
                other.affiliatedUniversity == affiliatedUniversity) &&
            (identical(other.establishedYear, establishedYear) ||
                other.establishedYear == establishedYear) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.hasHostel, hasHostel) ||
                other.hasHostel == hasHostel) &&
            (identical(other.nirfRank, nirfRank) ||
                other.nirfRank == nirfRank) &&
            (identical(other.nirfYear, nirfYear) ||
                other.nirfYear == nirfYear) &&
            const DeepCollectionEquality().equals(other._states, _states) &&
            const DeepCollectionEquality().equals(other._cities, _cities));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    slug,
    name,
    shortName,
    about,
    collegeType,
    ownership,
    affiliatedUniversity,
    establishedYear,
    website,
    hasHostel,
    nirfRank,
    nirfYear,
    const DeepCollectionEquality().hash(_states),
    const DeepCollectionEquality().hash(_cities),
  );

  /// Create a copy of CollegeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeInfoImplCopyWith<_$CollegeInfoImpl> get copyWith =>
      __$$CollegeInfoImplCopyWithImpl<_$CollegeInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeInfoImplToJson(this);
  }
}

abstract class _CollegeInfo extends CollegeInfo {
  const factory _CollegeInfo({
    required final String slug,
    required final String name,
    @JsonKey(name: 'short_name') final String? shortName,
    final String? about,
    @JsonKey(name: 'college_type') required final String collegeType,
    required final String ownership,
    @JsonKey(name: 'affiliated_university') final String? affiliatedUniversity,
    @JsonKey(name: 'established_year') final int? establishedYear,
    final String? website,
    @JsonKey(name: 'has_hostel') final bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') final int? nirfRank,
    @JsonKey(name: 'nirf_year_latest') final int? nirfYear,
    required final Map<String, dynamic> states,
    final Map<String, dynamic>? cities,
  }) = _$CollegeInfoImpl;
  const _CollegeInfo._() : super._();

  factory _CollegeInfo.fromJson(Map<String, dynamic> json) =
      _$CollegeInfoImpl.fromJson;

  @override
  String get slug;
  @override
  String get name;
  @override
  @JsonKey(name: 'short_name')
  String? get shortName;
  @override
  String? get about;
  @override
  @JsonKey(name: 'college_type')
  String get collegeType;
  @override
  String get ownership;
  @override
  @JsonKey(name: 'affiliated_university')
  String? get affiliatedUniversity;
  @override
  @JsonKey(name: 'established_year')
  int? get establishedYear;
  @override
  String? get website;
  @override
  @JsonKey(name: 'has_hostel')
  bool? get hasHostel;
  @override
  @JsonKey(name: 'nirf_rank_latest')
  int? get nirfRank;
  @override
  @JsonKey(name: 'nirf_year_latest')
  int? get nirfYear;
  @override
  Map<String, dynamic> get states;
  @override
  Map<String, dynamic>? get cities;

  /// Create a copy of CollegeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeInfoImplCopyWith<_$CollegeInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CollegeDetail _$CollegeDetailFromJson(Map<String, dynamic> json) {
  return _CollegeDetail.fromJson(json);
}

/// @nodoc
mixin _$CollegeDetail {
  CollegeInfo get college => throw _privateConstructorUsedError;
  List<CollegeProgramme> get programmes => throw _privateConstructorUsedError;
  List<CollegeAuthority> get authorities => throw _privateConstructorUsedError;

  /// Serializes this CollegeDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeDetailCopyWith<CollegeDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeDetailCopyWith<$Res> {
  factory $CollegeDetailCopyWith(
    CollegeDetail value,
    $Res Function(CollegeDetail) then,
  ) = _$CollegeDetailCopyWithImpl<$Res, CollegeDetail>;
  @useResult
  $Res call({
    CollegeInfo college,
    List<CollegeProgramme> programmes,
    List<CollegeAuthority> authorities,
  });

  $CollegeInfoCopyWith<$Res> get college;
}

/// @nodoc
class _$CollegeDetailCopyWithImpl<$Res, $Val extends CollegeDetail>
    implements $CollegeDetailCopyWith<$Res> {
  _$CollegeDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? college = null,
    Object? programmes = null,
    Object? authorities = null,
  }) {
    return _then(
      _value.copyWith(
            college: null == college
                ? _value.college
                : college // ignore: cast_nullable_to_non_nullable
                      as CollegeInfo,
            programmes: null == programmes
                ? _value.programmes
                : programmes // ignore: cast_nullable_to_non_nullable
                      as List<CollegeProgramme>,
            authorities: null == authorities
                ? _value.authorities
                : authorities // ignore: cast_nullable_to_non_nullable
                      as List<CollegeAuthority>,
          )
          as $Val,
    );
  }

  /// Create a copy of CollegeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CollegeInfoCopyWith<$Res> get college {
    return $CollegeInfoCopyWith<$Res>(_value.college, (value) {
      return _then(_value.copyWith(college: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CollegeDetailImplCopyWith<$Res>
    implements $CollegeDetailCopyWith<$Res> {
  factory _$$CollegeDetailImplCopyWith(
    _$CollegeDetailImpl value,
    $Res Function(_$CollegeDetailImpl) then,
  ) = __$$CollegeDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CollegeInfo college,
    List<CollegeProgramme> programmes,
    List<CollegeAuthority> authorities,
  });

  @override
  $CollegeInfoCopyWith<$Res> get college;
}

/// @nodoc
class __$$CollegeDetailImplCopyWithImpl<$Res>
    extends _$CollegeDetailCopyWithImpl<$Res, _$CollegeDetailImpl>
    implements _$$CollegeDetailImplCopyWith<$Res> {
  __$$CollegeDetailImplCopyWithImpl(
    _$CollegeDetailImpl _value,
    $Res Function(_$CollegeDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? college = null,
    Object? programmes = null,
    Object? authorities = null,
  }) {
    return _then(
      _$CollegeDetailImpl(
        college: null == college
            ? _value.college
            : college // ignore: cast_nullable_to_non_nullable
                  as CollegeInfo,
        programmes: null == programmes
            ? _value._programmes
            : programmes // ignore: cast_nullable_to_non_nullable
                  as List<CollegeProgramme>,
        authorities: null == authorities
            ? _value._authorities
            : authorities // ignore: cast_nullable_to_non_nullable
                  as List<CollegeAuthority>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeDetailImpl implements _CollegeDetail {
  const _$CollegeDetailImpl({
    required this.college,
    final List<CollegeProgramme> programmes = const <CollegeProgramme>[],
    final List<CollegeAuthority> authorities = const <CollegeAuthority>[],
  }) : _programmes = programmes,
       _authorities = authorities;

  factory _$CollegeDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeDetailImplFromJson(json);

  @override
  final CollegeInfo college;
  final List<CollegeProgramme> _programmes;
  @override
  @JsonKey()
  List<CollegeProgramme> get programmes {
    if (_programmes is EqualUnmodifiableListView) return _programmes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_programmes);
  }

  final List<CollegeAuthority> _authorities;
  @override
  @JsonKey()
  List<CollegeAuthority> get authorities {
    if (_authorities is EqualUnmodifiableListView) return _authorities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_authorities);
  }

  @override
  String toString() {
    return 'CollegeDetail(college: $college, programmes: $programmes, authorities: $authorities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeDetailImpl &&
            (identical(other.college, college) || other.college == college) &&
            const DeepCollectionEquality().equals(
              other._programmes,
              _programmes,
            ) &&
            const DeepCollectionEquality().equals(
              other._authorities,
              _authorities,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    college,
    const DeepCollectionEquality().hash(_programmes),
    const DeepCollectionEquality().hash(_authorities),
  );

  /// Create a copy of CollegeDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeDetailImplCopyWith<_$CollegeDetailImpl> get copyWith =>
      __$$CollegeDetailImplCopyWithImpl<_$CollegeDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeDetailImplToJson(this);
  }
}

abstract class _CollegeDetail implements CollegeDetail {
  const factory _CollegeDetail({
    required final CollegeInfo college,
    final List<CollegeProgramme> programmes,
    final List<CollegeAuthority> authorities,
  }) = _$CollegeDetailImpl;

  factory _CollegeDetail.fromJson(Map<String, dynamic> json) =
      _$CollegeDetailImpl.fromJson;

  @override
  CollegeInfo get college;
  @override
  List<CollegeProgramme> get programmes;
  @override
  List<CollegeAuthority> get authorities;

  /// Create a copy of CollegeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeDetailImplCopyWith<_$CollegeDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompareBranch _$CompareBranchFromJson(Map<String, dynamic> json) {
  return _CompareBranch.fromJson(json);
}

/// @nodoc
mixin _$CompareBranch {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Map<String, CompareCell> get byCollege => throw _privateConstructorUsedError;

  /// Serializes this CompareBranch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompareBranch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompareBranchCopyWith<CompareBranch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompareBranchCopyWith<$Res> {
  factory $CompareBranchCopyWith(
    CompareBranch value,
    $Res Function(CompareBranch) then,
  ) = _$CompareBranchCopyWithImpl<$Res, CompareBranch>;
  @useResult
  $Res call({String code, String name, Map<String, CompareCell> byCollege});
}

/// @nodoc
class _$CompareBranchCopyWithImpl<$Res, $Val extends CompareBranch>
    implements $CompareBranchCopyWith<$Res> {
  _$CompareBranchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompareBranch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? byCollege = null,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            byCollege: null == byCollege
                ? _value.byCollege
                : byCollege // ignore: cast_nullable_to_non_nullable
                      as Map<String, CompareCell>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompareBranchImplCopyWith<$Res>
    implements $CompareBranchCopyWith<$Res> {
  factory _$$CompareBranchImplCopyWith(
    _$CompareBranchImpl value,
    $Res Function(_$CompareBranchImpl) then,
  ) = __$$CompareBranchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String name, Map<String, CompareCell> byCollege});
}

/// @nodoc
class __$$CompareBranchImplCopyWithImpl<$Res>
    extends _$CompareBranchCopyWithImpl<$Res, _$CompareBranchImpl>
    implements _$$CompareBranchImplCopyWith<$Res> {
  __$$CompareBranchImplCopyWithImpl(
    _$CompareBranchImpl _value,
    $Res Function(_$CompareBranchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompareBranch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? byCollege = null,
  }) {
    return _then(
      _$CompareBranchImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        byCollege: null == byCollege
            ? _value._byCollege
            : byCollege // ignore: cast_nullable_to_non_nullable
                  as Map<String, CompareCell>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompareBranchImpl implements _CompareBranch {
  const _$CompareBranchImpl({
    required this.code,
    required this.name,
    required final Map<String, CompareCell> byCollege,
  }) : _byCollege = byCollege;

  factory _$CompareBranchImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompareBranchImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  final Map<String, CompareCell> _byCollege;
  @override
  Map<String, CompareCell> get byCollege {
    if (_byCollege is EqualUnmodifiableMapView) return _byCollege;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byCollege);
  }

  @override
  String toString() {
    return 'CompareBranch(code: $code, name: $name, byCollege: $byCollege)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompareBranchImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(
              other._byCollege,
              _byCollege,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    name,
    const DeepCollectionEquality().hash(_byCollege),
  );

  /// Create a copy of CompareBranch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompareBranchImplCopyWith<_$CompareBranchImpl> get copyWith =>
      __$$CompareBranchImplCopyWithImpl<_$CompareBranchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompareBranchImplToJson(this);
  }
}

abstract class _CompareBranch implements CompareBranch {
  const factory _CompareBranch({
    required final String code,
    required final String name,
    required final Map<String, CompareCell> byCollege,
  }) = _$CompareBranchImpl;

  factory _CompareBranch.fromJson(Map<String, dynamic> json) =
      _$CompareBranchImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  Map<String, CompareCell> get byCollege;

  /// Create a copy of CompareBranch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompareBranchImplCopyWith<_$CompareBranchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompareCell _$CompareCellFromJson(Map<String, dynamic> json) {
  return _CompareCell.fromJson(json);
}

/// @nodoc
mixin _$CompareCell {
  /// 'rank' or 'score'. A BITS column holds scores while the column beside
  /// it holds ranks, so the two are shown side by side and never subtracted.
  String get measure => throw _privateConstructorUsedError;
  num? get latestClosing => throw _privateConstructorUsedError;
  num? get maxScore => throw _privateConstructorUsedError;
  int? get latestYear => throw _privateConstructorUsedError;
  int? get yearsAvailable => throw _privateConstructorUsedError;

  /// Serializes this CompareCell to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompareCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompareCellCopyWith<CompareCell> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompareCellCopyWith<$Res> {
  factory $CompareCellCopyWith(
    CompareCell value,
    $Res Function(CompareCell) then,
  ) = _$CompareCellCopyWithImpl<$Res, CompareCell>;
  @useResult
  $Res call({
    String measure,
    num? latestClosing,
    num? maxScore,
    int? latestYear,
    int? yearsAvailable,
  });
}

/// @nodoc
class _$CompareCellCopyWithImpl<$Res, $Val extends CompareCell>
    implements $CompareCellCopyWith<$Res> {
  _$CompareCellCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompareCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? measure = null,
    Object? latestClosing = freezed,
    Object? maxScore = freezed,
    Object? latestYear = freezed,
    Object? yearsAvailable = freezed,
  }) {
    return _then(
      _value.copyWith(
            measure: null == measure
                ? _value.measure
                : measure // ignore: cast_nullable_to_non_nullable
                      as String,
            latestClosing: freezed == latestClosing
                ? _value.latestClosing
                : latestClosing // ignore: cast_nullable_to_non_nullable
                      as num?,
            maxScore: freezed == maxScore
                ? _value.maxScore
                : maxScore // ignore: cast_nullable_to_non_nullable
                      as num?,
            latestYear: freezed == latestYear
                ? _value.latestYear
                : latestYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            yearsAvailable: freezed == yearsAvailable
                ? _value.yearsAvailable
                : yearsAvailable // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompareCellImplCopyWith<$Res>
    implements $CompareCellCopyWith<$Res> {
  factory _$$CompareCellImplCopyWith(
    _$CompareCellImpl value,
    $Res Function(_$CompareCellImpl) then,
  ) = __$$CompareCellImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String measure,
    num? latestClosing,
    num? maxScore,
    int? latestYear,
    int? yearsAvailable,
  });
}

/// @nodoc
class __$$CompareCellImplCopyWithImpl<$Res>
    extends _$CompareCellCopyWithImpl<$Res, _$CompareCellImpl>
    implements _$$CompareCellImplCopyWith<$Res> {
  __$$CompareCellImplCopyWithImpl(
    _$CompareCellImpl _value,
    $Res Function(_$CompareCellImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompareCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? measure = null,
    Object? latestClosing = freezed,
    Object? maxScore = freezed,
    Object? latestYear = freezed,
    Object? yearsAvailable = freezed,
  }) {
    return _then(
      _$CompareCellImpl(
        measure: null == measure
            ? _value.measure
            : measure // ignore: cast_nullable_to_non_nullable
                  as String,
        latestClosing: freezed == latestClosing
            ? _value.latestClosing
            : latestClosing // ignore: cast_nullable_to_non_nullable
                  as num?,
        maxScore: freezed == maxScore
            ? _value.maxScore
            : maxScore // ignore: cast_nullable_to_non_nullable
                  as num?,
        latestYear: freezed == latestYear
            ? _value.latestYear
            : latestYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        yearsAvailable: freezed == yearsAvailable
            ? _value.yearsAvailable
            : yearsAvailable // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompareCellImpl extends _CompareCell {
  const _$CompareCellImpl({
    this.measure = 'rank',
    this.latestClosing,
    this.maxScore,
    this.latestYear,
    this.yearsAvailable,
  }) : super._();

  factory _$CompareCellImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompareCellImplFromJson(json);

  /// 'rank' or 'score'. A BITS column holds scores while the column beside
  /// it holds ranks, so the two are shown side by side and never subtracted.
  @override
  @JsonKey()
  final String measure;
  @override
  final num? latestClosing;
  @override
  final num? maxScore;
  @override
  final int? latestYear;
  @override
  final int? yearsAvailable;

  @override
  String toString() {
    return 'CompareCell(measure: $measure, latestClosing: $latestClosing, maxScore: $maxScore, latestYear: $latestYear, yearsAvailable: $yearsAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompareCellImpl &&
            (identical(other.measure, measure) || other.measure == measure) &&
            (identical(other.latestClosing, latestClosing) ||
                other.latestClosing == latestClosing) &&
            (identical(other.maxScore, maxScore) ||
                other.maxScore == maxScore) &&
            (identical(other.latestYear, latestYear) ||
                other.latestYear == latestYear) &&
            (identical(other.yearsAvailable, yearsAvailable) ||
                other.yearsAvailable == yearsAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    measure,
    latestClosing,
    maxScore,
    latestYear,
    yearsAvailable,
  );

  /// Create a copy of CompareCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompareCellImplCopyWith<_$CompareCellImpl> get copyWith =>
      __$$CompareCellImplCopyWithImpl<_$CompareCellImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompareCellImplToJson(this);
  }
}

abstract class _CompareCell extends CompareCell {
  const factory _CompareCell({
    final String measure,
    final num? latestClosing,
    final num? maxScore,
    final int? latestYear,
    final int? yearsAvailable,
  }) = _$CompareCellImpl;
  const _CompareCell._() : super._();

  factory _CompareCell.fromJson(Map<String, dynamic> json) =
      _$CompareCellImpl.fromJson;

  /// 'rank' or 'score'. A BITS column holds scores while the column beside
  /// it holds ranks, so the two are shown side by side and never subtracted.
  @override
  String get measure;
  @override
  num? get latestClosing;
  @override
  num? get maxScore;
  @override
  int? get latestYear;
  @override
  int? get yearsAvailable;

  /// Create a copy of CompareCell
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompareCellImplCopyWith<_$CompareCellImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompareCollege _$CompareCollegeFromJson(Map<String, dynamic> json) {
  return _CompareCollege.fromJson(json);
}

/// @nodoc
mixin _$CompareCollege {
  String get slug => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'short_name')
  String? get shortName => throw _privateConstructorUsedError;
  @JsonKey(name: 'college_type')
  String get collegeType => throw _privateConstructorUsedError;
  String get ownership => throw _privateConstructorUsedError;
  @JsonKey(name: 'state_name')
  String get stateName => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_name')
  String? get cityName => throw _privateConstructorUsedError;
  @JsonKey(name: 'established_year')
  int? get establishedYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_hostel')
  bool? get hasHostel => throw _privateConstructorUsedError;
  @JsonKey(name: 'nirf_rank_latest')
  int? get nirfRank => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  @JsonKey(name: 'programme_count')
  int get programmeCount => throw _privateConstructorUsedError;

  /// Serializes this CompareCollege to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompareCollege
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompareCollegeCopyWith<CompareCollege> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompareCollegeCopyWith<$Res> {
  factory $CompareCollegeCopyWith(
    CompareCollege value,
    $Res Function(CompareCollege) then,
  ) = _$CompareCollegeCopyWithImpl<$Res, CompareCollege>;
  @useResult
  $Res call({
    String slug,
    String name,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'college_type') String collegeType,
    String ownership,
    @JsonKey(name: 'state_name') String stateName,
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'established_year') int? establishedYear,
    @JsonKey(name: 'has_hostel') bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    String? website,
    @JsonKey(name: 'programme_count') int programmeCount,
  });
}

/// @nodoc
class _$CompareCollegeCopyWithImpl<$Res, $Val extends CompareCollege>
    implements $CompareCollegeCopyWith<$Res> {
  _$CompareCollegeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompareCollege
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? collegeType = null,
    Object? ownership = null,
    Object? stateName = null,
    Object? cityName = freezed,
    Object? establishedYear = freezed,
    Object? hasHostel = freezed,
    Object? nirfRank = freezed,
    Object? website = freezed,
    Object? programmeCount = null,
  }) {
    return _then(
      _value.copyWith(
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            shortName: freezed == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                      as String?,
            collegeType: null == collegeType
                ? _value.collegeType
                : collegeType // ignore: cast_nullable_to_non_nullable
                      as String,
            ownership: null == ownership
                ? _value.ownership
                : ownership // ignore: cast_nullable_to_non_nullable
                      as String,
            stateName: null == stateName
                ? _value.stateName
                : stateName // ignore: cast_nullable_to_non_nullable
                      as String,
            cityName: freezed == cityName
                ? _value.cityName
                : cityName // ignore: cast_nullable_to_non_nullable
                      as String?,
            establishedYear: freezed == establishedYear
                ? _value.establishedYear
                : establishedYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            hasHostel: freezed == hasHostel
                ? _value.hasHostel
                : hasHostel // ignore: cast_nullable_to_non_nullable
                      as bool?,
            nirfRank: freezed == nirfRank
                ? _value.nirfRank
                : nirfRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
            programmeCount: null == programmeCount
                ? _value.programmeCount
                : programmeCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompareCollegeImplCopyWith<$Res>
    implements $CompareCollegeCopyWith<$Res> {
  factory _$$CompareCollegeImplCopyWith(
    _$CompareCollegeImpl value,
    $Res Function(_$CompareCollegeImpl) then,
  ) = __$$CompareCollegeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String slug,
    String name,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'college_type') String collegeType,
    String ownership,
    @JsonKey(name: 'state_name') String stateName,
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'established_year') int? establishedYear,
    @JsonKey(name: 'has_hostel') bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    String? website,
    @JsonKey(name: 'programme_count') int programmeCount,
  });
}

/// @nodoc
class __$$CompareCollegeImplCopyWithImpl<$Res>
    extends _$CompareCollegeCopyWithImpl<$Res, _$CompareCollegeImpl>
    implements _$$CompareCollegeImplCopyWith<$Res> {
  __$$CompareCollegeImplCopyWithImpl(
    _$CompareCollegeImpl _value,
    $Res Function(_$CompareCollegeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompareCollege
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? collegeType = null,
    Object? ownership = null,
    Object? stateName = null,
    Object? cityName = freezed,
    Object? establishedYear = freezed,
    Object? hasHostel = freezed,
    Object? nirfRank = freezed,
    Object? website = freezed,
    Object? programmeCount = null,
  }) {
    return _then(
      _$CompareCollegeImpl(
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        shortName: freezed == shortName
            ? _value.shortName
            : shortName // ignore: cast_nullable_to_non_nullable
                  as String?,
        collegeType: null == collegeType
            ? _value.collegeType
            : collegeType // ignore: cast_nullable_to_non_nullable
                  as String,
        ownership: null == ownership
            ? _value.ownership
            : ownership // ignore: cast_nullable_to_non_nullable
                  as String,
        stateName: null == stateName
            ? _value.stateName
            : stateName // ignore: cast_nullable_to_non_nullable
                  as String,
        cityName: freezed == cityName
            ? _value.cityName
            : cityName // ignore: cast_nullable_to_non_nullable
                  as String?,
        establishedYear: freezed == establishedYear
            ? _value.establishedYear
            : establishedYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        hasHostel: freezed == hasHostel
            ? _value.hasHostel
            : hasHostel // ignore: cast_nullable_to_non_nullable
                  as bool?,
        nirfRank: freezed == nirfRank
            ? _value.nirfRank
            : nirfRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
        programmeCount: null == programmeCount
            ? _value.programmeCount
            : programmeCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompareCollegeImpl implements _CompareCollege {
  const _$CompareCollegeImpl({
    required this.slug,
    required this.name,
    @JsonKey(name: 'short_name') this.shortName,
    @JsonKey(name: 'college_type') required this.collegeType,
    required this.ownership,
    @JsonKey(name: 'state_name') required this.stateName,
    @JsonKey(name: 'city_name') this.cityName,
    @JsonKey(name: 'established_year') this.establishedYear,
    @JsonKey(name: 'has_hostel') this.hasHostel,
    @JsonKey(name: 'nirf_rank_latest') this.nirfRank,
    this.website,
    @JsonKey(name: 'programme_count') required this.programmeCount,
  });

  factory _$CompareCollegeImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompareCollegeImplFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  @JsonKey(name: 'short_name')
  final String? shortName;
  @override
  @JsonKey(name: 'college_type')
  final String collegeType;
  @override
  final String ownership;
  @override
  @JsonKey(name: 'state_name')
  final String stateName;
  @override
  @JsonKey(name: 'city_name')
  final String? cityName;
  @override
  @JsonKey(name: 'established_year')
  final int? establishedYear;
  @override
  @JsonKey(name: 'has_hostel')
  final bool? hasHostel;
  @override
  @JsonKey(name: 'nirf_rank_latest')
  final int? nirfRank;
  @override
  final String? website;
  @override
  @JsonKey(name: 'programme_count')
  final int programmeCount;

  @override
  String toString() {
    return 'CompareCollege(slug: $slug, name: $name, shortName: $shortName, collegeType: $collegeType, ownership: $ownership, stateName: $stateName, cityName: $cityName, establishedYear: $establishedYear, hasHostel: $hasHostel, nirfRank: $nirfRank, website: $website, programmeCount: $programmeCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompareCollegeImpl &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.collegeType, collegeType) ||
                other.collegeType == collegeType) &&
            (identical(other.ownership, ownership) ||
                other.ownership == ownership) &&
            (identical(other.stateName, stateName) ||
                other.stateName == stateName) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.establishedYear, establishedYear) ||
                other.establishedYear == establishedYear) &&
            (identical(other.hasHostel, hasHostel) ||
                other.hasHostel == hasHostel) &&
            (identical(other.nirfRank, nirfRank) ||
                other.nirfRank == nirfRank) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.programmeCount, programmeCount) ||
                other.programmeCount == programmeCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    slug,
    name,
    shortName,
    collegeType,
    ownership,
    stateName,
    cityName,
    establishedYear,
    hasHostel,
    nirfRank,
    website,
    programmeCount,
  );

  /// Create a copy of CompareCollege
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompareCollegeImplCopyWith<_$CompareCollegeImpl> get copyWith =>
      __$$CompareCollegeImplCopyWithImpl<_$CompareCollegeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompareCollegeImplToJson(this);
  }
}

abstract class _CompareCollege implements CompareCollege {
  const factory _CompareCollege({
    required final String slug,
    required final String name,
    @JsonKey(name: 'short_name') final String? shortName,
    @JsonKey(name: 'college_type') required final String collegeType,
    required final String ownership,
    @JsonKey(name: 'state_name') required final String stateName,
    @JsonKey(name: 'city_name') final String? cityName,
    @JsonKey(name: 'established_year') final int? establishedYear,
    @JsonKey(name: 'has_hostel') final bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') final int? nirfRank,
    final String? website,
    @JsonKey(name: 'programme_count') required final int programmeCount,
  }) = _$CompareCollegeImpl;

  factory _CompareCollege.fromJson(Map<String, dynamic> json) =
      _$CompareCollegeImpl.fromJson;

  @override
  String get slug;
  @override
  String get name;
  @override
  @JsonKey(name: 'short_name')
  String? get shortName;
  @override
  @JsonKey(name: 'college_type')
  String get collegeType;
  @override
  String get ownership;
  @override
  @JsonKey(name: 'state_name')
  String get stateName;
  @override
  @JsonKey(name: 'city_name')
  String? get cityName;
  @override
  @JsonKey(name: 'established_year')
  int? get establishedYear;
  @override
  @JsonKey(name: 'has_hostel')
  bool? get hasHostel;
  @override
  @JsonKey(name: 'nirf_rank_latest')
  int? get nirfRank;
  @override
  String? get website;
  @override
  @JsonKey(name: 'programme_count')
  int get programmeCount;

  /// Create a copy of CompareCollege
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompareCollegeImplCopyWith<_$CompareCollegeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompareResult _$CompareResultFromJson(Map<String, dynamic> json) {
  return _CompareResult.fromJson(json);
}

/// @nodoc
mixin _$CompareResult {
  Map<String, dynamic> get seatDimension => throw _privateConstructorUsedError;
  List<CompareCollege> get colleges => throw _privateConstructorUsedError;
  List<CompareBranch> get branches => throw _privateConstructorUsedError;

  /// Serializes this CompareResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompareResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompareResultCopyWith<CompareResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompareResultCopyWith<$Res> {
  factory $CompareResultCopyWith(
    CompareResult value,
    $Res Function(CompareResult) then,
  ) = _$CompareResultCopyWithImpl<$Res, CompareResult>;
  @useResult
  $Res call({
    Map<String, dynamic> seatDimension,
    List<CompareCollege> colleges,
    List<CompareBranch> branches,
  });
}

/// @nodoc
class _$CompareResultCopyWithImpl<$Res, $Val extends CompareResult>
    implements $CompareResultCopyWith<$Res> {
  _$CompareResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompareResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seatDimension = null,
    Object? colleges = null,
    Object? branches = null,
  }) {
    return _then(
      _value.copyWith(
            seatDimension: null == seatDimension
                ? _value.seatDimension
                : seatDimension // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            colleges: null == colleges
                ? _value.colleges
                : colleges // ignore: cast_nullable_to_non_nullable
                      as List<CompareCollege>,
            branches: null == branches
                ? _value.branches
                : branches // ignore: cast_nullable_to_non_nullable
                      as List<CompareBranch>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompareResultImplCopyWith<$Res>
    implements $CompareResultCopyWith<$Res> {
  factory _$$CompareResultImplCopyWith(
    _$CompareResultImpl value,
    $Res Function(_$CompareResultImpl) then,
  ) = __$$CompareResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<String, dynamic> seatDimension,
    List<CompareCollege> colleges,
    List<CompareBranch> branches,
  });
}

/// @nodoc
class __$$CompareResultImplCopyWithImpl<$Res>
    extends _$CompareResultCopyWithImpl<$Res, _$CompareResultImpl>
    implements _$$CompareResultImplCopyWith<$Res> {
  __$$CompareResultImplCopyWithImpl(
    _$CompareResultImpl _value,
    $Res Function(_$CompareResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompareResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seatDimension = null,
    Object? colleges = null,
    Object? branches = null,
  }) {
    return _then(
      _$CompareResultImpl(
        seatDimension: null == seatDimension
            ? _value._seatDimension
            : seatDimension // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        colleges: null == colleges
            ? _value._colleges
            : colleges // ignore: cast_nullable_to_non_nullable
                  as List<CompareCollege>,
        branches: null == branches
            ? _value._branches
            : branches // ignore: cast_nullable_to_non_nullable
                  as List<CompareBranch>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompareResultImpl implements _CompareResult {
  const _$CompareResultImpl({
    required final Map<String, dynamic> seatDimension,
    final List<CompareCollege> colleges = const <CompareCollege>[],
    final List<CompareBranch> branches = const <CompareBranch>[],
  }) : _seatDimension = seatDimension,
       _colleges = colleges,
       _branches = branches;

  factory _$CompareResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompareResultImplFromJson(json);

  final Map<String, dynamic> _seatDimension;
  @override
  Map<String, dynamic> get seatDimension {
    if (_seatDimension is EqualUnmodifiableMapView) return _seatDimension;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_seatDimension);
  }

  final List<CompareCollege> _colleges;
  @override
  @JsonKey()
  List<CompareCollege> get colleges {
    if (_colleges is EqualUnmodifiableListView) return _colleges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_colleges);
  }

  final List<CompareBranch> _branches;
  @override
  @JsonKey()
  List<CompareBranch> get branches {
    if (_branches is EqualUnmodifiableListView) return _branches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_branches);
  }

  @override
  String toString() {
    return 'CompareResult(seatDimension: $seatDimension, colleges: $colleges, branches: $branches)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompareResultImpl &&
            const DeepCollectionEquality().equals(
              other._seatDimension,
              _seatDimension,
            ) &&
            const DeepCollectionEquality().equals(other._colleges, _colleges) &&
            const DeepCollectionEquality().equals(other._branches, _branches));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_seatDimension),
    const DeepCollectionEquality().hash(_colleges),
    const DeepCollectionEquality().hash(_branches),
  );

  /// Create a copy of CompareResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompareResultImplCopyWith<_$CompareResultImpl> get copyWith =>
      __$$CompareResultImplCopyWithImpl<_$CompareResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompareResultImplToJson(this);
  }
}

abstract class _CompareResult implements CompareResult {
  const factory _CompareResult({
    required final Map<String, dynamic> seatDimension,
    final List<CompareCollege> colleges,
    final List<CompareBranch> branches,
  }) = _$CompareResultImpl;

  factory _CompareResult.fromJson(Map<String, dynamic> json) =
      _$CompareResultImpl.fromJson;

  @override
  Map<String, dynamic> get seatDimension;
  @override
  List<CompareCollege> get colleges;
  @override
  List<CompareBranch> get branches;

  /// Create a copy of CompareResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompareResultImplCopyWith<_$CompareResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
