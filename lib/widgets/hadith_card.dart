import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../utils/design_system.dart';

class HadithCard extends StatelessWidget {
  final HadithItem hadith;
  final VoidCallback onTap;
  final VoidCallback onShareTap;

  const HadithCard({
    super.key,
    required this.hadith,
    required this.onTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = HadithService();
    final isFav = service.isFavorite(hadith.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Number ornament & Book Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: DesignSystem.gold),
                            color: DesignSystem.gold.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              '${hadith.number}',
                              style: const TextStyle(
                                color: DesignSystem.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hadith.book,
                          style: const TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        hadith.topic,
                        style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Hadith Content Preview
                Text(
                  '«${hadith.text}»',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 14,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                // Footer: Narrator & Action Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        hadith.narrator,
                        style: const TextStyle(
                          color: DesignSystem.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFE11D48) : DesignSystem.textMuted,
                            size: 18,
                          ),
                          onPressed: () => service.toggleFavorite(hadith.id),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.share_rounded,
                            color: DesignSystem.textMuted,
                            size: 18,
                          ),
                          onPressed: onShareTap,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: DesignSystem.goldLight,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
