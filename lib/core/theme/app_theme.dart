import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Vibrant Light Theme Colors based on a Logo
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF14B8A6); // Teal
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color accentDanger = Color(0xFFEF4444); // Red
  static const Color accentSuccess = Color(0xFF10B981); // Emerald

  static ThemeData lightTheme([ColorScheme? dynamicColorScheme]) {
    final scheme = dynamicColorScheme ?? ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: accentDanger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scheme.surface,
      colorScheme: scheme,
      fontFamily: 'Outfit',
      textTheme: const TextTheme().copyWith(
        displayLarge: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displaySmall: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textColor),
        bodyMedium: const TextStyle(color: textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 8,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
        ),
      ),
    );
  }

  static ThemeData darkTheme([ColorScheme? dynamicColorScheme]) {
    final scheme = dynamicColorScheme ?? ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: const Color(0xFF121212), // Very dark grey for cards
      error: accentDanger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black, // Pure black
      colorScheme: scheme,
      fontFamily: 'Outfit',
      textTheme: ThemeData.dark().textTheme.copyWith(
        displayLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        displayMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        displaySmall: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        headlineMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        bodyLarge: const TextStyle(color: Colors.white, fontFamily: 'Outfit'),
        bodyMedium: const TextStyle(color: Color(0xFFCBD5E1), fontFamily: 'Outfit'), // Slate 300
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212), // Very dark grey
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
        ),
      ),
    );
  }
}

