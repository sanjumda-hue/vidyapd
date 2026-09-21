import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_controller.dart';
import '../../features/prediction/application/prediction_controller.dart';
import '../theme/app_theme.dart';
import 'shell_state.dart';

/// The desktop chrome: a fixed icon rail down the left, a brand header across
/// the top, and the current route in the remaining space.
///
/// Purely presentational. It reads the signed-in user to label the avatar and
/// calls the existing sign-out, and otherwise adds no behaviour of its own --
/// every screen inside it works exactly as it did standing alone.
///
/// Below [_narrow] the rail would leave too little room for a results table, so
/// it folds into a drawer and the header grows a menu button. The same widgets
/// are used either way.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double _narrow = 860;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final compact = MediaQuery.sizeOf(context).width < _narrow;
    // On a cold start the stored token is still being checked. Rendering the
    // page now would flash real content at someone who may turn out to be
    // signed out, so the chrome goes up and the content waits.
    final deciding = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Brand.canvas(brightness),
      drawer: compact
          ? Drawer(
              backgroundColor: Brand.rail(brightness),
              child: SafeArea(child: _NavRail(collapsed: false, inDrawer: true)),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) const _NavRail(),
            Expanded(
              // Keyed so it keeps its element when the rail appears or
              // disappears at the breakpoint. Without a key the Row matches
              // children by position, so dropping the rail shifts this slot
              // from index 1 to 0 and the whole subtree is rebuilt -- taking
              // the router's Navigator, and its GlobalKey, with it.
              key: const ValueKey('shell-content'),
              child: Column(
                children: [
                  _Header(showMenuButton: compact),
                  Expanded(
                    child: deciding
                        ? const Center(child: CircularProgressIndicator())
                        : child,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Rail
// -----------------------------------------------------------------------------

class _RailItem {
  const _RailItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

/// The destinations worth a permanent place. Deeper pages -- a single college,
/// a saved prediction -- are pushed on top and keep the rail highlight of
/// wherever they were opened from.
const _railItems = [
  _RailItem(Icons.dashboard_rounded, 'Home', '/'),
  _RailItem(Icons.auto_graph_rounded, 'Predict', '/predict'),
  _RailItem(Icons.apartment_rounded, 'Colleges', '/colleges'),
  _RailItem(Icons.fact_check_rounded, 'Mock Test', '/mock'),
  _RailItem(Icons.balance_rounded, 'Compare', '/compare'),
  _RailItem(Icons.bookmark_rounded, 'Shortlist', '/shortlist'),
  _RailItem(Icons.school_rounded, 'Exams', '/exams'),
  _RailItem(Icons.calendar_month_rounded, 'Calendar', '/calendar'),
];

class _NavRail extends ConsumerWidget {
  const _NavRail({this.collapsed, this.inDrawer = false});

  /// Overrides the shared collapsed state. The drawer is always expanded --
  /// it has the room, and a collapsed drawer is just a worse rail.
  final bool? collapsed;
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final bool isCollapsed = collapsed ?? ref.watch(railCollapsedProvider);
    final location = GoRouterState.of(context).uri.path;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: isCollapsed ? 72 : 104,
      decoration: BoxDecoration(
        color: Brand.rail(brightness),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Clear the header, so the first destination sits under it rather
          // than level with the wordmark.
          SizedBox(height: inDrawer ? 10 : 74),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final item in _railItems)
                  _RailTile(
                    item: item,
                    // Exact for '/', prefix for the rest, so /colleges/iit-bombay
                    // keeps Colleges lit while it is open.
                    selected: item.route == '/'
                        ? location == '/'
                        : location.startsWith(item.route),
                    collapsed: isCollapsed,
                    onTap: () {
                      // closeDrawer(), not Navigator.pop(). The drawer belongs
                      // to the shell's Scaffold, which is itself a page in the
                      // ROOT navigator -- so a pop from here targets that, and
                      // would tear the whole shell down instead of sliding the
                      // drawer shut.
                      if (inDrawer) Scaffold.of(context).closeDrawer();

                      // A rail tap is "start again", so the Predict form and
                      // its results go back to blank. Without this, tapping
                      // Predict from another page left the previous run on
                      // screen -- a result list headed COMEDK rank 8347 above
                      // a form that had since been changed to another exam.
                      resetPrediction(ref);

                      context.go(item.route);
                    },
                  ),
              ],
            ),
          ),
          if (!inDrawer) ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            _CollapseButton(collapsed: isCollapsed),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final _RailItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected
        ? (brightness == Brightness.light ? Brand.deep : Brand.light)
        : scheme.onSurfaceVariant;

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(vertical: collapsed ? 10 : 12, horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? Brand.selected(brightness) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(item.icon, size: 22, color: fg),
          if (!collapsed) ...[
            const SizedBox(height: 6),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        // Collapsed, the label is gone, so the icon needs to say what it is.
        child: collapsed ? Tooltip(message: item.label, child: tile) : tile,
      ),
    );
  }
}

class _CollapseButton extends ConsumerWidget {
  const _CollapseButton({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              ref.read(railCollapsedProvider.notifier).state = !collapsed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                if (!collapsed)
                  Flexible(
                    child: Text(
                      'Collapse',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.showMenuButton});
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final signedIn = ref.watch(isSignedInProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? Colors.white
            : scheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const _Wordmark(),
          const SizedBox(width: 14),
          Container(width: 1, height: 26, color: scheme.outlineVariant),
          const SizedBox(width: 14),
          // Expanded, not Flexible + Spacer. Both of those default to flex 1,
          // so the leftover width was split evenly between the pill and the
          // gap -- which parked the three action icons a third of the way in
          // from the right edge instead of against it.
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TaglinePill(),
            ),
          ),
          const SizedBox(width: 12),
          _HeaderIcon(
            icon: brightness == Brightness.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            tooltip: brightness == Brightness.light ? 'Dark mode' : 'Light mode',
            onTap: () => ref.read(themeModeProvider.notifier).state =
                brightness == Brightness.light ? ThemeMode.dark : ThemeMode.light,
          ),
          _HeaderIcon(
            icon: signedIn ? Icons.logout_rounded : Icons.login_rounded,
            tooltip: signedIn ? 'Sign out' : 'Sign in',
            onTap: () {
              if (signedIn) {
                ref.read(authControllerProvider.notifier).signOut();
              } else {
                // push, not go: signing in is a detour you come back from, and
                // `go` would replace the stack so there is nothing to return
                // to afterwards.
                context.push('/sign-in');
              }
            },
          ),
          const SizedBox(width: 4),
          _Avatar(email: user?.email),
        ],
      ),
    );
  }
}

/// Two-tone wordmark: the name splits where the meaning does.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Vidya',
            style: TextStyle(color: dark ? Brand.light : Brand.deep),
          ),
          const TextSpan(text: 'Pd', style: TextStyle(color: Brand.light)),
        ],
      ),
      style: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      ),
    );
  }
}

class _TaglinePill extends StatelessWidget {
  const _TaglinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Brand.deep,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'B.Tech Admission Predictor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 21),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    // Signed out, there is no initial to show and a letter would be a guess.
    final initial = (email == null || email!.isEmpty)
        ? null
        : email![0].toUpperCase();
    return Tooltip(
      message: email ?? 'Not signed in',
      child: CircleAvatar(
        radius: 17,
        backgroundColor: Brand.deep,
        child: initial == null
            ? const Icon(Icons.person_rounded, size: 19, color: Colors.white)
            : Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
