import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The heading strip at the top of a content page: a tinted icon chip, the
/// title, an optional subtitle, and room for one action on the right.
///
/// Screens that already carry an AppBar get this look from the AppBar theme
/// instead. This is for the ones that do not, so the two kinds of page line up
/// rather than starting at different heights.
class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Brand.selected(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 21, color: dark ? Brand.light : Brand.deep),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
