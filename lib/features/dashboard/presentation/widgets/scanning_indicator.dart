import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ScanningIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String text;

  const ScanningIndicator({
    super.key,
    this.size = 120.0,
    this.color,
    this.text = 'SCANNING',
  });

  @override
  State<ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<ScanningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.color ?? colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple 1
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  return Transform.scale(
                    scale: 0.5 + (0.5 * t),
                    child: Opacity(
                      opacity: 1.0 - t,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Ripple 2 (delayed)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  var t = _controller.value - 0.5;
                  if (t < 0) t += 1.0;
                  return Transform.scale(
                    scale: 0.5 + (0.5 * t),
                    child: Opacity(
                      opacity: 1.0 - t,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Inner Icon
              Container(
                width: widget.size * 0.5,
                height: widget.size * 0.5,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: primaryColor,
                  size: widget.size * 0.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = 0.4 + (0.6 * (1.0 - (_controller.value * 2 - 1.0).abs()));
            return Opacity(
              opacity: opacity,
              child: Text(
                widget.text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 4.0,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
