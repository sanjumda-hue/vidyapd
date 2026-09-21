import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/num_format.dart';
import '../../domain/prediction_response.dart';

/// The strongest option in each band, so the whole list does not have to be
/// read to find them.
///
/// Sorting the full list by the composite fit score was the obvious way to do
/// this and it is wrong. That score is a logistic on cut-off over rank, so it
/// rises as a programme gets easier: descending by it put the least
/// competitive college in the set at the top and buried what the student
/// actually wanted. 015_prediction_ordering.sql made the same correction to
/// the engine.
///
/// What is useful is the most competitive programme WITHIN each band -- a
/// reachable stretch, a realistic pick, and something held in reserve. That is
/// also the shape of a counselling choice list, which is filled across all
/// three.
///
/// The bands are the engine's own grades, under their own labels. Naming them
/// "safe" or "likely" would promise something the data cannot: every one of
/// these is a historical match, never an assurance of a seat.
class BestPicks extends StatelessWidget {
  const BestPicks({super.key, required this.response});

  final PredictionResponse response;

  static const _perBand = 3;

  /// Best first. A rank is better when it is lower and a score when it is
  /// higher, so the comparison flips with the measure.
  int _byBest(PredictionMatch a, PredictionMatch b) {
    if (response.isScoreBased) {
      final x = a.scoreBand?.weightedClosing ?? -1;
      final y = b.scoreBand?.weightedClosing ?? -1;
      return y.compareTo(x);
    }
    final x = a.weightedClosingRank ?? 1 << 30;
    final y = b.weightedClosingRank ?? 1 << 30;
    return x.compareTo(y);
  }

  @override
  Widget build(BuildContext context) {
    final bands = <_Band>[
      const _Band('borderline', 'closed tighter than your entry in most years'),
      const _Band('historical_match', 'closed around your entry'),
      const _Band('strong_historical_match', 'closed well clear of your entry'),
    ];

    final filled = <_Band, List<PredictionMatch>>{};
    for (final b in bands) {
      final rows = response.matches.where((m) => m.grade == b.grade).toList()
        ..sort(_byBest);
      if (rows.isNotEmpty) filled[b] = rows;
    }
    // One band on its own is just the top of the list again.
    if (filled.length < 2) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best in each band',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'The most competitive programme in each band, not the safest. '
          'The full list is below.',
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 720
                ? [
                    for (final e in filled.entries)
                      Expanded(child: _BandCard(band: e.key, rows: e.value, response: response)),
                  ]
                : null;
            if (columns == null) {
              return Column(
                children: [
                  for (final e in filled.entries) ...[
                    _BandCard(band: e.key, rows: e.value, response: response),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < columns.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  columns[i],
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Band {
  const _Band(this.grade, this.hint);
  final String grade;
  final String hint;
}

class _BandCard extends StatelessWidget {
  const _BandCard({required this.band, required this.rows, required this.response});

  final _Band band;
  final List<PredictionMatch> rows;
  final PredictionResponse response;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = GradeColors.of(band.grade);
    final shown = rows.take(BestPicks._perBand).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GradeColors.iconOf(band.grade), size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // The engine's own wording, not a friendlier synonym.
                  shown.first.gradeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              // The size of the whole band, matching the chip above -- not the
              // handful sampled into this card. Two different numbers for the
              // same thing on one screen is just a puzzle.
              Text('${response.counts[band.grade] ?? rows.length}',
                  style: TextStyle(fontSize: 11.5, color: scheme.outline)),
            ],
          ),
          const SizedBox(height: 1),
          Text(band.hint,
              style: TextStyle(fontSize: 10.5, color: scheme.outline, height: 1.3)),
          const SizedBox(height: 8),
          for (final m in shown) ...[
            _PickRow(match: m, isScore: response.isScoreBased),
            if (m != shown.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.match, required this.isScore});

  final PredictionMatch match;
  final bool isScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final band = match.scoreBand;
    final closing = isScore
        ? (band?.weightedClosing == null
            ? '--'
            : outOf(band!.weightedClosing!, band.maxScore))
        : (match.weightedClosingRank == null
            ? '--'
            : plainNum(match.weightedClosingRank!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          match.college.shortName ?? match.college.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        Text(
          '${match.branch.code}  ·  ~$closing',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
