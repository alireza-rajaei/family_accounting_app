import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({double scale = 1.0}) {
    final colorScheme = AppColors.lightScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: colorScheme.primary.withOpacity(0.15),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.primary
                : AppColors.lightOnSurface.withOpacity(0.7),
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : AppColors.lightOnSurface.withOpacity(0.8),
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.lightSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: TextStyle(color: AppColors.lightOnSurface.withOpacity(0.6)),
        labelStyle: TextStyle(color: AppColors.lightOnSurface.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      textTheme: AppTypography.textTheme(Brightness.light, scale: scale),
    );
  }

  static ThemeData dark({double scale = 1.0}) {
    final colorScheme = AppColors.darkScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : AppColors.darkOnSurface.withOpacity(0.85),
          );
        }),
        backgroundColor: AppColors.darkSurface,
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.primary
                : AppColors.darkOnSurface.withOpacity(0.75),
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: TextStyle(color: AppColors.darkOnSurface.withOpacity(0.6)),
        labelStyle: TextStyle(color: AppColors.darkOnSurface.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      textTheme: AppTypography.textTheme(Brightness.dark, scale: scale),
    );
  }
}
