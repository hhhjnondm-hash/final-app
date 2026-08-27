import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class DhikrHeroCard extends StatelessWidget {
  final VoidCallback? onContinueTap;

  const DhikrHeroCard({
    super.key,
    this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0C192E),
            const Color(0xFF081220),
            DesignSystem.bgDarkest,
          ],
        ),
        border: Border.all(
          color: DesignSystem.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Islamic Lantern & Mosque Artwork Background
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            child: Image.asset(
              'assets/azkar_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Deep Dark Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignSystem.bgDarkest.withValues(alpha: 0.7),
                  DesignSystem.bgDarkest.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag: Quran Surah Ar-Ra'd Reference
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DesignSystem.bgDarkest.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    border: Border.all(
                      color: DesignSystem.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: DesignSystem.goldLight, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'سورة الرعد • ٢٨',
                        style: TextStyle(
                          color: DesignSystem.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Central Verse & Callout
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ»',
                      style: TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignSystem.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ابدأ يومك وليلتك بذكر الله وحصّن نفسك',
                          style: TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
