import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/food_suggestion.dart';
import '../models/user_preferences.dart';
import '../services/groq_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/loading_state.dart';
import '../widgets/pressable_scale.dart';

/// Fetches and displays AI-generated food suggestions for the given
/// [preferences]. Handles loading, error (with retry), and success states
/// explicitly rather than assuming the network call always succeeds, and
/// supports refining the same conversation ("spicier", "cheaper", ...)
/// instead of only being able to re-roll from scratch.
class SuggestionScreen extends StatefulWidget {
  final UserPreferences preferences;

  const SuggestionScreen({super.key, required this.preferences});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _groqService = GroqService();

  late Future<GroqResult> _future;
  List<Map<String, String>>? _history;
  String? _activeRefinement;

  static const _refinements = [
    ('Spicier', '🌶️'),
    ('Cheaper', '💰'),
    ('Something different', '🔄'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _groqService.getSuggestions(widget.preferences);
  }

  void _retry() {
    setState(() {
      _activeRefinement = null;
      _future = _groqService.getSuggestions(widget.preferences);
    });
  }

  void _refine(String request) {
    if (_history == null) return;
    setState(() {
      _activeRefinement = request;
      _future = _groqService.refine(_history!, 'Make it $request.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your suggestions')),
      body: SafeArea(
        child: FutureBuilder<GroqResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _retry,
              );
            }

            final result = snapshot.data;
            _history = result?.history;
            final suggestions = result?.suggestions ?? [];
            if (suggestions.isEmpty) {
              return _ErrorState(
                message: 'No suggestions came back — try again.',
                onRetry: _retry,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              children: [
                if (_activeRefinement != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RefinedBanner(request: _activeRefinement!),
                  ),
                for (var i = 0; i < suggestions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnimatedEntrance(
                      delay: Duration(milliseconds: i * 120),
                      child: _SuggestionCard(suggestion: suggestions[i]),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Want something else?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.charcoal.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _refinements
                      .map((r) => PressableScale(
                            child: OutlinedButton.icon(
                              onPressed: () => _refine(r.$1),
                              icon: Text(r.$2, style: const TextStyle(fontSize: 15)),
                              label: Text(r.$1),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                PressableScale(
                  child: TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Start over with fresh ideas'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RefinedBanner extends StatelessWidget {
  final String request;
  const _RefinedBanner({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.sage),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Refined to be more $request, based on your last picks',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final FoodSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  void _copySuggestion(BuildContext context, FoodSuggestion s) {
    final text = StringBuffer(s.name);
    if (s.description.isNotEmpty) text.write('\n${s.description}');
    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Copied "${s.name}" to your clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = CuisineVisual.forCuisine(suggestion.cuisineType);

    return PressableScale(
      pressScale: 1.0,
      hoverScale: 1.015,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 92,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: visual.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -6,
                  bottom: -14,
                  child: Text(visual.emoji, style: const TextStyle(fontSize: 76)),
                ),
                if (suggestion.cuisineType.isNotEmpty)
                  Positioned(
                    left: 16,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        suggestion.cuisineType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    PressableScale(
                      pressScale: 0.85,
                      child: Tooltip(
                        message: 'Copy dish to clipboard',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _copySuggestion(context, suggestion),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.copy_outlined,
                              size: 18,
                              color: AppColors.terracottaDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(suggestion.description, style: theme.textTheme.bodyMedium),
                if (suggestion.whyItFits.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tan.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, size: 15, color: AppColors.terracotta),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.whyItFits,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.terracottaDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ramen_dining_outlined, size: 48, color: AppColors.errorRed),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            PressableScale(
              child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}
