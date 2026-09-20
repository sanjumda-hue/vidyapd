import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Honest placeholder. Says what is missing rather than "coming soon!", so the
/// screen is useful to whoever picks the feature up next.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.blockedBy});

  final String title;
  final String blockedBy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Same circular chip as the predict screen's empty pane, so
                // "nothing here yet" looks like one thing across the app.
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: Brand.selected(theme.brightness),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.construction_rounded,
                    size: 46,
                    color: theme.brightness == Brightness.light
                        ? Brand.deep
                        : Brand.light,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Not built yet',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  blockedBy,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
