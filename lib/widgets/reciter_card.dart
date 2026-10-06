import 'package:flutter/material.dart';
import '../models/audio_models.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';
import 'visual_effects/interactive_motion_card.dart';
import 'quran_download_sheet.dart';

class ReciterCard extends StatelessWidget {
  final ReciterProfile reciter;
  final VoidCallback onPlayTap;

  const ReciterCard({
    super.key,
    required this.reciter,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = AudioQuranService();
    final isCurrent = service.currentReciter.id == reciter.id;
    final isPlaying = isCurrent && service.isPlaying;
    final isFavorite = service.isFavorite(reciter.id);

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InteractiveMotionCard(
        onTap: onPlayTap,
        borderRadius: 20,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? (isCurrent
                      ? [
                          const Color(0xFFFFF7E6),
                          const Color(0xFFFFFDF8),
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFFAF5EB),
                        ])
                  : (isCurrent
                      ? [
                          DesignSystem.gold.withValues(alpha: 0.18),
                          DesignSystem.bgCard.withValues(alpha: 0.95),
                        ]
                      : [
                          DesignSystem.bgCard.withValues(alpha: 0.8),
                          DesignSystem.bgDarkest.withValues(alpha: 0.9),
                        ]),
            ),
            border: Border.all(
              color: isLight
                  ? (isCurrent ? const Color(0xFFC89B3C) : const Color(0xFFE5D4B3))
                  : (isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.08)),
              width: isCurrent ? 1.4 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: isLight
                          ? const Color(0xFFE5A83B).withValues(alpha: 0.2)
                          : DesignSystem.gold.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (isLight
                    ? [
                        BoxShadow(
                          color: const Color(0xFF854D0E).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Circular Avatar with Gold Ring
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLight
                          ? (isCurrent ? const Color(0xFFC89B3C) : const Color(0xFFE5D4B3))
                          : (isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.15)),
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? (isLight
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE5A83B).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                )
                              ]
                            : DesignSystem.goldGlow)
                        : null,
                  ),
                  child: ClipOval(
                    child: reciter.photoUrl.startsWith('assets/')
                        ? Image.asset(
                            reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isLight ? const Color(0xFFF1EAD8) : DesignSystem.bgDarkest,
                              child: Icon(
                                Icons.person_rounded,
                                color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                size: 26,
                              ),
                            ),
                          )
                        : Image.network(
                            reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isLight ? const Color(0xFFF1EAD8) : DesignSystem.bgDarkest,
                              child: Icon(
                                Icons.person_rounded,
                                color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                size: 26,
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Reciter Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              reciter.nameArabic,
                              style: TextStyle(
                                color: isLight
                                    ? (isCurrent ? const Color(0xFF854D0E) : const Color(0xFF1C1917))
                                    : (isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? const Color(0xFFFBF4E4)
                                    : DesignSystem.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                                border: Border.all(
                                  color: isLight ? const Color(0xFFC89B3C) : DesignSystem.gold,
                                ),
                              ),
                              child: Text(
                                'المحدد',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${reciter.country} • ${reciter.style}',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions: Download Button & Favorite & Play/Pause Button
                Row(
                  children: [
                    // Download Button (Icon + "تنزيل")
                    InkWell(
                      onTap: () {
                        QuranDownloadSheet.show(
                          context,
                          reciter: reciter,
                          currentSurah: service.currentSurah,
                        );
                      },
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFFBF4E4)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFFE5D4B3)
                                : DesignSystem.gold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              size: 18,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'تنزيل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? const Color(0xFFE11D48)
                            : (isLight ? const Color(0xFF78716C) : DesignSystem.textMuted),
                        size: 20,
                      ),
                      onPressed: () {
                        service.toggleFavorite(reciter.id);
                      },
                    ),
                    InkWell(
                      onTap: onPlayTap,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isCurrent
                              ? (isLight
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : DesignSystem.goldGradient)
                              : null,
                          color: isCurrent
                              ? null
                              : (isLight
                                  ? const Color(0xFFF1EAD8)
                                  : Colors.white.withValues(alpha: 0.05)),
                          border: Border.all(
                            color: isLight
                                ? (isCurrent ? const Color(0xFFC89B3C) : const Color(0xFFE5D4B3))
                                : (isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.15)),
                          ),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isCurrent
                              ? (isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest)
                              : (isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight),
                          size: 20,
                        ),
                      ),
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
