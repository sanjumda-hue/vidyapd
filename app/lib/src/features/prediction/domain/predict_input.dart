import 'package:freezed_annotation/freezed_annotation.dart';

part 'predict_input.freezed.dart';

/// The predict form's state. Kept separate from the wire format so the form can
/// hold a half-filled, invalid state without that leaking into a request body.
@freezed
class PredictInput with _$PredictInput {
  const factory PredictInput({
    String? examCode,
    int? rank,
    double? percentile,
    @Default(false) bool usePercentile,

    /// Marks-based exams only. [maxScore] is the paper total the score is out
    /// of; it comes from the reference payload and is sent explicitly, because
    /// a candidate entering an older BITSAT score was marked out of 450 while
    /// today's is out of 390.
    double? score,
    num? maxScore,

    /// Set from the exam's reference entry. Decides which input the form asks
    /// for and which field goes on the wire.
    @Default(false) bool usesMarks,
    String? categoryCode,
    @Default('male') String gender,
    @Default(false) bool isPwd,
    String? homeStateCode,
    @Default(<String>{}) Set<String> branchCodes,
    @Default(<String>{}) Set<String> stateCodes,
    @Default(<String>{}) Set<String> collegeTypes,
  }) = _PredictInput;

  const PredictInput._();

  bool get isValid {
    if (examCode == null || categoryCode == null) return false;
    if (usesMarks) {
      return score != null && score! > 0 && (maxScore == null || score! <= maxScore!);
    }
    return usePercentile ? percentile != null : (rank != null && rank! > 0);
  }

  Map<String, dynamic> toRequestBody() => {
        'examCode': examCode,
        if (usesMarks) ...{
          'score': score,
          if (maxScore != null) 'maxScore': maxScore,
        } else if (usePercentile)
          'percentile': percentile
        else
          'rank': rank,
        'categoryCode': categoryCode,
        'gender': gender,
        'isPwd': isPwd,
        if (homeStateCode != null) 'homeStateCode': homeStateCode,
        if (branchCodes.isNotEmpty) 'branchCodes': branchCodes.toList(),
        if (stateCodes.isNotEmpty) 'stateCodes': stateCodes.toList(),
        if (collegeTypes.isNotEmpty) 'collegeTypes': collegeTypes.toList(),
        'limit': 100,
      };
}
