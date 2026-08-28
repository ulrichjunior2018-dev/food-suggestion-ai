import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/food_suggestion.dart';
import '../models/user_preferences.dart';
import '../services/favorites_service.dart';
import '../services/groq_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/loading_state.dart';
import '../widgets/premium_route.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/suggestion_card.dart';
import 'chat_screen.dart';

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
  List<FoodSuggestion> _current = const [];
  String? _activeRefinement;

  List<(String, String)> get _refinements => [
        (S.spicier, '🌶️'),
        (S.cheaper, '💰'),
        (S.somethingDifferent, '🔄'),
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
    // Asking for a refinement is itself a signal: whatever was on screen
    // is not what they wanted. Recording it here means the app learns
    // from behaviour without ever asking anyone to rate anything.
    ProfileService.instance.recordSkipped(_current.map((d) => d.name));
    setState(() {
      _activeRefinement = request;
      _future = _groqService.refine(_history!, 'Make it $request.');
    });
  }

  void _openChat() {
    Navigator.of(context).push(
      premiumRoute(ChatScreen(preferences: widget.preferences)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.suggestionsTitle)),
      body: AmbientBackground(
        child: SafeArea(
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
            final suggestions = result?.suggestions ?? <FoodSuggestion>[];
            _current = suggestions;
            if (suggestions.isEmpty) {
              return _ErrorState(
                message: S.noSuggestions,
                onRetry: _retry,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                if (_activeRefinement != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RefinedBanner(request: _activeRefinement!),
                  ),
                ValueListenableBuilder(
                  valueListenable: FavoritesService.instance.favorites,
                  builder: (context, _, __) {
                    return Column(
                      children: [
                        for (var i = 0; i < suggestions.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AnimatedEntrance(
                              delay: Duration(milliseconds: i * 120),
                              child: SuggestionCard(
                                suggestion: suggestions[i],
                                isFavorite: FavoritesService.instance
                                    .isFavorite(suggestions[i]),
                                onToggleFavorite: () => FavoritesService
                                    .instance
                                    .toggle(suggestions[i]),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  S.wantSomethingElse,
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
                              icon: Text(
                                r.$2,
                                style: const TextStyle(fontSize: 15),
                              ),
                              label: Text(r.$1),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                PressableScale(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(Icons.forum_outlined, size: 19),
                      label: Text(S.askFollowUp),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PressableScale(
                  child: TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(S.startOver),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
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
              S.refinedBanner(request),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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
            const Icon(
              Icons.ramen_dining_outlined,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            PressableScale(
              child: FilledButton(
                onPressed: onRetry,
                child: Text(S.tryAgain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
