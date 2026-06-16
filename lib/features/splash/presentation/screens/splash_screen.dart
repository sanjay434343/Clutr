import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clutr/core/services/notification_service.dart';
import 'package:clutr/core/services/background_task_service.dart';
import 'package:clutr/core/services/trash_service.dart';
import 'package:clutr/core/services/auth_service.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;

  bool _isDark = false;
  bool _useDynamicColor = true;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadTheme();
    _playIntro();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('settings_theme_mode') ?? ThemeMode.system.index;
    final dynamicColor = prefs.getBool('settings_dynamic_color') ?? true;
    if (mounted) {
      setState(() {
        _useDynamicColor = dynamicColor;
        if (themeIndex == ThemeMode.dark.index) {
          _isDark = true;
        } else if (themeIndex == ThemeMode.system.index) {
          // Fallback to system brightness in build method
        }
      });
    }
  }

  Future<void> _playIntro() async {
    await _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));

    // Request necessary permissions on the splash screen
    await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.notification,
    ].request();

    try {
      await AuthService.init();
      await NotificationService().init();
      await BackgroundTaskService().init();
      
      final prefs = await SharedPreferences.getInstance();
      final trashAutoEmptyDays = prefs.getInt('settings_trash_auto_empty_days') ?? 30;
      await TrashService.cleanExpiredItems(trashAutoEmptyDays);
    } catch (e) {
      debugPrint("Startup initialization error: $e");
    }

    // Request specific notification permissions
    await NotificationService().requestPermissions();

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (hasSeenOnboarding) {
        if (AuthService.isLoggedIn()) {
          context.go('/main');
        } else {
          context.go('/login');
        }
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Logo
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_logoController.value);
              final scale = 0.85 + (0.15 * t);
              final height = MediaQuery.of(context).size.height;
              final dy = (1.0 - t) * (height / 2 + 100.0); // Slide up from bottom
              return Center(
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 160,
                  height: 160,
                  color: _useDynamicColor ? Theme.of(context).colorScheme.primary : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
