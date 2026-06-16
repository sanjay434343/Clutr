import 'package:flutter/material.dart';
import 'dart:math';

class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const SwipeableCard({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Offset>? _animation;
  
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      if (_animation != null) {
        setState(() {
          _dragOffset = _animation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, 0.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final escapeThreshold = _screenSize.width * 0.3;

    if (_dragOffset.dx > escapeThreshold) {
      _animateOffScreen(true);
    } else if (_dragOffset.dx < -escapeThreshold) {
      _animateOffScreen(false);
    } else {
      _animateBackToCenter();
    }
  }

  void _animateBackToCenter() {
    _animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.duration = const Duration(milliseconds: 300);
    _controller.forward(from: 0.0);
  }

  void _animateOffScreen(bool isRight) {
    final endX = isRight ? _screenSize.width * 1.5 : -_screenSize.width * 1.5;
    final endOffset = Offset(endX, 0.0);

    _animation = Tween<Offset>(begin: _dragOffset, end: endOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.duration = const Duration(milliseconds: 250);
    _controller.forward(from: 0.0).then((_) {
      if (isRight) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    // Calculate opacity for the swipe indicators
    final double rightOpacity = max(0, min(1, _dragOffset.dx / (_screenSize.width * 0.3)));
    final double leftOpacity = max(0, min(1, -_dragOffset.dx / (_screenSize.width * 0.3)));
    
    // Add playful rotation and scale
    final double rotation = _dragOffset.dx / _screenSize.width * 0.2;
    final double scale = max(0.9, 1.0 - (_dragOffset.dx.abs() / _screenSize.width * 0.1));

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: _isDragging ? BorderRadius.circular(32) : BorderRadius.zero,
                  child: widget.child,
                ),
                
                // Keep indicator (Right swipe)
                if (rightOpacity > 0)
                  Positioned(
                    top: 80,
                    left: 40,
                    child: Opacity(
                      opacity: rightOpacity,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.greenAccent, width: 4),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: const Text(
                            'KEEP',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Delete indicator (Left)
                if (leftOpacity > 0)
                  Positioned(
                    top: 80,
                    right: 40,
                    child: Opacity(
                      opacity: leftOpacity,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent, width: 4),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: const Text(
                            'DELETE',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
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
    );
  }
}
