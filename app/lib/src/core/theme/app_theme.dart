import 'package:flutter/material.dart';

/// Colours for the four match grades.
///
/// These are the only place the grade -> colour mapping lives. Deliberately
/// not green/red: "strong historical match" is still not a guarantee, and a
/// green tick would say otherwise. Blue reads as informational.
///
/// These stay blue/amber/grey even though the rest of the app is teal. The
/// palette is a brand decision; these four are a meaning decision, and a
/// "strong" badge that matched the brand colour would read as approval.
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

/// Brand palette for the desktop shell.
///
/// Kept apart from the generated ColorScheme because the shell paints a few
/// exact surfaces -- the rail, the header, the page background -- that a
/// tonal palette would only approximate.
class Brand {
  /// The darker half of the wordmark, and the colour of every primary action.
  static const deep = Color(0xFF0E7C78);

  /// The lighter half of the wordmark and the accent on selected rail items.
  static const light = Color(0xFF3FAFA6);

  /// Page background behind the content area. A hint of the brand, not white,
  /// so white cards read as raised without needing a shadow.
  static const canvasLight = Color(0xFFEDF6F6);
  static const canvasDark = Color(0xFF0E1517);

  /// The rail and header, which sit above the canvas.
  static const railLight = Color(0xFFF6FBFB);
  static const railDark = Color(0xFF14201F);

  /// Fill behind the selected rail item.
  static const selectedLight = Color(0xFFD6EBEA);
  static const selectedDark = Color(0xFF17403D);

  static Color canvas(Brightness b) =>
      b == Brightness.light ? canvasLight : canvasDark;
  static Color rail(Brightness b) => b == Brightness.light ? railLight : railDark;
  static Color selected(Brightness b) =>
      b == Brightness.light ? selectedLight : selectedDark;
}

class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.deep,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Every screen keeps its own Scaffold and sits inside the shell, so they
      // all paint this and the seam between shell and page disappears.
      scaffoldBackgroundColor: Brand.canvas(brightness),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        // A page inside the shell already has the brand header above it. Its
        // own AppBar is a page heading, not a second chrome bar, so it gets no
        // fill of its own.
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? Colors.white : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? Colors.white
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.deep, width: 1.6),
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
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
