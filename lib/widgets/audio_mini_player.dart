import 'package:flutter/material.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';

class AudioMiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const AudioMiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = AudioQuranService();
    final reciter = service.currentReciter;
    final surah = service.currentSurah;
    final isPlaying = service.isPlaying;
    final pos = service.currentPosition;
    final total = service.totalDuration;
    final progress = (total.inSeconds > 0 ? pos.inSeconds / total.inSeconds : 0.0).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DesignSystem.bgDarkest.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Small Reciter Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DesignSystem.gold),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      reciter.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: DesignSystem.goldLight, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Surah & Reciter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة ${surah.nameArabic}',
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reciter.nameArabic,
                        style: const TextStyle(
                          color: DesignSystem.goldLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: DesignSystem.goldLight,
                    size: 34,
                  ),
                  onPressed: service.togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: DesignSystem.textWhite, size: 24),
                  onPressed: service.nextSurah,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
