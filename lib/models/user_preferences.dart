/// Captures everything gathered from the onboarding questionnaire.
/// This is the single source of truth handed to the AI service to
/// generate personalized food suggestions.
class UserPreferences {
  final String dietaryRestriction;
  final List<String> cuisines;
  final String mood;
  final String budget;

  const UserPreferences({
    required this.dietaryRestriction,
    required this.cuisines,
    required this.mood,
    required this.budget,
  });

  UserPreferences copyWith({
    String? dietaryRestriction,
    List<String>? cuisines,
    String? mood,
    String? budget,
  }) {
    return UserPreferences(
      dietaryRestriction: dietaryRestriction ?? this.dietaryRestriction,
      cuisines: cuisines ?? this.cuisines,
      mood: mood ?? this.mood,
      budget: budget ?? this.budget,
    );
  }

  bool get isComplete =>
      dietaryRestriction.isNotEmpty &&
      cuisines.isNotEmpty &&
      mood.isNotEmpty &&
      budget.isNotEmpty;

  static const empty = UserPreferences(
    dietaryRestriction: '',
    cuisines: [],
    mood: '',
    budget: '',
  );
}
