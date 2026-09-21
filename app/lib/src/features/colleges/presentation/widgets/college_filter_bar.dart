import 'package:flutter/material.dart';

import '../../../reference/domain/reference_data.dart';
import '../../data/colleges_repository.dart';

/// Filters above the college list.
///
/// Only the dimensions with honest data behind them. Two that were asked for
/// are missing on purpose:
///
///   Ownership — 580 colleges are "government" and 3 are "private", because
///               the importer defaults the column and nothing has ever set it.
///               A filter on it would sort by a field nobody filled in.
///   Rating    — college_accreditations holds no NIRF rows at all.
///
/// Both come back the day the data does.
class CollegeFilterBar extends StatelessWidget {
  const CollegeFilterBar({
    super.key,
    required this.filter,
    required this.states,
    required this.exams,
    required this.branches,
    required this.total,
    required this.onChanged,
  });

  final CollegeFilter filter;
  final List<LookupItem> states;
  final List<ExamOption> exams;
  final List<BranchOption> branches;
  final int? total;
  final ValueChanged<CollegeFilter> onChanged;

  /// GFTI reads as "Other" deliberately. The importer types anything it does
  /// not recognise as an IIT, NIT or IIIT that way, so 482 of 583 colleges are
  /// sitting in it; labelling that bucket "Government Funded Technical
  /// Institute" would assert something about them nobody checked.
  static const _types = [
    ('IIT', 'IIT'),
    ('NIT', 'NIT'),
    ('IIIT', 'IIIT'),
    ('DEEMED', 'Deemed'),
    ('GFTI', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Only exams a cutoff has been published for; the rest would filter to
    // nothing and read as a broken filter rather than missing data.
    final examOptions = [
      for (final e in exams)
        if (e.hasCutoffData) (e.code, e.name),
    ];
    final stateOptions = [for (final s in states) (s.code, s.name)];
    final branchOptions = [
      for (final b in branches)
        if (b.isPopular) (b.code, b.code),
    ];

    final anyOn = filter.type != null ||
        filter.stateCode != null ||
        filter.examCode != null ||
        filter.branchCode != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Picker(
                label: 'Type',
                allLabel: 'All types',
                value: filter.type,
                options: _types,
                onPick: (v) => onChanged(withType(filter, v)),
              ),
              _Picker(
                label: 'State',
                allLabel: 'All states',
                value: filter.stateCode,
                options: stateOptions,
                onPick: (v) => onChanged(withState(filter, v)),
              ),
              _Picker(
                label: 'Exam',
                allLabel: 'All exams',
                value: filter.examCode,
                options: examOptions,
                onPick: (v) => onChanged(withExam(filter, v)),
              ),
              _Picker(
                label: 'Branch',
                allLabel: 'All branches',
                value: filter.branchCode,
                options: branchOptions,
                onPick: (v) => onChanged(withBranch(filter, v)),
              ),
              if (anyOn)
                TextButton.icon(
                  onPressed: () => onChanged(withQuery(emptyCollegeFilter, filter.q)),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: 7),
            Text(
              anyOn ? '$total colleges match' : '$total colleges',
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// A dropdown that reads as a chip, lit when it is doing something.
class _Picker extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onPick,
  });

  final String label;
  final String allLabel;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = value != null;
    final shown = on
        ? options
            .firstWhere((o) => o.$1 == value, orElse: () => (value!, value!))
            .$2
        : label;

    return PopupMenuButton<String?>(
      tooltip: label,
      position: PopupMenuPosition.under,
      // null clears the filter rather than filtering on a magic "all" value.
      onSelected: onPick,
      itemBuilder: (_) => [
        PopupMenuItem<String?>(value: null, child: Text(allLabel)),
        const PopupMenuDivider(),
        for (final o in options)
          PopupMenuItem<String?>(value: o.$1, child: Text(o.$2)),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 7, 6, 7),
        decoration: BoxDecoration(
          color: on ? scheme.primaryContainer : Colors.transparent,
          border: Border.all(color: on ? scheme.primary : scheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                shown,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  color: on ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 19,
                color: on ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
