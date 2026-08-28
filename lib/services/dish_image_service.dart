import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Where a dish photo came from. Drives the credit line, and makes the
/// resolution quality visible rather than hidden.
enum PhotoSource { recipeDb, stock }

/// A photograph for a dish plus the credit its source requires.
class DishPhoto {
  final String url;
  final String credit;
  final PhotoSource source;

  const DishPhoto({
    required this.url,
    required this.credit,
    required this.source,
  });
}

/// Resolves a photograph for a dish through a cascade, most specific
/// first:
///
///   1. TheMealDB — a real photograph *of that named dish*. Free, no key
///      needed for the public test key. Its catalogue is a few hundred
///      meals, so it hits sometimes, and when it does the picture is
///      genuinely correct rather than merely thematic.
///   2. Pexels — representative stock for anything the recipe database
///      doesn't know. Plausible, not exact.
///   3. Nothing — the card keeps its per-cuisine gradient treatment.
///
/// The whole chain is fail-soft. Every error path returns null and the
/// card renders its gradient: a missing photo must never produce a broken
/// frame or block a suggestion from appearing. The dish is the product;
/// the photo is decoration.
class DishImageService {
  DishImageService._();
  static final DishImageService instance = DishImageService._();

  static const String _pexelsKey = String.fromEnvironment('PEXELS_API_KEY');

  /// TheMealDB's documented free/development key.
  static const String _mealDbKey = '1';

  static bool get stockConfigured => _pexelsKey.isNotEmpty;

  /// Process-lifetime cache, negative results included. The same dish
  /// renders across the results screen, the chat and favorites, and the
  /// Pexels free tier is 200 requests/hour — so a miss is remembered
  /// rather than re-fetched on every rebuild.
  static final Map<String, DishPhoto?> _cache = {};

  Future<DishPhoto?> photoFor({
    required String canonicalName,
    required String displayName,
    required String cuisineType,
  }) async {
    final lookup = canonicalName.trim().isNotEmpty
        ? canonicalName.trim()
        : displayName.trim();
    if (lookup.isEmpty) return null;

    final key = lookup.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];

    final fromRecipeDb = await _tryMealDb(lookup);
    if (fromRecipeDb != null) {
      _cache[key] = fromRecipeDb;
      return fromRecipeDb;
    }

    final fromStock = await _tryPexels(lookup, cuisineType);
    _cache[key] = fromStock;
    return fromStock;
  }

  Future<DishPhoto?> _tryMealDb(String dishName) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://www.themealdb.com/api/json/v1/$_mealDbKey/search.php'
              '?s=${Uri.encodeQueryComponent(dishName)}',
            ),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final meals = decoded['meals'];
      if (meals is! List || meals.isEmpty) return null;

      final meal = meals.first as Map<String, dynamic>;
      final thumb = (meal['strMealThumb'] as String?)?.trim();
      final title = (meal['strMeal'] as String?)?.trim() ?? '';
      if (thumb == null || thumb.isEmpty) return null;

      // Guard against a loose match returning something unrelated: the
      // result should share at least one meaningful word with the query.
      if (!_looksRelated(dishName, title)) return null;

      return DishPhoto(
        url: thumb,
        credit: 'TheMealDB',
        source: PhotoSource.recipeDb,
      );
    } catch (_) {
      return null;
    }
  }

  Future<DishPhoto?> _tryPexels(String dishName, String cuisineType) async {
    if (!stockConfigured) return null;
    try {
      final query = Uri.encodeQueryComponent(
        '$dishName ${cuisineType.trim()} food dish'.trim(),
      );
      final response = await http
          .get(
            Uri.parse(
              'https://api.pexels.com/v1/search'
              '?query=$query&per_page=1&orientation=landscape&size=medium',
            ),
            headers: {'Authorization': _pexelsKey},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final photos = decoded['photos'];
      if (photos is! List || photos.isEmpty) return null;

      final photo = photos.first as Map<String, dynamic>;
      final src = photo['src'] as Map<String, dynamic>?;
      final url =
          (src?['landscape'] ?? src?['medium'] ?? src?['original']) as String?;
      if (url == null || url.isEmpty) return null;

      final photographer = (photo['photographer'] as String?)?.trim() ?? '';
      return DishPhoto(
        url: url,
        credit: photographer.isEmpty ? 'Pexels' : '$photographer / Pexels',
        source: PhotoSource.stock,
      );
    } catch (_) {
      // Network, parse, timeout, or a browser CORS rejection on web —
      // all the same outcome from the UI's point of view.
      return null;
    }
  }

  static const _stopWords = {
    'the', 'and', 'with', 'a', 'of', 'in', 'on', 'style', 'dish', 'food',
  };

  bool _looksRelated(String query, String result) {
    if (result.isEmpty) return false;
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), ' ');
    final queryWords = norm(query)
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();
    if (queryWords.isEmpty) return true;
    final resultWords = norm(result).split(RegExp(r'\s+')).toSet();
    return queryWords.any(resultWords.contains);
  }
}
