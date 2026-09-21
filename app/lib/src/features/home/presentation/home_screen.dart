import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../reference/data/reference_repository.dart';
import '../../shared/page_heading.dart';

class _Tile {
  const _Tile(this.icon, this.label, this.route, {this.ready = false});
  final IconData icon;
  final String label;
  final String route;
  final bool ready;
}

const _tiles = [
  _Tile(Icons.auto_graph_rounded, 'Predict My College', '/predict', ready: true),
  _Tile(Icons.school_outlined, 'Entrance Exams', '/exams', ready: true),
  _Tile(Icons.calendar_month_outlined, 'Exam Calendar', '/calendar'),
  _Tile(Icons.apartment_outlined, 'Colleges', '/colleges', ready: true),
  _Tile(Icons.workspace_premium_outlined, 'Branches', '/branches'),
  _Tile(Icons.fact_check_outlined, 'Mock Test', '/mock', ready: true),
  _Tile(Icons.balance_outlined, 'Compare Colleges', '/compare', ready: true),
  _Tile(Icons.favorite_border_rounded, 'My Shortlist', '/shortlist', ready: true),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm the lookup cache here so the predict form opens instantly.
    final reference = ref.watch(referenceDataProvider);

    return Scaffold(
      // The shell paints the canvas and owns the brand header, so this page
      // starts at its own heading rather than repeating the product name.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        children: [
          const PageHeading(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            subtitle: 'Explore Exams  •  Compare Colleges  •  Predict Branches',
          ),
          const SizedBox(height: 18),
          reference.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => _ConnectionError(message: '$e', onRetry: () {
              ref.invalidate(referenceDataProvider);
            }),
            data: (d) => _Stat(
              'Connected  ·  ${d.exams.length} exams  ·  '
              '${d.branches.length} branches  ·  ${d.states.length} states',
            ),
          ),
          const SizedBox(height: 18),
          // A desktop window is wide, so the grid grows columns instead of
          // stretching four cards across a metre of screen.
          LayoutBuilder(
            builder: (context, c) {
              final columns = switch (c.maxWidth) {
                > 1180 => 5,
                > 900 => 4,
                > 620 => 3,
                _ => 2,
              };
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                // Wide and short. The card holds an icon and one line of text,
                // and a taller box just puts empty space between them.
                childAspectRatio: 3.1,
                children: [
                  for (final t in _tiles) _TileCard(tile: t),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({required this.tile});
  final _Tile tile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(tile.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Brand.selected(Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  tile.icon,
                  size: 22,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Brand.deep
                      : Brand.light,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  tile.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (!tile.ready)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('soon',
                      style: TextStyle(
                          fontSize: 10.5, color: scheme.onSurfaceVariant)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 15, color: scheme.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: TextStyle(fontSize: 13, color: scheme.onErrorContainer)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
