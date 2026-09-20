// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LookupItemImpl _$$LookupItemImplFromJson(Map<String, dynamic> json) =>
    _$LookupItemImpl(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$$LookupItemImplToJson(_$LookupItemImpl instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

_$ExamOptionImpl _$$ExamOptionImplFromJson(Map<String, dynamic> json) =>
    _$ExamOptionImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      level: json['level'] as String,
      hasPercentile: json['hasPercentile'] as bool,
      hasPercentileData: json['hasPercentileData'] as bool? ?? false,
      usesMarks: json['usesMarks'] as bool? ?? false,
      maxScore: json['maxScore'] as num?,
      homeStateCode: json['homeStateCode'] as String?,
      hasCutoffData: json['hasCutoffData'] as bool? ?? true,
    );

Map<String, dynamic> _$$ExamOptionImplToJson(_$ExamOptionImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'level': instance.level,
      'hasPercentile': instance.hasPercentile,
      'hasPercentileData': instance.hasPercentileData,
      'usesMarks': instance.usesMarks,
      'maxScore': instance.maxScore,
      'homeStateCode': instance.homeStateCode,
      'hasCutoffData': instance.hasCutoffData,
    };

_$BranchOptionImpl _$$BranchOptionImplFromJson(Map<String, dynamic> json) =>
    _$BranchOptionImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      isPopular: json['isPopular'] as bool,
    );

Map<String, dynamic> _$$BranchOptionImplToJson(_$BranchOptionImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'isPopular': instance.isPopular,
    };

_$ReferenceDataImpl _$$ReferenceDataImplFromJson(Map<String, dynamic> json) =>
    _$ReferenceDataImpl(
      exams: (json['exams'] as List<dynamic>)
          .map((e) => ExamOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      genders: (json['genders'] as List<dynamic>)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      quotas: (json['quotas'] as List<dynamic>)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      states: (json['states'] as List<dynamic>)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      branches: (json['branches'] as List<dynamic>)
          .map((e) => BranchOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      collegeTypes: (json['collegeTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hasDemoData: json['hasDemoData'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReferenceDataImplToJson(_$ReferenceDataImpl instance) =>
    <String, dynamic>{
      'exams': instance.exams,
      'categories': instance.categories,
      'genders': instance.genders,
      'quotas': instance.quotas,
      'states': instance.states,
      'branches': instance.branches,
      'collegeTypes': instance.collegeTypes,
      'hasDemoData': instance.hasDemoData,
    };
