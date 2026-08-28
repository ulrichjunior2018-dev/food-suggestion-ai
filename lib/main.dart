import 'package:flutter/material.dart';

import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'services/favorites_service.dart';
import 'services/profile_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore everything persisted before first paint: bookmark state and
  // theme are correct immediately rather than flickering in, and the very
  // first suggestion request already carries the user's learned profile.
  await Future.wait([
    FavoritesService.instance.load(),
    ProfileService.instance.load(),
    AppTheme.load(),
    S.load(),
  ]);
  runApp(const FoodSuggestionApp());
}

class FoodSuggestionApp extends StatelessWidget {
  const FoodSuggestionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: S.language,
      builder: (context, language, __) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.mode,
          builder: (context, themeMode, ___) {
            // Resolve brightness before any widget reads AppColors, so the
            // first frame after a toggle is already correct.
            AppTheme.applyMode(context);

            return MaterialApp(
              title: S.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,

              // Screens read strings and surface colours as static values
              // (S.getStarted, AppColors.card) rather than through an
              // InheritedWidget, which is what keeps ~140 call sites free
              // of a BuildContext. The cost is that Flutter has no way to
              // know those values changed: a const child compares equal on
              // rebuild and its whole subtree is skipped, so a toggle would
              // flip the value in memory and repaint nothing.
              //
              // Keying the shell on both settings forces a genuine remount
              // when either changes. The tradeoff is that the tab stacks
              // reset — acceptable for an action taken rarely and
              // deliberately, and far cheaper than threading
              // Theme.of(context) and a Localizations lookup through every
              // widget in the app.
              home: HomeShell(
                key: ValueKey('$language|$themeMode|${AppColors.isDark}'),
              ),
            );
          },
        );
      },
    );
  }
}
