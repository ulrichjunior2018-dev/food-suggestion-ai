import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../l10n/strings.dart';
import '../models/food_suggestion.dart';
import '../models/user_preferences.dart';
import 'profile_service.dart';

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
/// [GroqService.refine] to continue the same conversation.
class GroqResult {
  final List<FoodSuggestion> suggestions;
  final List<Map<String, String>> history;

  const GroqResult({required this.suggestions, required this.history});
}

/// A conversational turn: natural-language [reply] plus any dish cards
/// the assistant decided to attach. Keeping both in one payload is what
/// lets the chat answer like a person AND render real cards inline.
class ChatResult {
  final String reply;
  final List<FoodSuggestion> suggestions;
  final List<Map<String, String>> history;

  const ChatResult({
    required this.reply,
    required this.suggestions,
    required this.history,
  });
}

/// Talks to Groq's OpenAI-compatible chat completions endpoint. Serves
/// three modes over one transport: one-shot suggestions from onboarding,
/// multi-turn refinement of those suggestions, and free-form conversation.
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

  /// Shared safety clause. Dietary restrictions are the one place where a
  /// wrong answer is a real-world harm and not just a bad recommendation,
  /// so it is stated once and injected into every system prompt rather
  /// than being left to chance in a single prompt's wording.
  static const String _safetyClause = '''
DIETARY SAFETY — this overrides every other instruction:
- Never suggest a dish that violates the user's stated dietary restriction.
- Treat allergies as absolute. If a user mentions an allergy, exclude that
  ingredient and anything that commonly contains it or is cross-contaminated
  with it, and say plainly that you have done so.
- If you are not certain a dish is safe for their restriction, do not suggest
  it. Offer a dish you are certain about instead.
- You are not a medical professional. For a severe allergy, remind the user
  once, briefly, to confirm ingredients before eating.''';

  /// Rules that govern the shape and honesty of every dish object,
  /// shared by both prompts so the two can't drift apart.
  static const String _dishRules = '''
For every dish you return:
- "canonicalName" must be the SHORT, widely-recognized name for the dish,
  suitable for looking up a photograph or a recipe (e.g. name: "Spicy
  Tomato Bruschetta" -> canonicalName: "Bruschetta"; name: "Grandma's
  Sunday Jollof" -> canonicalName: "Jollof Rice"). One to three words.
  Prefer a real, well-known dish name over an invented one.
- "nutritionTags": at most 3 short QUALITATIVE descriptors, e.g.
  "protein-rich", "light", "high fibre", "slow-release energy".
  NEVER output calories, grams, macros or any number. You cannot measure
  those, and people make health decisions on numbers. Qualitative only.
- "goalFit": one short sentence on how this dish serves the user's stated
  health goal. Return an empty string if they have not stated one. Do not
  invent a goal.''';

  static const String _suggestionSystemPrompt = '''
You are a friendly, knowledgeable food recommendation engine inside a mobile app.
Given a user's dietary restriction, favorite cuisines, current mood/craving, and
budget/time constraint, suggest exactly 3 specific dishes that fit ALL of their
constraints.
When the user asks you to refine your suggestions (e.g. "spicier", "cheaper",
"something different"), adjust your 3 suggestions to honor that request while
still respecting the original constraints — you may keep a suggestion that
already fits, replace it, or swap all three, whichever best satisfies the
new request.

$_safetyClause

$_dishRules

Respond with ONLY valid JSON in this exact shape, no prose outside the JSON:
{
  "suggestions": [
    {
      "name": "Dish name",
      "canonicalName": "Short well-known name for image lookup",
      "cuisineType": "e.g. Italian",
      "description": "1-2 sentence description of the dish",
      "whyItFits": "1 sentence tying it directly to what the user asked for",
      "nutritionTags": ["protein-rich", "light"],
      "goalFit": "1 sentence on how this serves their health goal, or empty"
    }
  ]
}
''';

  static const String _chatSystemPrompt = '''
You are the in-app food assistant for a personalized food suggestion app.
You talk with the user naturally about what to eat: answering questions about
dishes, ingredients, substitutions, prep time, and cost, and recommending
specific dishes when that is what they want.

Style: warm, concise, practical. Two or three sentences per reply unless the
user asks for detail. Never pad. Ask a short clarifying question when the
request is genuinely ambiguous, but prefer making a confident recommendation.

$_safetyClause

$_dishRules

Respond with ONLY valid JSON in this exact shape, no prose outside the JSON:
{
  "reply": "your conversational answer to the user",
  "suggestions": [
    {
      "name": "Dish name",
      "canonicalName": "Short well-known name for image lookup",
      "cuisineType": "e.g. Italian",
      "description": "1-2 sentence description of the dish",
      "whyItFits": "1 sentence tying it to what the user just asked for",
      "nutritionTags": ["protein-rich", "light"],
      "goalFit": "1 sentence on how this serves their health goal, or empty"
    }
  ]
}

Put dishes in "suggestions" ONLY when you are actually recommending specific
dishes in that turn. For a general question, an explanation, or a clarifying
question, return an empty "suggestions" array and put everything in "reply".
Never repeat a dish's full description in "reply" if it is already in
"suggestions" — the app renders those as cards.
''';

  /// Seeds a fresh conversation. When the user has already completed
  /// onboarding, their answers are folded into the system turn so the
  /// chat picks up where the questionnaire left off instead of starting
  /// cold and asking them everything a second time.
  static List<Map<String, String>> newChatHistory({
    UserPreferences? preferences,
  }) {
    final buffer = StringBuffer(_chatSystemPrompt)
      ..write(ProfileService.instance.promptBlock())
      ..write(S.aiLanguageInstruction);

    if (preferences != null && preferences.isComplete) {
      buffer.write('''

What you already know about this user from onboarding — apply it without
being asked, and do not re-ask for it:
- Dietary restriction: ${preferences.dietaryRestriction}
- Preferred cuisines: ${preferences.cuisines.join(', ')}
- Current mood/craving: ${preferences.mood}
- Budget/time: ${preferences.budget}''');
    }

    return [
      {'role': 'system', 'content': buffer.toString()},
    ];
  }

  Future<GroqResult> getSuggestions(UserPreferences prefs) async {
    final userPrompt = '''
Dietary restriction: ${prefs.dietaryRestriction}
Preferred cuisines: ${prefs.cuisines.join(', ')}
Current mood/craving: ${prefs.mood}
Budget/time: ${prefs.budget}
''';

    final history = <Map<String, String>>[
      {
        'role': 'system',
        'content': _suggestionSystemPrompt +
            ProfileService.instance.promptBlock() +
            S.aiLanguageInstruction,
      },
      {'role': 'user', 'content': userPrompt},
    ];

    return _suggestionCall(history);
  }

  /// Continues an existing suggestion conversation with a follow-up
  /// instead of starting a fresh one-shot prompt. This is what makes
  /// "spicier" / "cheaper" actually refine the prior answer rather than
  /// re-rolling a brand new random set of 3 dishes.
  Future<GroqResult> refine(
    List<Map<String, String>> priorHistory,
    String refinementRequest,
  ) async {
    final history = [
      ...priorHistory,
      {'role': 'user', 'content': refinementRequest},
    ];
    return _suggestionCall(history);
  }

  /// One conversational turn. Returns the assistant's prose reply plus
  /// any dish cards it attached, and the grown history for the next turn.
  Future<ChatResult> chat(
    List<Map<String, String>> priorHistory,
    String message,
  ) async {
    final history = [
      ...priorHistory,
      {'role': 'user', 'content': message},
    ];

    final content = await _rawCompletion(history);

    try {
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final reply = (parsed['reply'] as String?)?.trim() ?? '';
      final rawSuggestions = parsed['suggestions'];

      final suggestions = rawSuggestions is List
          ? rawSuggestions
              .whereType<Map<String, dynamic>>()
              .map(FoodSuggestion.fromJson)
              .toList()
          : <FoodSuggestion>[];

      return ChatResult(
        reply: reply.isEmpty ? S.didNotCatch : reply,
        suggestions: suggestions,
        history: [
          ...history,
          {'role': 'assistant', 'content': content},
        ],
      );
    } catch (e) {
      throw GroqServiceException('Got a reply but could not read it: $e');
    }
  }

  Future<GroqResult> _suggestionCall(List<Map<String, String>> history) async {
    final content = await _rawCompletion(history);

    try {
      final parsedContent = jsonDecode(content) as Map<String, dynamic>;
      final rawSuggestions = parsedContent['suggestions'] as List;

      final suggestions = rawSuggestions
          .map((s) => FoodSuggestion.fromJson(s as Map<String, dynamic>))
          .toList();

      return GroqResult(
        suggestions: suggestions,
        history: [
          ...history,
          {'role': 'assistant', 'content': content},
        ],
      );
    } catch (e) {
      throw GroqServiceException(
        'Got a response back but could not parse it: $e',
      );
    }
  }

  /// The single transport path every mode shares — one place to own
  /// auth, timeouts, token budget and HTTP error mapping, instead of
  /// three copies drifting apart.
  Future<String> _rawCompletion(List<Map<String, String>> history) async {
    if (_apiKey.isEmpty) {
      throw GroqServiceException(S.noApiKey);
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
              // gpt-oss-20b is a reasoning model — it spends part of its
              // completion budget thinking before it writes the JSON body.
              // A tight cap truncates it mid-thought and yields invalid
              // JSON (confirmed: 700 was too low and broke live requests).
              'max_tokens': 2048,
            }),
          )
          // Tight enough that a stalled connection fails fast into the
          // retry UI rather than spinning forever, but generous enough
          // not to punish a normal-if-slow mobile connection.
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw GroqServiceException(S.timedOut);
    } catch (e) {
      throw GroqServiceException(S.couldNotReach(e.toString()));
    }

    if (response.statusCode != 200) {
      throw GroqServiceException(
        'Groq API error (${response.statusCode}): ${response.body}',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw GroqServiceException('Unexpected response shape from Groq: $e');
    }
  }
}
