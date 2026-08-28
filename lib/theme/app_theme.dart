import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's visual identity.
///
/// Brand colours are compile-time constants because they are identical in
/// both themes — the identity does not change when the lights go out.
/// Surface colours are getters that resolve against [AppColors.isDark],
/// which lets every existing call site keep working unchanged.
///
/// The tradeoff is honest: [isDark] is static mutable state, which is
/// normally a smell. It is safe here because exactly one writer sets it —
/// [AppTheme.applyMode], called from the theme builder above MaterialApp —
/// and the whole tree rebuilds on that same notifier, so a frame can never
/// render against a stale value. The idiomatic alternative is threading
/// Theme.of(context) through every widget, which would mean touching ~65
/// call sites and stripping const from all of them for no visual gain.
class AppColors {
  // ---- brand: identical in light and dark ----
  static const terracotta = Color(0xFFC1502E);
  static const terracottaDark = Color(0xFF8F3A20);
  static const sage = Color(0xFF7A8B69);
  static const gold = Color(0xFFD4A24C);
  static const errorRed = Color(0xFFB3401F);

  static bool isDark = false;

  // ---- surfaces: resolve per theme ----

  /// Page background.
  static Color get cream =>
      isDark ? const Color(0xFF14100E) : const Color(0xFFFBF6EF);

  /// Primary text and icons.
  static Color get charcoal =>
      isDark ? const Color(0xFFF2EAE1) : const Color(0xFF2B2420);

  /// Hairlines, chip borders, muted fills.
  static Color get tan =>
      isDark ? const Color(0xFF3A2F28) : const Color(0xFFF3E5D3);

  /// Raised surfaces — cards, sheets, chat bubbles.
  static Color get card =>
      isDark ? const Color(0xFF201A16) : Colors.white;

  /// Shadow colour. A dark theme needs real black beneath a raised
  /// surface; reusing the (now light) text colour would make cards glow.
  static Color get shadow =>
      isDark ? Colors.black : const Color(0xFF2B2420);
}

class AppTheme {
  /// Drives the whole app's brightness. Persisted, and listened to above
  /// MaterialApp so a change rebuilds every screen.
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Resolves [ThemeMode.system] against the platform and syncs
  /// [AppColors.isDark] before any widget builds against it.
  static void applyMode(BuildContext context) {
    final resolved = mode.value == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : (mode.value == ThemeMode.dark ? Brightness.dark : Brightness.light);
    AppColors.isDark = resolved == Brightness.dark;
  }

