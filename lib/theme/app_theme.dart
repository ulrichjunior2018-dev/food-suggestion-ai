import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's full visual identity, kept in one place instead of scattered
/// magic colors — a deliberate warm, editorial food-magazine palette
/// instead of a default Material seed color.
class AppColors {
  static const terracotta = Color(0xFFC1502E);
  static const terracottaDark = Color(0xFF8F3A20);
  static const charcoal = Color(0xFF2B2420);
  static const cream = Color(0xFFFBF6EF);
  static const tan = Color(0xFFF3E5D3);
  static const sage = Color(0xFF7A8B69);
  static const gold = Color(0xFFD4A24C);
  static const errorRed = Color(0xFFB3401F);
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.terracotta,
      onPrimary: Colors.white,
      secondary: AppColors.sage,
      surface: AppColors.cream,
      surfaceContainerHighest: AppColors.tan,
      error: AppColors.errorRed,
    );

    final displayFont = GoogleFonts.fraunces;
    final bodyFont = GoogleFonts.workSans;

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: TextTheme(
        headlineMedium: displayFont(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
          height: 1.2,
        ),
        headlineSmall: displayFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
        titleLarge: displayFont(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
        bodyLarge: bodyFont(fontSize: 16, color: AppColors.charcoal, height: 1.4),
        bodyMedium: bodyFont(fontSize: 14, color: AppColors.charcoal, height: 1.4),
        bodySmall: bodyFont(fontSize: 12, color: AppColors.charcoal),
        labelLarge: bodyFont(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.charcoal,
        titleTextStyle: displayFont(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: bodyFont(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          side: const BorderSide(color: AppColors.charcoal, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Maps each cuisine type the AI can return to a distinctive emoji + a
/// gradient pair, so every suggestion card gets a strong, unique visual
/// identity without depending on an external image API (which is a network
/// dependency this app doesn't need and shouldn't risk failing on).
class CuisineVisual {
  final String emoji;
  final List<Color> gradient;

  const CuisineVisual(this.emoji, this.gradient);

  static const _map = <String, CuisineVisual>{
    'african': CuisineVisual('🍲', [AppColors.gold, AppColors.terracotta]),
    'italian': CuisineVisual('🍝', [AppColors.terracotta, AppColors.terracottaDark]),
    'asian': CuisineVisual('🍜', [AppColors.sage, Color(0xFF3F5A3F)]),
    'mexican': CuisineVisual('🌮', [AppColors.gold, Color(0xFFB23A2E)]),
    'american': CuisineVisual('🍔', [Color(0xFF8B5E3C), Color(0xFF4A342A)]),
    'mediterranean': CuisineVisual('🥙', [AppColors.sage, AppColors.gold]),
    'indian': CuisineVisual('🍛', [AppColors.terracotta, AppColors.gold]),
  };

  static const _fallback = CuisineVisual('🍽️', [Color(0xFF8B7355), AppColors.charcoal]);

  static CuisineVisual forCuisine(String cuisineType) {
    final key = cuisineType.trim().toLowerCase();
    for (final entry in _map.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return _fallback;
  }
}
