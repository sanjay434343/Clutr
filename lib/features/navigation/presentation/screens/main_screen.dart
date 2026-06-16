import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:clutr/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:clutr/features/cleanup/presentation/screens/cleanup_screen.dart';
import 'package:clutr/features/settings/presentation/screens/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CleanupScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: SizedBox(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, height: 0.5, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          height: 60,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01, color: colorScheme.onSurfaceVariant),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome01, color: colorScheme.onSurface),
              label: 'Home',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01, color: colorScheme.onSurfaceVariant),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01, color: colorScheme.onSurface),
              label: 'Review',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: colorScheme.onSurfaceVariant),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: colorScheme.onSurface),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
