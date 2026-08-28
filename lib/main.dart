import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/premium_route.dart';
import 'widgets/pressable_scale.dart';

void main() {
  runApp(const FoodSuggestionApp());
}

class FoodSuggestionApp extends StatelessWidget {
  const FoodSuggestionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Suggestion AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.terracotta],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('🍽️', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'What should\nI eat?',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Text(
                'Answer a few quick questions and get personalized food '
                'suggestions powered by AI — matched to your diet, mood, '
                'and budget. Not happy with the picks? Ask for spicier, '
                'cheaper, or something else entirely.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.charcoal.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: PressableScale(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      premiumRoute(const OnboardingScreen()),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
