import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/preference_chip.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/premium_route.dart';
import 'insights_screen.dart';

/// The optional deep profile. Kept off the critical path on purpose: the
/// 4-step onboarding still gets a first-time user to a real suggestion in
/// under a minute, and this is where the ones who want better answers go
/// to give the model more to work with.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _draft;
  late final TextEditingController _allergies;

  @override
  void initState() {
    super.initState();
    _draft = ProfileService.instance.profile.value;
    _allergies = TextEditingController(text: _draft.allergies);
  }

  @override
  void dispose() {
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ProfileService.instance.saveProfile(
      _draft.copyWith(allergies: _allergies.text.trim()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(S.profileSaved),
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

    return Scaffold(
      appBar: AppBar(title: Text(S.profileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 108),
          children: [
            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    child: OutlinedButton.icon(
                      onPressed: () => S.setLanguage(
                        S.isFr ? AppLanguage.en : AppLanguage.fr,
                      ),
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(S.isFr ? 'English' : 'Français'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PressableScale(
                    child: OutlinedButton.icon(
                      onPressed: () => AppTheme.setMode(
                        AppColors.isDark ? ThemeMode.light : ThemeMode.dark,
                      ),
                      icon: Icon(
                        AppColors.isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 18,
                      ),
                      label: Text(
                        AppColors.isDark
                            ? (S.isFr ? 'Clair' : 'Light')
                            : (S.isFr ? 'Sombre' : 'Dark'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              S.profileIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.charcoal.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 26),

            _Label(
              title: S.allergies,
              subtitle: S.allergiesSub,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _allergies,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: S.allergiesHint,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.tan, width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.terracotta,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),

            _Label(title: S.spiceTolerance),
            const SizedBox(height: 10),
            _ChipRow(
              options: S.spiceOptions,
              selected: _draft.spiceTolerance,
              onSelect: (v) => setState(
                () => _draft = _draft.copyWith(
                  spiceTolerance: _draft.spiceTolerance == v ? '' : v,
                ),
              ),
            ),
            const SizedBox(height: 26),

            _Label(title: S.cookingConfidence),
            const SizedBox(height: 10),
            _ChipRow(
              options: S.skillOptions,
              selected: _draft.cookingSkill,
              onSelect: (v) => setState(
                () => _draft = _draft.copyWith(
                  cookingSkill: _draft.cookingSkill == v ? '' : v,
                ),
              ),
            ),
            const SizedBox(height: 26),

            _Label(title: S.timeUsually),
            const SizedBox(height: 10),
            _ChipRow(
              options: S.timeOptions,
              selected: _draft.timeAvailable,
              onSelect: (v) => setState(
                () => _draft = _draft.copyWith(
                  timeAvailable: _draft.timeAvailable == v ? '' : v,
                ),
              ),
            ),
            const SizedBox(height: 26),

            _Label(
              title: S.eatingFor,
              subtitle: S.eatingForSub,
            ),
            const SizedBox(height: 10),
            _ChipRow(
              options: S.goalOptions,
              selected: _draft.healthGoal,
              onSelect: (v) => setState(
                () => _draft = _draft.copyWith(
                  healthGoal: _draft.healthGoal == v ? '' : v,
                ),
              ),
            ),
            const SizedBox(height: 26),

            _Label(title: S.cookingFor),
            const SizedBox(height: 10),
            _ChipRow(
              options: S.householdOptions,
              selected: _draft.householdSize,
              onSelect: (v) => setState(
                () => _draft = _draft.copyWith(
                  householdSize: _draft.householdSize == v ? '' : v,
                ),
              ),
            ),
            const SizedBox(height: 34),

            PressableScale(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(S.saveProfile),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PressableScale(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(premiumRoute(const InsightsScreen())),
                  icon: const Icon(Icons.insights_outlined, size: 19),
                  label: Text(S.insightsTitle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _Label({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.charcoal.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
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
}
