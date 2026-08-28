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

/// Talks to Groq's OpenAI-compatible chat completions endpoint to turn a
/// user's onboarding answers into concrete, personalized food suggestions.
///
/// The API key is never hardcoded — it's injected at build/run time via
/// --dart-define=GROQ_API_KEY=xxx, so it never lives in source control.
class GroqService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

  // Fast, free-tier-friendly Groq model. Swap for another Groq model name
  // if this one is deprecated by the time you run it.
  static const String _model = 'openai/gpt-oss-20b';

  Future<List<FoodSuggestion>> getSuggestions(UserPreferences prefs) async {
    if (_apiKey.isEmpty) {
      throw GroqServiceException(
        'No API key configured. Run the app with:\n'
        'flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here',
      );
    }

    final systemPrompt = '''
You are a friendly, knowledgeable food recommendation engine inside a mobile app.
Given a user's dietary restriction, favorite cuisines, current mood/craving, and
budget/time constraint, suggest exactly 3 specific dishes that fit ALL of their
constraints. Never suggest a dish that violates the stated dietary restriction.

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

    final userPrompt = '''
Dietary restriction: ${prefs.dietaryRestriction}
Preferred cuisines: ${prefs.cuisines.join(', ')}
Current mood/craving: ${prefs.mood}
Budget/time: ${prefs.budget}
''';

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
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
              'response_format': {'type': 'json_object'},
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      throw GroqServiceException('Could not reach Groq: $e');
    }

    if (response.statusCode != 200) {
      throw GroqServiceException(
        'Groq API error (${response.statusCode}): ${response.body}',
      );
    }

    late final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          decoded['choices'][0]['message']['content'] as String;
      final parsedContent = jsonDecode(content) as Map<String, dynamic>;
      final rawSuggestions = parsedContent['suggestions'] as List;

      return rawSuggestions
          .map((s) => FoodSuggestion.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw GroqServiceException(
        'Got a response back but could not parse it: $e',
      );
    }
  }
}
