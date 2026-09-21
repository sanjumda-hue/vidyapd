import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';

/// A paper that has been uploaded, with the scheme it will be scored under.
class MockPaper {
  MockPaper.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        title = j['title'] as String,
        examCode = (j['exam'] as Map<String, dynamic>)['code'] as String,
        examName = (j['exam'] as Map<String, dynamic>)['name'] as String,
        academicYear = j['academicYear'] as int?,
        totalQuestions = j['totalQuestions'] as int,
        maxMarks = (j['maxMarks'] as num).toDouble(),
        marksCorrect = (j['marksCorrect'] as num).toDouble(),
        marksWrong = (j['marksWrong'] as num).toDouble(),
        attempts = j['attempts'] as int;

  final int id;
  final String title;
  final String examCode;
  final String examName;
  final int? academicYear;
  final int totalQuestions;
  final double maxMarks;
  final double marksCorrect;
  final double marksWrong;
  final int attempts;
}

/// One scored question.
class MockAnswer {
  MockAnswer.fromJson(Map<String, dynamic> j)
      : questionNo = j['questionNo'] as int,
        section = j['section'] as String?,
        givenAnswer = j['givenAnswer'] as String?,
        correctAnswer = j['correctAnswer'] as String,
        // 'correct' | 'wrong' | 'skipped'. Read this, not isCorrect: that is
        // false for a blank too, and colouring from it marks a question the
        // student never answered as one they got wrong.
        status = j['status'] as String,
        awarded = (j['awarded'] as num).toDouble();

  final int questionNo;
  final String? section;
  final String? givenAnswer;
  final String correctAnswer;
  final String status;
  final double awarded;
}

class MockSection {
  MockSection.fromJson(Map<String, dynamic> j)
      : section = j['section'] as String,
        score = (j['score'] as num).toDouble(),
        correct = j['correct'] as int,
        wrong = j['wrong'] as int,
        skipped = j['skipped'] as int;

  final String section;
  final double score;
  final int correct;
  final int wrong;
  final int skipped;
}

class MockResult {
  MockResult.fromJson(Map<String, dynamic> j)
      : score = (j['score'] as num).toDouble(),
        maxMarks = (j['maxMarks'] as num).toDouble(),
        percentage = (j['percentage'] as num).toDouble(),
        correct = j['correct'] as int,
        wrong = j['wrong'] as int,
        skipped = j['skipped'] as int,
        paperTitle = ((j['paper'] as Map<String, dynamic>)['title']) as String,
        examCode = (((j['paper'] as Map<String, dynamic>)['exam']
            as Map<String, dynamic>)['code']) as String,
        marksCorrect = ((j['scheme'] as Map<String, dynamic>)['marksCorrect'] as num).toDouble(),
        marksWrong = ((j['scheme'] as Map<String, dynamic>)['marksWrong'] as num).toDouble(),
        sections = [
          for (final s in (j['sections'] as List))
            MockSection.fromJson(s as Map<String, dynamic>)
        ],
        answers = [
          for (final a in (j['answers'] as List))
            MockAnswer.fromJson(a as Map<String, dynamic>)
        ];

  final double score;
  final double maxMarks;
  final double percentage;
  final int correct;
  final int wrong;
  final int skipped;
  final String paperTitle;
  final String examCode;
  final double marksCorrect;
  final double marksWrong;
  final List<MockSection> sections;
  final List<MockAnswer> answers;
}

class MockRepository {
  MockRepository(this._api);
  final dynamic _api;

  Future<List<MockPaper>> papers() async {
    final json = await _api.get<List<dynamic>>('/mock/papers');
    return [for (final p in json) MockPaper.fromJson(p as Map<String, dynamic>)];
  }

  /// Uploads an answer key. The marking scheme is left to the server unless
  /// given: it knows the published one for the exams that have a fixed one and
  /// refuses rather than guessing for the ones that do not.
  Future<int> createPaper({
    required String examCode,
    required String title,
    required String answerKeyCsv,
    int? academicYear,
    double? marksCorrect,
    double? marksWrong,
    double? numericTolerance,
  }) async {
    final json = await _api.post<Map<String, dynamic>>('/mock/papers', body: {
      'examCode': examCode,
      'title': title,
      'answerKeyCsv': answerKeyCsv,
      if (academicYear != null) 'academicYear': academicYear,
      if (marksCorrect != null) 'marksCorrect': marksCorrect,
      if (marksWrong != null) 'marksWrong': marksWrong,
      if (numericTolerance != null) 'numericTolerance': numericTolerance,
    });
    return json['id'] as int;
  }

  Future<MockResult> submit(int paperId, String responsesCsv) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/mock/papers/$paperId/attempts',
      body: {'responsesCsv': responsesCsv},
    );
    return MockResult.fromJson(json);
  }
}

final mockRepositoryProvider = Provider<MockRepository>(
  (ref) => MockRepository(ref.watch(apiClientProvider)),
);

final mockPapersProvider = FutureProvider<List<MockPaper>>(
  (ref) => ref.watch(mockRepositoryProvider).papers(),
);
