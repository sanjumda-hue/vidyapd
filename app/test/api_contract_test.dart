@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vidyapd/src/core/api/api_client.dart';
import 'package:vidyapd/src/features/prediction/domain/predict_input.dart';
import 'package:vidyapd/src/features/prediction/domain/prediction_response.dart';
import 'package:vidyapd/src/features/colleges/domain/college.dart';
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

  test('bootstrap reports which exams actually have cutoff data', () async {
    // A student picked an exam with nothing imported, got an empty list with no
    // explanation, and hit Predict three more times. The form now greys out
    // exams with no data, and that depends on this flag being present and
    // honest -- including for marks-based exams, whose rows live in a separate
    // trend view that this flag once did not look at.
    final json = await api.get<Map<String, dynamic>>('/reference/bootstrap');
    final data = ReferenceData.fromJson(json);

    final jeeMain = data.exams.firstWhere((e) => e.code == 'JEE_MAIN');
    expect(jeeMain.hasCutoffData, isTrue,
        reason: 'seed-dev loads JEE Main cutoffs');

    expect(data.exams.any((e) => !e.hasCutoffData), isTrue,
        reason: 'most exams have no imported cutoffs yet, and the form must '
            'be able to say so');
  });

  test('an exam with no cutoff data returns zero matches, not an error', () async {
    // Not a marks-based one: those reject a rank outright, which is a
    // different behaviour and has its own test.
    final withoutData = ReferenceData.fromJson(
      await api.get<Map<String, dynamic>>('/reference/bootstrap'),
    ).exams.firstWhere((e) => !e.hasCutoffData && !e.usesMarks);

    final json = await api.post<Map<String, dynamic>>('/prediction', body: {
      'examCode': withoutData.code,
      'rank': 200,
      'categoryCode': 'OPEN',
      'gender': 'female',
      'homeStateCode': 'UP',
    });
    final response = PredictionResponse.fromJson(json);
    expect(response.matches, isEmpty);
    expect(response.disclaimer, isNotEmpty);
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

  test('the demo-data warning is driven by the database, not hardcoded', () async {
    // The predict screen rendered a red "Development build ... (DEMO)" banner
    // unconditionally. Once real cut-offs replaced the seed-dev colleges it was
    // warning about institutes that no longer existed, on every page load.
    final data = ReferenceData.fromJson(
      await api.get<Map<String, dynamic>>('/reference/bootstrap'),
    );

    final colleges = await api.get<Map<String, dynamic>>('/colleges', query: {'limit': '1', 'q': 'Demo'});
    final items = (colleges['items'] as List).cast<Map<String, dynamic>>();
    final demoPresent = items.any((c) => (c['slug'] as String).startsWith('demo-'));

    expect(data.hasDemoData, demoPresent,
        reason: 'the flag has to track what is actually loaded, or the warning '
            'is either crying wolf or silently absent when it matters');
  });

  test('the percentile toggle is only offered when a percentile can be converted',
      () async {
    // has_percentile says the exam REPORTS a percentile. It said nothing about
    // whether one could be turned into a rank, and the form offered the toggle
    // on that basis while percentile_rank_mapping and exam_rank_data were both
    // empty -- so picking Percentile on JEE Main and hitting Predict returned
    // a 400 every single time. hasPercentileData is the flag the form reads.
    final data = ReferenceData.fromJson(
      await api.get<Map<String, dynamic>>('/reference/bootstrap'),
    );

    for (final exam in data.exams) {
      if (!exam.hasPercentileData) continue;
      // Claiming it works means it has to work.
      final response = PredictionResponse.fromJson(
        await api.post<Map<String, dynamic>>('/prediction', body: {
          'examCode': exam.code,
          'percentile': 94.2,
          'categoryCode': 'OPEN',
          'gender': 'male',
        }),
      );
      expect(response.rankUsed, isNotNull);
      expect(response.rankIsEstimated, isTrue,
          reason: 'a converted percentile is never presented as a known rank');
      expect(response.rankEstimateMethod, isNotNull,
          reason: 'the UI names the method in the estimate badge');
    }

    expect(data.exams.every((e) => !e.hasPercentileData || e.hasPercentile), isTrue,
        reason: 'an exam that reports no percentile can never convert one');
  });

  // ---------------------------------------------------------------------------
  // Marks-based exams. BITSAT publishes a cut-off SCORE, not a rank, and runs
  // through a second engine -- so none of the rank assertions above cover it.
  // ---------------------------------------------------------------------------

  test('bootstrap flags BITSAT as marks-based and gives the paper total', () async {
    final data = ReferenceData.fromJson(
      await api.get<Map<String, dynamic>>('/reference/bootstrap'),
    );
    final bitsat = data.exams.firstWhere((e) => e.code == 'BITSAT');

    expect(bitsat.usesMarks, isTrue);
    expect(bitsat.hasPercentile, isFalse);
    expect(bitsat.maxScore, isNotNull,
        reason: 'the form labels the input "out of N" and sends it back');
    expect(bitsat.hasCutoffData, isTrue,
        reason: 'its rows live in the score trend view, not the rank one');
  });

  test('a BITSAT score returns score bands and no ranks', () async {
    final input = PredictInput(
      examCode: 'BITSAT',
      usesMarks: true,
      score: 300,
      maxScore: 390,
      categoryCode: 'OPEN',
      gender: 'male',
    );
    final response = PredictionResponse.fromJson(
      await api.post<Map<String, dynamic>>('/prediction', body: input.toRequestBody()),
    );

    expect(response.measure, 'score');
    expect(response.isScoreBased, isTrue);
    expect(response.scoreUsed, 300);
    expect(response.maxScoreUsed, 390);
    expect(response.rankUsed, isNull,
        reason: 'there is no rank to report, and inventing one would be a lie');
    expect(response.matches, isNotEmpty);

    for (final m in response.matches) {
      expect(m.scoreBand, isNotNull);
      expect(m.scoreBand!.maxScore, 390,
          reason: 'figures come back out of the total the student entered');
      expect(m.weightedClosingRank, isNull);
      expect(m.rankMargin, isNull);
      // The card prints the total on every pill, so it has to be there.
      for (final y in m.cutoffHistory) {
        expect(y.max, isNotNull);
        expect(y.isScore, isTrue);
      }
    }
  });

  test('score results are ordered hardest-reachable first', () async {
    final input = PredictInput(
      examCode: 'BITSAT',
      usesMarks: true,
      score: 300,
      maxScore: 390,
      categoryCode: 'OPEN',
      gender: 'male',
    );
    final matches = PredictionResponse.fromJson(
      await api.post<Map<String, dynamic>>('/prediction', body: input.toRequestBody()),
    ).matches;
    if (matches.length < 2) return;

    final cutoffs = matches
        .map((m) => m.scoreBand?.weightedClosing)
        .whereType<num>()
        .toList();
    final sorted = [...cutoffs]..sort((a, b) => b.compareTo(a));
    expect(cutoffs, sorted,
        reason: 'descending, the mirror of the rank list ascending: for a '
            'score the most competitive programme has the HIGHEST cut-off');
  });

  test('a rank sent to a marks-based exam is rejected, not silently ignored', () async {
    await expectLater(
      api.post<Map<String, dynamic>>('/prediction', body: {
        'examCode': 'BITSAT',
        'rank': 500,
        'categoryCode': 'OPEN',
        'gender': 'male',
      }),
      throwsA(isA<Exception>()),
    );
  });

  test('a score above the paper total is rejected', () async {
    await expectLater(
      api.post<Map<String, dynamic>>('/prediction', body: {
        'examCode': 'BITSAT',
        'score': 400,
        'maxScore': 390,
        'categoryCode': 'OPEN',
        'gender': 'male',
      }),
      throwsA(isA<Exception>()),
    );
  });

  test('a college page carries the measure its cutoffs are in', () async {
    // These four screens all read v_program_latest_cutoff now. Before it
    // existed they read the rank trend view alone, and a BITS programme showed
    // a blank on every one of them with ten years of cut-offs loaded.
    final bits = CollegeDetail.fromJson(
      await api.get<Map<String, dynamic>>('/colleges/bits-pilani-pilani-campus'),
    );
    expect(bits.programmes, isNotEmpty);
    expect(bits.authorities.map((a) => a.code), contains('BITS'));

    final cse = bits.programmes.firstWhere((p) => p.branchCode == 'CSE');
    expect(cse.isScore, isTrue);
    expect(cse.latestClosing, isNotNull);
    expect(cse.latestMaxScore, isNotNull,
        reason: 'a score with no paper total cannot be read');

    final iit = CollegeDetail.fromJson(
      await api.get<Map<String, dynamic>>(
          '/colleges/indian-institute-of-technology-bombay-t0pc'),
    );
    final iitCse = iit.programmes.firstWhere((p) => p.branchCode == 'CSE');
    expect(iitCse.isScore, isFalse);
    expect(iitCse.latestMaxScore, isNull, reason: 'a rank is out of nothing');
  });

  test('compare labels each cell with its own measure', () async {
    final result = CompareResult.fromJson(
      await api.get<Map<String, dynamic>>('/colleges/compare', query: {
        'slugs': 'bits-pilani-pilani-campus,'
            'indian-institute-of-technology-bombay-t0pc',
      }),
    );

    final cse = result.branches.firstWhere((b) => b.code == 'CSE');
    final bitsCell = cse.byCollege['bits-pilani-pilani-campus']!;
    final iitCell = cse.byCollege['indian-institute-of-technology-bombay-t0pc']!;

    expect(bitsCell.isScore, isTrue);
    expect(bitsCell.maxScore, isNotNull);
    expect(iitCell.isScore, isFalse);
    expect(iitCell.maxScore, isNull);
    // The row renderer refuses to mark a winner when these disagree: a score of
    // 308/390 and a rank of 67 are not on one scale.
    expect(bitsCell.measure, isNot(iitCell.measure));
  });

  test('a bad request surfaces the server validation message', () async {
    await expectLater(
      api.post<Map<String, dynamic>>('/prediction',
          body: {'examCode': 'JEE_MAIN', 'categoryCode': 'OPEN', 'gender': 'male'}),
      throwsA(isA<Exception>()),
    );
  });
}
