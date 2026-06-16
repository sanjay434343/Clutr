import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:ui';
import 'package:clutr/core/utils/size_formatter.dart';

class SwipeCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSwipeUp; // Delete
  final ValueNotifier<String?>? deleteTrigger;

  const SwipeCard({
    Key? key,
    required this.item,
    required this.onSwipeUp,
    this.deleteTrigger,
  }) : super(key: key);

  @override
  SwipeCardState createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _snapController;
  double _dragOffsetY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    widget.deleteTrigger?.addListener(_onDeleteTriggered);
  }

  void _onDeleteTriggered() {
    if (widget.deleteTrigger?.value == widget.item['path']) {
      swipeUp();
      widget.deleteTrigger?.value = null; // Consume event
    }
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['path'] != widget.item['path']) {
      setState(() {
        _dragOffsetY = 0.0;
        _isDragging = false;
      });
    }
    if (oldWidget.deleteTrigger != widget.deleteTrigger) {
      oldWidget.deleteTrigger?.removeListener(_onDeleteTriggered);
      widget.deleteTrigger?.addListener(_onDeleteTriggered);
    }
  }

  @override
  void dispose() {
    widget.deleteTrigger?.removeListener(_onDeleteTriggered);
    _snapController.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _snapController.stop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Only allow dragging up (negative Y)
    if (_dragOffsetY + details.delta.dy > 0) return;
    
    setState(() {
      _dragOffsetY += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (_dragOffsetY < -screenHeight * 0.2 || details.velocity.pixelsPerSecond.dy < -800) {
      _flyOutUp();
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    final startOffsetY = _dragOffsetY;
    
    _snapController.duration = const Duration(milliseconds: 400);
    final curve = CurvedAnimation(parent: _snapController, curve: Curves.elasticOut);
    
    void listener() {
      setState(() {
        _dragOffsetY = lerpDouble(startOffsetY, 0, curve.value)!;
      });
    }
    
    _snapController.addListener(listener);
    _snapController.forward(from: 0).whenComplete(() {
      _snapController.removeListener(listener);
    });
  }

  void _flyOutUp() {
    final startOffsetY = _dragOffsetY;
    final endOffsetY = -MediaQuery.of(context).size.height * 1.5;

    final flyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    final curve = CurvedAnimation(parent: flyController, curve: Curves.easeOutCubic);
    
    void listener() {
      if (mounted) {
        setState(() {
          _dragOffsetY = lerpDouble(startOffsetY, endOffsetY, curve.value)!;
        });
      }
    }

    flyController.addListener(listener);
    flyController.forward().whenComplete(() {
      flyController.removeListener(listener);
      flyController.dispose();
      widget.onSwipeUp();
    });
  }
  
  // Expose method for button clicks
  void swipeUp() {
    _flyOutUp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileSize = widget.item['size'] as int? ?? 0;
    final mimeType = widget.item['mimeType'].toString();
    final isVideo = mimeType.startsWith('video/') || mimeType.startsWith('audio/');
    
    // Status overlay
    double actionThreshold = 100.0;
    double opacity = (_dragOffsetY.abs() / actionThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                isVideo
                    ? VideoThumbnail(path: widget.item['path'])
                    : Image.file(
                        File(widget.item['path']),
                        fit: BoxFit.contain,
                        cacheHeight: 1200,
                        errorBuilder: (context, error, stack) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const HugeIcon(icon: HugeIcons.strokeRoundedAlert01, color: Colors.red, size: 80),
                        ),
                      ),
                
                // Bottom Info Gradient
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  height: 160,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                
                // File Info
                Positioned(
                  bottom: 30, left: 24, right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item['name'] ?? 'Unknown File',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          SizeFormatter.formatBytes(fileSize),
                          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Overlay (DELETE)
                if (opacity > 0)
                  Positioned(
                    top: 40,
                    left: 0, right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 4),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: const Text(
                            'DELETE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
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

class VideoThumbnail extends StatefulWidget {
  final String path;
  const VideoThumbnail({Key? key, required this.path}) : super(key: key);

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _controller.dispose();
      _initialized = false;
      _hasError = false;
      _initController();
    }
  }

  void _initController() {
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.setVolume(_isMuted ? 0 : 1);
          _controller.setLooping(true);
          _controller.play();
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.black12,
          child: const Center(
            child: HugeIcon(icon: HugeIcons.strokeRoundedAlert01, color: Colors.red, size: 80),
          ),
        ),
      );
    }
    
    if (_initialized) {
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_controller),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: _toggleMute,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
  }
}
