/// One AI-generated food suggestion, parsed from the LLM's structured
/// JSON response.
class FoodSuggestion {
  final String name;
  final String cuisineType;
  final String description;
  final String whyItFits;

  const FoodSuggestion({
    required this.name,
    required this.cuisineType,
    required this.description,
    required this.whyItFits,
  });

  factory FoodSuggestion.fromJson(Map<String, dynamic> json) {
    return FoodSuggestion(
      name: (json['name'] as String?)?.trim() ?? 'Untitled dish',
      cuisineType: (json['cuisineType'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      whyItFits: (json['whyItFits'] as String?)?.trim() ?? '',
    );
  }
}
