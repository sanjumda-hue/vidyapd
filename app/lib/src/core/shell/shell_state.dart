import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation-only state for the desktop shell.
///
/// Nothing here touches the API or any repository. It is the two things the
/// chrome remembers while the app is open: which way the theme is set, and
/// whether the rail is collapsed to icons.
///
/// Not persisted. Writing it to disk would mean a storage dependency for a
/// preference that costs one click to set again.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final railCollapsedProvider = StateProvider<bool>((ref) => false);
