import 'food_suggestion.dart';

/// A single turn in the conversational assistant. Carries optional
/// [suggestions] so the assistant can answer in natural language AND
/// render real dish cards inline in the same message, rather than
/// forcing the user back to a separate results screen.
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final List<FoodSuggestion> suggestions;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.suggestions = const [],
  });
}
