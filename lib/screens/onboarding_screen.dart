import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/animated_entrance.dart';
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


  List<String> get _steps => S.steps;
  List<String> get _dietaryOptions => S.dietaryOptions;
  List<String> get _cuisineOptions => S.cuisineOptions;
  List<String> get _moodOptions => S.moodOptions;
  List<String> get _budgetOptions => S.budgetOptions;

  static const _stepIcons = [
    Icons.eco_outlined,
    Icons.public,
    Icons.mood_outlined,
    Icons.payments_outlined,
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
      appBar: AppBar(title: Text(S.onboardingTitle)),
      body: AmbientBackground(
        child: SafeArea(
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
                    subtitle: S.stepSubtitles[0],
                    child: _singleChoiceWrap(
                      options: _dietaryOptions,
                      selected: _dietaryRestriction,
                      onSelect: (v) => setState(() => _dietaryRestriction = v),
                    ),
                  ),
                  _buildStep(
                    title: _steps[1],
                    subtitle: S.stepSubtitles[1],
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
                    subtitle: S.stepSubtitles[2],
                    child: _singleChoiceWrap(
                      options: _moodOptions,
                      selected: _mood,
                      onSelect: (v) => setState(() => _mood = v),
                    ),
                  ),
                  _buildStep(
                    title: _steps[3],
                    subtitle: S.stepSubtitles[3],
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 92),
              child: Row(
                children: [
                  if (_step > 0)
                    PressableScale(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: Text(S.back),
                      ),
                    ),
                  const Spacer(),
                  PressableScale(
                    child: FilledButton(
                      onPressed: _canAdvance ? _next : null,
                      child: Text(
                        _step == _steps.length - 1 ? S.getMySuggestions : S.next,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedEntrance(
                  key: ValueKey('title-' + title),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedEntrance(
                  key: ValueKey('sub-' + title),
                  delay: const Duration(milliseconds: 70),
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.charcoal.withValues(alpha: 0.62),
                        ),
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedEntrance(
                  key: ValueKey('opts-' + title),
                  delay: const Duration(milliseconds: 140),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
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
