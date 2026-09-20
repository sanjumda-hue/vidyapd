// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'college.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CollegeListItemImpl _$$CollegeListItemImplFromJson(
  Map<String, dynamic> json,
) => _$CollegeListItemImpl(
  slug: json['slug'] as String,
  name: json['name'] as String,
  shortName: json['short_name'] as String?,
  collegeType: json['college_type'] as String,
  stateName: json['state_name'] as String,
  cityName: json['city_name'] as String?,
  nirfRank: (json['nirf_rank_latest'] as num?)?.toInt(),
  programmeCount: (json['programme_count'] as num).toInt(),
);

Map<String, dynamic> _$$CollegeListItemImplToJson(
  _$CollegeListItemImpl instance,
) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'short_name': instance.shortName,
  'college_type': instance.collegeType,
  'state_name': instance.stateName,
  'city_name': instance.cityName,
  'nirf_rank_latest': instance.nirfRank,
  'programme_count': instance.programmeCount,
};

_$CollegeProgrammeImpl _$$CollegeProgrammeImplFromJson(
  Map<String, dynamic> json,
) => _$CollegeProgrammeImpl(
  collegeBranchId: json['college_branch_id'] as String,
  programName: json['program_name'] as String,
  branchCode: json['branch_code'] as String,
  branchName: json['branch_name'] as String,
  degree: json['degree'] as String,
  durationYears: json['duration_years'] as String?,
  totalIntake: (json['total_intake'] as num?)?.toInt(),
  measure: json['measure'] as String?,
  latestClosing: json['latest_closing'] as String?,
  latestMaxScore: json['latest_max_score'] as String?,
  latestYear: (json['latest_year'] as num?)?.toInt(),
  yearsAvailable: (json['years_available'] as num?)?.toInt(),
);

Map<String, dynamic> _$$CollegeProgrammeImplToJson(
  _$CollegeProgrammeImpl instance,
) => <String, dynamic>{
  'college_branch_id': instance.collegeBranchId,
  'program_name': instance.programName,
  'branch_code': instance.branchCode,
  'branch_name': instance.branchName,
  'degree': instance.degree,
  'duration_years': instance.durationYears,
  'total_intake': instance.totalIntake,
  'measure': instance.measure,
  'latest_closing': instance.latestClosing,
  'latest_max_score': instance.latestMaxScore,
  'latest_year': instance.latestYear,
  'years_available': instance.yearsAvailable,
};

