import 'package:freezed_annotation/freezed_annotation.dart';

part 'reference_data.freezed.dart';
part 'reference_data.g.dart';

@freezed
class LookupItem with _$LookupItem {
  const factory LookupItem({
    required String code,
    required String name,
  }) = _LookupItem;

  factory LookupItem.fromJson(Map<String, dynamic> json) =>
      _$LookupItemFromJson(json);
}

@freezed
class ExamOption with _$ExamOption {
  const factory ExamOption({
    required String code,
    required String name,
    required String level,
    required bool hasPercentile,

    /// True when a percentile could actually be converted to a rank for this
    /// season. [hasPercentile] only says the exam reports one -- the form needs
    /// this, because offering the toggle without it is offering a button that
    /// always fails.
    @Default(false) bool hasPercentileData,

    /// True when the authority allots on marks rather than a rank, so the form
    /// must ask for a score out of [maxScore]. BITSAT is the only one so far.
    @Default(false) bool usesMarks,

    /// Paper total for a marks-based exam, from the most recent year on record.
    num? maxScore,
    String? homeStateCode,
    /// False when nothing has been imported for this exam yet. The form greys
    /// the option out rather than letting a student hit an empty result list.
    @Default(true) bool hasCutoffData,
  }) = _ExamOption;

  factory ExamOption.fromJson(Map<String, dynamic> json) =>
      _$ExamOptionFromJson(json);
}

@freezed
class BranchOption with _$BranchOption {
  const factory BranchOption({
    required String code,
    required String name,
    required bool isPopular,
  }) = _BranchOption;

  factory BranchOption.fromJson(Map<String, dynamic> json) =>
      _$BranchOptionFromJson(json);
}

/// Everything the predict form needs, fetched once on app start.
@freezed
class ReferenceData with _$ReferenceData {
  const factory ReferenceData({
    required List<ExamOption> exams,
    required List<LookupItem> categories,
    required List<LookupItem> genders,
    required List<LookupItem> quotas,
    required List<LookupItem> states,
    required List<BranchOption> branches,
    required List<String> collegeTypes,

    /// True when the invented db/seeds-dev colleges are loaded. Defaults to
    /// false so a real database never shows the demo warning.
    @Default(false) bool hasDemoData,
  }) = _ReferenceData;

  factory ReferenceData.fromJson(Map<String, dynamic> json) =>
      _$ReferenceDataFromJson(json);
}
