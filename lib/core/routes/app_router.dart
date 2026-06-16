import 'package:clutr/features/cleanup/presentation/screens/cleanup_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clutr/features/splash/presentation/screens/splash_screen.dart';
import 'package:clutr/features/navigation/presentation/screens/main_screen.dart';
import 'package:clutr/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:clutr/features/cleanup/presentation/trash_screen.dart';
import 'package:clutr/features/auth/presentation/screens/login_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/main',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
    GoRoute(
      path: '/cleanup',
      builder: (context, state) {
        final folderFilter = state.extra as String?;
        return CleanupScreen(folderFilter: folderFilter);
      },
    ),
  ],
);
