// ============================================================
// lib/core/theme/app_theme.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType { mysticNight, cottonCandy, skyBlue }

extension AppThemeTypeExtension on AppThemeType {
  String get displayName {
    switch (this) {
      case AppThemeType.mysticNight:
        return 'Mystic Night';
      case AppThemeType.cottonCandy:
        return 'Cotton Candy';
      case AppThemeType.skyBlue:
        return 'Sky Blue';
    }
  }

  String get storageKey {
    switch (this) {
      case AppThemeType.mysticNight:
        return 'mystic_night';
      case AppThemeType.cottonCandy:
        return 'cotton_candy';
      case AppThemeType.skyBlue:
        return 'sky_blue';
    }
  }

  static AppThemeType fromKey(String key) {
    switch (key) {
      case 'cotton_candy':
        return AppThemeType.cottonCandy;
      case 'sky_blue':
        return AppThemeType.skyBlue;
      default:
        return AppThemeType.mysticNight;
    }
  }
}

class AppColors {
  final Color background;
  final Color backgroundGradientEnd;
  final Color surface;
  final Color surfaceVariant;
  final Color accent;
  final Color accentSecondary;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color cardBorder;
  final Color presentColor;
  final Color absentColor;
  final Color unsetColor;
  final Color introBackground;

  const AppColors({
    required this.background,
    required this.backgroundGradientEnd,
    required this.surface,
    required this.surfaceVariant,
    required this.accent,
    required this.accentSecondary,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.cardBorder,
    required this.presentColor,
    required this.absentColor,
    required this.unsetColor,
    required this.introBackground,
  });
}

class AppThemeData {
  final AppColors colors;
  final ThemeData materialTheme;
  final AppThemeType type;

  AppThemeData({
    required this.colors,
    required this.materialTheme,
    required this.type,
  });
}

class AppThemes {
  static final Map<AppThemeType, AppColors> _colors = {
    AppThemeType.mysticNight: const AppColors(
      background: Color(0xFF0D0F1A),
      backgroundGradientEnd: Color(0xFF1A1D2E),
      surface: Color(0xFF1E2235),
      surfaceVariant: Color(0xFF252840),
      accent: Color(0xFF7C6BFF),
      accentSecondary: Color(0xFFB06BFF),
      onAccent: Color(0xFFFFFFFF),
      textPrimary: Color(0xFFE8E8F0),
      textSecondary: Color(0xFFB0B0C8),
      textMuted: Color(0xFF6B6B8A),
      divider: Color(0xFF2A2D42),
      cardBorder: Color(0xFF2E3150),
      presentColor: Color(0xFF4ADE80),
      absentColor: Color(0xFFFF6B6B),
      unsetColor: Color(0xFF4A4A6A),
      introBackground: Color(0xFF0D0F1A),
    ),
    AppThemeType.cottonCandy: const AppColors(
      background: Color(0xFFFFF0F5),
      backgroundGradientEnd: Color(0xFFFCE4EC),
      surface: Color(0xFFFFFFFF),
      surfaceVariant: Color(0xFFFFF0F8),
      accent: Color(0xFFF06292),
      accentSecondary: Color(0xFFEC407A),
      onAccent: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF4A1942),
      textSecondary: Color(0xFF7B3F6E),
      textMuted: Color(0xFFBA8BAF),
      divider: Color(0xFFF8D7E8),
      cardBorder: Color(0xFFFFB6D9),
      presentColor: Color(0xFF66BB6A),
      absentColor: Color(0xFFEF5350),
      unsetColor: Color(0xFFDDB8CC),
      introBackground: Color(0xFFFFF0F5),
    ),
    AppThemeType.skyBlue: const AppColors(
      background: Color(0xFFE3F2FD),
      backgroundGradientEnd: Color(0xFFBBDEFB),
      surface: Color(0xFFFFFFFF),
      surfaceVariant: Color(0xFFE8F4FD),
      accent: Color(0xFF42A5F5),
      accentSecondary: Color(0xFF1E88E5),
      onAccent: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF0D2137),
      textSecondary: Color(0xFF1A4A72),
      textMuted: Color(0xFF7AAACB),
      divider: Color(0xFFCCE5F8),
      cardBorder: Color(0xFF90CAF9),
      presentColor: Color(0xFF43A047),
      absentColor: Color(0xFFE53935),
      unsetColor: Color(0xFF90BDD9),
      introBackground: Color(0xFFE3F2FD),
    ),
  };

  static AppThemeData getTheme(AppThemeType type) {
    final colors = _colors[type]!;
    final isDark = type == AppThemeType.mysticNight;

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        color: colors.textPrimary,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        color: colors.textSecondary,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        color: colors.textMuted,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );

    final theme = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.accentSecondary,
        onSecondary: colors.onAccent,
        error: const Color(0xFFFF6B6B),
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        labelStyle: GoogleFonts.nunito(color: colors.textSecondary),
        hintStyle: GoogleFonts.nunito(color: colors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        labelStyle: GoogleFonts.nunito(color: colors.textSecondary, fontSize: 13),
        side: BorderSide(color: colors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w500, fontSize: 14),
        labelColor: colors.accent,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.accent,
      ),
    );

    return AppThemeData(colors: colors, materialTheme: theme, type: type);
  }
}
