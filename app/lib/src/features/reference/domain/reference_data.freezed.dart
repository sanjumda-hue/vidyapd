// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reference_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LookupItem _$LookupItemFromJson(Map<String, dynamic> json) {
  return _LookupItem.fromJson(json);
}

/// @nodoc
mixin _$LookupItem {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this LookupItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LookupItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LookupItemCopyWith<LookupItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LookupItemCopyWith<$Res> {
  factory $LookupItemCopyWith(
    LookupItem value,
    $Res Function(LookupItem) then,
  ) = _$LookupItemCopyWithImpl<$Res, LookupItem>;
  @useResult
  $Res call({String code, String name});
}

/// @nodoc
class _$LookupItemCopyWithImpl<$Res, $Val extends LookupItem>
    implements $LookupItemCopyWith<$Res> {
  _$LookupItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LookupItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? code = null, Object? name = null}) {
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LookupItemImplCopyWith<$Res>
    implements $LookupItemCopyWith<$Res> {
  factory _$$LookupItemImplCopyWith(
    _$LookupItemImpl value,
    $Res Function(_$LookupItemImpl) then,
  ) = __$$LookupItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String name});
}

/// @nodoc
class __$$LookupItemImplCopyWithImpl<$Res>
    extends _$LookupItemCopyWithImpl<$Res, _$LookupItemImpl>
    implements _$$LookupItemImplCopyWith<$Res> {
  __$$LookupItemImplCopyWithImpl(
    _$LookupItemImpl _value,
    $Res Function(_$LookupItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LookupItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? code = null, Object? name = null}) {
    return _then(
      _$LookupItemImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LookupItemImpl implements _LookupItem {
  const _$LookupItemImpl({required this.code, required this.name});

  factory _$LookupItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$LookupItemImplFromJson(json);

  @override
  final String code;
  @override
  final String name;

  @override
  String toString() {
    return 'LookupItem(code: $code, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LookupItemImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, name);

  /// Create a copy of LookupItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LookupItemImplCopyWith<_$LookupItemImpl> get copyWith =>
      __$$LookupItemImplCopyWithImpl<_$LookupItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LookupItemImplToJson(this);
  }
}

abstract class _LookupItem implements LookupItem {
  const factory _LookupItem({
    required final String code,
    required final String name,
  }) = _$LookupItemImpl;

  factory _LookupItem.fromJson(Map<String, dynamic> json) =
      _$LookupItemImpl.fromJson;

  @override
  String get code;
  @override
  String get name;

  /// Create a copy of LookupItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LookupItemImplCopyWith<_$LookupItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExamOption _$ExamOptionFromJson(Map<String, dynamic> json) {
  return _ExamOption.fromJson(json);
}

/// @nodoc
mixin _$ExamOption {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  bool get hasPercentile => throw _privateConstructorUsedError;
  String? get homeStateCode => throw _privateConstructorUsedError;

  /// Serializes this ExamOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExamOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamOptionCopyWith<ExamOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamOptionCopyWith<$Res> {
  factory $ExamOptionCopyWith(
    ExamOption value,
    $Res Function(ExamOption) then,
  ) = _$ExamOptionCopyWithImpl<$Res, ExamOption>;
  @useResult
  $Res call({
    String code,
    String name,
    String level,
    bool hasPercentile,
    String? homeStateCode,
  });
}

/// @nodoc
class _$ExamOptionCopyWithImpl<$Res, $Val extends ExamOption>
    implements $ExamOptionCopyWith<$Res> {
  _$ExamOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExamOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? level = null,
    Object? hasPercentile = null,
    Object? homeStateCode = freezed,
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
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as String,
            hasPercentile: null == hasPercentile
                ? _value.hasPercentile
                : hasPercentile // ignore: cast_nullable_to_non_nullable
                      as bool,
            homeStateCode: freezed == homeStateCode
                ? _value.homeStateCode
                : homeStateCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExamOptionImplCopyWith<$Res>
    implements $ExamOptionCopyWith<$Res> {
  factory _$$ExamOptionImplCopyWith(
    _$ExamOptionImpl value,
    $Res Function(_$ExamOptionImpl) then,
  ) = __$$ExamOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    String name,
    String level,
    bool hasPercentile,
    String? homeStateCode,
  });
}

/// @nodoc
class __$$ExamOptionImplCopyWithImpl<$Res>
    extends _$ExamOptionCopyWithImpl<$Res, _$ExamOptionImpl>
    implements _$$ExamOptionImplCopyWith<$Res> {
  __$$ExamOptionImplCopyWithImpl(
    _$ExamOptionImpl _value,
    $Res Function(_$ExamOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExamOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? level = null,
    Object? hasPercentile = null,
    Object? homeStateCode = freezed,
  }) {
    return _then(
      _$ExamOptionImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as String,
        hasPercentile: null == hasPercentile
            ? _value.hasPercentile
            : hasPercentile // ignore: cast_nullable_to_non_nullable
                  as bool,
        homeStateCode: freezed == homeStateCode
            ? _value.homeStateCode
            : homeStateCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExamOptionImpl implements _ExamOption {
  const _$ExamOptionImpl({
    required this.code,
    required this.name,
    required this.level,
    required this.hasPercentile,
    this.homeStateCode,
  });

  factory _$ExamOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamOptionImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  @override
  final String level;
  @override
  final bool hasPercentile;
  @override
  final String? homeStateCode;

  @override
  String toString() {
    return 'ExamOption(code: $code, name: $name, level: $level, hasPercentile: $hasPercentile, homeStateCode: $homeStateCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamOptionImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.hasPercentile, hasPercentile) ||
                other.hasPercentile == hasPercentile) &&
            (identical(other.homeStateCode, homeStateCode) ||
                other.homeStateCode == homeStateCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, code, name, level, hasPercentile, homeStateCode);

  /// Create a copy of ExamOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamOptionImplCopyWith<_$ExamOptionImpl> get copyWith =>
      __$$ExamOptionImplCopyWithImpl<_$ExamOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamOptionImplToJson(this);
  }
}

abstract class _ExamOption implements ExamOption {
  const factory _ExamOption({
    required final String code,
    required final String name,
    required final String level,
    required final bool hasPercentile,
    final String? homeStateCode,
  }) = _$ExamOptionImpl;

  factory _ExamOption.fromJson(Map<String, dynamic> json) =
      _$ExamOptionImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  String get level;
  @override
  bool get hasPercentile;
  @override
  String? get homeStateCode;

  /// Create a copy of ExamOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamOptionImplCopyWith<_$ExamOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BranchOption _$BranchOptionFromJson(Map<String, dynamic> json) {
  return _BranchOption.fromJson(json);
}

/// @nodoc
mixin _$BranchOption {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;

  /// Serializes this BranchOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BranchOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BranchOptionCopyWith<BranchOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BranchOptionCopyWith<$Res> {
  factory $BranchOptionCopyWith(
    BranchOption value,
    $Res Function(BranchOption) then,
  ) = _$BranchOptionCopyWithImpl<$Res, BranchOption>;
  @useResult
  $Res call({String code, String name, bool isPopular});
}

/// @nodoc
class _$BranchOptionCopyWithImpl<$Res, $Val extends BranchOption>
    implements $BranchOptionCopyWith<$Res> {
  _$BranchOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BranchOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? isPopular = null,
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
            isPopular: null == isPopular
                ? _value.isPopular
                : isPopular // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BranchOptionImplCopyWith<$Res>
    implements $BranchOptionCopyWith<$Res> {
  factory _$$BranchOptionImplCopyWith(
    _$BranchOptionImpl value,
    $Res Function(_$BranchOptionImpl) then,
  ) = __$$BranchOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String name, bool isPopular});
}

/// @nodoc
class __$$BranchOptionImplCopyWithImpl<$Res>
    extends _$BranchOptionCopyWithImpl<$Res, _$BranchOptionImpl>
    implements _$$BranchOptionImplCopyWith<$Res> {
  __$$BranchOptionImplCopyWithImpl(
    _$BranchOptionImpl _value,
    $Res Function(_$BranchOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BranchOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? isPopular = null,
  }) {
    return _then(
      _$BranchOptionImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isPopular: null == isPopular
            ? _value.isPopular
            : isPopular // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BranchOptionImpl implements _BranchOption {
  const _$BranchOptionImpl({
    required this.code,
    required this.name,
    required this.isPopular,
  });

  factory _$BranchOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$BranchOptionImplFromJson(json);

  @override
  final String code;
  @override
  final String name;
  @override
  final bool isPopular;

  @override
  String toString() {
    return 'BranchOption(code: $code, name: $name, isPopular: $isPopular)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BranchOptionImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, name, isPopular);

  /// Create a copy of BranchOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BranchOptionImplCopyWith<_$BranchOptionImpl> get copyWith =>
      __$$BranchOptionImplCopyWithImpl<_$BranchOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BranchOptionImplToJson(this);
  }
}

abstract class _BranchOption implements BranchOption {
  const factory _BranchOption({
    required final String code,
    required final String name,
    required final bool isPopular,
  }) = _$BranchOptionImpl;

  factory _BranchOption.fromJson(Map<String, dynamic> json) =
      _$BranchOptionImpl.fromJson;

  @override
  String get code;
  @override
  String get name;
  @override
  bool get isPopular;

  /// Create a copy of BranchOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BranchOptionImplCopyWith<_$BranchOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReferenceData _$ReferenceDataFromJson(Map<String, dynamic> json) {
  return _ReferenceData.fromJson(json);
}

/// @nodoc
mixin _$ReferenceData {
  List<ExamOption> get exams => throw _privateConstructorUsedError;
  List<LookupItem> get categories => throw _privateConstructorUsedError;
  List<LookupItem> get genders => throw _privateConstructorUsedError;
  List<LookupItem> get quotas => throw _privateConstructorUsedError;
  List<LookupItem> get states => throw _privateConstructorUsedError;
  List<BranchOption> get branches => throw _privateConstructorUsedError;
  List<String> get collegeTypes => throw _privateConstructorUsedError;

  /// Serializes this ReferenceData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReferenceData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReferenceDataCopyWith<ReferenceData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReferenceDataCopyWith<$Res> {
  factory $ReferenceDataCopyWith(
    ReferenceData value,
    $Res Function(ReferenceData) then,
  ) = _$ReferenceDataCopyWithImpl<$Res, ReferenceData>;
  @useResult
  $Res call({
    List<ExamOption> exams,
    List<LookupItem> categories,
    List<LookupItem> genders,
    List<LookupItem> quotas,
    List<LookupItem> states,
    List<BranchOption> branches,
    List<String> collegeTypes,
  });
}

/// @nodoc
class _$ReferenceDataCopyWithImpl<$Res, $Val extends ReferenceData>
    implements $ReferenceDataCopyWith<$Res> {
  _$ReferenceDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReferenceData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exams = null,
    Object? categories = null,
    Object? genders = null,
    Object? quotas = null,
    Object? states = null,
    Object? branches = null,
    Object? collegeTypes = null,
  }) {
    return _then(
      _value.copyWith(
            exams: null == exams
                ? _value.exams
                : exams // ignore: cast_nullable_to_non_nullable
                      as List<ExamOption>,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<LookupItem>,
            genders: null == genders
                ? _value.genders
                : genders // ignore: cast_nullable_to_non_nullable
                      as List<LookupItem>,
            quotas: null == quotas
                ? _value.quotas
                : quotas // ignore: cast_nullable_to_non_nullable
                      as List<LookupItem>,
            states: null == states
                ? _value.states
                : states // ignore: cast_nullable_to_non_nullable
                      as List<LookupItem>,
            branches: null == branches
                ? _value.branches
                : branches // ignore: cast_nullable_to_non_nullable
                      as List<BranchOption>,
            collegeTypes: null == collegeTypes
                ? _value.collegeTypes
                : collegeTypes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReferenceDataImplCopyWith<$Res>
    implements $ReferenceDataCopyWith<$Res> {
  factory _$$ReferenceDataImplCopyWith(
    _$ReferenceDataImpl value,
    $Res Function(_$ReferenceDataImpl) then,
  ) = __$$ReferenceDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<ExamOption> exams,
    List<LookupItem> categories,
    List<LookupItem> genders,
    List<LookupItem> quotas,
    List<LookupItem> states,
    List<BranchOption> branches,
    List<String> collegeTypes,
  });
}

/// @nodoc
class __$$ReferenceDataImplCopyWithImpl<$Res>
    extends _$ReferenceDataCopyWithImpl<$Res, _$ReferenceDataImpl>
    implements _$$ReferenceDataImplCopyWith<$Res> {
  __$$ReferenceDataImplCopyWithImpl(
    _$ReferenceDataImpl _value,
    $Res Function(_$ReferenceDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReferenceData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exams = null,
    Object? categories = null,
    Object? genders = null,
    Object? quotas = null,
    Object? states = null,
    Object? branches = null,
    Object? collegeTypes = null,
  }) {
    return _then(
      _$ReferenceDataImpl(
        exams: null == exams
            ? _value._exams
            : exams // ignore: cast_nullable_to_non_nullable
                  as List<ExamOption>,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<LookupItem>,
        genders: null == genders
            ? _value._genders
            : genders // ignore: cast_nullable_to_non_nullable
                  as List<LookupItem>,
        quotas: null == quotas
            ? _value._quotas
            : quotas // ignore: cast_nullable_to_non_nullable
                  as List<LookupItem>,
        states: null == states
            ? _value._states
            : states // ignore: cast_nullable_to_non_nullable
                  as List<LookupItem>,
        branches: null == branches
            ? _value._branches
            : branches // ignore: cast_nullable_to_non_nullable
                  as List<BranchOption>,
        collegeTypes: null == collegeTypes
            ? _value._collegeTypes
            : collegeTypes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReferenceDataImpl implements _ReferenceData {
  const _$ReferenceDataImpl({
    required final List<ExamOption> exams,
    required final List<LookupItem> categories,
    required final List<LookupItem> genders,
    required final List<LookupItem> quotas,
    required final List<LookupItem> states,
    required final List<BranchOption> branches,
    required final List<String> collegeTypes,
  }) : _exams = exams,
       _categories = categories,
       _genders = genders,
       _quotas = quotas,
       _states = states,
       _branches = branches,
       _collegeTypes = collegeTypes;

  factory _$ReferenceDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReferenceDataImplFromJson(json);

  final List<ExamOption> _exams;
  @override
  List<ExamOption> get exams {
    if (_exams is EqualUnmodifiableListView) return _exams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exams);
  }

  final List<LookupItem> _categories;
  @override
  List<LookupItem> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<LookupItem> _genders;
  @override
  List<LookupItem> get genders {
    if (_genders is EqualUnmodifiableListView) return _genders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genders);
  }

  final List<LookupItem> _quotas;
  @override
  List<LookupItem> get quotas {
    if (_quotas is EqualUnmodifiableListView) return _quotas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quotas);
  }

  final List<LookupItem> _states;
  @override
  List<LookupItem> get states {
    if (_states is EqualUnmodifiableListView) return _states;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_states);
  }

  final List<BranchOption> _branches;
  @override
  List<BranchOption> get branches {
    if (_branches is EqualUnmodifiableListView) return _branches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_branches);
  }

  final List<String> _collegeTypes;
  @override
  List<String> get collegeTypes {
    if (_collegeTypes is EqualUnmodifiableListView) return _collegeTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collegeTypes);
  }

  @override
  String toString() {
    return 'ReferenceData(exams: $exams, categories: $categories, genders: $genders, quotas: $quotas, states: $states, branches: $branches, collegeTypes: $collegeTypes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReferenceDataImpl &&
            const DeepCollectionEquality().equals(other._exams, _exams) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._genders, _genders) &&
            const DeepCollectionEquality().equals(other._quotas, _quotas) &&
            const DeepCollectionEquality().equals(other._states, _states) &&
            const DeepCollectionEquality().equals(other._branches, _branches) &&
            const DeepCollectionEquality().equals(
              other._collegeTypes,
              _collegeTypes,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_exams),
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_genders),
    const DeepCollectionEquality().hash(_quotas),
    const DeepCollectionEquality().hash(_states),
    const DeepCollectionEquality().hash(_branches),
    const DeepCollectionEquality().hash(_collegeTypes),
  );

  /// Create a copy of ReferenceData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReferenceDataImplCopyWith<_$ReferenceDataImpl> get copyWith =>
      __$$ReferenceDataImplCopyWithImpl<_$ReferenceDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReferenceDataImplToJson(this);
  }
}

abstract class _ReferenceData implements ReferenceData {
  const factory _ReferenceData({
    required final List<ExamOption> exams,
    required final List<LookupItem> categories,
    required final List<LookupItem> genders,
    required final List<LookupItem> quotas,
    required final List<LookupItem> states,
    required final List<BranchOption> branches,
    required final List<String> collegeTypes,
  }) = _$ReferenceDataImpl;

  factory _ReferenceData.fromJson(Map<String, dynamic> json) =
      _$ReferenceDataImpl.fromJson;

  @override
  List<ExamOption> get exams;
  @override
  List<LookupItem> get categories;
  @override
  List<LookupItem> get genders;
  @override
  List<LookupItem> get quotas;
  @override
  List<LookupItem> get states;
  @override
  List<BranchOption> get branches;
  @override
  List<String> get collegeTypes;

  /// Create a copy of ReferenceData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReferenceDataImplCopyWith<_$ReferenceDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
