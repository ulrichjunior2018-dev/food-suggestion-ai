import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Three dots that breathe in sequence while the assistant is thinking.
/// A chat with no pending-state reads as broken the moment the network
/// is slow — this is the cheapest thing that makes the wait feel alive.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              // Stagger each dot a third of a cycle apart, then map the
              // sawtooth onto a smooth up-down so it reads as a wave.
              final phase = (_controller.value + i * 0.22) % 1.0;
              final lift = (phase < 0.5 ? phase : 1.0 - phase) * 2;
              return Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                child: Transform.translate(
                  offset: Offset(0, -3 * lift),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.terracotta.withValues(
                        alpha: 0.4 + 0.5 * lift,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
