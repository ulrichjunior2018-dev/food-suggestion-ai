/// The optional deep profile, gathered separately from the fast 4-step
/// onboarding so a first-time user still reaches a suggestion in under a
/// minute. Every field is optional; an empty profile is valid and simply
/// contributes nothing to the prompt.
class UserProfile {
  /// Free text, deliberately not a fixed list — real allergies are
  /// specific and a dropdown would quietly exclude someone.
  final String allergies;

  final String spiceTolerance;
  final String cookingSkill;
  final String timeAvailable;
  final String healthGoal;
  final String householdSize;

  const UserProfile({
    this.allergies = '',
    this.spiceTolerance = '',
    this.cookingSkill = '',
    this.timeAvailable = '',
    this.healthGoal = '',
    this.householdSize = '',
  });

  static const empty = UserProfile();

  static const spiceOptions = ['Mild', 'Medium', 'Hot', 'Very hot'];
  static const skillOptions = ['Beginner', 'Comfortable', 'Confident'];
  static const timeOptions = ['Under 15 min', '15–30 min', '30–60 min', 'No rush'];
  static const goalOptions = [
    'Just eat well',
    'Lose weight',
    'Build muscle',
    'More energy',
    'Eat on a budget',
  ];
  static const householdOptions = ['Just me', 'Two of us', '3–4', '5+'];

  bool get isEmpty =>
      allergies.isEmpty &&
      spiceTolerance.isEmpty &&
      cookingSkill.isEmpty &&
      timeAvailable.isEmpty &&
      healthGoal.isEmpty &&
      householdSize.isEmpty;

  UserProfile copyWith({
    String? allergies,
    String? spiceTolerance,
    String? cookingSkill,
    String? timeAvailable,
    String? healthGoal,
    String? householdSize,
  }) {
    return UserProfile(
      allergies: allergies ?? this.allergies,
      spiceTolerance: spiceTolerance ?? this.spiceTolerance,
      cookingSkill: cookingSkill ?? this.cookingSkill,
      timeAvailable: timeAvailable ?? this.timeAvailable,
      healthGoal: healthGoal ?? this.healthGoal,
      householdSize: householdSize ?? this.householdSize,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        allergies: (json['allergies'] as String?) ?? '',
        spiceTolerance: (json['spiceTolerance'] as String?) ?? '',
        cookingSkill: (json['cookingSkill'] as String?) ?? '',
        timeAvailable: (json['timeAvailable'] as String?) ?? '',
        healthGoal: (json['healthGoal'] as String?) ?? '',
        householdSize: (json['householdSize'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'allergies': allergies,
        'spiceTolerance': spiceTolerance,
        'cookingSkill': cookingSkill,
        'timeAvailable': timeAvailable,
        'healthGoal': healthGoal,
        'householdSize': householdSize,
      };
}
