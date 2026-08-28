import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';

/// The app's root: persistent floating tab navigation.
///
/// Each tab owns its own [Navigator], which is what lets the bar survive
/// pushes. Onboarding, results and insights now stack *inside* their tab
/// instead of on top of the shell, so the bar never disappears mid-flow
/// and each tab remembers where you left it — the same model iOS itself
/// uses. A single shared Navigator would mean every push covered the bar,
/// which is exactly the behaviour being fixed here.
///
/// The bar floats rather than sitting flush: inset from the edges, fully
/// rounded, with a real backdrop blur so content passes visibly beneath
/// it. Blur is what makes translucency read as depth; a semi-transparent
/// fill alone just looks washed out.
class HomeShell extends StatefulWidget {
  /// Survives the remount that a language or theme change forces, so a
  /// settings toggle leaves you on the tab you were already on instead of
  /// bouncing you back to Home.
  static int lastIndex = 0;

  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = HomeShell.lastIndex;

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void _select(int next) {
    HapticFeedback.selectionClick();
    if (next == _index) {
      // Re-tapping the active tab pops it back to its root — a small iOS
      // convention people reach for without being told.
      _navKeys[next].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _index = next;
      HomeShell.lastIndex = next;
    });
  }

  Widget _tabRoot(int i) {
    switch (i) {
      case 0:
        return WelcomeScreen(onNavigate: _select);
      case 1:
        return const ChatScreen();
      case 2:
        return const FavoritesScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <({IconData icon, IconData active, String label})>[
      (
        icon: Icons.restaurant_outlined,
        active: Icons.restaurant,
        label: S.isFr ? 'Accueil' : 'Home'
      ),
      (icon: Icons.forum_outlined, active: Icons.forum, label: 'Assistant'),
      (icon: Icons.bookmark_border, active: Icons.bookmark, label: S.saved),
      (icon: Icons.person_outline, active: Icons.person, label: S.profile),
    ];

    return PopScope(
      // Back should unwind the current tab's stack before it ever closes
      // the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() {
            _index = 0;
            HomeShell.lastIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < 4; i++)
                  Navigator(
                    key: _navKeys[i],
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings,
                      builder: (_) => _tabRoot(i),
                    ),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FloatingBar(
                tabs: tabs,
                index: _index,
                onSelect: _select,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBar extends StatelessWidget {
  final List<({IconData icon, IconData active, String label})> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  const _FloatingBar({
    required this.tabs,
    required this.index,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                // Slightly more opaque than a normal translucent bar: on the
              // Home tab it floats over moving footage, where a light fill
              // would strobe as the video changes behind it.
              color: AppColors.card.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.charcoal.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _TabButton(
                        icon: index == i ? tabs[i].active : tabs[i].icon,
                        label: tabs[i].label,
                        selected: index == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.terracotta
        : AppColors.charcoal.withValues(alpha: 0.45);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: selected ? 1.14 : 1.0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
