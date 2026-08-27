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
    this.borderRadius = DesignSystem.radiusMedium,
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
    final borderColor = widget.isSelected
        ? DesignSystem.gold.withOpacity(0.6)
        : (_isHovered
            ? DesignSystem.electricBlue.withOpacity(0.4)
            : Colors.white.withOpacity(0.08));

    final effectiveGlowColor = widget.glowColor ??
        (widget.isSelected ? DesignSystem.gold : DesignSystem.electricBlue);

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
                        DesignSystem.gold.withOpacity(0.12),
                        DesignSystem.bgCard.withOpacity(0.85),
                      ]
                    : [
                        DesignSystem.bgCard.withOpacity(0.7),
                        DesignSystem.bgElevated.withOpacity(0.85),
                      ],
              ),
          border: Border.all(
            color: borderColor,
            width: widget.isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            if (widget.hasGlow || widget.isSelected || _isHovered)
              BoxShadow(
                color: effectiveGlowColor.withOpacity(
                    widget.isSelected ? 0.25 : (_isHovered ? 0.18 : 0.12)),
                blurRadius: 20,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: widget.onTap,
            splashColor: DesignSystem.electricBlue.withOpacity(0.15),
            highlightColor: DesignSystem.gold.withOpacity(0.08),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
