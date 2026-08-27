import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../utils/design_system.dart';

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1D3A),
            const Color(0xFF071324),
            DesignSystem.bgDarkest,
          ],
        ),
        border: Border.all(
          color: DesignSystem.gold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.16),
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
        children: [
          // Islamic Lantern & Mosque Night Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/hadith_hero.jpg',
              height: 360,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox(height: 360),
            ),
          ),

          // Deep Dark Gradient Overlay
          Container(
            height: 360,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignSystem.bgDarkest.withValues(alpha: 0.7),
                  DesignSystem.bgDarkest.withValues(alpha: 0.98),
                ],
                stops: const [0.0, 0.45, 1.0],
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
                        gradient: DesignSystem.goldGradient,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        boxShadow: DesignSystem.goldGlow,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: DesignSystem.bgDarkest, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'حديث اليوم النبوي',
                            style: TextStyle(
                              color: DesignSystem.bgDarkest,
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
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        hadith.book,
                        style: const TextStyle(color: DesignSystem.goldLight, fontSize: 10),
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
                  style: const TextStyle(
                    color: DesignSystem.textWhite,
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
                  style: const TextStyle(
                    color: DesignSystem.goldLight,
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
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFE11D48) : DesignSystem.textWhite,
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
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: DesignSystem.textWhite,
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
                            gradient: DesignSystem.goldGradient,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            boxShadow: DesignSystem.goldGlow,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded, color: DesignSystem.bgDarkest, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'عرض الحديث وشرحه',
                                style: TextStyle(
                                  color: DesignSystem.bgDarkest,
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
    );
  }
}
