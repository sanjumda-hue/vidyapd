import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../reference/data/reference_repository.dart';
import '../../shared/num_format.dart';
import '../../shared/page_heading.dart';
import '../data/mock_repository.dart';

/// Upload a paper's answer key, then a response sheet, and see the score.
///
/// The scoring is the server's: the marking scheme lives on the paper, because
/// it differs by exam and by year. Nothing here decides what an answer is
/// worth.
class MockScreen extends ConsumerStatefulWidget {
  const MockScreen({super.key});

  @override
  ConsumerState<MockScreen> createState() => _MockScreenState();
}

class _MockScreenState extends ConsumerState<MockScreen> {
  final _title = TextEditingController();
  String? _examCode;
  String? _keyCsv;
  String? _keyName;

  int? _paperId;
  String? _responsesName;

  MockResult? _result;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// Read the bytes rather than the path: on the web a picked file has no
  /// path, and these are two small CSVs either way.
  Future<({String name, String text})?> _pickCsv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    // allowMalformed, so a sheet saved from Excel in a non-UTF-8 codepage
    // still scores instead of throwing on one stray byte in a heading.
    return (name: file.name, text: utf8.decode(bytes, allowMalformed: true));
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } catch (e) {
      // The server's message names the row and column that went wrong; that is
      // more use to someone holding a spreadsheet than "upload failed".
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPaper() => _run(() async {
        final id = await ref.read(mockRepositoryProvider).createPaper(
              examCode: _examCode!,
              title: _title.text.trim(),
              answerKeyCsv: _keyCsv!,
            );
        ref.invalidate(mockPapersProvider);
        if (mounted) setState(() => _paperId = id);
      });

  Future<void> _submit(String csv) => _run(() async {
        final r = await ref.read(mockRepositoryProvider).submit(_paperId!, csv);
        if (mounted) setState(() => _result = r);
      });

  @override
  Widget build(BuildContext context) {
    final referenceAsync = ref.watch(referenceDataProvider);
    final reference = referenceAsync.valueOrNull;
    final papers = ref.watch(mockPapersProvider);
    final canCreate =
        _examCode != null && _keyCsv != null && _title.text.trim().length >= 3 && !_busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Mock Test')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          const PageHeading(
            icon: Icons.fact_check_rounded,
            title: 'Score a mock test',
            subtitle: 'Upload the answer key, then your response sheet.',
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            _ErrorBox(message: _error!),
            const SizedBox(height: 14),
          ],

          // The exam dropdown is built from this list, and a dropdown with no
          // items renders as a field that does nothing when clicked. Rather
          // than leave that unexplained, say the list did not load and offer
          // the retry -- the rest of the page still works from a paper that
          // was uploaded earlier.
          if (referenceAsync.hasError) ...[
            _ErrorBox(
              message: 'Could not load the exam list, so a new paper cannot be '
                  'uploaded yet. ${referenceAsync.error}',
              onRetry: () => ref.invalidate(referenceDataProvider),
            ),
            const SizedBox(height: 14),
          ],

          _Step(
            n: 1,
            title: 'The paper and its answer key',
            done: _paperId != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _examCode,
                        hint: Text(switch (referenceAsync) {
                          AsyncError() => 'Exam list unavailable',
                          AsyncLoading() => 'Loading exams…',
                          _ => 'Exam',
                        }),
                        items: [
                          for (final e in reference?.exams ?? const [])
                            DropdownMenuItem(
                              value: e.code,
                              child: Text(e.name, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: _paperId != null
                            ? null
                            : (v) => setState(() => _examCode = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _title,
                        enabled: _paperId == null,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Paper name',
                          hintText: 'JEE Main 2025, Session 1 Shift 1',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FileRow(
                  label: 'Answer key (.csv)',
                  fileName: _keyName,
                  hint: 'Columns: Question No, Section, Type, Correct Answer',
                  enabled: _paperId == null && !_busy,
                  onPick: () async {
                    final f = await _pickCsv();
                    if (f != null) setState(() { _keyCsv = f.text; _keyName = f.name; });
                  },
                ),
                const SizedBox(height: 12),
                if (_paperId == null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: canCreate ? _createPaper : null,
                    icon: _busy
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload answer key'),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _paperId = null;
                      _result = null;
                      _responsesName = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Use a different paper'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _Step(
            n: 2,
            title: 'Your response sheet',
            done: _result != null,
            enabled: _paperId != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FileRow(
                  label: 'Responses (.csv)',
                  fileName: _responsesName,
                  hint: 'Columns: Question No, Your Answer. Leave a blank for unattempted.',
                  enabled: _paperId != null && !_busy,
                  onPick: () async {
                    final f = await _pickCsv();
                    if (f == null) return;
                    setState(() => _responsesName = f.name);
                    await _submit(f.text);
                  },
                ),
              ],
            ),
          ),

          if (_result != null) ...[
            const SizedBox(height: 18),
            _ResultCard(result: _result!),
          ],

          const SizedBox(height: 24),
          papers.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : _PreviousPapers(
                    papers: list,
                    selectedId: _paperId,
                    onPick: (p) => setState(() {
                      _paperId = p.id;
                      _examCode = p.examCode;
                      _title.text = p.title;
                      _result = null;
                      _responsesName = null;
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.child,
    this.done = false,
    this.enabled = true,
  });

  final int n;
  final String title;
  final Widget child;
  final bool done;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: done ? Brand.deep : scheme.surfaceContainerHighest,
                      child: done
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : Text('$n',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 10),
                    Text(title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.label,
    required this.fileName,
    required this.hint,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final String? fileName;
  final String hint;
  final bool enabled;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: enabled ? onPick : null,
              icon: const Icon(Icons.attach_file_rounded, size: 17),
              label: Text(fileName == null ? 'Choose $label' : 'Replace'),
            ),
            if (fileName != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(hint, style: TextStyle(fontSize: 11.5, color: scheme.outline)),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final MockResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.paperTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(
              // The scheme is shown, not just the total: a student comparing
              // two mocks needs to know one of them penalised wrong answers.
              '${result.examCode}  ·  +${plainNum(result.marksCorrect)} correct, '
              '−${plainNum(result.marksWrong)} wrong',
              style: TextStyle(fontSize: 11.5, color: scheme.outline),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plainNum(result.score),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: dark ? Brand.light : Brand.deep,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('/ ${plainNum(result.maxMarks)}',
                      style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
                ),
                const Spacer(),
                Text('${result.percentage}%',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tally('Correct', result.correct, GradeColors.match),
                _Tally('Wrong', result.wrong, GradeColors.borderline),
                _Tally('Skipped', result.skipped, GradeColors.outside),
              ],
            ),
            if (result.sections.length > 1) ...[
              const SizedBox(height: 16),
              Text('By section',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 7),
              for (final s in result.sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.section, style: const TextStyle(fontSize: 12.5))),
                      Text(
                        '${plainNum(s.score)}   ·   ${s.correct} right, ${s.wrong} wrong, ${s.skipped} left',
                        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Text('Every question',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final a in result.answers) _QuestionChip(answer: a)],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text('$count $label',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
      );
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.answer});
  final MockAnswer answer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Three states. A blank is grey, never red: the student did not get it
    // wrong, they did not answer it.
    final (color, icon) = switch (answer.status) {
      'correct' => (GradeColors.match, Icons.check_rounded),
      'wrong' => (GradeColors.borderline, Icons.close_rounded),
      _ => (scheme.outline, Icons.remove_rounded),
    };

    return Tooltip(
      message: 'Q${answer.questionNo}  ·  '
          'you: ${answer.givenAnswer ?? "—"}  ·  key: ${answer.correctAnswer}  ·  '
          '${answer.awarded > 0 ? "+" : ""}${plainNum(answer.awarded)}',
      child: Container(
        width: 34,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text('${answer.questionNo}',
                style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
            Icon(icon, size: 13, color: color),
          ],
        ),
      ),
    );
  }
}

class _PreviousPapers extends StatelessWidget {
  const _PreviousPapers({
    required this.papers,
    required this.selectedId,
    required this.onPick,
  });

  final List<MockPaper> papers;
  final int? selectedId;
  final ValueChanged<MockPaper> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Papers already uploaded',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (final p in papers)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              selected: p.id == selectedId,
              title: Text(p.title, style: const TextStyle(fontSize: 13.5)),
              subtitle: Text(
                '${p.examCode}  ·  ${p.totalQuestions} questions  ·  '
                '${plainNum(p.maxMarks)} marks  ·  +${plainNum(p.marksCorrect)}/−${plainNum(p.marksWrong)}',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: TextButton(onPressed: () => onPick(p), child: const Text('Use')),
            ),
          ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: scheme.onErrorContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12.5, color: scheme.onErrorContainer)),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 9),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
