import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/num_format.dart';
import '../../../shortlist/presentation/save_button.dart';
import '../../domain/prediction_response.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});
  final PredictionMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = GradeColors.of(match.grade);
    // BITSAT admits on marks, so these rows carry a score band and no ranks.
    // Everything below reads one or the other, never a mix.
    final band = match.scoreBand;
    final maxScore = band?.maxScore;

    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(GradeColors.iconOf(match.grade), color: color),
        title: Row(
          children: [
            Flexible(
              child: Text(
                match.college.shortName ?? match.college.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _InstituteTypeBadge(type: match.college.type),
          ],
        ),
        // Two lines, because with real data the branch name alone is ambiguous.
        // A rank can match the same programme twice -- once in the OPEN pool
        // and once in the candidate's own category -- and those rows looked
        // identical when only the branch showed. The programme name matters
        // too: "B.Tech (ECE) - M.Tech in VLSI, 5 Years" is not plain ECE.
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.programName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                '${match.seatType}  ·  ${match.quota}  ·  ${match.college.state}',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SaveButton(collegeBranchId: match.collegeBranchId.toString()),
            const SizedBox(width: 2),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(match.gradeLabel,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                if (band?.weightedClosing != null)
                  Text('~${outOf(band!.weightedClosing!, maxScore)}',
                      style: TextStyle(
                          fontSize: 11, color: theme.colorScheme.onSurfaceVariant))
                else if (match.weightedClosingRank != null)
                  Text('~${plainNum(match.weightedClosingRank!)}',
                      style: TextStyle(
                          fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(match.genderPool),
              if (match.trend != 'unknown') _Pill('cutoff ${match.trend}'),
            ],
          ),
          const SizedBox(height: 14),
          _StatRow(
            label: band == null ? 'Weighted closing rank' : 'Weighted closing score',
            value: band != null
                ? (band.weightedClosing == null
                    ? '--'
                    : outOf(band.weightedClosing!, maxScore))
                : (match.weightedClosingRank == null
                    ? '--'
                    : plainNum(match.weightedClosingRank!)),
            hint: 'Recency-weighted over ${match.yearsAvailable} year'
                '${match.yearsAvailable == 1 ? '' : 's'}',
          ),
          if (band?.margin != null)
            _StatRow(
              label: band!.margin! >= 0 ? 'You are ahead by' : 'You are short by',
              value: plainNum(band.margin!.abs()),
              hint: 'marks',
            )
          else if (match.rankMargin != null)
            _StatRow(
              label: match.rankMargin! >= 0 ? 'You are ahead by' : 'You are behind by',
              value: plainNum(match.rankMargin!.abs()),
              hint: 'ranks',
            ),
          // Both pairs are printed low number first. For a rank that is the
          // strictest year; for a score it is the most lenient one, so the hint
          // has to say which -- the same ordering means opposite things.
          if (band?.easiestClosing != null && band?.toughestClosing != null)
            _StatRow(
              label: 'Historical range',
              value: '${plainNum(band!.easiestClosing!)} - '
                  '${plainNum(band.toughestClosing!)}',
              hint: 'most lenient to strictest year',
            )
          else if (match.bestClosingRank != null && match.worstClosingRank != null)
            _StatRow(
              label: 'Historical range',
              value: '${plainNum(match.bestClosingRank!)} - '
                  '${plainNum(match.worstClosingRank!)}',
              hint: 'strictest to most lenient year',
            ),
          if (match.cutoffHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(band == null ? 'Closing rank by year' : 'Closing score by year',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final y in match.cutoffHistory) _YearPill(year: y),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// IIT/NIT/IIIT badge on each card's title row.
///
/// The DB's college_type also has GFTI/STATE_GOVT/GOVT_AIDED/PRIVATE/DEEMED/
/// AUTONOMOUS values, but only IIT/NIT/IIIT are reliably classified -- import
/// defaults nearly everything else to GFTI and `ownership` to government, so
/// a real Govt/Private split isn't something the data can back up yet.
/// Everything outside the three known types reads as "Other" rather than a
/// specific, likely-wrong label.
class _InstituteTypeBadge extends StatelessWidget {
  const _InstituteTypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (type) {
      'IIT' => ('IIT', const Color(0xFF8B5CF6)),
      'NIT' => ('NIT', const Color(0xFF0891B2)),
      'IIIT' => ('IIIT', const Color(0xFFDB2777)),
      _ => ('Other', scheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
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
  const _YearPill({required this.year});
  final CutoffYear year;

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
          Text('${year.year}',
              style: TextStyle(fontSize: 10.5, color: scheme.outline)),
          // The paper total goes on every score pill, not only when it changes:
          // BITSAT was out of 450 until 2021 and 390 after, so a bare 306 next
          // to a bare 226 reads as a collapse when the two are near enough the
          // same standard.
          Text(
            year.isScore ? outOf(year.closing, year.max) : plainNum(year.closing),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          Text('R${year.round}',
              style: TextStyle(fontSize: 9.5, color: scheme.outline)),
        ],
      ),
    );
  }
}
