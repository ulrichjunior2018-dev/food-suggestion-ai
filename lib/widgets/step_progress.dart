import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A branded step indicator — icon badges connected by a line, each
/// animating between upcoming/active/done states — used in place of a
/// plain LinearProgressIndicator so onboarding feels like a designed
/// flow rather than a generic form.
class StepProgress extends StatelessWidget {
  final int currentStep;
  final List<IconData> stepIcons;

  const StepProgress({
    super.key,
    required this.currentStep,
    required this.stepIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepIcons.length * 2 - 1, (i) {
        if (i.isOdd) {
          final segmentIndex = i ~/ 2;
          final done = segmentIndex < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: done ? AppColors.terracotta : AppColors.tan,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isDone = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive ? AppColors.terracotta : AppColors.tan,
            border: isActive
                ? Border.all(color: AppColors.gold, width: 2.5)
                : null,
          ),
          child: Icon(
            isDone ? Icons.check : stepIcons[stepIndex],
            size: 18,
            color: isDone || isActive ? Colors.white : AppColors.charcoal.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }
}
