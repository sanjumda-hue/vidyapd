// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prediction_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CollegeRef _$CollegeRefFromJson(Map<String, dynamic> json) {
  return _CollegeRef.fromJson(json);
}

/// @nodoc
mixin _$CollegeRef {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get shortName => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;

  /// Serializes this CollegeRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeRefCopyWith<CollegeRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeRefCopyWith<$Res> {
  factory $CollegeRefCopyWith(
    CollegeRef value,
    $Res Function(CollegeRef) then,
  ) = _$CollegeRefCopyWithImpl<$Res, CollegeRef>;
  @useResult
  $Res call({
    int id,
    String name,
    String? shortName,
    String type,
    String state,
  });
}

/// @nodoc
class _$CollegeRefCopyWithImpl<$Res, $Val extends CollegeRef>
    implements $CollegeRefCopyWith<$Res> {
  _$CollegeRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? type = null,
    Object? state = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            shortName: freezed == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollegeRefImplCopyWith<$Res>
    implements $CollegeRefCopyWith<$Res> {
  factory _$$CollegeRefImplCopyWith(
    _$CollegeRefImpl value,
    $Res Function(_$CollegeRefImpl) then,
  ) = __$$CollegeRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String? shortName,
    String type,
    String state,
  });
}

/// @nodoc
class __$$CollegeRefImplCopyWithImpl<$Res>
    extends _$CollegeRefCopyWithImpl<$Res, _$CollegeRefImpl>
    implements _$$CollegeRefImplCopyWith<$Res> {
  __$$CollegeRefImplCopyWithImpl(
    _$CollegeRefImpl _value,
    $Res Function(_$CollegeRefImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shortName = freezed,
    Object? type = null,
    Object? state = null,
  }) {
    return _then(
      _$CollegeRefImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        shortName: freezed == shortName
            ? _value.shortName
            : shortName // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeRefImpl implements _CollegeRef {
  const _$CollegeRefImpl({
    required this.id,
    required this.name,
    this.shortName,
    required this.type,
    required this.state,
  });

  factory _$CollegeRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeRefImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String? shortName;
  @override
  final String type;
  @override
  final String state;

  @override
  String toString() {
    return 'CollegeRef(id: $id, name: $name, shortName: $shortName, type: $type, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, shortName, type, state);

  /// Create a copy of CollegeRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeRefImplCopyWith<_$CollegeRefImpl> get copyWith =>
      __$$CollegeRefImplCopyWithImpl<_$CollegeRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeRefImplToJson(this);
  }
}

abstract class _CollegeRef implements CollegeRef {
  const factory _CollegeRef({
    required final int id,
    required final String name,
    final String? shortName,
    required final String type,
    required final String state,
  }) = _$CollegeRefImpl;

  factory _CollegeRef.fromJson(Map<String, dynamic> json) =
      _$CollegeRefImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String? get shortName;
  @override
  String get type;
  @override
  String get state;

  /// Create a copy of CollegeRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeRefImplCopyWith<_$CollegeRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BranchRef _$BranchRefFromJson(Map<String, dynamic> json) {
  return _BranchRef.fromJson(json);
}

/// @nodoc
mixin _$BranchRef {
  int get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this BranchRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BranchRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BranchRefCopyWith<BranchRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BranchRefCopyWith<$Res> {
  factory $BranchRefCopyWith(BranchRef value, $Res Function(BranchRef) then) =
      _$BranchRefCopyWithImpl<$Res, BranchRef>;
  @useResult
  $Res call({int id, String code, String name});
}

/// @nodoc
class _$BranchRefCopyWithImpl<$Res, $Val extends BranchRef>
    implements $BranchRefCopyWith<$Res> {
  _$BranchRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BranchRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? code = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$BranchRefImplCopyWith<$Res>
    implements $BranchRefCopyWith<$Res> {
  factory _$$BranchRefImplCopyWith(
    _$BranchRefImpl value,
    $Res Function(_$BranchRefImpl) then,
  ) = __$$BranchRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String code, String name});
}

/// @nodoc
class __$$BranchRefImplCopyWithImpl<$Res>
    extends _$BranchRefCopyWithImpl<$Res, _$BranchRefImpl>
    implements _$$BranchRefImplCopyWith<$Res> {
  __$$BranchRefImplCopyWithImpl(
    _$BranchRefImpl _value,
    $Res Function(_$BranchRefImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BranchRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? code = null, Object? name = null}) {
    return _then(
      _$BranchRefImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$BranchRefImpl implements _BranchRef {
  const _$BranchRefImpl({
    required this.id,
    required this.code,
    required this.name,
  });

  factory _$BranchRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$BranchRefImplFromJson(json);

  @override
  final int id;
  @override
  final String code;
  @override
  final String name;

  @override
  String toString() {
    return 'BranchRef(id: $id, code: $code, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BranchRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, name);

  /// Create a copy of BranchRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BranchRefImplCopyWith<_$BranchRefImpl> get copyWith =>
      __$$BranchRefImplCopyWithImpl<_$BranchRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BranchRefImplToJson(this);
  }
}

abstract class _BranchRef implements BranchRef {
  const factory _BranchRef({
    required final int id,
    required final String code,
    required final String name,
  }) = _$BranchRefImpl;

  factory _BranchRef.fromJson(Map<String, dynamic> json) =
      _$BranchRefImpl.fromJson;

  @override
  int get id;
  @override
  String get code;
  @override
  String get name;

  /// Create a copy of BranchRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BranchRefImplCopyWith<_$BranchRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CutoffYear _$CutoffYearFromJson(Map<String, dynamic> json) {
  return _CutoffYear.fromJson(json);
}

/// @nodoc
mixin _$CutoffYear {
  int get year => throw _privateConstructorUsedError;
  num? get opening => throw _privateConstructorUsedError;
  num get closing => throw _privateConstructorUsedError;
  int get round => throw _privateConstructorUsedError;
  num? get max => throw _privateConstructorUsedError;
  double? get pct => throw _privateConstructorUsedError;

  /// Serializes this CutoffYear to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CutoffYear
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CutoffYearCopyWith<CutoffYear> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CutoffYearCopyWith<$Res> {
  factory $CutoffYearCopyWith(
    CutoffYear value,
    $Res Function(CutoffYear) then,
  ) = _$CutoffYearCopyWithImpl<$Res, CutoffYear>;
  @useResult
  $Res call({
    int year,
    num? opening,
    num closing,
    int round,
    num? max,
    double? pct,
  });
}

/// @nodoc
class _$CutoffYearCopyWithImpl<$Res, $Val extends CutoffYear>
    implements $CutoffYearCopyWith<$Res> {
  _$CutoffYearCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CutoffYear
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? opening = freezed,
    Object? closing = null,
    Object? round = null,
    Object? max = freezed,
    Object? pct = freezed,
  }) {
    return _then(
      _value.copyWith(
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            opening: freezed == opening
                ? _value.opening
                : opening // ignore: cast_nullable_to_non_nullable
                      as num?,
            closing: null == closing
                ? _value.closing
                : closing // ignore: cast_nullable_to_non_nullable
                      as num,
            round: null == round
                ? _value.round
                : round // ignore: cast_nullable_to_non_nullable
                      as int,
            max: freezed == max
                ? _value.max
                : max // ignore: cast_nullable_to_non_nullable
                      as num?,
            pct: freezed == pct
                ? _value.pct
                : pct // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CutoffYearImplCopyWith<$Res>
    implements $CutoffYearCopyWith<$Res> {
  factory _$$CutoffYearImplCopyWith(
    _$CutoffYearImpl value,
    $Res Function(_$CutoffYearImpl) then,
  ) = __$$CutoffYearImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int year,
    num? opening,
    num closing,
    int round,
    num? max,
    double? pct,
  });
}

/// @nodoc
class __$$CutoffYearImplCopyWithImpl<$Res>
    extends _$CutoffYearCopyWithImpl<$Res, _$CutoffYearImpl>
    implements _$$CutoffYearImplCopyWith<$Res> {
  __$$CutoffYearImplCopyWithImpl(
    _$CutoffYearImpl _value,
    $Res Function(_$CutoffYearImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CutoffYear
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? opening = freezed,
    Object? closing = null,
    Object? round = null,
    Object? max = freezed,
    Object? pct = freezed,
  }) {
    return _then(
      _$CutoffYearImpl(
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        opening: freezed == opening
            ? _value.opening
            : opening // ignore: cast_nullable_to_non_nullable
                  as num?,
        closing: null == closing
            ? _value.closing
            : closing // ignore: cast_nullable_to_non_nullable
                  as num,
        round: null == round
            ? _value.round
            : round // ignore: cast_nullable_to_non_nullable
                  as int,
        max: freezed == max
            ? _value.max
            : max // ignore: cast_nullable_to_non_nullable
                  as num?,
        pct: freezed == pct
            ? _value.pct
            : pct // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CutoffYearImpl extends _CutoffYear {
  const _$CutoffYearImpl({
    required this.year,
    this.opening,
    required this.closing,
    required this.round,
    this.max,
    this.pct,
  }) : super._();

  factory _$CutoffYearImpl.fromJson(Map<String, dynamic> json) =>
      _$$CutoffYearImplFromJson(json);

  @override
  final int year;
  @override
  final num? opening;
  @override
  final num closing;
  @override
  final int round;
  @override
  final num? max;
  @override
  final double? pct;

  @override
  String toString() {
    return 'CutoffYear(year: $year, opening: $opening, closing: $closing, round: $round, max: $max, pct: $pct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CutoffYearImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.opening, opening) || other.opening == opening) &&
            (identical(other.closing, closing) || other.closing == closing) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.max, max) || other.max == max) &&
            (identical(other.pct, pct) || other.pct == pct));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, year, opening, closing, round, max, pct);

  /// Create a copy of CutoffYear
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CutoffYearImplCopyWith<_$CutoffYearImpl> get copyWith =>
      __$$CutoffYearImplCopyWithImpl<_$CutoffYearImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CutoffYearImplToJson(this);
  }
}

abstract class _CutoffYear extends CutoffYear {
  const factory _CutoffYear({
    required final int year,
    final num? opening,
    required final num closing,
    required final int round,
    final num? max,
    final double? pct,
  }) = _$CutoffYearImpl;
  const _CutoffYear._() : super._();

  factory _CutoffYear.fromJson(Map<String, dynamic> json) =
      _$CutoffYearImpl.fromJson;

  @override
  int get year;
  @override
  num? get opening;
  @override
  num get closing;
  @override
  int get round;
  @override
  num? get max;
  @override
  double? get pct;

  /// Create a copy of CutoffYear
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CutoffYearImplCopyWith<_$CutoffYearImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScoreBand _$ScoreBandFromJson(Map<String, dynamic> json) {
  return _ScoreBand.fromJson(json);
}

/// @nodoc
mixin _$ScoreBand {
  num? get weightedClosing => throw _privateConstructorUsedError;

  /// Strictest year on record: the HIGHEST cut-off.
  num? get toughestClosing => throw _privateConstructorUsedError;

  /// Most lenient year: the LOWEST cut-off.
  num? get easiestClosing => throw _privateConstructorUsedError;
  num? get latestClosing => throw _privateConstructorUsedError;
  num? get maxScore => throw _privateConstructorUsedError;

  /// Candidate score minus the weighted cut-off. Positive = ahead of it.
  num? get margin => throw _privateConstructorUsedError;

  /// Serializes this ScoreBand to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScoreBand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScoreBandCopyWith<ScoreBand> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoreBandCopyWith<$Res> {
  factory $ScoreBandCopyWith(ScoreBand value, $Res Function(ScoreBand) then) =
      _$ScoreBandCopyWithImpl<$Res, ScoreBand>;
  @useResult
  $Res call({
    num? weightedClosing,
    num? toughestClosing,
    num? easiestClosing,
    num? latestClosing,
    num? maxScore,
    num? margin,
  });
}

/// @nodoc
class _$ScoreBandCopyWithImpl<$Res, $Val extends ScoreBand>
    implements $ScoreBandCopyWith<$Res> {
  _$ScoreBandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScoreBand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightedClosing = freezed,
    Object? toughestClosing = freezed,
    Object? easiestClosing = freezed,
    Object? latestClosing = freezed,
    Object? maxScore = freezed,
    Object? margin = freezed,
  }) {
    return _then(
      _value.copyWith(
            weightedClosing: freezed == weightedClosing
                ? _value.weightedClosing
                : weightedClosing // ignore: cast_nullable_to_non_nullable
                      as num?,
            toughestClosing: freezed == toughestClosing
                ? _value.toughestClosing
                : toughestClosing // ignore: cast_nullable_to_non_nullable
                      as num?,
            easiestClosing: freezed == easiestClosing
                ? _value.easiestClosing
                : easiestClosing // ignore: cast_nullable_to_non_nullable
                      as num?,
            latestClosing: freezed == latestClosing
                ? _value.latestClosing
                : latestClosing // ignore: cast_nullable_to_non_nullable
                      as num?,
            maxScore: freezed == maxScore
                ? _value.maxScore
                : maxScore // ignore: cast_nullable_to_non_nullable
                      as num?,
            margin: freezed == margin
                ? _value.margin
                : margin // ignore: cast_nullable_to_non_nullable
                      as num?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScoreBandImplCopyWith<$Res>
    implements $ScoreBandCopyWith<$Res> {
  factory _$$ScoreBandImplCopyWith(
    _$ScoreBandImpl value,
    $Res Function(_$ScoreBandImpl) then,
  ) = __$$ScoreBandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    num? weightedClosing,
    num? toughestClosing,
    num? easiestClosing,
    num? latestClosing,
    num? maxScore,
    num? margin,
  });
}

/// @nodoc
class __$$ScoreBandImplCopyWithImpl<$Res>
    extends _$ScoreBandCopyWithImpl<$Res, _$ScoreBandImpl>
    implements _$$ScoreBandImplCopyWith<$Res> {
  __$$ScoreBandImplCopyWithImpl(
    _$ScoreBandImpl _value,
    $Res Function(_$ScoreBandImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScoreBand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightedClosing = freezed,
    Object? toughestClosing = freezed,
    Object? easiestClosing = freezed,
    Object? latestClosing = freezed,
    Object? maxScore = freezed,
    Object? margin = freezed,
  }) {
    return _then(
      _$ScoreBandImpl(
        weightedClosing: freezed == weightedClosing
            ? _value.weightedClosing
            : weightedClosing // ignore: cast_nullable_to_non_nullable
                  as num?,
        toughestClosing: freezed == toughestClosing
            ? _value.toughestClosing
            : toughestClosing // ignore: cast_nullable_to_non_nullable
                  as num?,
        easiestClosing: freezed == easiestClosing
            ? _value.easiestClosing
            : easiestClosing // ignore: cast_nullable_to_non_nullable
                  as num?,
        latestClosing: freezed == latestClosing
            ? _value.latestClosing
            : latestClosing // ignore: cast_nullable_to_non_nullable
                  as num?,
        maxScore: freezed == maxScore
            ? _value.maxScore
            : maxScore // ignore: cast_nullable_to_non_nullable
                  as num?,
        margin: freezed == margin
            ? _value.margin
            : margin // ignore: cast_nullable_to_non_nullable
                  as num?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScoreBandImpl implements _ScoreBand {
  const _$ScoreBandImpl({
    this.weightedClosing,
    this.toughestClosing,
    this.easiestClosing,
    this.latestClosing,
    this.maxScore,
    this.margin,
  });

  factory _$ScoreBandImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScoreBandImplFromJson(json);

  @override
  final num? weightedClosing;

  /// Strictest year on record: the HIGHEST cut-off.
  @override
  final num? toughestClosing;

  /// Most lenient year: the LOWEST cut-off.
  @override
  final num? easiestClosing;
  @override
  final num? latestClosing;
  @override
  final num? maxScore;

  /// Candidate score minus the weighted cut-off. Positive = ahead of it.
  @override
  final num? margin;

  @override
  String toString() {
    return 'ScoreBand(weightedClosing: $weightedClosing, toughestClosing: $toughestClosing, easiestClosing: $easiestClosing, latestClosing: $latestClosing, maxScore: $maxScore, margin: $margin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScoreBandImpl &&
            (identical(other.weightedClosing, weightedClosing) ||
                other.weightedClosing == weightedClosing) &&
            (identical(other.toughestClosing, toughestClosing) ||
                other.toughestClosing == toughestClosing) &&
            (identical(other.easiestClosing, easiestClosing) ||
                other.easiestClosing == easiestClosing) &&
            (identical(other.latestClosing, latestClosing) ||
                other.latestClosing == latestClosing) &&
            (identical(other.maxScore, maxScore) ||
                other.maxScore == maxScore) &&
            (identical(other.margin, margin) || other.margin == margin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    weightedClosing,
    toughestClosing,
    easiestClosing,
    latestClosing,
    maxScore,
    margin,
  );

  /// Create a copy of ScoreBand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScoreBandImplCopyWith<_$ScoreBandImpl> get copyWith =>
      __$$ScoreBandImplCopyWithImpl<_$ScoreBandImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScoreBandImplToJson(this);
  }
}

abstract class _ScoreBand implements ScoreBand {
  const factory _ScoreBand({
    final num? weightedClosing,
    final num? toughestClosing,
    final num? easiestClosing,
    final num? latestClosing,
    final num? maxScore,
    final num? margin,
  }) = _$ScoreBandImpl;

  factory _ScoreBand.fromJson(Map<String, dynamic> json) =
      _$ScoreBandImpl.fromJson;

  @override
  num? get weightedClosing;

  /// Strictest year on record: the HIGHEST cut-off.
  @override
  num? get toughestClosing;

  /// Most lenient year: the LOWEST cut-off.
  @override
  num? get easiestClosing;
  @override
  num? get latestClosing;
  @override
  num? get maxScore;

  /// Candidate score minus the weighted cut-off. Positive = ahead of it.
  @override
  num? get margin;

  /// Create a copy of ScoreBand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScoreBandImplCopyWith<_$ScoreBandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PredictionMatch _$PredictionMatchFromJson(Map<String, dynamic> json) {
  return _PredictionMatch.fromJson(json);
}

/// @nodoc
mixin _$PredictionMatch {
  int get collegeBranchId => throw _privateConstructorUsedError;
  CollegeRef get college => throw _privateConstructorUsedError;
  BranchRef get branch => throw _privateConstructorUsedError;
  String get programName => throw _privateConstructorUsedError;
  String get seatType => throw _privateConstructorUsedError;
  String get quota => throw _privateConstructorUsedError;
  String get genderPool => throw _privateConstructorUsedError;
  String get grade => throw _privateConstructorUsedError;
  String get gradeLabel => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  int? get weightedClosingRank => throw _privateConstructorUsedError;
  int? get bestClosingRank => throw _privateConstructorUsedError;
  int? get worstClosingRank => throw _privateConstructorUsedError;
  int? get latestClosingRank => throw _privateConstructorUsedError;
  int? get rankMargin => throw _privateConstructorUsedError;

  /// Set instead of the rank fields when the exam is marks-based.
  ScoreBand? get scoreBand => throw _privateConstructorUsedError;
  int get yearsAvailable => throw _privateConstructorUsedError;
  String get trend => throw _privateConstructorUsedError;
  List<CutoffYear> get cutoffHistory => throw _privateConstructorUsedError;

  /// Serializes this PredictionMatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PredictionMatchCopyWith<PredictionMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PredictionMatchCopyWith<$Res> {
  factory $PredictionMatchCopyWith(
    PredictionMatch value,
    $Res Function(PredictionMatch) then,
  ) = _$PredictionMatchCopyWithImpl<$Res, PredictionMatch>;
  @useResult
  $Res call({
    int collegeBranchId,
    CollegeRef college,
    BranchRef branch,
    String programName,
    String seatType,
    String quota,
    String genderPool,
    String grade,
    String gradeLabel,
    double score,
    int? weightedClosingRank,
    int? bestClosingRank,
    int? worstClosingRank,
    int? latestClosingRank,
    int? rankMargin,
    ScoreBand? scoreBand,
    int yearsAvailable,
    String trend,
    List<CutoffYear> cutoffHistory,
  });

  $CollegeRefCopyWith<$Res> get college;
  $BranchRefCopyWith<$Res> get branch;
  $ScoreBandCopyWith<$Res>? get scoreBand;
}

/// @nodoc
class _$PredictionMatchCopyWithImpl<$Res, $Val extends PredictionMatch>
    implements $PredictionMatchCopyWith<$Res> {
  _$PredictionMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collegeBranchId = null,
    Object? college = null,
    Object? branch = null,
    Object? programName = null,
    Object? seatType = null,
    Object? quota = null,
    Object? genderPool = null,
    Object? grade = null,
    Object? gradeLabel = null,
    Object? score = null,
    Object? weightedClosingRank = freezed,
    Object? bestClosingRank = freezed,
    Object? worstClosingRank = freezed,
    Object? latestClosingRank = freezed,
    Object? rankMargin = freezed,
    Object? scoreBand = freezed,
    Object? yearsAvailable = null,
    Object? trend = null,
    Object? cutoffHistory = null,
  }) {
    return _then(
      _value.copyWith(
            collegeBranchId: null == collegeBranchId
                ? _value.collegeBranchId
                : collegeBranchId // ignore: cast_nullable_to_non_nullable
                      as int,
            college: null == college
                ? _value.college
                : college // ignore: cast_nullable_to_non_nullable
                      as CollegeRef,
            branch: null == branch
                ? _value.branch
                : branch // ignore: cast_nullable_to_non_nullable
                      as BranchRef,
            programName: null == programName
                ? _value.programName
                : programName // ignore: cast_nullable_to_non_nullable
                      as String,
            seatType: null == seatType
                ? _value.seatType
                : seatType // ignore: cast_nullable_to_non_nullable
                      as String,
            quota: null == quota
                ? _value.quota
                : quota // ignore: cast_nullable_to_non_nullable
                      as String,
            genderPool: null == genderPool
                ? _value.genderPool
                : genderPool // ignore: cast_nullable_to_non_nullable
                      as String,
            grade: null == grade
                ? _value.grade
                : grade // ignore: cast_nullable_to_non_nullable
                      as String,
            gradeLabel: null == gradeLabel
                ? _value.gradeLabel
                : gradeLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
            weightedClosingRank: freezed == weightedClosingRank
                ? _value.weightedClosingRank
                : weightedClosingRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            bestClosingRank: freezed == bestClosingRank
                ? _value.bestClosingRank
                : bestClosingRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            worstClosingRank: freezed == worstClosingRank
                ? _value.worstClosingRank
                : worstClosingRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            latestClosingRank: freezed == latestClosingRank
                ? _value.latestClosingRank
                : latestClosingRank // ignore: cast_nullable_to_non_nullable
                      as int?,
            rankMargin: freezed == rankMargin
                ? _value.rankMargin
                : rankMargin // ignore: cast_nullable_to_non_nullable
                      as int?,
            scoreBand: freezed == scoreBand
                ? _value.scoreBand
                : scoreBand // ignore: cast_nullable_to_non_nullable
                      as ScoreBand?,
            yearsAvailable: null == yearsAvailable
                ? _value.yearsAvailable
                : yearsAvailable // ignore: cast_nullable_to_non_nullable
                      as int,
            trend: null == trend
                ? _value.trend
                : trend // ignore: cast_nullable_to_non_nullable
                      as String,
            cutoffHistory: null == cutoffHistory
                ? _value.cutoffHistory
                : cutoffHistory // ignore: cast_nullable_to_non_nullable
                      as List<CutoffYear>,
          )
          as $Val,
    );
  }

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CollegeRefCopyWith<$Res> get college {
    return $CollegeRefCopyWith<$Res>(_value.college, (value) {
      return _then(_value.copyWith(college: value) as $Val);
    });
  }

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BranchRefCopyWith<$Res> get branch {
    return $BranchRefCopyWith<$Res>(_value.branch, (value) {
      return _then(_value.copyWith(branch: value) as $Val);
    });
  }

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreBandCopyWith<$Res>? get scoreBand {
    if (_value.scoreBand == null) {
      return null;
    }

    return $ScoreBandCopyWith<$Res>(_value.scoreBand!, (value) {
      return _then(_value.copyWith(scoreBand: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PredictionMatchImplCopyWith<$Res>
    implements $PredictionMatchCopyWith<$Res> {
  factory _$$PredictionMatchImplCopyWith(
    _$PredictionMatchImpl value,
    $Res Function(_$PredictionMatchImpl) then,
  ) = __$$PredictionMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int collegeBranchId,
    CollegeRef college,
    BranchRef branch,
    String programName,
    String seatType,
    String quota,
    String genderPool,
    String grade,
    String gradeLabel,
    double score,
    int? weightedClosingRank,
    int? bestClosingRank,
    int? worstClosingRank,
    int? latestClosingRank,
    int? rankMargin,
    ScoreBand? scoreBand,
    int yearsAvailable,
    String trend,
    List<CutoffYear> cutoffHistory,
  });

  @override
  $CollegeRefCopyWith<$Res> get college;
  @override
  $BranchRefCopyWith<$Res> get branch;
  @override
  $ScoreBandCopyWith<$Res>? get scoreBand;
}

/// @nodoc
class __$$PredictionMatchImplCopyWithImpl<$Res>
    extends _$PredictionMatchCopyWithImpl<$Res, _$PredictionMatchImpl>
    implements _$$PredictionMatchImplCopyWith<$Res> {
  __$$PredictionMatchImplCopyWithImpl(
    _$PredictionMatchImpl _value,
    $Res Function(_$PredictionMatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collegeBranchId = null,
    Object? college = null,
    Object? branch = null,
    Object? programName = null,
    Object? seatType = null,
    Object? quota = null,
    Object? genderPool = null,
    Object? grade = null,
    Object? gradeLabel = null,
    Object? score = null,
    Object? weightedClosingRank = freezed,
    Object? bestClosingRank = freezed,
    Object? worstClosingRank = freezed,
    Object? latestClosingRank = freezed,
    Object? rankMargin = freezed,
    Object? scoreBand = freezed,
    Object? yearsAvailable = null,
    Object? trend = null,
    Object? cutoffHistory = null,
  }) {
    return _then(
      _$PredictionMatchImpl(
        collegeBranchId: null == collegeBranchId
            ? _value.collegeBranchId
            : collegeBranchId // ignore: cast_nullable_to_non_nullable
                  as int,
        college: null == college
            ? _value.college
            : college // ignore: cast_nullable_to_non_nullable
                  as CollegeRef,
        branch: null == branch
            ? _value.branch
            : branch // ignore: cast_nullable_to_non_nullable
                  as BranchRef,
        programName: null == programName
            ? _value.programName
            : programName // ignore: cast_nullable_to_non_nullable
                  as String,
        seatType: null == seatType
            ? _value.seatType
            : seatType // ignore: cast_nullable_to_non_nullable
                  as String,
        quota: null == quota
            ? _value.quota
            : quota // ignore: cast_nullable_to_non_nullable
                  as String,
        genderPool: null == genderPool
            ? _value.genderPool
            : genderPool // ignore: cast_nullable_to_non_nullable
                  as String,
        grade: null == grade
            ? _value.grade
            : grade // ignore: cast_nullable_to_non_nullable
                  as String,
        gradeLabel: null == gradeLabel
            ? _value.gradeLabel
            : gradeLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
        weightedClosingRank: freezed == weightedClosingRank
            ? _value.weightedClosingRank
            : weightedClosingRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        bestClosingRank: freezed == bestClosingRank
            ? _value.bestClosingRank
            : bestClosingRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        worstClosingRank: freezed == worstClosingRank
            ? _value.worstClosingRank
            : worstClosingRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        latestClosingRank: freezed == latestClosingRank
            ? _value.latestClosingRank
            : latestClosingRank // ignore: cast_nullable_to_non_nullable
                  as int?,
        rankMargin: freezed == rankMargin
            ? _value.rankMargin
            : rankMargin // ignore: cast_nullable_to_non_nullable
                  as int?,
        scoreBand: freezed == scoreBand
            ? _value.scoreBand
            : scoreBand // ignore: cast_nullable_to_non_nullable
                  as ScoreBand?,
        yearsAvailable: null == yearsAvailable
            ? _value.yearsAvailable
            : yearsAvailable // ignore: cast_nullable_to_non_nullable
                  as int,
        trend: null == trend
            ? _value.trend
            : trend // ignore: cast_nullable_to_non_nullable
                  as String,
        cutoffHistory: null == cutoffHistory
            ? _value._cutoffHistory
            : cutoffHistory // ignore: cast_nullable_to_non_nullable
                  as List<CutoffYear>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PredictionMatchImpl implements _PredictionMatch {
  const _$PredictionMatchImpl({
    required this.collegeBranchId,
    required this.college,
    required this.branch,
    required this.programName,
    required this.seatType,
    required this.quota,
    required this.genderPool,
    required this.grade,
    required this.gradeLabel,
    required this.score,
    this.weightedClosingRank,
    this.bestClosingRank,
    this.worstClosingRank,
    this.latestClosingRank,
    this.rankMargin,
    this.scoreBand,
    required this.yearsAvailable,
    required this.trend,
    final List<CutoffYear> cutoffHistory = const <CutoffYear>[],
  }) : _cutoffHistory = cutoffHistory;

  factory _$PredictionMatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$PredictionMatchImplFromJson(json);

  @override
  final int collegeBranchId;
  @override
  final CollegeRef college;
  @override
  final BranchRef branch;
  @override
  final String programName;
  @override
  final String seatType;
  @override
  final String quota;
  @override
  final String genderPool;
  @override
  final String grade;
  @override
  final String gradeLabel;
  @override
  final double score;
  @override
  final int? weightedClosingRank;
  @override
  final int? bestClosingRank;
  @override
  final int? worstClosingRank;
  @override
  final int? latestClosingRank;
  @override
  final int? rankMargin;

  /// Set instead of the rank fields when the exam is marks-based.
  @override
  final ScoreBand? scoreBand;
  @override
  final int yearsAvailable;
  @override
  final String trend;
  final List<CutoffYear> _cutoffHistory;
  @override
  @JsonKey()
  List<CutoffYear> get cutoffHistory {
    if (_cutoffHistory is EqualUnmodifiableListView) return _cutoffHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cutoffHistory);
  }

  @override
  String toString() {
    return 'PredictionMatch(collegeBranchId: $collegeBranchId, college: $college, branch: $branch, programName: $programName, seatType: $seatType, quota: $quota, genderPool: $genderPool, grade: $grade, gradeLabel: $gradeLabel, score: $score, weightedClosingRank: $weightedClosingRank, bestClosingRank: $bestClosingRank, worstClosingRank: $worstClosingRank, latestClosingRank: $latestClosingRank, rankMargin: $rankMargin, scoreBand: $scoreBand, yearsAvailable: $yearsAvailable, trend: $trend, cutoffHistory: $cutoffHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PredictionMatchImpl &&
            (identical(other.collegeBranchId, collegeBranchId) ||
                other.collegeBranchId == collegeBranchId) &&
            (identical(other.college, college) || other.college == college) &&
            (identical(other.branch, branch) || other.branch == branch) &&
            (identical(other.programName, programName) ||
                other.programName == programName) &&
            (identical(other.seatType, seatType) ||
                other.seatType == seatType) &&
            (identical(other.quota, quota) || other.quota == quota) &&
            (identical(other.genderPool, genderPool) ||
                other.genderPool == genderPool) &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.gradeLabel, gradeLabel) ||
                other.gradeLabel == gradeLabel) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.weightedClosingRank, weightedClosingRank) ||
                other.weightedClosingRank == weightedClosingRank) &&
            (identical(other.bestClosingRank, bestClosingRank) ||
                other.bestClosingRank == bestClosingRank) &&
            (identical(other.worstClosingRank, worstClosingRank) ||
                other.worstClosingRank == worstClosingRank) &&
            (identical(other.latestClosingRank, latestClosingRank) ||
                other.latestClosingRank == latestClosingRank) &&
            (identical(other.rankMargin, rankMargin) ||
                other.rankMargin == rankMargin) &&
            (identical(other.scoreBand, scoreBand) ||
                other.scoreBand == scoreBand) &&
            (identical(other.yearsAvailable, yearsAvailable) ||
                other.yearsAvailable == yearsAvailable) &&
            (identical(other.trend, trend) || other.trend == trend) &&
            const DeepCollectionEquality().equals(
              other._cutoffHistory,
              _cutoffHistory,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    collegeBranchId,
    college,
    branch,
    programName,
    seatType,
    quota,
    genderPool,
    grade,
    gradeLabel,
    score,
    weightedClosingRank,
    bestClosingRank,
    worstClosingRank,
    latestClosingRank,
    rankMargin,
    scoreBand,
    yearsAvailable,
    trend,
    const DeepCollectionEquality().hash(_cutoffHistory),
  ]);

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PredictionMatchImplCopyWith<_$PredictionMatchImpl> get copyWith =>
      __$$PredictionMatchImplCopyWithImpl<_$PredictionMatchImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PredictionMatchImplToJson(this);
  }
}

abstract class _PredictionMatch implements PredictionMatch {
  const factory _PredictionMatch({
    required final int collegeBranchId,
    required final CollegeRef college,
    required final BranchRef branch,
    required final String programName,
    required final String seatType,
    required final String quota,
    required final String genderPool,
    required final String grade,
    required final String gradeLabel,
    required final double score,
    final int? weightedClosingRank,
    final int? bestClosingRank,
    final int? worstClosingRank,
    final int? latestClosingRank,
    final int? rankMargin,
    final ScoreBand? scoreBand,
    required final int yearsAvailable,
    required final String trend,
    final List<CutoffYear> cutoffHistory,
  }) = _$PredictionMatchImpl;

  factory _PredictionMatch.fromJson(Map<String, dynamic> json) =
      _$PredictionMatchImpl.fromJson;

  @override
  int get collegeBranchId;
  @override
  CollegeRef get college;
  @override
  BranchRef get branch;
  @override
  String get programName;
  @override
  String get seatType;
  @override
  String get quota;
  @override
  String get genderPool;
  @override
  String get grade;
  @override
  String get gradeLabel;
  @override
  double get score;
  @override
  int? get weightedClosingRank;
  @override
  int? get bestClosingRank;
  @override
  int? get worstClosingRank;
  @override
  int? get latestClosingRank;
  @override
  int? get rankMargin;

  /// Set instead of the rank fields when the exam is marks-based.
  @override
  ScoreBand? get scoreBand;
  @override
  int get yearsAvailable;
  @override
  String get trend;
  @override
  List<CutoffYear> get cutoffHistory;

  /// Create a copy of PredictionMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PredictionMatchImplCopyWith<_$PredictionMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExamRef _$ExamRefFromJson(Map<String, dynamic> json) {
  return _ExamRef.fromJson(json);
}

/// @nodoc
mixin _$ExamRef {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this ExamRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExamRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamRefCopyWith<ExamRef> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamRefCopyWith<$Res> {
  factory $ExamRefCopyWith(ExamRef value, $Res Function(ExamRef) then) =
      _$ExamRefCopyWithImpl<$Res, ExamRef>;
  @useResult
  $Res call({String code, String name});
}

/// @nodoc
class _$ExamRefCopyWithImpl<$Res, $Val extends ExamRef>
    implements $ExamRefCopyWith<$Res> {
  _$ExamRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExamRef
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
abstract class _$$ExamRefImplCopyWith<$Res> implements $ExamRefCopyWith<$Res> {
  factory _$$ExamRefImplCopyWith(
    _$ExamRefImpl value,
    $Res Function(_$ExamRefImpl) then,
  ) = __$$ExamRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String name});
}

/// @nodoc
class __$$ExamRefImplCopyWithImpl<$Res>
    extends _$ExamRefCopyWithImpl<$Res, _$ExamRefImpl>
    implements _$$ExamRefImplCopyWith<$Res> {
  __$$ExamRefImplCopyWithImpl(
    _$ExamRefImpl _value,
    $Res Function(_$ExamRefImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExamRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? code = null, Object? name = null}) {
    return _then(
      _$ExamRefImpl(
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
class _$ExamRefImpl implements _ExamRef {
  const _$ExamRefImpl({required this.code, required this.name});

  factory _$ExamRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamRefImplFromJson(json);

  @override
  final String code;
  @override
  final String name;

  @override
  String toString() {
    return 'ExamRef(code: $code, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamRefImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, name);

  /// Create a copy of ExamRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamRefImplCopyWith<_$ExamRefImpl> get copyWith =>
      __$$ExamRefImplCopyWithImpl<_$ExamRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamRefImplToJson(this);
  }
}

abstract class _ExamRef implements ExamRef {
  const factory _ExamRef({
    required final String code,
    required final String name,
  }) = _$ExamRefImpl;

  factory _ExamRef.fromJson(Map<String, dynamic> json) = _$ExamRefImpl.fromJson;

  @override
  String get code;
  @override
  String get name;

  /// Create a copy of ExamRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamRefImplCopyWith<_$ExamRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PredictionResponse _$PredictionResponseFromJson(Map<String, dynamic> json) {
  return _PredictionResponse.fromJson(json);
}

/// @nodoc
mixin _$PredictionResponse {
  String get requestId => throw _privateConstructorUsedError;
  ExamRef get exam => throw _privateConstructorUsedError;
  int get academicYear => throw _privateConstructorUsedError;

  /// 'rank' or 'score'. Says which set of fields on each match to read, and
  /// which way "better" points -- a lower rank is better, a higher score is.
  String get measure => throw _privateConstructorUsedError;

  /// Null on a marks-based exam.
  int? get rankUsed => throw _privateConstructorUsedError;
  bool get rankIsEstimated => throw _privateConstructorUsedError;
  String? get rankEstimateMethod => throw _privateConstructorUsedError;

  /// Both null unless the exam is marks-based.
  num? get scoreUsed => throw _privateConstructorUsedError;
  num? get maxScoreUsed => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String? get homeState => throw _privateConstructorUsedError;
  Map<String, int> get counts => throw _privateConstructorUsedError;
  List<PredictionMatch> get matches => throw _privateConstructorUsedError;

  /// Shown verbatim under every result list. Never dropped, never reworded.
  String get disclaimer => throw _privateConstructorUsedError;

  /// Serializes this PredictionResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PredictionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PredictionResponseCopyWith<PredictionResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PredictionResponseCopyWith<$Res> {
  factory $PredictionResponseCopyWith(
    PredictionResponse value,
    $Res Function(PredictionResponse) then,
  ) = _$PredictionResponseCopyWithImpl<$Res, PredictionResponse>;
  @useResult
  $Res call({
    String requestId,
    ExamRef exam,
    int academicYear,
    String measure,
    int? rankUsed,
    bool rankIsEstimated,
    String? rankEstimateMethod,
    num? scoreUsed,
    num? maxScoreUsed,
    String category,
    String gender,
    String? homeState,
    Map<String, int> counts,
    List<PredictionMatch> matches,
    String disclaimer,
  });

  $ExamRefCopyWith<$Res> get exam;
}

/// @nodoc
class _$PredictionResponseCopyWithImpl<$Res, $Val extends PredictionResponse>
    implements $PredictionResponseCopyWith<$Res> {
  _$PredictionResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PredictionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? exam = null,
    Object? academicYear = null,
    Object? measure = null,
    Object? rankUsed = freezed,
    Object? rankIsEstimated = null,
    Object? rankEstimateMethod = freezed,
    Object? scoreUsed = freezed,
    Object? maxScoreUsed = freezed,
    Object? category = null,
    Object? gender = null,
    Object? homeState = freezed,
    Object? counts = null,
    Object? matches = null,
    Object? disclaimer = null,
  }) {
    return _then(
      _value.copyWith(
            requestId: null == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                      as String,
            exam: null == exam
                ? _value.exam
                : exam // ignore: cast_nullable_to_non_nullable
                      as ExamRef,
            academicYear: null == academicYear
                ? _value.academicYear
                : academicYear // ignore: cast_nullable_to_non_nullable
                      as int,
            measure: null == measure
                ? _value.measure
                : measure // ignore: cast_nullable_to_non_nullable
                      as String,
            rankUsed: freezed == rankUsed
                ? _value.rankUsed
                : rankUsed // ignore: cast_nullable_to_non_nullable
                      as int?,
            rankIsEstimated: null == rankIsEstimated
                ? _value.rankIsEstimated
                : rankIsEstimated // ignore: cast_nullable_to_non_nullable
                      as bool,
            rankEstimateMethod: freezed == rankEstimateMethod
                ? _value.rankEstimateMethod
                : rankEstimateMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
            scoreUsed: freezed == scoreUsed
                ? _value.scoreUsed
                : scoreUsed // ignore: cast_nullable_to_non_nullable
                      as num?,
            maxScoreUsed: freezed == maxScoreUsed
                ? _value.maxScoreUsed
                : maxScoreUsed // ignore: cast_nullable_to_non_nullable
                      as num?,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            homeState: freezed == homeState
                ? _value.homeState
                : homeState // ignore: cast_nullable_to_non_nullable
                      as String?,
            counts: null == counts
                ? _value.counts
                : counts // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            matches: null == matches
                ? _value.matches
                : matches // ignore: cast_nullable_to_non_nullable
                      as List<PredictionMatch>,
            disclaimer: null == disclaimer
                ? _value.disclaimer
                : disclaimer // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of PredictionResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExamRefCopyWith<$Res> get exam {
    return $ExamRefCopyWith<$Res>(_value.exam, (value) {
      return _then(_value.copyWith(exam: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PredictionResponseImplCopyWith<$Res>
    implements $PredictionResponseCopyWith<$Res> {
  factory _$$PredictionResponseImplCopyWith(
    _$PredictionResponseImpl value,
    $Res Function(_$PredictionResponseImpl) then,
  ) = __$$PredictionResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String requestId,
    ExamRef exam,
    int academicYear,
    String measure,
    int? rankUsed,
    bool rankIsEstimated,
    String? rankEstimateMethod,
    num? scoreUsed,
    num? maxScoreUsed,
    String category,
    String gender,
    String? homeState,
    Map<String, int> counts,
    List<PredictionMatch> matches,
    String disclaimer,
  });

  @override
  $ExamRefCopyWith<$Res> get exam;
}

/// @nodoc
class __$$PredictionResponseImplCopyWithImpl<$Res>
    extends _$PredictionResponseCopyWithImpl<$Res, _$PredictionResponseImpl>
    implements _$$PredictionResponseImplCopyWith<$Res> {
  __$$PredictionResponseImplCopyWithImpl(
    _$PredictionResponseImpl _value,
    $Res Function(_$PredictionResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PredictionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? exam = null,
    Object? academicYear = null,
    Object? measure = null,
    Object? rankUsed = freezed,
    Object? rankIsEstimated = null,
    Object? rankEstimateMethod = freezed,
    Object? scoreUsed = freezed,
    Object? maxScoreUsed = freezed,
    Object? category = null,
    Object? gender = null,
    Object? homeState = freezed,
    Object? counts = null,
    Object? matches = null,
    Object? disclaimer = null,
  }) {
    return _then(
      _$PredictionResponseImpl(
        requestId: null == requestId
            ? _value.requestId
            : requestId // ignore: cast_nullable_to_non_nullable
                  as String,
        exam: null == exam
            ? _value.exam
            : exam // ignore: cast_nullable_to_non_nullable
                  as ExamRef,
        academicYear: null == academicYear
            ? _value.academicYear
            : academicYear // ignore: cast_nullable_to_non_nullable
                  as int,
        measure: null == measure
            ? _value.measure
            : measure // ignore: cast_nullable_to_non_nullable
                  as String,
        rankUsed: freezed == rankUsed
            ? _value.rankUsed
            : rankUsed // ignore: cast_nullable_to_non_nullable
                  as int?,
        rankIsEstimated: null == rankIsEstimated
            ? _value.rankIsEstimated
            : rankIsEstimated // ignore: cast_nullable_to_non_nullable
                  as bool,
        rankEstimateMethod: freezed == rankEstimateMethod
            ? _value.rankEstimateMethod
            : rankEstimateMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
        scoreUsed: freezed == scoreUsed
            ? _value.scoreUsed
            : scoreUsed // ignore: cast_nullable_to_non_nullable
                  as num?,
        maxScoreUsed: freezed == maxScoreUsed
            ? _value.maxScoreUsed
            : maxScoreUsed // ignore: cast_nullable_to_non_nullable
                  as num?,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        homeState: freezed == homeState
            ? _value.homeState
            : homeState // ignore: cast_nullable_to_non_nullable
                  as String?,
        counts: null == counts
            ? _value._counts
            : counts // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        matches: null == matches
            ? _value._matches
            : matches // ignore: cast_nullable_to_non_nullable
                  as List<PredictionMatch>,
        disclaimer: null == disclaimer
            ? _value.disclaimer
            : disclaimer // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PredictionResponseImpl extends _PredictionResponse {
  const _$PredictionResponseImpl({
    required this.requestId,
    required this.exam,
    required this.academicYear,
    this.measure = 'rank',
    this.rankUsed,
    required this.rankIsEstimated,
    this.rankEstimateMethod,
    this.scoreUsed,
    this.maxScoreUsed,
    required this.category,
    required this.gender,
    this.homeState,
    required final Map<String, int> counts,
    final List<PredictionMatch> matches = const <PredictionMatch>[],
    required this.disclaimer,
  }) : _counts = counts,
       _matches = matches,
       super._();

  factory _$PredictionResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PredictionResponseImplFromJson(json);

  @override
  final String requestId;
  @override
  final ExamRef exam;
  @override
  final int academicYear;

  /// 'rank' or 'score'. Says which set of fields on each match to read, and
  /// which way "better" points -- a lower rank is better, a higher score is.
  @override
  @JsonKey()
  final String measure;

  /// Null on a marks-based exam.
  @override
  final int? rankUsed;
  @override
  final bool rankIsEstimated;
  @override
  final String? rankEstimateMethod;

  /// Both null unless the exam is marks-based.
  @override
  final num? scoreUsed;
  @override
  final num? maxScoreUsed;
  @override
  final String category;
  @override
  final String gender;
  @override
  final String? homeState;
  final Map<String, int> _counts;
  @override
  Map<String, int> get counts {
    if (_counts is EqualUnmodifiableMapView) return _counts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_counts);
  }

  final List<PredictionMatch> _matches;
  @override
  @JsonKey()
  List<PredictionMatch> get matches {
    if (_matches is EqualUnmodifiableListView) return _matches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matches);
  }

  /// Shown verbatim under every result list. Never dropped, never reworded.
  @override
  final String disclaimer;

  @override
  String toString() {
    return 'PredictionResponse(requestId: $requestId, exam: $exam, academicYear: $academicYear, measure: $measure, rankUsed: $rankUsed, rankIsEstimated: $rankIsEstimated, rankEstimateMethod: $rankEstimateMethod, scoreUsed: $scoreUsed, maxScoreUsed: $maxScoreUsed, category: $category, gender: $gender, homeState: $homeState, counts: $counts, matches: $matches, disclaimer: $disclaimer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PredictionResponseImpl &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.exam, exam) || other.exam == exam) &&
            (identical(other.academicYear, academicYear) ||
                other.academicYear == academicYear) &&
            (identical(other.measure, measure) || other.measure == measure) &&
            (identical(other.rankUsed, rankUsed) ||
                other.rankUsed == rankUsed) &&
            (identical(other.rankIsEstimated, rankIsEstimated) ||
                other.rankIsEstimated == rankIsEstimated) &&
            (identical(other.rankEstimateMethod, rankEstimateMethod) ||
                other.rankEstimateMethod == rankEstimateMethod) &&
            (identical(other.scoreUsed, scoreUsed) ||
                other.scoreUsed == scoreUsed) &&
            (identical(other.maxScoreUsed, maxScoreUsed) ||
                other.maxScoreUsed == maxScoreUsed) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.homeState, homeState) ||
                other.homeState == homeState) &&
            const DeepCollectionEquality().equals(other._counts, _counts) &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            (identical(other.disclaimer, disclaimer) ||
                other.disclaimer == disclaimer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    requestId,
    exam,
    academicYear,
    measure,
    rankUsed,
    rankIsEstimated,
    rankEstimateMethod,
    scoreUsed,
    maxScoreUsed,
    category,
    gender,
    homeState,
    const DeepCollectionEquality().hash(_counts),
    const DeepCollectionEquality().hash(_matches),
    disclaimer,
  );

  /// Create a copy of PredictionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PredictionResponseImplCopyWith<_$PredictionResponseImpl> get copyWith =>
      __$$PredictionResponseImplCopyWithImpl<_$PredictionResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PredictionResponseImplToJson(this);
  }
}

abstract class _PredictionResponse extends PredictionResponse {
  const factory _PredictionResponse({
    required final String requestId,
    required final ExamRef exam,
    required final int academicYear,
    final String measure,
    final int? rankUsed,
    required final bool rankIsEstimated,
    final String? rankEstimateMethod,
    final num? scoreUsed,
    final num? maxScoreUsed,
    required final String category,
    required final String gender,
    final String? homeState,
    required final Map<String, int> counts,
    final List<PredictionMatch> matches,
    required final String disclaimer,
  }) = _$PredictionResponseImpl;
  const _PredictionResponse._() : super._();

  factory _PredictionResponse.fromJson(Map<String, dynamic> json) =
      _$PredictionResponseImpl.fromJson;

  @override
  String get requestId;
  @override
  ExamRef get exam;
  @override
  int get academicYear;

  /// 'rank' or 'score'. Says which set of fields on each match to read, and
  /// which way "better" points -- a lower rank is better, a higher score is.
  @override
  String get measure;

  /// Null on a marks-based exam.
  @override
  int? get rankUsed;
  @override
  bool get rankIsEstimated;
  @override
  String? get rankEstimateMethod;

  /// Both null unless the exam is marks-based.
  @override
  num? get scoreUsed;
  @override
  num? get maxScoreUsed;
  @override
  String get category;
  @override
  String get gender;
  @override
  String? get homeState;
  @override
  Map<String, int> get counts;
  @override
  List<PredictionMatch> get matches;

  /// Shown verbatim under every result list. Never dropped, never reworded.
  @override
  String get disclaimer;

  /// Create a copy of PredictionResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PredictionResponseImplCopyWith<_$PredictionResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
