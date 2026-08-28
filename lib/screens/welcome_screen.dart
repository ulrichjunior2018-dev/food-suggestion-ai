import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_video.dart';
import '../widgets/premium_route.dart';
import '../widgets/pressable_scale.dart';
import 'onboarding_screen.dart';

/// The home tab — a full-bleed cinematic surface.
///
/// The video fills the screen behind everything and the content sits on
/// top in light type. This is a deliberate break from the warm, light
/// treatment used everywhere else: Home is the one screen whose job is to
/// make you want to use the app, and an immersive hero does that in a way
/// a static page cannot.
///
/// Two decisions worth stating, because both were tempting to get wrong:
///
/// 1. **No faded-video-behind-light-content.** A low-opacity video under
///    dark text reads as a rendering fault, not as subtlety. Either the
///    footage is present and the type goes light over a real scrim, or it
///    isn't there at all.
/// 2. **No ambient drift here.** The drifting colour fields still run on
///    the other screens; running them behind moving footage would be two
///    motion systems competing for the same attention, and the video wins
///    that fight anyway.
///
/// Text colours are hardcoded light rather than themed, because they sit
/// on footage — not on the app surface — in both light and dark mode.
class WelcomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const WelcomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          HeroVideo(
            height: null,
            scrimTop: 0.42,
            scrimBottom: 0.72,
            // Full-screen gradient, so a missing video still gives a
            // deliberate-looking surface rather than an empty one.
            fallback: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8F3A20),
                    Color(0xFF2B2420),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // A second bottom-weighted scrim: the CTAs and body copy sit low
          // on the screen, which is exactly where footage tends to be
          // busiest.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PressableScale(
                        pressScale: 0.88,
                        child: IconButton(
                          tooltip: AppColors.isDark ? 'Light' : 'Dark',
                          onPressed: () => AppTheme.setMode(
                            AppColors.isDark ? ThemeMode.light : ThemeMode.dark,
                          ),
                          icon: Icon(
                            AppColors.isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 21,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      PressableScale(
                        pressScale: 0.88,
                        child: TextButton.icon(
                          onPressed: () => S.setLanguage(
                            S.isFr ? AppLanguage.en : AppLanguage.fr,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.9),
                          ),
                          icon: const Icon(Icons.language, size: 19),
                          label: Text(S.isFr ? 'EN' : 'FR'),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    S.welcomeHeadline,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.welcomeBody,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PressableScale(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          premiumRoute(const OnboardingScreen()),
                        ),
                        child: Text(S.getStarted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onNavigate?.call(1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 1.3,
                          ),
                        ),
                        icon: const Icon(Icons.forum_outlined, size: 19),
                        label: Text(S.justAsk),
                      ),
                    ),
                  ),
                  const SizedBox(height: 86),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
