import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hugeicons/hugeicons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Discover',
      'subtitle': 'Find and manage large files with our beautiful new unified dashboard. See exactly what is taking up space.',
      'icon': HugeIcons.strokeRoundedHardDrive,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Cleanse',
      'subtitle': 'Review your clutter using a simple reels-like swipe interface, complete with satisfying haptics and fluid animations.',
      'icon': HugeIcons.strokeRoundedMagicWand01,
      'color': const Color(0xFF14B8A6),
    },
    {
      'title': 'Automate',
      'subtitle': 'Set up auto-empty schedules and get smart cleanup alerts for specific apps like WhatsApp, Telegram, or your Downloads.',
      'icon': HugeIcons.strokeRoundedNotification02,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Adapt',
      'subtitle': 'Personalize your experience. Match the app\'s colors seamlessly with your device using Material You and enjoy Dark Mode.',
      'icon': HugeIcons.strokeRoundedPaintBoard,
      'color': const Color(0xFFEC4899),
    },
    {
      'title': 'Reclaim',
      'subtitle': 'Take back control of your device\'s storage. Say goodbye to clutter and hello to a faster, cleaner phone.',
      'icon': HugeIcons.strokeRoundedRocket01,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text('Skip', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: page['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(icon: page['icon'], size: 100, color: page['color']),
                        ),
                        const SizedBox(height: 64),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            page['title'],
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontFamily: 'Newstalgia',
                              fontWeight: FontWeight.bold,
                              color: page['color'],
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['subtitle'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? colorScheme.primary : colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_currentIndex == _pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(_currentIndex == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
