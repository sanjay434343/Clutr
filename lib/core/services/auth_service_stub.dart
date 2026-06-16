import 'package:flutter/foundation.dart';

class AuthService {
  static Future<void> init() async {
    // No-op for FOSS version
    debugPrint("AuthService (FOSS) initialized.");
  }

  static bool isLoggedIn() {
    // In FOSS version, we skip the login screen entirely by pretending we are always logged in
    return true;
  }

  static Future<void> signIn() async {
    // No-op
  }

  static Future<void> signOut() async {
    // No-op
  }
}
