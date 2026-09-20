import 'package:flutter/material.dart';

/// Shown wherever cutoff numbers appear, but ONLY while the database actually
/// holds seed-dev data -- gate every use on `ReferenceData.hasDemoData`.
///
/// The demo colleges are all suffixed "(DEMO)", but a student glancing at a
/// results list would not notice, so this makes it unmissable. That only works
/// while it is rare: rendering it unconditionally meant it stayed on screen
/// after the demo seeds were gone, and a warning that is always on is one
/// people stop reading -- including on the day it is true.
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
