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
    String? homeStateCode,
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
  }) = _ReferenceData;

  factory ReferenceData.fromJson(Map<String, dynamic> json) =>
      _$ReferenceDataFromJson(json);
}