  static const String _storageKey = 'theme_mode_v1';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_storageKey)) {
        case 'dark':
          mode.value = ThemeMode.dark;
        case 'system':
          mode.value = ThemeMode.system;
        default:
          mode.value = ThemeMode.light;
      }
    } catch (_) {
      mode.value = ThemeMode.light;
    }
  }

  static Future<void> setMode(ThemeMode next) async {
    mode.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        next == ThemeMode.dark
            ? 'dark'
            : next == ThemeMode.system
                ? 'system'
                : 'light',
      );
    } catch (_) {
      // Non-fatal: the choice holds for this session.
    }
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final surface = dark ? const Color(0xFF14100E) : const Color(0xFFFBF6EF);
    final onSurface = dark ? const Color(0xFFF2EAE1) : const Color(0xFF2B2420);
    final muted = dark ? const Color(0xFF3A2F28) : const Color(0xFFF3E5D3);

    final base = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.terracotta,
      onPrimary: Colors.white,
      secondary: AppColors.sage,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: muted,
      error: AppColors.errorRed,
    );

    final displayFont = GoogleFonts.fraunces;
    final bodyFont = GoogleFonts.workSans;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: base,
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        headlineMedium: displayFont(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.15,
          letterSpacing: -0.4,
        ),
        headlineSmall: displayFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: displayFont(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: bodyFont(fontSize: 16, color: onSurface, height: 1.45),
        bodyMedium: bodyFont(fontSize: 14, color: onSurface, height: 1.45),
        bodySmall: bodyFont(fontSize: 12, color: onSurface),
        labelLarge: bodyFont(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: onSurface,
        titleTextStyle: displayFont(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: onSurface,
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
          foregroundColor: onSurface,
          side: BorderSide(color: onSurface.withValues(alpha: 0.35), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: onSurface),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF201A16) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// The visual identity a dish falls back to when no photograph is
/// available.
///
/// Keyed off the DISH, not the cuisine. Keying off cuisine meant a
/// Caprese Salad and a Bruschetta — both "Italian" — rendered as the
/// identical pasta emoji on the identical gradient, which is exactly
/// what made a results screen look generic.
class CuisineVisual {
  final String emoji;
  final List<Color> gradient;

  const CuisineVisual(this.emoji, this.gradient);

  /// Matched longest-first so "sweet potato" beats "potato".
  static const _dishKeywords = <String, String>{
    'bruschetta': '🥖', 'garlic bread': '🥖', 'baguette': '🥖',
    'sandwich': '🥪', 'burger': '🍔', 'hot dog': '🌭', 'pizza': '🍕',
    'spaghetti': '🍝', 'pasta': '🍝', 'lasagne': '🍝', 'lasagna': '🍝',
    'noodle': '🍜', 'ramen': '🍜', 'pho': '🍜',
    'salad': '🥗', 'slaw': '🥗', 'soup': '🥣', 'broth': '🥣',
    'stew': '🍲', 'chili': '🍲', 'curry': '🍛',
    'rice': '🍚', 'jollof': '🍚', 'risotto': '🍚', 'paella': '🥘',
    'taco': '🌮', 'burrito': '🌯', 'wrap': '🌯', 'quesadilla': '🫓',
    'flatbread': '🫓', 'naan': '🫓', 'sushi': '🍣', 'dumpling': '🥟',
    'chicken': '🍗', 'turkey': '🍗', 'steak': '🥩', 'beef': '🥩',
    'lamb': '🥩', 'pork': '🥓', 'bacon': '🥓',
    'fish': '🐟', 'salmon': '🐟', 'tuna': '🐟', 'shrimp': '🍤', 'prawn': '🍤',
    'egg': '🍳', 'omelette': '🍳', 'omelet': '🍳', 'frittata': '🍳',
    'pancake': '🥞', 'waffle': '🧇', 'oat': '🥣', 'porridge': '🥣',
    'toast': '🍞', 'bread': '🍞', 'cheese': '🧀', 'avocado': '🥑',
    'potato': '🥔', 'corn': '🌽', 'mushroom': '🍄', 'tofu': '🧊',
    'bean': '🫘', 'lentil': '🫘', 'hummus': '🧆', 'falafel': '🧆',
    'kebab': '🥙', 'shawarma': '🥙', 'gyro': '🥙',
    'smoothie': '🥤', 'juice': '🧃', 'cake': '🍰', 'pie': '🥧',
    'dessert': '🍮', 'pudding': '🍮', 'fruit': '🍓', 'berry': '🍓',
    'banana': '🍌', 'apple': '🍎', 'tomato': '🍅',
    'pepper': '🌶️', 'spicy': '🌶️',
  };

  static const _cuisineFallback = <String, String>{
    'african': '🍲', 'italian': '🍝', 'asian': '🍜', 'chinese': '🥡',
    'japanese': '🍣', 'thai': '🍜', 'mexican': '🌮', 'american': '🍔',
    'mediterranean': '🥙', 'greek': '🥙', 'indian': '🍛',
    'french': '🥐', 'spanish': '🥘',
  };

  static const _gradients = <List<Color>>[
    [AppColors.terracotta, AppColors.terracottaDark],
    [AppColors.gold, AppColors.terracotta],
    [AppColors.sage, Color(0xFF3F5A3F)],
    [Color(0xFF8B5E3C), Color(0xFF4A342A)],
    [AppColors.sage, AppColors.gold],
    [Color(0xFFC97B3E), Color(0xFF7A3B1E)],
    [Color(0xFF9B8557), Color(0xFF4E5F41)],
    [Color(0xFFB23A2E), Color(0xFF5C2A33)],
  ];

  static String _emojiFor(String dishName, String cuisineType) {
    final dish = dishName.toLowerCase();
    final matches = _dishKeywords.keys.where(dish.contains).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (matches.isNotEmpty) return _dishKeywords[matches.first]!;

    final cuisine = cuisineType.toLowerCase();
    for (final entry in _cuisineFallback.entries) {
      if (cuisine.contains(entry.key)) return entry.value;
    }
    return '🍽️';
  }

  /// Stable across runs — Dart's own hashCode is not guaranteed to be,
  /// and a card that changed colour between launches would read as a bug.
  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static CuisineVisual forDish(String dishName, String cuisineType) {
    final seed = _stableHash('$dishName|$cuisineType');
    return CuisineVisual(
      _emojiFor(dishName, cuisineType),
      _gradients[seed % _gradients.length],
    );
  }

  static List<({double left, double top, double size, double opacity})>
      motifFor(String dishName) {
    final seed = _stableHash(dishName);
    return List.generate(5, (i) {
      final n = (seed >> (i * 3)) & 0xff;
      return (
        left: 0.06 + ((n % 7) / 7.0) * 0.72,
        top: 0.08 + (((n >> 3) % 5) / 5.0) * 0.68,
        size: 15.0 + (n % 11) * 1.6,
        opacity: 0.07 + ((n % 5) / 5.0) * 0.07,
      );
    });
  }
}
