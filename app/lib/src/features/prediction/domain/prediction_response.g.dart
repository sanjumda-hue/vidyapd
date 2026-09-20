// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CollegeRefImpl _$$CollegeRefImplFromJson(Map<String, dynamic> json) =>
    _$CollegeRefImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      type: json['type'] as String,
      state: json['state'] as String,
    );

Map<String, dynamic> _$$CollegeRefImplToJson(_$CollegeRefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'shortName': instance.shortName,
      'type': instance.type,
      'state': instance.state,
    };

_$BranchRefImpl _$$BranchRefImplFromJson(Map<String, dynamic> json) =>
    _$BranchRefImpl(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$$BranchRefImplToJson(_$BranchRefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

_$CutoffYearImpl _$$CutoffYearImplFromJson(Map<String, dynamic> json) =>
    _$CutoffYearImpl(
      year: (json['year'] as num).toInt(),
      opening: json['opening'] as num?,
      closing: json['closing'] as num,
      round: (json['round'] as num).toInt(),
      max: json['max'] as num?,
      pct: (json['pct'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$CutoffYearImplToJson(_$CutoffYearImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'opening': instance.opening,
      'closing': instance.closing,
      'round': instance.round,
      'max': instance.max,
      'pct': instance.pct,
    };

_$ScoreBandImpl _$$ScoreBandImplFromJson(Map<String, dynamic> json) =>
    _$ScoreBandImpl(
      weightedClosing: json['weightedClosing'] as num?,
      toughestClosing: json['toughestClosing'] as num?,
      easiestClosing: json['easiestClosing'] as num?,
      latestClosing: json['latestClosing'] as num?,
      maxScore: json['maxScore'] as num?,
      margin: json['margin'] as num?,
    );

Map<String, dynamic> _$$ScoreBandImplToJson(_$ScoreBandImpl instance) =>
    <String, dynamic>{
      'weightedClosing': instance.weightedClosing,
      'toughestClosing': instance.toughestClosing,
      'easiestClosing': instance.easiestClosing,
      'latestClosing': instance.latestClosing,
      'maxScore': instance.maxScore,
      'margin': instance.margin,
    };

_$PredictionMatchImpl _$$PredictionMatchImplFromJson(
  Map<String, dynamic> json,
) => _$PredictionMatchImpl(
  collegeBranchId: (json['collegeBranchId'] as num).toInt(),
  college: CollegeRef.fromJson(json['college'] as Map<String, dynamic>),
  branch: BranchRef.fromJson(json['branch'] as Map<String, dynamic>),
  programName: json['programName'] as String,
  seatType: json['seatType'] as String,
  quota: json['quota'] as String,
  genderPool: json['genderPool'] as String,
  grade: json['grade'] as String,
  gradeLabel: json['gradeLabel'] as String,
  score: (json['score'] as num).toDouble(),
  weightedClosingRank: (json['weightedClosingRank'] as num?)?.toInt(),
  bestClosingRank: (json['bestClosingRank'] as num?)?.toInt(),
  worstClosingRank: (json['worstClosingRank'] as num?)?.toInt(),
  latestClosingRank: (json['latestClosingRank'] as num?)?.toInt(),
  rankMargin: (json['rankMargin'] as num?)?.toInt(),
  scoreBand: json['scoreBand'] == null
      ? null
      : ScoreBand.fromJson(json['scoreBand'] as Map<String, dynamic>),
  yearsAvailable: (json['yearsAvailable'] as num).toInt(),
  trend: json['trend'] as String,
  cutoffHistory:
      (json['cutoffHistory'] as List<dynamic>?)
          ?.map((e) => CutoffYear.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CutoffYear>[],
);

Map<String, dynamic> _$$PredictionMatchImplToJson(
  _$PredictionMatchImpl instance,
) => <String, dynamic>{
  'collegeBranchId': instance.collegeBranchId,
  'college': instance.college,
  'branch': instance.branch,
  'programName': instance.programName,
  'seatType': instance.seatType,
  'quota': instance.quota,
  'genderPool': instance.genderPool,
  'grade': instance.grade,
  'gradeLabel': instance.gradeLabel,
  'score': instance.score,
  'weightedClosingRank': instance.weightedClosingRank,
  'bestClosingRank': instance.bestClosingRank,
  'worstClosingRank': instance.worstClosingRank,
  'latestClosingRank': instance.latestClosingRank,
  'rankMargin': instance.rankMargin,
  'scoreBand': instance.scoreBand,
  'yearsAvailable': instance.yearsAvailable,
  'trend': instance.trend,
  'cutoffHistory': instance.cutoffHistory,
};

_$ExamRefImpl _$$ExamRefImplFromJson(Map<String, dynamic> json) =>
    _$ExamRefImpl(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$$ExamRefImplToJson(_$ExamRefImpl instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

_$PredictionResponseImpl _$$PredictionResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PredictionResponseImpl(
  requestId: json['requestId'] as String,
  exam: ExamRef.fromJson(json['exam'] as Map<String, dynamic>),
  academicYear: (json['academicYear'] as num).toInt(),
  measure: json['measure'] as String? ?? 'rank',
  rankUsed: (json['rankUsed'] as num?)?.toInt(),
  rankIsEstimated: json['rankIsEstimated'] as bool,
  rankEstimateMethod: json['rankEstimateMethod'] as String?,
  scoreUsed: json['scoreUsed'] as num?,
  maxScoreUsed: json['maxScoreUsed'] as num?,
  category: json['category'] as String,
  gender: json['gender'] as String,
  homeState: json['homeState'] as String?,
  counts: Map<String, int>.from(json['counts'] as Map),
  matches:
      (json['matches'] as List<dynamic>?)
          ?.map((e) => PredictionMatch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PredictionMatch>[],
  disclaimer: json['disclaimer'] as String,
);

Map<String, dynamic> _$$PredictionResponseImplToJson(
  _$PredictionResponseImpl instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'exam': instance.exam,
  'academicYear': instance.academicYear,
  'measure': instance.measure,
  'rankUsed': instance.rankUsed,
  'rankIsEstimated': instance.rankIsEstimated,
  'rankEstimateMethod': instance.rankEstimateMethod,
  'scoreUsed': instance.scoreUsed,
  'maxScoreUsed': instance.maxScoreUsed,
  'category': instance.category,
  'gender': instance.gender,
  'homeState': instance.homeState,
  'counts': instance.counts,
  'matches': instance.matches,
  'disclaimer': instance.disclaimer,
};
