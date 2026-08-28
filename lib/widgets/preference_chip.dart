import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// A single selectable chip used throughout onboarding. Kept as one
/// reusable widget instead of duplicating ChoiceChip styling on every
/// screen. Styled as a full pill against the app's warm palette rather
/// than default Material chip colors, with real spring-physics press/hover
/// feedback via [PressableScale] instead of a flat, static tap target.
class PreferenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.tan,
            width: 1.4,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.charcoal,
          ),
        ),
      ),
      ),
      ),
    );
  }
}
