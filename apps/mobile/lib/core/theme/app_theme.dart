import 'package:flutter/material.dart';

/// Design tokens matching the CoreBridge app icon: deep near-black
/// surfaces with an electric blue → violet gradient accent.
class AppColors {
  AppColors._();

  static const Color canvas = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF13131F);
  static const Color surfaceRaised = Color(0xFF1B1B2B);
  static const Color border = Color(0xFF2A2A3D);

  static const Color accentBlue = Color(0xFF4F8EF7);
  static const Color accentViolet = Color(0xFFA855F7);

  static const Color textPrimary = Color(0xFFF4F4F8);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color textMuted = Color(0xFF6B6B80);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentViolet],
  );
}

class AppRadii {
  AppRadii._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 26;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentBlue,
      brightness: Brightness.dark,
      surface: AppColors.surface,
      primary: AppColors.accentBlue,
      secondary: AppColors.accentViolet,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        headlineLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 28),
        headlineMedium: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        titleLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        labelSmall: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentBlue.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.accentBlue : AppColors.textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.accentBlue : AppColors.textMuted);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: const IconThemeData(color: AppColors.accentBlue),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: const TextStyle(color: AppColors.accentBlue, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        indicatorColor: AppColors.accentBlue.withValues(alpha: 0.15),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
