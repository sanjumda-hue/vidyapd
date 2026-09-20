import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_controller.dart';
import '../data/shortlist_repository.dart';

/// Heart toggle used on prediction results and programme rows.
///
/// When signed out it does not hide -- it offers the sign-in, because a
/// disappearing control is more confusing than one that explains itself.
class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.collegeBranchId, this.size = 20});

  final String collegeBranchId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final signedIn = ref.watch(isSignedInProvider);
    final saved = ref.watch(shortlistIdsProvider).valueOrNull?.contains(collegeBranchId) ?? false;

    return IconButton(
      tooltip: !signedIn
          ? 'Sign in to save'
          : saved
              ? 'Remove from shortlist'
              : 'Save to shortlist',
      iconSize: size,
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        if (!signedIn) {
          context.push('/sign-in');
          return;
        }
        final repo = ref.read(shortlistRepositoryProvider);
        saved ? await repo.remove(collegeBranchId) : await repo.add(collegeBranchId);
        ref.invalidate(shortlistIdsProvider);
        ref.invalidate(shortlistProvider);
      },
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_border_rounded,
        color: saved ? scheme.primary : scheme.outline,
      ),
    );
  }
}
