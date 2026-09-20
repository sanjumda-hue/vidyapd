import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/colleges/presentation/college_detail_screen.dart';
import '../../features/colleges/presentation/colleges_screen.dart';
import '../../features/colleges/presentation/compare_screen.dart';
import '../../features/exams/presentation/exams_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/prediction/presentation/predict_screen.dart';
import '../../features/shared/coming_soon_screen.dart';
import '../../features/shortlist/presentation/shortlist_screen.dart';
import '../shell/app_shell.dart';

/// Turns auth changes into something go_router will listen to.
///
/// `redirect` runs on navigation, not on state change, so signing out while
/// sitting on the dashboard would otherwise leave the page up until the next
/// tap. This nudges the router to re-run its redirect the moment auth moves.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

/// The router, as a provider so the redirect can see the auth state.
///
/// It deliberately does NOT `watch` auth. Rebuilding a GoRouter throws away
/// its navigator -- and with it the GlobalKey the framework is holding -- so a
/// router recreated on every sign-in would take the whole element tree with
/// it. It reads instead, and `refreshListenable` re-runs the redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,

    /// Nothing but the sign-in page is reachable signed out.
    ///
    /// This is a gate on the UI, not on the data: the API still answers an
    /// anonymous prediction, so it stops someone browsing the app, not someone
    /// calling the endpoints. Real enforcement belongs on the API routes.
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      // Startup, while the stored token is being checked against /auth/me.
      // Bouncing to sign-in here would throw out a perfectly good session on
      // every page reload, so hold still; AppShell shows a spinner meanwhile.
      if (auth.isLoading) return null;

      final signedIn = auth.valueOrNull != null;
      final atSignIn = state.matchedLocation == '/sign-in';

      if (!signedIn && !atSignIn) return '/sign-in';
      if (signedIn && atSignIn) return '/';
      return null;
    },
    routes: [
      // Outside the shell. A rail full of destinations you cannot open is
      // worse than no rail: every click would bounce straight back here.
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),

      /// Routes that exist today map to real screens. The rest resolve to
      /// [ComingSoonScreen], which names the backend work that is still
      /// missing instead of showing a dead tile.
      ///
      /// One ShellRoute, so the rail and header are built once and survive
      /// navigation. Each screen keeps the Scaffold and AppBar it already had;
      /// inside the shell that AppBar reads as the page heading, which is
      /// where its title belonged anyway.
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/predict', builder: (_, __) => const PredictScreen()),
          GoRoute(path: '/exams', builder: (_, __) => const ExamsScreen()),
          GoRoute(
            path: '/calendar',
            builder: (_, __) => const ComingSoonScreen(
              title: 'Exam Calendar',
              blockedBy: 'No exam dates are in the database yet. Dates only '
                  'arrive through an import job with an official source behind it.',
            ),
          ),
          GoRoute(path: '/colleges', builder: (_, __) => const CollegesScreen()),
          GoRoute(
            path: '/colleges/:slug',
            builder: (_, state) =>
                CollegeDetailScreen(slug: state.pathParameters['slug'] as String),
          ),
          GoRoute(
            path: '/branches',
            builder: (_, __) => const ComingSoonScreen(
              title: 'Branches',
              blockedBy: 'The branches API module has no routes yet.',
            ),
          ),
          GoRoute(path: '/compare', builder: (_, __) => const CompareScreen()),
          GoRoute(path: '/shortlist', builder: (_, __) => const ShortlistScreen()),
        ],
      ),
    ],
  );
});
