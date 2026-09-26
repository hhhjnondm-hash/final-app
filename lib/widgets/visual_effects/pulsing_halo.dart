import 'package:flutter/material.dart';

/// Animated pulsing golden aura / halo widget for highlighted active prayer or important focal elements.
class PulsingHalo extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color haloColor;
  final double borderRadius;
  final Duration duration;

  const PulsingHalo({
    super.key,
    required this.child,
    this.isActive = true,
    this.haloColor = const Color(0xFFFFD56B),
    this.borderRadius = 16,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<PulsingHalo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _pulseAnimation.value;
        final blur = 10.0 + 12.0 * t;
        final spread = 0.5 + 2.5 * t;
        final opacity = 0.25 + 0.35 * t;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.haloColor.withValues(alpha: opacity),
                blurRadius: blur,
                spreadRadius: spread,
              ),
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.2 * t),
                blurRadius: blur * 1.5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
