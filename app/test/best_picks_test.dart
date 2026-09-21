import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyapd/src/features/prediction/domain/prediction_response.dart';
import 'package:vidyapd/src/features/prediction/presentation/widgets/best_picks.dart';

/// The ordering inside each band is the whole point of this widget, and it is
/// the thing most easily got backwards: a rank is better when it is lower, a
/// score when it is higher. Driving it through the browser needs a populated
/// database and a dropdown that does not take keyboard input well, so it is
/// pinned here instead.
void main() {
  PredictionMatch match({
    required String grade,
    required String college,
    int? rank,
    num? score,
    num? maxScore,
  }) =>
      PredictionMatch(
        collegeBranchId: college.hashCode,
        college: CollegeRef(
            id: college.hashCode, name: college, shortName: college, type: 'NIT', state: 'UP'),
        branch: const BranchRef(id: 1, code: 'CSE', name: 'Computer Science'),
        programName: 'Computer Science and Engineering',
        seatType: 'Open',
        quota: 'All India',
        genderPool: 'Gender-Neutral',
        grade: grade,
        gradeLabel: switch (grade) {
          'strong_historical_match' => 'Strong historical match',
          'historical_match' => 'Historical match',
          _ => 'Borderline',
        },
        score: 50,
        weightedClosingRank: rank,
        scoreBand: score == null
            ? null
            : ScoreBand(weightedClosing: score, maxScore: maxScore),
        yearsAvailable: 4,
        trend: 'stable',
      );

  PredictionResponse response(List<PredictionMatch> matches, {String measure = 'rank'}) =>
      PredictionResponse(
        requestId: 'test',
        exam: const ExamRef(code: 'JEE_MAIN', name: 'JEE Main'),
        academicYear: 2026,
        measure: measure,
        rankUsed: measure == 'rank' ? 45821 : null,
        rankIsEstimated: false,
        scoreUsed: measure == 'score' ? 300 : null,
        maxScoreUsed: measure == 'score' ? 390 : null,
        category: 'OPEN',
        gender: 'male',
        counts: const {},
        matches: matches,
        disclaimer: 'x',
      );

  Future<void> pump(WidgetTester tester, PredictionResponse r) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 1000, child: BestPicks(response: r)),
      ),
    ));
  }

  testWidgets('a rank band leads with the lowest closing rank', (tester) async {
    await pump(
      tester,
      response([
        match(grade: 'historical_match', college: 'Safest NIT', rank: 60000),
        match(grade: 'historical_match', college: 'Best NIT', rank: 46000),
        match(grade: 'historical_match', college: 'Middle NIT', rank: 52000),
        match(grade: 'borderline', college: 'Stretch NIT', rank: 36000),
      ]),
    );

    // Most competitive first, which for a rank is the smallest number -- not
    // the highest fit score, which would put Safest NIT on top.
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(texts.indexOf('Best NIT'), lessThan(texts.indexOf('Middle NIT')));
    expect(texts.indexOf('Middle NIT'), lessThan(texts.indexOf('Safest NIT')));
  });

  testWidgets('a score band leads with the highest closing score', (tester) async {
    await pump(
      tester,
      response(
        [
          match(grade: 'historical_match', college: 'Easy BITS', score: 240, maxScore: 390),
          match(grade: 'historical_match', college: 'Hard BITS', score: 308, maxScore: 390),
          match(grade: 'borderline', college: 'Stretch BITS', score: 320, maxScore: 390),
        ],
        measure: 'score',
      ),
    );

    // The comparison flips: a higher score is the more competitive programme.
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(texts.indexOf('Hard BITS'), lessThan(texts.indexOf('Easy BITS')));
  });

  testWidgets('each band is labelled with the engine\'s own wording', (tester) async {
    await pump(
      tester,
      response([
        match(grade: 'borderline', college: 'A', rank: 30000),
        match(grade: 'historical_match', college: 'B', rank: 46000),
        match(grade: 'strong_historical_match', college: 'C', rank: 60000),
      ]),
    );

    // Not "safe" or "likely" -- those promise something the data cannot.
    expect(find.text('Borderline'), findsOneWidget);
    expect(find.text('Historical match'), findsOneWidget);
    expect(find.text('Strong historical match'), findsOneWidget);
  });

  testWidgets('nothing is shown when the results are all one band', (tester) async {
    await pump(
      tester,
      response([
        match(grade: 'borderline', college: 'A', rank: 30000),
        match(grade: 'borderline', college: 'B', rank: 31000),
      ]),
    );

    // Splitting one band out is just the top of the list again.
    expect(find.text('Best in each band'), findsNothing);
    expect(find.text('A'), findsNothing);
  });
}
