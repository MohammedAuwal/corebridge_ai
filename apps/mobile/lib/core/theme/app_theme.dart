import 'package:flutter/material.dart';

/// Design tokens mirrored 1:1 from the web app's CSS variables so both
/// platforms feel like the same product.
class AppColors {
  AppColors._();

  static const Color canvasLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceRaisedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color accentLight = Color(0xFFC15F3C);
  static const Color accentHoverLight = Color(0xFFA84F30);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF525252);
  static const Color textMutedLight = Color(0xFF8A8A8A);

  static const Color canvasDark = Color(0xFF191919);
  static const Color surfaceDark = Color(0xFF212121);
  static const Color surfaceRaisedDark = Color(0xFF262626);
  static const Color borderDark = Color(0xFF333333);
  static const Color accentDark = Color(0xFFD97757);
  static const Color accentHoverDark = Color(0xFFE08A6A);
  static const Color textPrimaryDark = Color(0xFFF2F2F2);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textMutedDark = Color(0xFF7A7A7A);
}

class AppRadii {
  AppRadii._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentLight,
      brightness: Brightness.light,
      surface: AppColors.surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasLight,
      fontFamily: 'Inter',
      textTheme: _textTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvasLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedIconTheme: const IconThemeData(color: AppColors.accentLight),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMutedLight),
        selectedLabelTextStyle: const TextStyle(color: AppColors.accentLight, fontSize: 12),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.textMutedLight, fontSize: 12),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentDark,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasDark,
      fontFamily: 'Inter',
      textTheme: _textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvasDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedIconTheme: const IconThemeData(color: AppColors.accentDark),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMutedDark),
        selectedLabelTextStyle: const TextStyle(color: AppColors.accentDark, fontSize: 12),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 12),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineLarge: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 28),
      headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 22),
      titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 18),
      bodyLarge: TextStyle(color: primary, fontSize: 16),
      bodyMedium: TextStyle(color: secondary, fontSize: 14),
      labelSmall: TextStyle(color: secondary, fontSize: 12),
    );
  }
}
