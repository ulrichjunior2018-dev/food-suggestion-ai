import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/preference_chip.dart';
import '../widgets/premium_route.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/step_progress.dart';
import 'suggestion_screen.dart';

/// A 4-step questionnaire that builds up a [UserPreferences] object,
/// then hands off to [SuggestionScreen] once every step is answered.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  String _dietaryRestriction = '';
  final Set<String> _cuisines = {};
  String _mood = '';
  String _budget = '';

  static const _steps = [
    'Dietary needs',
    'Favorite cuisines',
    'What are you craving?',
    'Budget & time',
  ];

  static const _stepIcons = [
    Icons.eco_outlined,
    Icons.public,
    Icons.mood_outlined,
    Icons.payments_outlined,
  ];

  static const _dietaryOptions = [
    'No restrictions',
    'Vegetarian',
    'Vegan',
    'Halal',
    'Gluten-Free',
    'Dairy-Free',
  ];

  static const _cuisineOptions = [
    'Any',
    'Italian',
    'Asian',
    'Mexican',
    'American',
    'African',
    'Mediterranean',
    'Indian',
  ];

  static const _moodOptions = [
    'Comfort food',
    'Light & fresh',
    'Spicy',
    'Sweet',
    'Something new',
  ];

  static const _budgetOptions = [
    'Quick & cheap',
    'Moderate',
    'Willing to splurge',
  ];

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _dietaryRestriction.isNotEmpty;
      case 1:
        return _cuisines.isNotEmpty;
      case 2:
        return _mood.isNotEmpty;
      case 3:
        return _budget.isNotEmpty;
      default:
        return false;
    }
  }

  void _next() {
    if (!_canAdvance) return;
    if (_step == _steps.length - 1) {
      _submit();
      return;
    }
    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _submit() {
    final prefs = UserPreferences(
      dietaryRestriction: _dietaryRestriction,
      cuisines: _cuisines.toList(),
      mood: _mood,
      budget: _budget,
    );
    Navigator.of(context).push(
      premiumRoute(SuggestionScreen(preferences: prefs)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell us what you\'re craving')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: StepProgress(currentStep: _step, stepIcons: _stepIcons),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep(
                    title: _steps[0],
                    subtitle: 'Any foods we should avoid?',
                    child: _singleChoiceWrap(
                      options: _dietaryOptions,
                      selected: _dietaryRestriction,
                      onSelect: (v) => setState(() => _dietaryRestriction = v),
                    ),
                  ),
                  _buildStep(
                    title: _steps[1],
                    subtitle: 'Pick as many as you like',
                    child: _multiChoiceWrap(
                      options: _cuisineOptions,
                      selected: _cuisines,
                      onToggle: (v) => setState(() {
                        _cuisines.contains(v)
                            ? _cuisines.remove(v)
                            : _cuisines.add(v);
                      }),
                    ),
                  ),
                  _buildStep(
                    title: _steps[2],
                    subtitle: 'What kind of meal do you want right now?',
                    child: _singleChoiceWrap(
                      options: _moodOptions,
                      selected: _mood,
                      onSelect: (v) => setState(() => _mood = v),
                    ),
                  ),
                  _buildStep(
                    title: _steps[3],
                    subtitle: 'How much time or money do you want to spend?',
                    child: _singleChoiceWrap(
                      options: _budgetOptions,
                      selected: _budget,
                      onSelect: (v) => setState(() => _budget = v),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    PressableScale(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    ),
                  const Spacer(),
                  PressableScale(
                    child: FilledButton(
                      onPressed: _canAdvance ? _next : null,
                      child: Text(
                        _step == _steps.length - 1 ? 'Get My Suggestions' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.charcoal.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _singleChoiceWrap({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options
          .map((o) => PreferenceChip(
                label: o,
                selected: selected == o,
                onTap: () => onSelect(o),
              ))
          .toList(),
    );
  }

  Widget _multiChoiceWrap({
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options
          .map((o) => PreferenceChip(
                label: o,
                selected: selected.contains(o),
                onTap: () => onToggle(o),
              ))
          .toList(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
