import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool hasGlow;
  final Color? glowColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignSystem.spacingM),
    this.margin,
    this.borderRadius = DesignSystem.radiusLarge,
    this.onTap,
    this.isSelected = false,
    this.hasGlow = false,
    this.glowColor,
    this.gradient,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    if (!isLight) {
      return _buildLuxuryDarkModeCard();
    }

    final borderColor = widget.isSelected
        ? const Color(0xFFC89B3C)
        : (_isHovered
            ? const Color(0xFF102A43).withValues(alpha: 0.25)
            : const Color(0xFFDCE3EC));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.gradient,
          border: Border.all(
            color: borderColor,
            width: widget.isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF102A43).withValues(alpha: widget.isSelected ? 0.09 : (_isHovered ? 0.08 : 0.04)),
              blurRadius: widget.isSelected ? 24 : 18,
              offset: const Offset(0, 5),
            ),
            if (widget.hasGlow || widget.isSelected)
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(DesignSystem.spacingM),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryDarkModeCard() {
    final borderColor = widget.isSelected
        ? const Color(0xFFC89B3C)
        : (_isHovered
            ? const Color(0xFFC89B3C).withValues(alpha: 0.4)
            : const Color(0xFFC89B3C).withValues(alpha: 0.15));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isSelected
                    ? [
                        const Color(0xFF1C273C),
                        const Color(0xFF111722),
                      ]
                    : [
                        const Color(0xFF131A26),
                        const Color(0xFF0C111A),
                      ],
              ),
          border: Border.all(
            color: borderColor,
            width: widget.isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: widget.isSelected ? 24 : 16,
              offset: const Offset(0, 6),
            ),
            if (widget.hasGlow || widget.isSelected || _isHovered)
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: widget.isSelected ? 0.2 : 0.1),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(DesignSystem.spacingM),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
