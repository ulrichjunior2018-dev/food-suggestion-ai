import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches a short, muted, looping food clip for the home hero.
///
/// Cached for the process lifetime and requested once per launch. A hero
/// video is the most bandwidth-expensive element in the app, so it is
/// deliberately: fetched at SD rather than HD, capped at a short
/// duration, and entirely optional — every failure path returns null and
/// the home screen keeps its gradient hero with no layout shift.
class HeroVideoService {
  HeroVideoService._();
  static final HeroVideoService instance = HeroVideoService._();

  static const String _pexelsKey = String.fromEnvironment('PEXELS_API_KEY');

  static String? _cached;
  static bool _attempted = false;

  /// Rotating queries so the hero is not identical on every device, while
  /// staying on-theme.
  static const _queries = [
    'cooking food closeup',
    'fresh vegetables cooking',
    'restaurant food plating',
    'pasta cooking pan',
  ];

  Future<String?> heroClip() async {
    if (_attempted) return _cached;
    _attempted = true;
    if (_pexelsKey.isEmpty) return null;

    try {
      final query = _queries[DateTime.now().day % _queries.length];
      final response = await http
          .get(
            Uri.parse(
              'https://api.pexels.com/v1/videos/search'
              '?query=${Uri.encodeQueryComponent(query)}'
              '&per_page=8&orientation=portrait&size=small',
            ),
            headers: {'Authorization': _pexelsKey},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final videos = decoded['videos'];
      if (videos is! List || videos.isEmpty) return null;

      // Prefer a genuinely short clip: this loops behind a headline, and
      // a 30-second file is thirty seconds of data nobody watches.
      final candidates = videos
          .whereType<Map<String, dynamic>>()
          .where((v) => (v['duration'] as num?) != null)
          .toList()
        ..sort((a, b) =>
            (a['duration'] as num).compareTo(b['duration'] as num));

      for (final video in candidates) {
        final files = video['video_files'];
        if (files is! List) continue;

        // SD mp4 only. HLS entries have null dimensions and are not worth
        // the player complexity for a decorative loop.
        final mp4s = files
            .whereType<Map<String, dynamic>>()
            .where((f) =>
                (f['file_type'] as String?)?.contains('mp4') == true &&
                (f['link'] as String?)?.isNotEmpty == true)
            .toList();
        if (mp4s.isEmpty) continue;

        mp4s.sort((a, b) {
          final aw = (a['width'] as num?) ?? 9999;
          final bw = (b['width'] as num?) ?? 9999;
          return aw.compareTo(bw);
        });

        final link = mp4s.first['link'] as String;
        _cached = link;
        return link;
      }
      return null;
    } catch (_) {
      // No key, rate limited, offline, or CORS-blocked on web — the hero
      // simply stays as it is.
      return null;
    }
  }
}
