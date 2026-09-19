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
    String? categoryCode,
    @Default('male') String gender,
    @Default(false) bool isPwd,
    String? homeStateCode,
    @Default(<String>{}) Set<String> branchCodes,
    @Default(<String>{}) Set<String> stateCodes,
    @Default(<String>{}) Set<String> collegeTypes,
  }) = _PredictInput;

  const PredictInput._();

  bool get isValid =>
      examCode != null &&
      categoryCode != null &&
      (usePercentile ? percentile != null : (rank != null && rank! > 0));

  Map<String, dynamic> toRequestBody() => {
        'examCode': examCode,
        if (usePercentile) 'percentile': percentile else 'rank': rank,
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
