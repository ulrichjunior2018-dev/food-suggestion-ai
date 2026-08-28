import 'package:flutter/material.dart';

/// A calmer fade + gentle-rise push transition, replacing Flutter's default
/// slide-from-the-right Material transition on every screen change in this
/// app. Small, but it's the difference between "an app built with the
/// default template" and "an app someone made deliberate choices about".
Route<T> premiumRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 18),
          child: child,
        ),
      );
    },
  );
}
