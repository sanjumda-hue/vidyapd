import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/shell/shell_state.dart';
import 'core/theme/app_theme.dart';

class VidyaPdApp extends ConsumerWidget {
  const VidyaPdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'B.Tech Admission Predictor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Driven by the header toggle rather than the platform, because the
      // platform setting is not what someone is reaching for when they click
      // the moon in the corner.
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
