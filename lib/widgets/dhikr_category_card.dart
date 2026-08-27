import 'package:flutter/material.dart';
import '../models/azkar_models.dart';
import '../utils/design_system.dart';

class DhikrCategoryCard extends StatelessWidget {
  final AzkarCategoryMeta category;
  final VoidCallback onTap;

  const DhikrCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.gradientColors[0].withValues(alpha: 0.35),
              category.gradientColors[1].withValues(alpha: 0.15),
              DesignSystem.bgDarkest,
            ],
          ),
          border: Border.all(
            color: category.accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: category.accentColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignSystem.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Icon & Count Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: category.accentColor.withValues(alpha: 0.15),
                      border: Border.all(color: category.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(category.icon, color: category.accentColor, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      '${category.count} ذكر',
                      style: const TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Title and Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.titleArabic,
                    style: const TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.subtitle,
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: 0.65,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(category.accentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
