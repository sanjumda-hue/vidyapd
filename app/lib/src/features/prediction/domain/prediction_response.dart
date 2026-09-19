import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction_response.freezed.dart';
part 'prediction_response.g.dart';

@freezed
class CollegeRef with _$CollegeRef {
  const factory CollegeRef({
    required int id,
    required String name,
    String? shortName,
    required String type,
    required String state,
  }) = _CollegeRef;

  factory CollegeRef.fromJson(Map<String, dynamic> json) =>
      _$CollegeRefFromJson(json);
}

@freezed
class BranchRef with _$BranchRef {
  const factory BranchRef({
    required int id,
    required String code,
    required String name,
  }) = _BranchRef;

  factory BranchRef.fromJson(Map<String, dynamic> json) =>
      _$BranchRefFromJson(json);
}

@freezed
class CutoffYear with _$CutoffYear {
  const factory CutoffYear({
    required int year,
    int? opening,
    required int closing,
    required int round,
  }) = _CutoffYear;

  factory CutoffYear.fromJson(Map<String, dynamic> json) =>
      _$CutoffYearFromJson(json);
}

@freezed
class PredictionMatch with _$PredictionMatch {
  const factory PredictionMatch({
    required int collegeBranchId,
    required CollegeRef college,
    required BranchRef branch,
    required String programName,
    required String seatType,
    required String quota,
    required String genderPool,
    required String grade,
    required String gradeLabel,
    required double score,
    int? weightedClosingRank,
    int? bestClosingRank,
    int? worstClosingRank,
    int? latestClosingRank,
    int? rankMargin,
    required int yearsAvailable,
    required String trend,
    @Default(<CutoffYear>[]) List<CutoffYear> cutoffHistory,
  }) = _PredictionMatch;

  factory PredictionMatch.fromJson(Map<String, dynamic> json) =>
      _$PredictionMatchFromJson(json);
}

@freezed
class ExamRef with _$ExamRef {
  const factory ExamRef({
    required String code,
    required String name,
  }) = _ExamRef;

  factory ExamRef.fromJson(Map<String, dynamic> json) => _$ExamRefFromJson(json);
}

@freezed
class PredictionResponse with _$PredictionResponse {
  const factory PredictionResponse({
    required String requestId,
    required ExamRef exam,
    required int academicYear,
    required int rankUsed,
    required bool rankIsEstimated,
    String? rankEstimateMethod,
    required String category,
    required String gender,
    String? homeState,
    required Map<String, int> counts,
    @Default(<PredictionMatch>[]) List<PredictionMatch> matches,
    /// Shown verbatim under every result list. Never dropped, never reworded.
    required String disclaimer,
  }) = _PredictionResponse;

  factory PredictionResponse.fromJson(Map<String, dynamic> json) =>
      _$PredictionResponseFromJson(json);
}
