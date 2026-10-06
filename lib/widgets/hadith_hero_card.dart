import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../utils/design_system.dart';
import 'visual_effects/floating_particles.dart';
import 'visual_effects/shimmer_sweep.dart';

class HadithHeroCard extends StatelessWidget {
  final HadithItem hadith;
  final VoidCallback onOpenHadithTap;
  final VoidCallback onShareTap;

  const HadithHeroCard({
    super.key,
    required this.hadith,
    required this.onOpenHadithTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = HadithService();
    final isFav = service.isFavorite(hadith.id);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ShimmerSweep(
      duration: const Duration(milliseconds: 3600),
      pauseDuration: const Duration(milliseconds: 3000),
      shimmerColor: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    const Color(0xFFFFFDF8),
                    const Color(0xFFFAF5EB),
                    const Color(0xFFF5EBD7),
                  ]
                : [
                    const Color(0xFF0D1D3A),
                    const Color(0xFF071324),
                    DesignSystem.bgDarkest,
                  ],
          ),
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFFC89B3C).withValues(alpha: 0.12)
                  : DesignSystem.gold.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingParticles(
          numberOfParticles: 12,
          particleColor: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
          child: Stack(
            children: [
              // Islamic Lantern & Mosque Artwork
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Opacity(
                    opacity: isLight ? 0.35 : 0.85,
                    child: Image.asset(
                      isLight ? 'assets/daylight_mosque_bg.jpg' : 'assets/hadith_hero.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLight
                          ? [
                              const Color(0xFFFFFDF8).withValues(alpha: 0.2),
                              const Color(0xFFFFFDF8).withValues(alpha: 0.82),
                              const Color(0xFFFFFDF8).withValues(alpha: 0.98),
                            ]
                          : [
                              Colors.transparent,
                              DesignSystem.bgDarkest.withValues(alpha: 0.7),
                              DesignSystem.bgDarkest.withValues(alpha: 0.98),
                            ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Content Layer
              Padding(
                padding: const EdgeInsets.all(DesignSystem.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Tag: حديث اليوم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isLight
                                ? const LinearGradient(colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)])
                                : DesignSystem.goldGradient,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            boxShadow: isLight
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : DesignSystem.goldGlow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'حديث اليوم النبوي',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFFBF4E4)
                                : Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFE5D4B3)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            hadith.book,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 70),

                    // Prophetic Hadith Text
                    Text(
                      '«${hadith.text}»',
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                        fontSize: 16,
                        height: 1.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Narrator
                    Text(
                      hadith.narrator,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Action Buttons: Favorite, Share, View Hadith
                    Row(
                      children: [
                        // Favorite button
                        InkWell(
                          onTap: () => service.toggleFavorite(hadith.id),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight
                                  ? const Color(0xFFFBF4E4)
                                  : Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: isLight
                                    ? const Color(0xFFE5D4B3)
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav
                                  ? const Color(0xFFE11D48)
                                  : (isLight ? const Color(0xFF78716C) : DesignSystem.textWhite),
                              size: 18,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Share button
                        InkWell(
                          onTap: onShareTap,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight
                                  ? const Color(0xFFFBF4E4)
                                  : Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: isLight
                                    ? const Color(0xFFE5D4B3)
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              color: isLight ? const Color(0xFF78716C) : DesignSystem.textWhite,
                              size: 18,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // View Hadith Button
                        Expanded(
                          child: InkWell(
                            onTap: onOpenHadithTap,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isLight
                                    ? const LinearGradient(colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)])
                                    : DesignSystem.goldGradient,
                                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                                boxShadow: isLight
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFC89B3C).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : DesignSystem.goldGlow,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    color: isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'عرض الحديث وشرحه',
                                    style: TextStyle(
                                      color: isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
