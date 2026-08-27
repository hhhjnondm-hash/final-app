import 'package:flutter/material.dart';
import '../models/audio_models.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [
                  DesignSystem.gold.withValues(alpha: 0.18),
                  DesignSystem.bgCard.withValues(alpha: 0.95),
                ]
              : [
                  DesignSystem.bgCard.withValues(alpha: 0.8),
                  DesignSystem.bgDarkest.withValues(alpha: 0.9),
                ],
        ),
        border: Border.all(
          color: isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.08),
          width: isCurrent ? 1.4 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: DesignSystem.gold.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
                  color: isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
                boxShadow: isCurrent ? DesignSystem.goldGlow : null,
              ),
              child: ClipOval(
                child: reciter.photoUrl.startsWith('assets/')
                    ? Image.asset(
                        reciter.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: DesignSystem.bgDarkest,
                          child: const Icon(Icons.person_rounded, color: DesignSystem.goldLight, size: 26),
                        ),
                      )
                    : Image.network(
                        reciter.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: DesignSystem.bgDarkest,
                          child: const Icon(Icons.person_rounded, color: DesignSystem.goldLight, size: 26),
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
                            color: isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite,
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
                            color: DesignSystem.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: DesignSystem.gold),
                          ),
                          child: const Text(
                            'المحدد',
                            style: TextStyle(color: DesignSystem.goldLight, fontSize: 9, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(
                          color: DesignSystem.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Favorite & Play/Pause Button
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? const Color(0xFFE11D48) : DesignSystem.textMuted,
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
                      gradient: isCurrent ? DesignSystem.goldGradient : null,
                      color: isCurrent ? null : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isCurrent ? DesignSystem.bgDarkest : DesignSystem.goldLight,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
