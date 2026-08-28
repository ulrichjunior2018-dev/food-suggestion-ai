import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Wraps any child in genuine spring-physics feedback: a subtle lift on
/// hover (desktop/web) and a compress-then-overshoot-back on press,
/// instead of Flutter's default instant/linear state changes. This is the
/// kind of small, real-physics detail (real spring simulation, not just a
/// tween with an easing curve) that separates a "styled" interface from a
/// crafted one.
///
/// Deliberately built on `package:flutter/physics.dart` (part of the SDK)
/// rather than a third-party animation package — zero new dependencies,
/// zero risk of a pub.dev resolution surprise right before a deadline.
///
/// Uses `Listener` rather than `GestureDetector` so it only *observes*
/// pointer state — it never claims the gesture, so it's always safe to
/// wrap around a real button, chip, or card that has its own tap handler.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressScale;
  final double hoverScale;

  const PressableScale({
    super.key,
    required this.child,
    this.pressScale = 0.95,
    this.hoverScale = 1.02,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  bool _hovered = false;
  bool _pressed = false;

  // A snappy, slightly underdamped spring: it overshoots just enough to
  // read as physical rather than mechanical.
  static const _spring = SpringDescription(mass: 1, stiffness: 500, damping: 18);

  void _retarget() {
    final target = _pressed ? widget.pressScale : (_hovered ? widget.hoverScale : 1.0);
    _controller.animateWith(SpringSimulation(_spring, _controller.value, target, 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hovered = true;
        _retarget();
      },
      onExit: (_) {
        _hovered = false;
        _retarget();
      },
      child: Listener(
        onPointerDown: (_) {
          _pressed = true;
          _retarget();
        },
        onPointerUp: (_) {
          _pressed = false;
          _retarget();
        },
        onPointerCancel: (_) {
          _pressed = false;
          _retarget();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(scale: _controller.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}
