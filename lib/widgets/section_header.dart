import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spacingL,
        vertical: DesignSystem.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(DesignSystem.spacingS),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111722),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                    border: Border.all(
                      color: const Color(0xFFC89B3C).withValues(alpha: isLight ? 0.4 : 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight
                            ? const Color(0xFF102A43).withValues(alpha: 0.04)
                            : const Color(0xFFC89B3C).withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFE8D29A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF172033) : const Color(0xFFF6F8FA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF667085) : const Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (actionText != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  actionText!,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF0F6B78) : const Color(0xFFE8D29A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
