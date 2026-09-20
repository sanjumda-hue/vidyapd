import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_controller.dart';
import '../../shared/num_format.dart';
import '../data/shortlist_repository.dart';

class ShortlistScreen extends ConsumerWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final signedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      // Sign out lives in the shell header now, on every page rather than
      // only this one, so a second button here would be the same action twice
      // on the same screen.
      appBar: AppBar(title: const Text('My Shortlist')),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : signedIn
              ? const _List()
              : const _SignedOut(),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

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
              Icon(Icons.favorite_border_rounded, size: 44, color: scheme.outline),
              const SizedBox(height: 14),
              const Text('Sign in to keep a shortlist',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Your saved programmes are tied to an account so they survive '
                'closing the tab. Predictions work without one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.push('/sign-in'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(shortlistProvider);
    final scheme = Theme.of(context).colorScheme;

    return entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text('$e')),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 40, color: scheme.outline),
                  const SizedBox(height: 12),
                  const Text('Nothing saved yet',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the heart on any prediction result or programme.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: list.length,
              // Preference order is the point of the list -- it mirrors a
              // choice-filling sheet -- so it is saved, not just displayed.
              onReorder: (from, to) async {
                final ids = list.map((e) => e.collegeBranchId).toList();
                final moved = ids.removeAt(from);
                ids.insert(to > from ? to - 1 : to, moved);
                await ref.read(shortlistRepositoryProvider).reorder(ids);
                ref.invalidate(shortlistProvider);
              },
              itemBuilder: (context, i) => _Row(
                key: ValueKey(list[i].collegeBranchId),
                index: i,
                entry: list[i],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({super.key, required this.index, required this.entry});
  final int index;
  final ShortlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/colleges/${entry.collegeSlug}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text('${index + 1}',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: scheme.outline)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.collegeName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(entry.programName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        entry.branchCode,
                        entry.stateName,
                        if (entry.latestClosing != null)
                          entry.isScore
                              // "closed at 308" would read as a rank.
                              ? 'closed ${outOf(entry.latestClosing!, entry.maxScore)} '
                                  'in ${entry.latestYear}'
                              : 'closed ${plainNum(entry.latestClosing!)} '
                                  'in ${entry.latestYear}',
                      ].join('  ·  '),
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () async {
                  await ref.read(shortlistRepositoryProvider).remove(entry.collegeBranchId);
                  ref.invalidate(shortlistProvider);
                  ref.invalidate(shortlistIdsProvider);
                },
                icon: Icon(Icons.favorite, size: 20, color: scheme.primary),
              ),
              Icon(Icons.drag_handle_rounded, size: 20, color: scheme.outlineVariant),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
