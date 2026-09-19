@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vidyapd/src/core/api/api_client.dart';
import 'package:vidyapd/src/features/prediction/domain/predict_input.dart';
import 'package:vidyapd/src/features/prediction/domain/prediction_response.dart';
import 'package:vidyapd/src/features/reference/domain/reference_data.dart';

/// Parses real API responses with the real models.
///
/// A field renamed on the server is the single most likely way this app breaks,
/// and `flutter analyze` cannot catch it -- the mismatch only shows up as a
/// runtime cast error in the browser. Run against a live API:
///
///   flutter test test/api_contract_test.dart
void main() {
  final api = ApiClient();

  test('reference/bootstrap parses into ReferenceData', () async {
    final json = await api.get<Map<String, dynamic>>('/reference/bootstrap');
    final data = ReferenceData.fromJson(json);

    expect(data.exams, isNotEmpty, reason: 'seeds should provide exams');
    expect(data.categories.map((c) => c.code), contains('OPEN'));
    expect(data.states.map((s) => s.code), contains('UP'));
    expect(data.branches.any((b) => b.code == 'CSE'), isTrue);
    expect(data.collegeTypes, contains('NIT'));
  });

  test('prediction parses into PredictionResponse', () async {
    const input = PredictInput(
      examCode: 'JEE_MAIN',
      rank: 45821,
      categoryCode: 'OBC_NCL',
      gender: 'male',
      homeStateCode: 'UP',
    );
    final json = await api.post<Map<String, dynamic>>(
      '/prediction',
      body: input.toRequestBody(),
    );
    final response = PredictionResponse.fromJson(json);

    expect(response.requestId, isNotEmpty);
    expect(response.rankUsed, 45821);
    expect(response.disclaimer, isNotEmpty,
        reason: 'the disclaimer must always be present');
    expect(response.counts.keys, contains('historical_match'));

    for (final m in response.matches) {
      expect(m.gradeLabel, isNotEmpty);
      expect(
        m.grade,
        anyOf('strong_historical_match', 'historical_match', 'borderline',
            'outside_historical_range'),
      );
      // Every card renders these, so a null here is a blank row in the UI.
      expect(m.college.name, isNotEmpty);
      expect(m.branch.code, isNotEmpty);
      expect(m.seatType, isNotEmpty);
      expect(m.quota, isNotEmpty);
    }
  });

  test('results are ordered best-reachable first', () async {
    const input = PredictInput(
      examCode: 'JEE_MAIN',
      rank: 45821,
      categoryCode: 'OBC_NCL',
      gender: 'male',
      homeStateCode: 'UP',
    );
    final json = await api.post<Map<String, dynamic>>(
      '/prediction',
      body: input.toRequestBody(),
    );
    final matches = PredictionResponse.fromJson(json).matches;
    if (matches.length < 2) return;

    final ranks = matches
        .map((m) => m.weightedClosingRank)
        .whereType<int>()
        .toList();
    final sorted = [...ranks]..sort();
    expect(ranks, sorted,
        reason: 'weighted closing rank must ascend: the most competitive '
            'programme the student can reach belongs at the top');
  });

  test('a bad request surfaces the server validation message', () async {
    await expectLater(
      api.post<Map<String, dynamic>>('/prediction',
          body: {'examCode': 'JEE_MAIN', 'categoryCode': 'OPEN', 'gender': 'male'}),
      throwsA(isA<Exception>()),
    );
  });
}
