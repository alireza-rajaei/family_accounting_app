import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness, {double scale = 1.0}) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final themed = GoogleFonts.vazirmatnTextTheme(base);
    if (scale == 1.0) return themed;
    return _scaleTextTheme(themed, scale);
  }

  static TextTheme _scaleTextTheme(TextTheme theme, double factor) {
    TextStyle? s(TextStyle? style) {
      if (style == null) return null;
      final current = style.fontSize;
      return style.copyWith(
        fontSize: current != null ? current * factor : null,
      );
    }

    return theme.copyWith(
      displayLarge: s(theme.displayLarge),
      displayMedium: s(theme.displayMedium),
      displaySmall: s(theme.displaySmall),
      headlineLarge: s(theme.headlineLarge),
      headlineMedium: s(theme.headlineMedium),
      headlineSmall: s(theme.headlineSmall),
      titleLarge: s(theme.titleLarge),
      titleMedium: s(theme.titleMedium),
      titleSmall: s(theme.titleSmall),
      bodyLarge: s(theme.bodyLarge),
      bodyMedium: s(theme.bodyMedium),
      bodySmall: s(theme.bodySmall),
      labelLarge: s(theme.labelLarge),
      labelMedium: s(theme.labelMedium),
      labelSmall: s(theme.labelSmall),
    );
  }
}
