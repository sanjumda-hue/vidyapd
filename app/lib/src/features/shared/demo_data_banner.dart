import 'package:flutter/material.dart';

/// Shown wherever cutoff numbers appear while the database holds seed-dev data.
///
/// The demo colleges are all suffixed "(DEMO)", but a student glancing at a
/// results list would not notice. This makes it unmissable.
class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Development build. Colleges marked (DEMO) carry invented ranks, '
              'not published cutoffs.',
              style: TextStyle(fontSize: 12.5, color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
