import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'favorites_service.dart';

/// Owns everything the app knows about the user beyond a single session:
/// the profile they filled in explicitly, and the preferences inferred
/// from what they actually do.
///
/// The inference is deliberately asymmetric. Saves are already persisted
/// by [FavoritesService], so the positive signal is read straight from
/// there rather than tracked twice. Only the negative signal — dishes
/// they moved on from — needs its own store.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const String _profileKey = 'user_profile_v1';
  static const String _skippedKey = 'skipped_dishes_v1';

  /// Cap on remembered skips. Recent behaviour is the useful signal, and
  /// an unbounded list would eventually bloat both storage and the prompt.
  static const int _maxSkips = 24;

  final ValueNotifier<UserProfile> profile =
      ValueNotifier<UserProfile>(UserProfile.empty);
  final ValueNotifier<List<String>> skipped =
      ValueNotifier<List<String>>(const []);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawProfile = prefs.getString(_profileKey);
      if (rawProfile != null && rawProfile.isNotEmpty) {
        profile.value = UserProfile.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
      }

      skipped.value = prefs.getStringList(_skippedKey) ?? const [];
    } catch (_) {
      profile.value = UserProfile.empty;
      skipped.value = const [];
    }
  }

  Future<void> saveProfile(UserProfile next) async {
    profile.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(next.toJson()));
    } catch (_) {
      // Storage unavailable — profile stays live for this session only.
    }
  }

  /// Records dishes the user moved past. Called when they ask for a
  /// refinement: whatever was on screen at that moment is, implicitly,
  /// not what they wanted. Implicit signal beats asking them to rate
  /// things they never wanted to rate.
  Future<void> recordSkipped(Iterable<String> dishNames) async {
    final next = [...skipped.value];
    for (final name in dishNames) {
      final clean = name.trim();
      if (clean.isEmpty) continue;
      next.remove(clean);
      next.insert(0, clean);
    }
    skipped.value = next.take(_maxSkips).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_skippedKey, skipped.value);
    } catch (_) {
      // Non-fatal: learning degrades, the app does not.
    }
  }

  Future<void> clearLearned() async {
    skipped.value = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skippedKey);
    } catch (_) {
      // Ignored by design.
    }
  }

  /// Cuisines ranked by how often the user has saved a dish from them.
  /// Derived from favorites rather than counted separately, so it can
  /// never drift out of sync with what they actually kept.
  Map<String, int> get likedCuisines {
    final counts = <String, int>{};
    for (final dish in FavoritesService.instance.favorites.value) {
      final cuisine = dish.cuisineType.trim();
      if (cuisine.isEmpty) continue;
      counts[cuisine] = (counts[cuisine] ?? 0) + 1;
    }
    return counts;
  }

  /// The compact block folded into every system prompt. Returns an empty
  /// string when there is genuinely nothing to say, so a brand-new user
  /// doesn't get a prompt full of empty headings.
  String promptBlock() {
    final p = profile.value;
    final lines = <String>[];

    if (p.allergies.trim().isNotEmpty) {
      lines.add('- ALLERGIES (treat as absolute): ${p.allergies.trim()}');
    }
    if (p.spiceTolerance.isNotEmpty) {
      lines.add('- Spice tolerance: ${p.spiceTolerance}');
    }
    if (p.cookingSkill.isNotEmpty) {
      lines.add('- Cooking confidence: ${p.cookingSkill}');
    }
    if (p.timeAvailable.isNotEmpty) {
      lines.add('- Time they usually have: ${p.timeAvailable}');
    }
    if (p.healthGoal.isNotEmpty) {
      lines.add('- Health goal: ${p.healthGoal}');
    }
    if (p.householdSize.isNotEmpty) {
      lines.add('- Cooking for: ${p.householdSize}');
    }

    final saved = FavoritesService.instance.favorites.value
        .take(8)
        .map((d) => d.name)
        .toList();
    if (saved.isNotEmpty) {
      lines.add('- Dishes they saved (they liked these): ${saved.join(', ')}');
    }

    final cuisines = likedCuisines.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (cuisines.isNotEmpty) {
      lines.add(
        '- Cuisines they gravitate to: '
        '${cuisines.take(3).map((e) => '${e.key} (${e.value})').join(', ')}',
      );
    }

    final recentSkips = skipped.value.take(8).toList();
    if (recentSkips.isNotEmpty) {
      lines.add(
        '- Dishes they passed on recently (avoid repeating these and '
        'prefer a different direction): ${recentSkips.join(', ')}',
      );
    }

    if (lines.isEmpty) return '';

    return '''

WHAT YOU KNOW ABOUT THIS USER — apply it without being asked, and never
re-ask for anything already listed here:
${lines.join('\n')}''';
  }
}
