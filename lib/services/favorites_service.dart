import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_suggestion.dart';

/// Local persistence for dishes the user saved. Exposed as a singleton
/// with a [ValueNotifier] so any screen can listen and stay in sync
/// without threading callbacks through the widget tree.
///
/// Every storage call is defensive: a device that refuses local storage
/// (private browsing, cleared site data) should degrade to "favorites
/// don't persist", never to a crash on launch.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const String _storageKey = 'saved_dishes_v1';

  final ValueNotifier<List<FoodSuggestion>> favorites =
      ValueNotifier<List<FoodSuggestion>>(const []);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? const <String>[];
      favorites.value = raw
          .map((entry) {
            try {
              return FoodSuggestion.fromJson(
                jsonDecode(entry) as Map<String, dynamic>,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<FoodSuggestion>()
          .toList();
    } catch (_) {
      favorites.value = const [];
    }
  }

  bool isFavorite(FoodSuggestion suggestion) =>
      favorites.value.contains(suggestion);

  Future<void> toggle(FoodSuggestion suggestion) async {
    final next = [...favorites.value];
    if (next.contains(suggestion)) {
      next.remove(suggestion);
    } else {
      next.insert(0, suggestion);
    }
    favorites.value = next;
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        favorites.value.map((s) => jsonEncode(s.toJson())).toList(),
      );
    } catch (_) {
      // Storage unavailable — favorites stay live for this session only.
    }
  }
}
