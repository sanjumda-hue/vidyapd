import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/predict_input.dart';
import '../domain/prediction_response.dart';

class PredictionRepository {
  PredictionRepository(this._api);
  final ApiClient _api;

  Future<PredictionResponse> predict(PredictInput input) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/prediction',
      body: input.toRequestBody(),
    );
    return PredictionResponse.fromJson(json);
  }
}

final predictionRepositoryProvider = Provider<PredictionRepository>(
  (ref) => PredictionRepository(ref.watch(apiClientProvider)),
);
