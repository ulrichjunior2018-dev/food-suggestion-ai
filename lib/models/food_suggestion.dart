/// One AI-generated food suggestion, parsed from the LLM's structured
/// JSON response.
class FoodSuggestion {
  final String name;

  /// The widely-recognized name for this dish, asked of the model purely
  /// for image lookup. The creative name ("Spicy Tomato Bruschetta") is
  /// what the user reads; the canonical one ("Bruschetta") is what
  /// actually matches a recipe database or a photo library. Without this
  /// split, image search is guessing.
  final String canonicalName;

  final String cuisineType;
  final String description;
  final String whyItFits;

  /// Qualitative nutrition descriptors only — "protein-rich", "light",
  /// "slow-release energy". Deliberately never numeric: a language model
  /// estimating calories or macros is guessing, and people make health
  /// decisions on numbers. Real figures need a real nutrition database.
  final List<String> nutritionTags;

  /// One line on how this dish serves the user's stated health goal.
  /// Empty when they haven't set one.
  final String goalFit;

  const FoodSuggestion({
    required this.name,
    required this.canonicalName,
    required this.cuisineType,
    required this.description,
    required this.whyItFits,
    this.nutritionTags = const [],
    this.goalFit = '',
  });

  factory FoodSuggestion.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? 'Untitled dish';
    final rawTags = json['nutritionTags'];

    return FoodSuggestion(
      name: name,
      // Fall back to the display name so image lookup still has something
      // to work with if the model omits the field.
      canonicalName: (json['canonicalName'] as String?)?.trim().isNotEmpty ==
              true
          ? (json['canonicalName'] as String).trim()
          : name,
      cuisineType: (json['cuisineType'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      whyItFits: (json['whyItFits'] as String?)?.trim() ?? '',
      nutritionTags: rawTags is List
          ? rawTags
              .whereType<String>()
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .take(3)
              .toList()
          : const [],
      goalFit: (json['goalFit'] as String?)?.trim() ?? '',
    );
  }

  /// Round-trips back to JSON so saved favorites can be persisted to
  /// local storage and rehydrated with [fromJson] on next launch.
  Map<String, dynamic> toJson() => {
        'name': name,
        'canonicalName': canonicalName,
        'cuisineType': cuisineType,
        'description': description,
        'whyItFits': whyItFits,
        'nutritionTags': nutritionTags,
        'goalFit': goalFit,
      };

  /// Dish name is the natural identity here — the same dish suggested
  /// twice in different sessions should not save twice.
  @override
  bool operator ==(Object other) =>
      other is FoodSuggestion && other.name.toLowerCase() == name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}
