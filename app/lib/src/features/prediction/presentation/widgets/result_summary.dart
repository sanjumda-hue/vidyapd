import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/prediction_response.dart';

const _gradeOrder = [
  ('strong_historical_match', 'Strong'),
  ('historical_match', 'Match'),
  ('borderline', 'Borderline'),
];

class ResultSummary extends StatelessWidget {
  const ResultSummary({super.key, required this.response});
  final PredictionResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${response.matches.length} results',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          '${response.exam.name}  ·  rank ${response.rankUsed}  ·  '
          '${response.category}${response.homeState != null ? '  ·  ${response.homeState}' : ''}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (response.rankIsEstimated) ...[
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
            for (final (key, label) in _gradeOrder)
              if ((response.counts[key] ?? 0) > 0)
                _CountChip(
                  label: label,
                  count: response.counts[key]!,
                  color: GradeColors.of(key),
                ),
          ],
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text('$count $label',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
      );
}
