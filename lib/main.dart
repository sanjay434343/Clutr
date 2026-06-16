import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:clutr/core/theme/app_theme.dart';
import 'package:clutr/core/routes/app_router.dart';
import 'package:clutr/features/settings/providers/settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:clutr/core/services/notification_service.dart';
import 'package:clutr/core/services/background_task_service.dart';
import 'package:clutr/core/services/trash_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialization has been moved to the SplashScreen to avoid black screen on startup.


  runApp(const ProviderScope(child: ClutrApp()));
}

class ClutrApp extends ConsumerWidget {
  const ClutrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Clutr',
          debugShowCheckedModeBanner: false,
          themeMode: settingsState.themeMode,
          theme: AppTheme.lightTheme(
            settingsState.useDynamicColor ? lightDynamic : null,
          ),
          darkTheme: AppTheme.darkTheme(
            settingsState.useDynamicColor ? darkDynamic : null,
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
