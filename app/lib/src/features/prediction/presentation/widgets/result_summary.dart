import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/num_format.dart';
import '../../application/prediction_controller.dart';
import '../../domain/prediction_response.dart';

const _gradeOrder = [
  ('strong_historical_match', 'Strong'),
  ('historical_match', 'Match'),
  ('borderline', 'Borderline'),
];

class ResultSummary extends ConsumerWidget {
  const ResultSummary({super.key, required this.response});
  final PredictionResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedGradeFilterProvider);
    // The fetched list is a fair-share sample across bands, not the full
    // result set -- response.counts holds the true per-band totals. When a
    // band is selected, say so rather than implying the sample is everything.
    final shown = selected == null
        ? response.matches.length
        : response.matches.where((m) => m.grade == selected).length;
    final trueTotal =
        selected == null ? response.matches.length : (response.counts[selected] ?? shown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shown == trueTotal ? '$shown results' : 'Showing $shown of $trueTotal results',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${response.exam.name}  ·  ${_measure(response)}  ·  '
          '${response.category}${response.homeState != null ? '  ·  ${response.homeState}' : ''}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (response.rankIsEstimated && response.rankUsed != null) ...[
          const SizedBox(height: 8),
          // The student typed a percentile; this rank was derived. Saying so is
          // not optional -- see docs/04-prediction-engine.md.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rank ${response.rankUsed} is an estimate converted from your '
              'percentile (${response.rankEstimateMethod ?? 'estimated'}).',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CountChip(
              label: 'All',
              count: response.matches.length,
              color: theme.colorScheme.primary,
              selected: selected == null,
              onTap: () => ref.read(selectedGradeFilterProvider.notifier).state = null,
            ),
            for (final (key, label) in _gradeOrder)
              if ((response.counts[key] ?? 0) > 0)
                _CountChip(
                  label: label,
                  count: response.counts[key]!,
                  color: GradeColors.of(key),
                  selected: selected == key,
                  // Tapping the already-selected chip clears back to All.
                  onTap: () => ref.read(selectedGradeFilterProvider.notifier).state =
                      selected == key ? null : key,
                ),
          ],
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: color.withValues(alpha: selected ? 0.9 : 0.35),
                width: selected ? 1.4 : 1),
          ),
          child: Text('$count $label',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        ),
      );
}

/// How the run is described in the summary line: "rank 45821", or "300/390"
/// for an exam that admits on marks.
String _measure(PredictionResponse r) => r.isScoreBased
    ? '${outOf(r.scoreUsed!, r.maxScoreUsed)} marks'
    : 'rank ${r.rankUsed}';
