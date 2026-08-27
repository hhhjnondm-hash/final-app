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
                    color: DesignSystem.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                    border: Border.all(
                      color: DesignSystem.gold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: DesignSystem.gold,
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
                    style: const TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: DesignSystem.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (actionText != null && onActionTap != null)
            InkWell(
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              onTap: onActionTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacingM,
                  vertical: DesignSystem.spacingXS,
                ),
                child: Row(
                  children: [
                    Text(
                      actionText!,
                      style: const TextStyle(
                        color: DesignSystem.goldLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: DesignSystem.goldLight,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
