import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/college.dart';

class CollegesRepository {
  CollegesRepository(this._api);
  final ApiClient _api;

  Future<({List<CollegeListItem> items, int total})> search({
    String? q,
    String? stateCode,
    String? type,
    int limit = 25,
    int page = 1,
  }) async {
    final json = await _api.get<Map<String, dynamic>>('/colleges', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (stateCode != null) 'stateCode': stateCode,
      if (type != null) 'type': type,
      'limit': limit,
      'page': page,
    });
    return (
      items: (json['items'] as List)
          .map((e) => CollegeListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Future<CollegeDetail> detail(String slug) async =>
      CollegeDetail.fromJson(await _api.get<Map<String, dynamic>>('/colleges/$slug'));

  Future<CompareResult> compare(List<String> slugs) async =>
      CompareResult.fromJson(await _api.get<Map<String, dynamic>>(
        '/colleges/compare',
        query: {'slugs': slugs.join(',')},
      ));
}

final collegesRepositoryProvider =
    Provider<CollegesRepository>((ref) => CollegesRepository(ref.watch(apiClientProvider)));

final collegeSearchProvider = FutureProvider.family<
    ({List<CollegeListItem> items, int total}), String>(
  (ref, query) => ref.watch(collegesRepositoryProvider).search(q: query),
);

final collegeDetailProvider = FutureProvider.family<CollegeDetail, String>(
  (ref, slug) => ref.watch(collegesRepositoryProvider).detail(slug),
);

/// Slugs the student has ticked for comparison. Capped at 4 by the API.
final compareSelectionProvider = StateProvider<List<String>>((ref) => []);

final compareResultProvider = FutureProvider<CompareResult?>((ref) async {
  final slugs = ref.watch(compareSelectionProvider);
  if (slugs.length < 2) return null;
  return ref.watch(collegesRepositoryProvider).compare(slugs);
});
