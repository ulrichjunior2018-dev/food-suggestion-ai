import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/suggestion_card.dart';

/// Dishes the user saved, restored from local storage across launches.
/// Turns the app from a one-shot suggestion box into something with a
/// reason to come back to it.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.savedDishes)),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: FavoritesService.instance.favorites,
          builder: (context, saved, _) {
            if (saved.isEmpty) {
              return const _EmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
              itemCount: saved.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: i * 90),
                    child: SuggestionCard(
                      suggestion: saved[i],
                      isFavorite: true,
                      onToggleFavorite: () =>
                          FavoritesService.instance.toggle(saved[i]),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tan.withValues(alpha: 0.6),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 28,
                color: AppColors.terracottaDark,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              S.nothingSaved,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              S.nothingSavedBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal.withValues(alpha: 0.65),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
