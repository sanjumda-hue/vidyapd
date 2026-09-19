import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';

class ExamSummary {
  ExamSummary.fromJson(Map<String, dynamic> j)
      : code = j['code'] as String,
        name = j['name'] as String,
        shortName = j['short_name'] as String?,
        level = j['level'] as String,
        authority = j['conducting_authority'] as String,
        website = j['official_website'] as String?,
        stateName = (j['states'] as Map<String, dynamic>?)?['name'] as String?;

  final String code;
  final String name;
  final String? shortName;
  final String level;
  final String authority;
  final String? website;
  final String? stateName;
}

final examsProvider = FutureProvider<List<ExamSummary>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final list = await api.get<List<dynamic>>('/exams');
  return list
      .map((e) => ExamSummary.fromJson(e as Map<String, dynamic>))
      .toList();
});
