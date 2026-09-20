import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/num_format.dart';
import '../data/colleges_repository.dart';
import '../domain/college.dart';

class CollegeDetailScreen extends ConsumerWidget {
  const CollegeDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(collegeDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.valueOrNull?.college.shortName ??
            detail.valueOrNull?.college.name ??
            'College'),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (d) => _Body(detail: d),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});
  final CollegeDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = detail.college;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(c.name, style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _Chip(c.collegeType),
                _Chip(c.ownership.replaceAll('_', ' ')),
                _Chip([c.cityName, c.stateName].whereType<String>().join(', ')),
                if (c.establishedYear != null) _Chip('Est. ${c.establishedYear}'),
                if (c.nirfRank != null) _Chip('NIRF #${c.nirfRank} (${c.nirfYear})'),
                if (c.hasHostel == true) _Chip('Hostel'),
              ],
            ),
            if (c.about != null && c.about!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(c.about!, style: theme.textTheme.bodyMedium),
            ],

            const SizedBox(height: 22),
            _SectionTitle('Cutoff data available'),
            const SizedBox(height: 8),
            if (detail.authorities.isEmpty)
              Text('No published cutoffs for this college yet.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
            else
              // Which counselling bodies admit here matters: a student needs to
              // know whether to look at JoSAA, CSAB or a state process.
              Column(
                children: [
                  for (final a in detail.authorities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(a.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Text(
                            '${a.years.first}-${a.years.last}  ·  ${plainNum(a.rows)} rows',
                            style: TextStyle(
                                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 22),
            _SectionTitle('Programmes  (${detail.programmes.length})'),
            const SizedBox(height: 4),
            Text(
              'Closing rank shown is the open general seat in the most recent '
              'year that has data.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            for (final p in detail.programmes) _ProgrammeRow(programme: p),
          ],
        ),
      ),
    );
  }
}

class _ProgrammeRow extends StatelessWidget {
  const _ProgrammeRow({required this.programme});
  final CollegeProgramme programme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A BITS programme closes at a SCORE, not a rank, and the paper total goes
    // with it: 308 alone is unreadable, 308/390 is not.
    final closing = programme.latestClosing == null
        ? null
        : num.tryParse(programme.latestClosing!);
    final maxScore = programme.latestMaxScore == null
        ? null
        : num.tryParse(programme.latestMaxScore!);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(programme.branchCode,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(programme.programName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.25)),
                const SizedBox(height: 2),
                Text(
                  [
                    programme.degree,
                    if (programme.durationYears != null)
                      '${programme.durationYears!.replaceAll('.0', '')} yr',
                    if (programme.totalIntake != null) '${programme.totalIntake} seats',
                  ].join('  ·  '),
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                closing == null
                    ? '--'
                    : programme.isScore
                        ? outOf(closing, maxScore)
                        : plainNum(closing),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              Text(
                closing == null
                    ? 'no data'
                    : programme.isScore
                        ? 'score, ${programme.latestYear}'
                        : 'closed ${programme.latestYear}',
                style: TextStyle(fontSize: 10.5, color: scheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700));
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(text, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
    );
  }
}
