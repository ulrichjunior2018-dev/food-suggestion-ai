import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/food_suggestion.dart';
import '../models/user_preferences.dart';

/// Thrown when the Groq API call fails or returns something we can't parse.
/// Kept as its own type so the UI can distinguish "no API key configured"
/// from "network/API error" and show the right message.
class GroqServiceException implements Exception {
  final String message;
  GroqServiceException(this.message);

  @override
  String toString() => message;
}

/// A round-trip result: the parsed suggestions plus the full message
/// history so far. Callers hang onto [history] and pass it back into
/// [GroqService.refine] to continue the same conversation — the model
/// keeps context of what it already suggested and why, instead of
/// starting from scratch on every request.
class GroqResult {
  final List<FoodSuggestion> suggestions;
  final List<Map<String, String>> history;

  const GroqResult({required this.suggestions, required this.history});
}

/// Talks to Groq's OpenAI-compatible chat completions endpoint to turn a
/// user's onboarding answers into concrete, personalized food suggestions,
/// and supports multi-turn refinement ("spicier", "cheaper", etc.) on top
/// of the same conversation rather than re-rolling from nothing.
///
/// The API key is never hardcoded — it's injected at build/run time via
/// --dart-define=GROQ_API_KEY=xxx, so it never lives in source control.
class GroqService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

  // Fast, free-tier Groq model confirmed available on a standard API key.
  // Check `curl https://api.groq.com/openai/v1/models -H "Authorization:
  // Bearer $KEY"` if this ever 404s — Groq's free lineup changes.
  static const String _model = 'openai/gpt-oss-20b';

  static const String _systemPrompt = '''
You are a friendly, knowledgeable food recommendation engine inside a mobile app.
Given a user's dietary restriction, favorite cuisines, current mood/craving, and
budget/time constraint, suggest exactly 3 specific dishes that fit ALL of their
constraints. Never suggest a dish that violates the stated dietary restriction.
When the user asks you to refine your suggestions (e.g. "spicier", "cheaper",
"something different"), adjust your 3 suggestions to honor that request while
still respecting the original constraints — you may keep a suggestion that
already fits, replace it, or swap all three, whichever best satisfies the
new request.

Respond with ONLY valid JSON in this exact shape, no prose outside the JSON:
{
  "suggestions": [
    {
      "name": "Dish name",
      "cuisineType": "e.g. Italian",
      "description": "1-2 sentence description of the dish",
      "whyItFits": "1 sentence tying it directly to what the user asked for"
    }
  ]
}
''';

  Future<GroqResult> getSuggestions(UserPreferences prefs) async {
    final userPrompt = '''
Dietary restriction: ${prefs.dietaryRestriction}
Preferred cuisines: ${prefs.cuisines.join(', ')}
Current mood/craving: ${prefs.mood}
Budget/time: ${prefs.budget}
''';

    final history = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    return _call(history);
  }

  /// Continues an existing conversation with a follow-up request instead
  /// of starting a fresh one-shot prompt. This is what makes "spicier" /
  /// "cheaper" actually refine the prior answer rather than just re-rolling
  /// a brand new random set of 3 dishes.
  Future<GroqResult> refine(
    List<Map<String, String>> priorHistory,
    String refinementRequest,
  ) async {
    final history = [
      ...priorHistory,
      {'role': 'user', 'content': refinementRequest},
    ];
    return _call(history);
  }

  Future<GroqResult> _call(List<Map<String, String>> history) async {
    if (_apiKey.isEmpty) {
      throw GroqServiceException(
        'No API key configured. Run the app with:\n'
        'flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here',
      );
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': history,
              'response_format': {'type': 'json_object'},
              'temperature': 0.7,
              // Caps worst-case generation length so a request can't hang
              // waiting on tokens well past what 3 short suggestions need —
              // keeps the "fast, swift" feel even if the model gets chatty.
              'max_tokens': 2048,
            }),
          )
          // Tight enough that a stalled connection fails fast into the
          // retry UI instead of leaving the loading state spinning
          // indefinitely, but generous enough not to punish a normal
          // (if slightly slow) mobile connection.
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw GroqServiceException(
        'That took too long — your connection might be slow right now. Try again?',
      );
    } catch (e) {
      throw GroqServiceException('Could not reach Groq — check your connection: $e');
    }

    if (response.statusCode != 200) {
      throw GroqServiceException(
        'Groq API error (${response.statusCode}): ${response.body}',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices'][0]['message']['content'] as String;
      final parsedContent = jsonDecode(content) as Map<String, dynamic>;
      final rawSuggestions = parsedContent['suggestions'] as List;

      final suggestions = rawSuggestions
          .map((s) => FoodSuggestion.fromJson(s as Map<String, dynamic>))
          .toList();

      // Append the assistant's own reply to the history so a subsequent
      // refine() call gives the model full context of what it already said.
      final updatedHistory = [
        ...history,
        {'role': 'assistant', 'content': content},
      ];

      return GroqResult(suggestions: suggestions, history: updatedHistory);
    } catch (e) {
      throw GroqServiceException(
        'Got a response back but could not parse it: $e',
      );
    }
  }
}
