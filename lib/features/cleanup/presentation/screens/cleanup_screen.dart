import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:clutr/features/cleanup/providers/media_provider.dart';
import 'package:clutr/core/utils/size_formatter.dart';
import 'package:clutr/features/cleanup/presentation/widgets/swipe_card.dart';
import 'dart:ui';
import 'dart:io';

class CleanupScreen extends ConsumerStatefulWidget {
  final String? folderFilter;

  const CleanupScreen({super.key, this.folderFilter});

  @override
  ConsumerState<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends ConsumerState<CleanupScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  int _totalClearedBytes = 0;
  final ValueNotifier<String?> _deleteTrigger = ValueNotifier(null);

  void _handleDelete(Map<String, dynamic> media, int index, int listLength) {
    ref.read(mediaProvider.notifier).deleteMedia(media['path']);
    if (mounted) {
      setState(() {
        _totalClearedBytes += (media['size'] as int? ?? 0);
      });
    }
  }

  void _handleKeep() {
    // Just move to the next page in the carousel
    final currentIndex = _pageController.page?.round() ?? 0;
    _pageController.animateToPage(
      currentIndex + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _triggerDelete() {
    final currentIndex = _pageController.page?.round() ?? 0;
    final mediaList = ref.read(mediaProvider).value ?? [];
    List<Map<String, dynamic>> filteredList = mediaList;
    if (widget.folderFilter != null) {
      filteredList = filteredList.where((item) {
        final path = item['path'] as String?;
        if (path == null) return false;
        final parts = path.split('/');
        final folderName = parts.length > 1 ? parts[parts.length - 2] : 'Unknown';
        return folderName == widget.folderFilter;
      }).toList();
    }
    if (currentIndex < filteredList.length) {
      final path = filteredList[currentIndex]['path'] as String;
      _deleteTrigger.value = path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    final theme = Theme.of(context);

    final mediaList = mediaState.value ?? [];
    List<Map<String, dynamic>> filteredList = mediaList;
    if (widget.folderFilter != null) {
      filteredList = filteredList.where((item) {
        final path = item['path'] as String?;
        if (path == null) return false;
        final parts = path.split('/');
        final folderName = parts.length > 1 ? parts[parts.length - 2] : 'Unknown';
        return folderName == widget.folderFilter;
      }).toList();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.7),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                widget.folderFilter ?? 'Cleanup', 
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            if (_totalClearedBytes > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cleared: ${SizeFormatter.formatBytes(_totalClearedBytes)}',
                  style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          mediaState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            data: (_) {

          return SafeArea(
            bottom: true,
            top: false, // Let cards underlap the App bar
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return const SizedBox.shrink();
                      }

                      final item = filteredList[index];

                      // Preload the next 3 images in the background so they are ready instantly!
                      for (int i = 1; i <= 3; i++) {
                        if (index + i < filteredList.length) {
                          final nextItem = filteredList[index + i];
                          final mimeType = nextItem['mimeType'].toString();
                          if (!mimeType.startsWith('video/') && !mimeType.startsWith('audio/')) {
                            precacheImage(
                              ResizeImage(FileImage(File(nextItem['path'])), height: 1200),
                              context,
                            );
                          }
                        }
                      }

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = (_pageController.page! - index).abs();
                            value = (1 - (value * 0.15)).clamp(0.85, 1.0);
                          }
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) {
                            if (child.key == ValueKey(item['path'])) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation),
                                  child: child,
                                ),
                              );
                            } else {
                              return FadeTransition(opacity: animation, child: child);
                            }
                          },
                          child: SwipeCard(
                            key: ValueKey(item['path']),
                            item: item,
                            deleteTrigger: _deleteTrigger,
                            onSwipeUp: () => _handleDelete(item, index, filteredList.length),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom Control Buttons
                // Bottom Control Buttons
                AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    final isAtEnd = _pageController.hasClients && (_pageController.page ?? 0) >= filteredList.length - 0.5;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isAtEnd ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: isAtEnd,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32.0, left: 32.0, right: 32.0, top: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CleanupActionButton(
                            onTap: _triggerDelete,
                            color: Colors.red,
                            icon: HugeIcons.strokeRoundedDelete02,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CleanupActionButton(
                            onTap: _handleKeep,
                            color: Colors.green,
                            icon: HugeIcons.strokeRoundedTick02,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      
      // The Full Screen Completion Overlay (constrained to body)
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double progress = 0.0;
              if (filteredList.isEmpty && !mediaState.isLoading && !mediaState.hasError) {
                progress = 1.0;
              } else if (_pageController.hasClients) {
                double page = _pageController.page ?? 0;
                progress = (page - (filteredList.length - 1)).clamp(0.0, 1.0);
              }

              if (progress == 0.0) return const SizedBox.shrink();

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: progress,
                child: IgnorePointer(
                  ignoring: progress < 0.5,
                  child: child,
                ),
              );
            },
            child: _buildFullScreenCompletion(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenCompletion(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, color: Colors.green, size: 120),
            const SizedBox(height: 32),
            Text('Clean up completed!', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Cleared ${SizeFormatter.formatBytes(_totalClearedBytes)}', style: theme.textTheme.titleLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class CleanupActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final dynamic icon;

  const CleanupActionButton({
    Key? key,
    required this.onTap,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  State<CleanupActionButton> createState() => _CleanupActionButtonState();
}

class _CleanupActionButtonState extends State<CleanupActionButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        height: 72,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(_isPressed ? 23 : 50),
        ),
        child: Center(
          child: AnimatedScale(
            scale: _isPressed ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: HugeIcon(icon: widget.icon, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
