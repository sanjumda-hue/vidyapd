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
  /// One published year for a programme.
  ///
  /// `closing` is a rank on most exams and a SCORE on marks-based ones, which
  /// is why it is a num rather than an int -- and why [max] matters: BITSAT was
  /// marked out of 450 until 2021 and 390 after, so 306 and 226 are the same
  /// standard and the raw figures alone say the opposite.
  const factory CutoffYear({
    required int year,
    num? opening,
    required num closing,
    required int round,
    num? max,
    double? pct,
  }) = _CutoffYear;

  const CutoffYear._();

  /// True when this row is a score out of [max] rather than a rank.
  bool get isScore => max != null;

  factory CutoffYear.fromJson(Map<String, dynamic> json) =>
      _$CutoffYearFromJson(json);
}

/// Cut-off figures for a marks-based programme, out of the candidate's own
/// paper total. Null on a rank-based exam, where the rank fields carry it.
@freezed
class ScoreBand with _$ScoreBand {
  const factory ScoreBand({
    num? weightedClosing,

    /// Strictest year on record: the HIGHEST cut-off.
    num? toughestClosing,

    /// Most lenient year: the LOWEST cut-off.
    num? easiestClosing,
    num? latestClosing,
    num? maxScore,

    /// Candidate score minus the weighted cut-off. Positive = ahead of it.
    num? margin,
  }) = _ScoreBand;

  factory ScoreBand.fromJson(Map<String, dynamic> json) =>
      _$ScoreBandFromJson(json);
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

    /// Set instead of the rank fields when the exam is marks-based.
    ScoreBand? scoreBand,
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

    /// 'rank' or 'score'. Says which set of fields on each match to read, and
    /// which way "better" points -- a lower rank is better, a higher score is.
    @Default('rank') String measure,

    /// Null on a marks-based exam.
    int? rankUsed,
    required bool rankIsEstimated,
    String? rankEstimateMethod,

    /// Both null unless the exam is marks-based.
    num? scoreUsed,
    num? maxScoreUsed,
    required String category,
    required String gender,
    String? homeState,
    required Map<String, int> counts,
    @Default(<PredictionMatch>[]) List<PredictionMatch> matches,
    /// Shown verbatim under every result list. Never dropped, never reworded.
    required String disclaimer,
  }) = _PredictionResponse;

  const PredictionResponse._();

  bool get isScoreBased => measure == 'score';

  factory PredictionResponse.fromJson(Map<String, dynamic> json) =>
      _$PredictionResponseFromJson(json);
}
