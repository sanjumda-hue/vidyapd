import 'package:flutter/material.dart';

/// Colours for the four match grades.
///
/// These are the only place the grade -> colour mapping lives. Deliberately
/// not green/red: "strong historical match" is still not a guarantee, and a
/// green tick would say otherwise. Blue reads as informational.
class GradeColors {
  static const strong = Color(0xFF1B6FE0);
  static const match = Color(0xFF2E9E6B);
  static const borderline = Color(0xFFD98510);
  static const outside = Color(0xFF8A8F98);

  static Color of(String grade) => switch (grade) {
        'strong_historical_match' => strong,
        'historical_match' => match,
        'borderline' => borderline,
        _ => outside,
      };

  static IconData iconOf(String grade) => switch (grade) {
        'strong_historical_match' => Icons.trending_up_rounded,
        'historical_match' => Icons.check_circle_outline_rounded,
        'borderline' => Icons.warning_amber_rounded,
        _ => Icons.remove_circle_outline_rounded,
      };
}

class AppTheme {
  static const _seed = Color(0xFF1B4FE0);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }
}
