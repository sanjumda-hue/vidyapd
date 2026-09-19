import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../reference/data/reference_repository.dart';

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
  _Tile(Icons.apartment_outlined, 'Colleges', '/colleges'),
  _Tile(Icons.workspace_premium_outlined, 'Branches', '/branches'),
  _Tile(Icons.balance_outlined, 'Compare Colleges', '/compare'),
  _Tile(Icons.favorite_border_rounded, 'My Shortlist', '/shortlist'),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Warm the lookup cache here so the predict form opens instantly.
    final reference = ref.watch(referenceDataProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                Text('B.Tech Admission Predictor',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Explore Exams  •  Compare Colleges  •  Predict Branches',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) => GridView.count(
                    crossAxisCount: c.maxWidth > 560 ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      for (final t in _tiles) _TileCard(tile: t),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(tile.icon, size: 26, color: scheme.primary),
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
              Text(tile.label,
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2)),
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
