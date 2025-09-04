import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand & semantic colors
  static const Color primary = Color(0xFF3B82F6); // blue
  static const Color secondary = Color(0xFF38BDF8); // sky
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Light theme neutrals
  static const Color lightBackground = Color(
    0xFFF7F7FB,
  ); // page background (near white with blue tint)
  static const Color lightSurface = Color(0xFFFFFFFF); // cards/surfaces
  static const Color lightOnBackground = Color(0xFF0F172A); // slate-900
  static const Color lightOnSurface = Color(0xFF1F2937); // slate-800
  static const Color lightOutline = Color(0xFFE5E7EB); // thin borders/dividers

  // Dark theme neutrals
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF161A21);
  static const Color darkOnBackground = Color(0xFFE5E7EB);
  static const Color darkOnSurface = Color(0xFFD1D5DB);
  static const Color darkOutline = Color(0xFF2B3340);

  // ColorSchemes used by ThemeData
  static ColorScheme lightScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    return base.copyWith(
      primary: primary,
      secondary: secondary,
      background: lightBackground,
      surface: lightSurface,
      onBackground: lightOnBackground,
      onSurface: lightOnSurface,
      error: danger,
    );
  }

  static ColorScheme darkScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      primary: primary,
      secondary: secondary,
      background: darkBackground,
      surface: darkSurface,
      onBackground: darkOnBackground,
      onSurface: darkOnSurface,
      error: danger,
    );
  }
}
