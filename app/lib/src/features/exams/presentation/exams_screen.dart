import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exams_repository.dart';

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrance Exams')),
      body: exams.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          // Group by level so national exams are not buried among state CETs.
          final byLevel = <String, List<ExamSummary>>{};
          for (final e in list) {
            byLevel.putIfAbsent(e.level, () => []).add(e);
          }
          const order = ['national', 'deemed', 'university', 'state'];
          const titles = {
            'national': 'National',
            'deemed': 'Deemed university',
            'university': 'University',
            'state': 'State',
          };

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (final level in order)
                    if (byLevel[level] != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
                        child: Text(
                          '${titles[level]}  (${byLevel[level]!.length})',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      for (final e in byLevel[level]!) ...[
                        _ExamTile(exam: e),
                        const SizedBox(height: 8),
                      ],
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.exam});
  final ExamSummary exam;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(exam.shortName ?? exam.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (exam.stateName != null)
                  Text(exam.stateName!,
                      style: TextStyle(fontSize: 11.5, color: scheme.outline)),
              ],
            ),
            const SizedBox(height: 4),
            Text(exam.authority,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