_$CollegeAuthorityImpl _$$CollegeAuthorityImplFromJson(
  Map<String, dynamic> json,
) => _$CollegeAuthorityImpl(
  code: json['code'] as String,
  name: json['name'] as String,
  years: (json['years'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  rows: (json['rows'] as num).toInt(),
);

Map<String, dynamic> _$$CollegeAuthorityImplToJson(
  _$CollegeAuthorityImpl instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'years': instance.years,
  'rows': instance.rows,
};

_$CollegeInfoImpl _$$CollegeInfoImplFromJson(Map<String, dynamic> json) =>
    _$CollegeInfoImpl(
      slug: json['slug'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      about: json['about'] as String?,
      collegeType: json['college_type'] as String,
      ownership: json['ownership'] as String,
      affiliatedUniversity: json['affiliated_university'] as String?,
      establishedYear: (json['established_year'] as num?)?.toInt(),
      website: json['website'] as String?,
      hasHostel: json['has_hostel'] as bool?,
      nirfRank: (json['nirf_rank_latest'] as num?)?.toInt(),
      nirfYear: (json['nirf_year_latest'] as num?)?.toInt(),
      states: json['states'] as Map<String, dynamic>,
      cities: json['cities'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$CollegeInfoImplToJson(_$CollegeInfoImpl instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'short_name': instance.shortName,
      'about': instance.about,
      'college_type': instance.collegeType,
      'ownership': instance.ownership,
      'affiliated_university': instance.affiliatedUniversity,
      'established_year': instance.establishedYear,
      'website': instance.website,
      'has_hostel': instance.hasHostel,
      'nirf_rank_latest': instance.nirfRank,
      'nirf_year_latest': instance.nirfYear,
      'states': instance.states,
      'cities': instance.cities,
    };

_$CollegeDetailImpl _$$CollegeDetailImplFromJson(Map<String, dynamic> json) =>
    _$CollegeDetailImpl(
      college: CollegeInfo.fromJson(json['college'] as Map<String, dynamic>),
      programmes:
          (json['programmes'] as List<dynamic>?)
              ?.map((e) => CollegeProgramme.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CollegeProgramme>[],
      authorities:
          (json['authorities'] as List<dynamic>?)
              ?.map((e) => CollegeAuthority.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CollegeAuthority>[],
    );

Map<String, dynamic> _$$CollegeDetailImplToJson(_$CollegeDetailImpl instance) =>
    <String, dynamic>{
      'college': instance.college,
      'programmes': instance.programmes,
      'authorities': instance.authorities,
    };

_$CompareBranchImpl _$$CompareBranchImplFromJson(Map<String, dynamic> json) =>
    _$CompareBranchImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      byCollege: (json['byCollege'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, CompareCell.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$CompareBranchImplToJson(_$CompareBranchImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'byCollege': instance.byCollege,
    };

_$CompareCellImpl _$$CompareCellImplFromJson(Map<String, dynamic> json) =>
    _$CompareCellImpl(
      measure: json['measure'] as String? ?? 'rank',
      latestClosing: json['latestClosing'] as num?,
      maxScore: json['maxScore'] as num?,
      latestYear: (json['latestYear'] as num?)?.toInt(),
      yearsAvailable: (json['yearsAvailable'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$CompareCellImplToJson(_$CompareCellImpl instance) =>
    <String, dynamic>{
      'measure': instance.measure,
      'latestClosing': instance.latestClosing,
      'maxScore': instance.maxScore,
      'latestYear': instance.latestYear,
      'yearsAvailable': instance.yearsAvailable,
    };

_$CompareCollegeImpl _$$CompareCollegeImplFromJson(Map<String, dynamic> json) =>
    _$CompareCollegeImpl(
      slug: json['slug'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      collegeType: json['college_type'] as String,
      ownership: json['ownership'] as String,
      stateName: json['state_name'] as String,
      cityName: json['city_name'] as String?,
      establishedYear: (json['established_year'] as num?)?.toInt(),
      hasHostel: json['has_hostel'] as bool?,
      nirfRank: (json['nirf_rank_latest'] as num?)?.toInt(),
      website: json['website'] as String?,
      programmeCount: (json['programme_count'] as num).toInt(),
    );

Map<String, dynamic> _$$CompareCollegeImplToJson(
  _$CompareCollegeImpl instance,
) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'short_name': instance.shortName,
  'college_type': instance.collegeType,
  'ownership': instance.ownership,
  'state_name': instance.stateName,
  'city_name': instance.cityName,
  'established_year': instance.establishedYear,
  'has_hostel': instance.hasHostel,
  'nirf_rank_latest': instance.nirfRank,
  'website': instance.website,
  'programme_count': instance.programmeCount,
};

_$CompareResultImpl _$$CompareResultImplFromJson(Map<String, dynamic> json) =>
    _$CompareResultImpl(
      seatDimension: json['seatDimension'] as Map<String, dynamic>,
      colleges:
          (json['colleges'] as List<dynamic>?)
              ?.map((e) => CompareCollege.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CompareCollege>[],
      branches:
          (json['branches'] as List<dynamic>?)
              ?.map((e) => CompareBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CompareBranch>[],
    );

Map<String, dynamic> _$$CompareResultImplToJson(_$CompareResultImpl instance) =>
    <String, dynamic>{
      'seatDimension': instance.seatDimension,
      'colleges': instance.colleges,
      'branches': instance.branches,
    };
