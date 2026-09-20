import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/num_format.dart';
import '../data/colleges_repository.dart';
import '../domain/college.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(compareSelectionProvider);
    final result = ref.watch(compareResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Colleges'),
        actions: [
          if (selected.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(compareSelectionProvider.notifier).state = [],
              child: const Text('Clear'),
            ),
        ],
      ),
      body: selected.length < 2
          ? _PickMore(count: selected.length)
          : result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e', textAlign: TextAlign.center),
                ),
              ),
              data: (r) => r == null ? _PickMore(count: selected.length) : _Table(result: r),
            ),
    );
  }
}

class _PickMore extends StatelessWidget {
  const _PickMore({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.balance_outlined, size: 44, color: scheme.outline),
              const SizedBox(height: 14),
              Text(
                count == 0
                    ? 'Pick colleges to compare'
                    : 'Pick one more college',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Tick the box on any college in the list. Two to four at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/colleges'),
                child: const Text('Browse colleges'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.result});
  final CompareResult result;

  static const _labelWidth = 104.0;
  static const _colWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cols = result.colleges;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        // Every cell is read at one seat dimension. Saying so on the page
        // matters: an OPEN All-India number next to an SC Home-State number
        // would look like a comparison and mean nothing.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Closing ranks shown for the '
                  '${result.seatDimension['seatType']} seat, '
                  '${result.seatDimension['quota']} quota, '
                  '${(result.seatDimension['gender'] as String).replaceAll('_', ' ').toLowerCase()} pool.',
                  style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(colleges: cols, labelWidth: _labelWidth, colWidth: _colWidth),
              const SizedBox(height: 4),
              _FactRow(label: 'Type', values: cols.map((c) => c.collegeType).toList(),
                  labelWidth: _labelWidth, colWidth: _colWidth),
              _FactRow(label: 'Location',
                  values: cols.map((c) => c.cityName ?? c.stateName).toList(),
                  labelWidth: _labelWidth, colWidth: _colWidth),
              _FactRow(label: 'NIRF',
                  values: cols.map((c) => c.nirfRank == null ? '--' : '#${c.nirfRank}').toList(),
                  labelWidth: _labelWidth, colWidth: _colWidth),
              _FactRow(label: 'Established',
                  values: cols.map((c) => c.establishedYear?.toString() ?? '--').toList(),
                  labelWidth: _labelWidth, colWidth: _colWidth),
              _FactRow(label: 'Hostel',
                  values: cols.map((c) => c.hasHostel == null
                      ? '--' : (c.hasHostel! ? 'Yes' : 'No')).toList(),
                  labelWidth: _labelWidth, colWidth: _colWidth),
              _FactRow(label: 'Programmes',
                  values: cols.map((c) => '${c.programmeCount}').toList(),
                  labelWidth: _labelWidth, colWidth: _colWidth),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Text('Closing rank by branch',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant)),
              ),
              for (final b in result.branches)
                _BranchRow(branch: b, colleges: cols,
                    labelWidth: _labelWidth, colWidth: _colWidth),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.colleges, required this.labelWidth, required this.colWidth});
  final List<CompareCollege> colleges;
  final double labelWidth;
  final double colWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: labelWidth),
        for (final c in colleges)
          SizedBox(
            width: colWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 6),
              child: Text(
                c.shortName ?? c.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ),
          ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.values,
    required this.labelWidth,
    required this.colWidth,
  });
  final String label;
  final List<String> values;
  final double labelWidth;
  final double colWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
          for (final v in values)
            SizedBox(
              width: colWidth,
              child: Text(v, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({
    required this.branch,
    required this.colleges,
    required this.labelWidth,
    required this.colWidth,
  });
  final CompareBranch branch;
  final List<CompareCollege> colleges;
  final double labelWidth;
  final double colWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final cells = colleges
        .map((c) => branch.byCollege[c.slug])
        .whereType<CompareCell>()
        .where((x) => x.latestClosing != null)
        .toList();

    // The most competitive figure in this row, so it can be marked -- the
    // LOWEST rank, or the HIGHEST score.
    //
    // Only when every populated cell uses the same measure. A row with BITS in
    // one column and an NIT in another holds a score of 308/390 and a rank of
    // 4,102, and there is no sense in which one of those is "better" than the
    // other; marking either would invent a comparison the data cannot make.
    final mixed = cells.map((x) => x.measure).toSet().length > 1;
    final values = cells.map((x) => x.latestClosing!);
    final best = mixed || values.isEmpty
        ? null
        : cells.first.isScore
            ? values.reduce((a, b) => a > b ? a : b)
            : values.reduce((a, b) => a < b ? a : b);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Tooltip(
              message: branch.name,
              child: Text(branch.code,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          for (final c in colleges)
            SizedBox(
              width: colWidth,
              child: Builder(builder: (_) {
                final cell = branch.byCollege[c.slug];
                if (cell?.latestClosing == null) {
                  return Text('--', style: TextStyle(fontSize: 12.5, color: scheme.outline));
                }
                final closing = cell!.latestClosing!;
                final isBest = best != null && closing == best;
                return Row(
                  children: [
                    Text(
                      cell.isScore
                          ? outOf(closing, cell.maxScore)
                          : plainNum(closing),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
                        color: isBest ? scheme.primary : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // The year matters: a programme with no recent data falls
                    // back to an older one, and comparing 2024 against 2026
                    // without saying so would be misleading.
                    Text("'${cell.latestYear.toString().substring(2)}",
                        style: TextStyle(fontSize: 10, color: scheme.outline)),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}
