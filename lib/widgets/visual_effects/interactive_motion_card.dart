import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Luxury interactive card with responsive scale, hover illumination, and haptics
class InteractiveMotionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? backgroundColor;

  const InteractiveMotionCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    this.borderColor,
    this.glowColor,
    this.padding,
    this.margin,
    this.gradient,
    this.backgroundColor,
  });

  @override
  State<InteractiveMotionCard> createState() => _InteractiveMotionCardState();
}

class _InteractiveMotionCardState extends State<InteractiveMotionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final goldGlow = widget.glowColor ?? const Color(0xFFFFD56B);
    final border = widget.borderColor ?? const Color(0xFFFFD56B).withValues(alpha: 0.35);

    return Container(
      margin: widget.margin,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: widget.onTap != null ? _handleTapDown : null,
          onTapUp: widget.onTap != null ? _handleTapUp : null,
          onTapCancel: widget.onTap != null ? _handleTapCancel : null,
          onTap: widget.onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onTap!();
                }
              : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * (_isHovered ? 1.015 : 1.0),
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _isHovered ? const Color(0xFFFFD56B) : border,
                  width: _isHovered ? 1.4 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldGlow.withValues(alpha: _isHovered ? 0.28 : 0.08),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
