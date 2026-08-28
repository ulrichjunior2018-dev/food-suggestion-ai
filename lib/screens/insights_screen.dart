import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/pressable_scale.dart';

/// Makes the personalization visible. A model quietly reading your
/// history is unnerving; showing exactly what it has picked up — and
/// giving you one button to erase it — is the difference between a
/// feature that feels smart and one that feels creepy.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ProfileService.instance;

    return Scaffold(
      appBar: AppBar(title: Text(S.insightsTitle)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            service.profile,
            service.skipped,
            FavoritesService.instance.favorites,
          ]),
          builder: (context, _) {
            final profile = service.profile.value;
            final saved = FavoritesService.instance.favorites.value;
            final cuisines = service.likedCuisines.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final skipped = service.skipped.value;

            final stated = <String, String>{
              if (profile.allergies.isNotEmpty) S.allergies: profile.allergies,
              if (profile.spiceTolerance.isNotEmpty)
                S.spiceTolerance: profile.spiceTolerance,
              if (profile.cookingSkill.isNotEmpty)
                S.cookingConfidenceShort: profile.cookingSkill,
              if (profile.timeAvailable.isNotEmpty)
                S.timeAvailable: profile.timeAvailable,
              if (profile.healthGoal.isNotEmpty) S.goal: profile.healthGoal,
              if (profile.householdSize.isNotEmpty)
                S.cookingFor: profile.householdSize,
            };

            final nothingYet =
                stated.isEmpty && saved.isEmpty && skipped.isEmpty;

            if (nothingYet) {
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
                          Icons.insights_outlined,
                          size: 28,
                          color: AppColors.terracottaDark,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        S.nothingLearned,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.nothingLearnedBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.charcoal.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            var order = 0;
            Widget stagger(Widget child) {
              final w = AnimatedEntrance(
                delay: Duration(milliseconds: order * 80),
                child: child,
              );
              order++;
              return w;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 104),
              children: [
                Text(
                  S.insightsIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 24),

                if (stated.isNotEmpty)
                  stagger(_Section(
                    icon: Icons.person_outline,
                    title: S.youToldUs,
                    children: stated.entries
                        .map((e) => _Fact(label: e.key, value: e.value))
                        .toList(),
                  )),

                if (cuisines.isNotEmpty)
                  stagger(_Section(
                    icon: Icons.public,
                    title: S.cuisinesYouLike,
                    children: cuisines
                        .take(4)
                        .map((e) => _Fact(
                              label: e.key,
                              value: S.savedDishCount(e.value),
                            ))
                        .toList(),
                  )),

                if (saved.isNotEmpty)
                  stagger(_Section(
                    icon: Icons.bookmark_outline,
                    title: S.dishesYouKept,
                    children: [
                      _Fact(
                        label: S.savedTotal(saved.length),
                        value: saved.take(5).map((d) => d.name).join(', '),
                      ),
                    ],
                  )),

                if (skipped.isNotEmpty)
                  stagger(_Section(
                    icon: Icons.swipe_left_outlined,
                    title: S.dishesYouSkipped,
                    children: [
                      _Fact(
                        label: S.recentlySkipped,
                        value: skipped.take(6).join(', '),
                      ),
                    ],
                  )),

                const SizedBox(height: 12),
                if (skipped.isNotEmpty)
                  PressableScale(
                    child: TextButton.icon(
                      onPressed: () => service.clearLearned(),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(S.clearLearned),
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

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.terracotta),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
