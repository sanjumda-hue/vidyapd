import 'package:go_router/go_router.dart';

import '../../features/exams/presentation/exams_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/prediction/presentation/predict_screen.dart';
import '../../features/shared/coming_soon_screen.dart';

/// Routes that exist today map to real screens. The rest resolve to
/// [ComingSoonScreen], which names the backend work that is still missing
/// instead of showing a dead tile.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/predict', builder: (_, __) => const PredictScreen()),
    GoRoute(path: '/exams', builder: (_, __) => const ExamsScreen()),
    GoRoute(
      path: '/calendar',
      builder: (_, __) => const ComingSoonScreen(
        title: 'Exam Calendar',
        blockedBy: 'No exam dates are in the database yet. Dates only arrive '
            'through an import job with an official source behind it.',
      ),
    ),
    GoRoute(
      path: '/colleges',
      builder: (_, __) => const ComingSoonScreen(
        title: 'Colleges',
        blockedBy: 'The colleges API module has no routes yet.',
      ),
    ),
    GoRoute(
      path: '/branches',
      builder: (_, __) => const ComingSoonScreen(
        title: 'Branches',
        blockedBy: 'The branches API module has no routes yet.',
      ),
    ),
    GoRoute(
      path: '/compare',
      builder: (_, __) => const ComingSoonScreen(
        title: 'Compare Colleges',
        blockedBy: 'Needs the compare endpoint, backed by v_program_summary.',
      ),
    ),
    GoRoute(
      path: '/shortlist',
      builder: (_, __) => const ComingSoonScreen(
        title: 'My Shortlist',
        blockedBy: 'Needs sign-in and the shortlist endpoints.',
      ),
    ),
  ],
);
