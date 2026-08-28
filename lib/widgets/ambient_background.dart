import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Slow-drifting colour fields behind the content.
///
/// Screens with a lot of breathing room read as unfinished when the
/// background is a flat fill. Three large, very low-opacity radial fields
/// moving on long sine paths give the surface depth and a sense of life
/// without ever competing with the content — the motion is slow enough
/// (18s and 25s cycles) that it registers as atmosphere rather than
/// animation.
///
/// Built from radial gradients rather than blurred layers on purpose:
/// a real blur filter is expensive to composite every frame, and at this
/// opacity it would be indistinguishable.
class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _slow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 25),
  )..repeat();

  late final AnimationController _slower = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _slow.dispose();
    _slower.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_slow, _slower]),
              builder: (context, _) {
                final a = _slow.value * 2 * math.pi;
                final b = _slower.value * 2 * math.pi;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        _blob(
                          color: AppColors.gold,
                          size: w * 1.05,
                          left: w * 0.05 + math.sin(a) * w * 0.14,
                          top: h * 0.02 + math.cos(a) * h * 0.05,
                          opacity: 0.16,
                        ),
                        _blob(
                          color: AppColors.terracotta,
                          size: w * 0.95,
                          left: w * 0.32 + math.cos(b) * w * 0.18,
                          top: h * 0.46 + math.sin(b) * h * 0.07,
                          opacity: 0.12,
                        ),
                        _blob(
                          color: AppColors.sage,
                          size: w * 0.8,
                          left: w * -0.18 + math.sin(b + 1.6) * w * 0.12,
                          top: h * 0.66 + math.cos(a + 0.8) * h * 0.06,
                          opacity: 0.10,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }

  Widget _blob({
    required Color color,
    required double size,
    required double left,
    required double top,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
