import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clutr/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isRequestInProgress = false;
  int _failedAttempts = 0;
  DateTime? _lastAttemptTime;

  Future<void> _signInWithGoogle() async {
    if (_isRequestInProgress) return;

    // Rate limiter to prevent API spam
    if (_lastAttemptTime != null && _failedAttempts >= 3) {
      final diff = DateTime.now().difference(_lastAttemptTime!);
      if (diff.inSeconds < 30) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Too many attempts. Please wait ${30 - diff.inSeconds} seconds.')),
          );
        }
        return;
      } else {
        _failedAttempts = 0;
      }
    }

    _isRequestInProgress = true;
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await AuthService.signIn();

      if (user != null) {
        if (mounted) {
          context.go('/main');
        }
      }
    } catch (e) {
      _failedAttempts++;
      _lastAttemptTime = DateTime.now();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: $e')),
        );
      }
    } finally {
      _isRequestInProgress = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  width: 120,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Welcome to Clutr',
                style: textTheme.displayMedium?.copyWith(
                  fontFamily: 'Newstalgia',
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in to sync your preferences and access personalized features.',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.login, size: 24),
                  label: const Text('Login with Google'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
