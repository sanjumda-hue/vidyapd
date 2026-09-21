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
    String? examCode,
    String? branchCode,
    int limit = 25,
    int page = 1,
  }) async {
    final json = await _api.get<Map<String, dynamic>>('/colleges', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (stateCode != null) 'stateCode': stateCode,
      if (type != null) 'type': type,
      if (examCode != null) 'examCode': examCode,
      if (branchCode != null) 'branchCode': branchCode,
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

/// Everything the college list filters on.
///
/// A record rather than a class because Riverpod families key on equality and
/// records already have it structurally -- two identical filter sets hit the
/// same cache entry without any == to keep in sync.
typedef CollegeFilter = ({
  String q,
  String? stateCode,
  String? type,
  String? examCode,
  String? branchCode,
});

const emptyCollegeFilter = (
  q: '',
  stateCode: null,
  type: null,
  examCode: null,
  branchCode: null,
) as CollegeFilter;

/// Records are immutable, so changing one field means rebuilding the whole
/// value. These keep that out of the widgets, where a hand-written literal
/// per dropdown is five chances to drop a field on the floor.
CollegeFilter withQuery(CollegeFilter f, String q) => (
      q: q,
      stateCode: f.stateCode,
      type: f.type,
      examCode: f.examCode,
      branchCode: f.branchCode,
    );

CollegeFilter withType(CollegeFilter f, String? type) => (
      q: f.q,
      stateCode: f.stateCode,
      type: type,
      examCode: f.examCode,
      branchCode: f.branchCode,
    );

CollegeFilter withState(CollegeFilter f, String? stateCode) => (
      q: f.q,
      stateCode: stateCode,
      type: f.type,
      examCode: f.examCode,
      branchCode: f.branchCode,
    );

CollegeFilter withExam(CollegeFilter f, String? examCode) => (
      q: f.q,
      stateCode: f.stateCode,
      type: f.type,
      examCode: examCode,
      branchCode: f.branchCode,
    );

CollegeFilter withBranch(CollegeFilter f, String? branchCode) => (
      q: f.q,
      stateCode: f.stateCode,
      type: f.type,
      examCode: f.examCode,
      branchCode: branchCode,
    );

final collegeSearchProvider = FutureProvider.family<
    ({List<CollegeListItem> items, int total}), CollegeFilter>(
  (ref, f) => ref.watch(collegesRepositoryProvider).search(
        q: f.q,
        stateCode: f.stateCode,
        type: f.type,
        examCode: f.examCode,
        branchCode: f.branchCode,
      ),
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
