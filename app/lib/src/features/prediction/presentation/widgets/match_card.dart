import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/prediction_response.dart';

final _n = NumberFormat.decimalPattern('en_IN');

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});
  final PredictionMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = GradeColors.of(match.grade);

    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(GradeColors.iconOf(match.grade), color: color),
        title: Text(
          match.college.shortName ?? match.college.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${match.branch.name}  ·  ${match.college.state}',
            style: TextStyle(
                fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(match.gradeLabel,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
            if (match.weightedClosingRank != null)
              Text('~${_n.format(match.weightedClosingRank)}',
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(match.seatType),
              _Pill(match.quota),
              _Pill(match.genderPool),
              _Pill(match.college.type),
              if (match.trend != 'unknown') _Pill('cutoff ${match.trend}'),
            ],
          ),
          const SizedBox(height: 14),
          _StatRow(
            label: 'Weighted closing rank',
            value: match.weightedClosingRank == null
                ? '--'
                : _n.format(match.weightedClosingRank),
            hint: 'Recency-weighted over ${match.yearsAvailable} year'
                '${match.yearsAvailable == 1 ? '' : 's'}',
          ),
          if (match.rankMargin != null)
            _StatRow(
              label: match.rankMargin! >= 0 ? 'You are ahead by' : 'You are behind by',
              value: _n.format(match.rankMargin!.abs()),
              hint: 'ranks',
            ),
          if (match.bestClosingRank != null && match.worstClosingRank != null)
            _StatRow(
              label: 'Historical range',
              value:
                  '${_n.format(match.bestClosingRank)} - ${_n.format(match.worstClosingRank)}',
              hint: 'strictest to most lenient year',
            ),
          if (match.cutoffHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Closing rank by year',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final y in match.cutoffHistory)
                  _YearPill(year: y.year, closing: y.closing, round: y.round),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              if (hint != null)
                Text(hint!,
                    style: TextStyle(fontSize: 10.5, color: scheme.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  const _YearPill({required this.year, required this.closing, required this.round});
  final int year;
  final int closing;
  final int round;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$year',
              style: TextStyle(fontSize: 10.5, color: scheme.outline)),
          Text(_n.format(closing),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          Text('R$round',
              style: TextStyle(fontSize: 9.5, color: scheme.outline)),
        ],
      ),
    );
  }
}
