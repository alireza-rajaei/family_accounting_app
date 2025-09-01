import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness, {double scale = 1.0}) {
    final base = brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    return GoogleFonts.vazirmatnTextTheme(base).apply(fontSizeFactor: scale, bodyColor: null, displayColor: null);
  }
}


