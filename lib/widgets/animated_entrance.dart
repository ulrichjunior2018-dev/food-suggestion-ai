import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Staggers a child into view with a real spring simulation (fade + rise +
/// a hair of scale overshoot) instead of a linear/eased tween. Used to
/// bring suggestion cards in one at a time so the results screen feels
/// considered rather than assembled — the spring gives it a tiny, natural
/// "settle" instead of a mechanical stop.
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: 0.0);

  static const _spring = SpringDescription(mass: 1, stiffness: 180, damping: 17);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _controller.animateWith(SpringSimulation(_spring, 0, 1, 0));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final raw = _controller.value;
        final rise = (1 - raw).clamp(-0.3, 1.0);
        return Opacity(
          opacity: raw.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, rise * 22),
            child: Transform.scale(scale: 0.94 + 0.06 * raw, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
