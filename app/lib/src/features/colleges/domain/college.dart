import 'package:freezed_annotation/freezed_annotation.dart';

part 'college.freezed.dart';
part 'college.g.dart';

@freezed
class CollegeListItem with _$CollegeListItem {
  const factory CollegeListItem({
    required String slug,
    required String name,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'college_type') required String collegeType,
    @JsonKey(name: 'state_name') required String stateName,
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    @JsonKey(name: 'programme_count') required int programmeCount,
  }) = _CollegeListItem;

  factory CollegeListItem.fromJson(Map<String, dynamic> json) =>
      _$CollegeListItemFromJson(json);
}

@freezed
class CollegeProgramme with _$CollegeProgramme {
  const factory CollegeProgramme({
    @JsonKey(name: 'college_branch_id') required String collegeBranchId,
    @JsonKey(name: 'program_name') required String programName,
    @JsonKey(name: 'branch_code') required String branchCode,
    @JsonKey(name: 'branch_name') required String branchName,
    required String degree,
    @JsonKey(name: 'duration_years') String? durationYears,
    @JsonKey(name: 'total_intake') int? totalIntake,
    /// 'rank' or 'score'. Null when nothing has been published for this
    /// programme yet.
    String? measure,

    /// The latest published cut-off, as a string because Postgres sends
    /// NUMERIC that way. A rank when [measure] is 'rank', a score out of
    /// [latestMaxScore] when it is 'score'.
    @JsonKey(name: 'latest_closing') String? latestClosing,
    @JsonKey(name: 'latest_max_score') String? latestMaxScore,
    @JsonKey(name: 'latest_year') int? latestYear,
    @JsonKey(name: 'years_available') int? yearsAvailable,
  }) = _CollegeProgramme;

  const CollegeProgramme._();

  bool get isScore => measure == 'score';

  factory CollegeProgramme.fromJson(Map<String, dynamic> json) =>
      _$CollegeProgrammeFromJson(json);
}

@freezed
class CollegeAuthority with _$CollegeAuthority {
  const factory CollegeAuthority({
    required String code,
    required String name,
    required List<int> years,
    required int rows,
  }) = _CollegeAuthority;

  factory CollegeAuthority.fromJson(Map<String, dynamic> json) =>
      _$CollegeAuthorityFromJson(json);
}

@freezed
class CollegeInfo with _$CollegeInfo {
  const factory CollegeInfo({
    required String slug,
    required String name,
    @JsonKey(name: 'short_name') String? shortName,
    String? about,
    @JsonKey(name: 'college_type') required String collegeType,
    required String ownership,
    @JsonKey(name: 'affiliated_university') String? affiliatedUniversity,
    @JsonKey(name: 'established_year') int? establishedYear,
    String? website,
    @JsonKey(name: 'has_hostel') bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    @JsonKey(name: 'nirf_year_latest') int? nirfYear,
    required Map<String, dynamic> states,
    Map<String, dynamic>? cities,
  }) = _CollegeInfo;

  const CollegeInfo._();

  String get stateName => states['name'] as String? ?? '';
  String? get cityName => cities?['name'] as String?;

  factory CollegeInfo.fromJson(Map<String, dynamic> json) =>
      _$CollegeInfoFromJson(json);
}

@freezed
class CollegeDetail with _$CollegeDetail {
  const factory CollegeDetail({
    required CollegeInfo college,
    @Default(<CollegeProgramme>[]) List<CollegeProgramme> programmes,
    @Default(<CollegeAuthority>[]) List<CollegeAuthority> authorities,
  }) = _CollegeDetail;

  factory CollegeDetail.fromJson(Map<String, dynamic> json) =>
      _$CollegeDetailFromJson(json);
}

/// One branch row in the comparison table, with a cell per college.
@freezed
class CompareBranch with _$CompareBranch {
  const factory CompareBranch({
    required String code,
    required String name,
    required Map<String, CompareCell> byCollege,
  }) = _CompareBranch;

  factory CompareBranch.fromJson(Map<String, dynamic> json) =>
      _$CompareBranchFromJson(json);
}

@freezed
class CompareCell with _$CompareCell {
  const factory CompareCell({
    /// 'rank' or 'score'. A BITS column holds scores while the column beside
    /// it holds ranks, so the two are shown side by side and never subtracted.
    @Default('rank') String measure,
    num? latestClosing,
    num? maxScore,
    int? latestYear,
    int? yearsAvailable,
  }) = _CompareCell;

  const CompareCell._();

  bool get isScore => measure == 'score';

  factory CompareCell.fromJson(Map<String, dynamic> json) =>
      _$CompareCellFromJson(json);
}

/// The comparison endpoint returns colleges flat (state_name, not a nested
/// states object), so this is deliberately not CollegeInfo.
@freezed
class CompareCollege with _$CompareCollege {
  const factory CompareCollege({
    required String slug,
    required String name,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'college_type') required String collegeType,
    required String ownership,
    @JsonKey(name: 'state_name') required String stateName,
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'established_year') int? establishedYear,
    @JsonKey(name: 'has_hostel') bool? hasHostel,
    @JsonKey(name: 'nirf_rank_latest') int? nirfRank,
    String? website,
    @JsonKey(name: 'programme_count') required int programmeCount,
  }) = _CompareCollege;

  factory CompareCollege.fromJson(Map<String, dynamic> json) =>
      _$CompareCollegeFromJson(json);
}

@freezed
class CompareResult with _$CompareResult {
  const factory CompareResult({
    required Map<String, dynamic> seatDimension,
    @Default(<CompareCollege>[]) List<CompareCollege> colleges,
    @Default(<CompareBranch>[]) List<CompareBranch> branches,
  }) = _CompareResult;

  factory CompareResult.fromJson(Map<String, dynamic> json) =>
      _$CompareResultFromJson(json);
}
