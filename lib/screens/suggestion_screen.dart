import 'package:flutter/material.dart';

import '../models/food_suggestion.dart';
import '../models/user_preferences.dart';
import '../services/groq_service.dart';

/// Fetches and displays AI-generated food suggestions for the given
/// [preferences]. Handles loading, error (with retry), and success states
/// explicitly rather than assuming the network call always succeeds.
class SuggestionScreen extends StatefulWidget {
  final UserPreferences preferences;

  const SuggestionScreen({super.key, required this.preferences});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _groqService = GroqService();

  late Future<List<FoodSuggestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _groqService.getSuggestions(widget.preferences);
  }

  void _retry() {
    setState(() {
      _future = _groqService.getSuggestions(widget.preferences);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your suggestions')),
      body: SafeArea(
        child: FutureBuilder<List<FoodSuggestion>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Thinking about what you\'d love to eat...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _retry,
              );
            }

            final suggestions = snapshot.data ?? [];
            if (suggestions.isEmpty) {
              return _ErrorState(
                message: 'No suggestions came back — try again.',
                onRetry: _retry,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _SuggestionCard(suggestion: suggestions[index]),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: OutlinedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Give me different ideas'),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final FoodSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (suggestion.cuisineType.isNotEmpty)
                  Chip(
                    label: Text(suggestion.cuisineType),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(suggestion.description, style: theme.textTheme.bodyMedium),
            if (suggestion.whyItFits.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      suggestion.whyItFits,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
