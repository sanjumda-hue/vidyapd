import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyapd/src/features/colleges/data/colleges_repository.dart';
import 'package:vidyapd/src/features/colleges/presentation/widgets/college_filter_bar.dart';
import 'package:vidyapd/src/features/reference/domain/reference_data.dart';

/// Picking a filter has to reach the provider key, and clearing one has to put
/// it back to null rather than to some sentinel the API would then search for.
/// Driving the popup through a browser needs a populated database and a
/// six-minute build, so it is pinned here.
void main() {
  final states = [
    const LookupItem(code: 'KA', name: 'Karnataka'),
    const LookupItem(code: 'TN', name: 'Tamil Nadu'),
  ];
  final exams = [
    const ExamOption(
        code: 'JEE_ADVANCED', name: 'JEE Advanced', level: 'national',
        hasPercentile: false, hasCutoffData: true),
    // No cutoffs, so it must not be offered: filtering on it returns nothing
    // and reads as a broken filter rather than as missing data.
    const ExamOption(
        code: 'VITEEE', name: 'VITEEE', level: 'university',
        hasPercentile: false, hasCutoffData: false),
  ];
  final branches = [
    const BranchOption(code: 'CSE', name: 'Computer Science', isPopular: true),
  ];

  Future<CollegeFilter?> tapThrough(
    WidgetTester tester, {
    required CollegeFilter start,
    required String chip,
    required String item,
  }) async {
    CollegeFilter? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CollegeFilterBar(
          filter: start,
          states: states,
          exams: exams,
          branches: branches,
          total: 583,
          onChanged: (f) => got = f,
        ),
      ),
    ));
    await tester.tap(find.text(chip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
    return got;
  }

  testWidgets('picking a type sets it and leaves the rest alone', (tester) async {
    final got = await tapThrough(
      tester,
      start: withQuery(emptyCollegeFilter, 'trichy'),
      chip: 'Type',
      item: 'IIT',
    );
    expect(got?.type, 'IIT');
    expect(got?.q, 'trichy', reason: 'the typed search survives a filter change');
    expect(got?.stateCode, isNull);
  });

  testWidgets('picking a state sends the code, not the display name', (tester) async {
    final got = await tapThrough(
      tester, start: emptyCollegeFilter, chip: 'State', item: 'Karnataka');
    expect(got?.stateCode, 'KA');
  });

  testWidgets('an exam with no cutoffs is not offered', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CollegeFilterBar(
          filter: emptyCollegeFilter,
          states: states,
          exams: exams,
          branches: branches,
          total: 0,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.tap(find.text('Exam'));
    await tester.pumpAndSettle();
    expect(find.text('JEE Advanced'), findsOneWidget);
    expect(find.text('VITEEE'), findsNothing);
  });

  testWidgets('"All" clears the filter rather than setting a sentinel', (tester) async {
    final got = await tapThrough(
      tester,
      start: withType(emptyCollegeFilter, 'IIT'),
      chip: 'IIT',
      item: 'All types',
    );
    expect(got?.type, isNull);
  });

  testWidgets('Clear drops every filter but keeps the search text', (tester) async {
    CollegeFilter? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CollegeFilterBar(
          filter: withState(withType(withQuery(emptyCollegeFilter, 'nit'), 'NIT'), 'TN'),
          states: states,
          exams: exams,
          branches: branches,
          total: 1,
          onChanged: (f) => got = f,
        ),
      ),
    ));
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(got?.type, isNull);
    expect(got?.stateCode, isNull);
    expect(got?.q, 'nit');
  });
}
