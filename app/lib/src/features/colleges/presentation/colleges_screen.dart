import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../reference/data/reference_repository.dart';
import '../data/colleges_repository.dart';
import '../domain/college.dart';
import 'widgets/college_filter_bar.dart';

class CollegesScreen extends ConsumerStatefulWidget {
  const CollegesScreen({super.key});

  @override
  ConsumerState<CollegesScreen> createState() => _CollegesScreenState();
}

class _CollegesScreenState extends ConsumerState<CollegesScreen> {
  CollegeFilter _filter = emptyCollegeFilter;
  Timer? _debounce;

  void _set(CollegeFilter next) => setState(() => _filter = next);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Search on a pause, not on every keystroke: each query is a database hit.
  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _set(withQuery(_filter, v.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(collegeSearchProvider(_filter));
    final selected = ref.watch(compareSelectionProvider);
    final reference = ref.watch(referenceDataProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colleges'),
        actions: [
          if (selected.length >= 2)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                onPressed: () => context.push('/compare'),
                icon: const Icon(Icons.balance_outlined, size: 18),
                label: Text('Compare ${selected.length}'),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: _onChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, e.g. "Tiruchirappalli" or "IIIT"',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              CollegeFilterBar(
                filter: _filter,
                states: reference?.states ?? const [],
                exams: reference?.exams ?? const [],
                branches: reference?.branches ?? const [],
                total: results.valueOrNull?.total,
                onChanged: _set,
              ),
              Expanded(
                child: results.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('$e', textAlign: TextAlign.center),
                    ),
                  ),
                  data: (r) => r.items.isEmpty
                      ? const Center(child: Text('No colleges match that search.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          itemCount: r.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _CollegeCard(
                            college: r.items[i],
                            selected: selected.contains(r.items[i].slug),
                            onToggle: () => _toggle(r.items[i].slug),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(String slug) {
    final notifier = ref.read(compareSelectionProvider.notifier);
    final current = [...notifier.state];
    if (current.contains(slug)) {
      current.remove(slug);
    } else {
      // The API compares at most four; say so rather than failing the request.
      if (current.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can compare up to four colleges.')),
        );
        return;
      }
      current.add(slug);
    }
    notifier.state = current;
  }
}

class _CollegeCard extends StatelessWidget {
  const _CollegeCard({
    required this.college,
    required this.selected,
    required this.onToggle,
  });

  final CollegeListItem college;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/colleges/${college.slug}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(college.shortName ?? college.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        college.collegeType,
                        college.cityName ?? college.stateName,
                        '${college.programmeCount} programmes',
                        if (college.nirfRank != null) 'NIRF #${college.nirfRank}',
                      ].join('  ·  '),
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: selected ? 'Remove from comparison' : 'Add to comparison',
                child: IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
