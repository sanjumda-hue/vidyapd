import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../auth/data/auth_controller.dart';

class ShortlistEntry {
  ShortlistEntry.fromJson(Map<String, dynamic> j)
      : collegeBranchId = j['college_branch_id'].toString(),
        collegeSlug = j['college_slug'] as String,
        collegeName = (j['college_short_name'] ?? j['college_name']) as String,
        stateName = j['state_name'] as String,
        branchCode = j['branch_code'] as String,
        programName = j['program_name'] as String,
        note = j['note'] as String?,
        preferenceOrder = j['preference_order'] as int?,
        measure = j['measure'] as String?,
        latestClosing = j['latest_closing'] == null
            ? null
            : num.tryParse(j['latest_closing'].toString()),
        maxScore = j['latest_max_score'] == null
            ? null
            : num.tryParse(j['latest_max_score'].toString()),
        latestYear = j['latest_year'] as int?;

  final String collegeBranchId;
  final String collegeSlug;
  final String collegeName;
  final String stateName;
  final String branchCode;
  final String programName;
  final String? note;
  final int? preferenceOrder;
  /// 'rank' or 'score'. Null when nothing has been published yet.
  final String? measure;
  final num? latestClosing;

  /// The paper total, on a score entry only.
  final num? maxScore;
  final int? latestYear;

  bool get isScore => measure == 'score';
}

class ShortlistRepository {
  ShortlistRepository(this._api);
  final ApiClient _api;

  Future<List<ShortlistEntry>> list() async {
    final rows = await _api.get<List<dynamic>>('/shortlist');
    return rows.map((e) => ShortlistEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Set<String>> ids() async {
    final rows = await _api.get<List<dynamic>>('/shortlist/ids');
    return rows.map((e) => e.toString()).toSet();
  }

  Future<void> add(String collegeBranchId) =>
      _api.post<Map<String, dynamic>>('/shortlist/$collegeBranchId');

  Future<void> remove(String collegeBranchId) =>
      _api.delete<Map<String, dynamic>>('/shortlist/$collegeBranchId');

  Future<void> reorder(List<String> ids) =>
      _api.post<Map<String, dynamic>>('/shortlist/reorder', body: {'ids': ids});
}

final shortlistRepositoryProvider =
    Provider<ShortlistRepository>((ref) => ShortlistRepository(ref.watch(apiClientProvider)));

/// Rebuilt whenever auth changes, so signing out empties it immediately.
final shortlistProvider = FutureProvider<List<ShortlistEntry>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return [];
  return ref.watch(shortlistRepositoryProvider).list();
});

final shortlistIdsProvider = FutureProvider<Set<String>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return {};
  return ref.watch(shortlistRepositoryProvider).ids();
});
