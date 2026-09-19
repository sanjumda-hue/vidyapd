import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/reference_data.dart';

class ReferenceRepository {
  ReferenceRepository(this._api);
  final ApiClient _api;

  Future<ReferenceData> bootstrap() async {
    final json = await _api.get<Map<String, dynamic>>('/reference/bootstrap');
    return ReferenceData.fromJson(json);
  }
}

final referenceRepositoryProvider =
    Provider<ReferenceRepository>((ref) => ReferenceRepository(ref.watch(apiClientProvider)));

/// Lookup lists change a few times a year, so this is fetched once and kept
/// for the lifetime of the app.
final referenceDataProvider = FutureProvider<ReferenceData>(
  (ref) => ref.watch(referenceRepositoryProvider).bootstrap(),
);
