import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';

class IqraAudioHero extends StatelessWidget {
  final SurahMeta currentSurah;
  final int activeAyahNumber;
  final VoidCallback onReciterChangeTap;
  final VoidCallback onSurahChangeTap;

  const IqraAudioHero({
    super.key,
    required this.currentSurah,
    required this.activeAyahNumber,
    required this.onReciterChangeTap,
    required this.onSurahChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final audio = AudioQuranService();
    final reciter = audio.currentReciter;
    final isPlaying = audio.isPlaying;
    final pos = audio.currentPosition;
    final total = audio.totalDuration;
    final progress = (total.inSeconds > 0 ? pos.inSeconds / total.inSeconds : 0.0).clamp(0.0, 1.0);

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
          // Background Cinematic Quran Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/audio_hero.jpg',
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox(height: 320),
            ),
          ),

          // Deep Dark Gradient Overlay
          Container(
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignSystem.bgDarkest.withValues(alpha: 0.72),
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
                // Top Tag: Current Reciter & Surah info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onReciterChangeTap,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: DesignSystem.bgDarkest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: DesignSystem.gold,
                              ),
                              child: const Icon(Icons.person, color: DesignSystem.bgDarkest, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reciter.nameArabic,
                              style: const TextStyle(
                                color: DesignSystem.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: DesignSystem.goldLight, size: 16),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: onSurahChangeTap,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'سورة ${currentSurah.nameArabic}',
                              style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.format_list_bulleted_rounded, color: DesignSystem.goldLight, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Surah Name, Juz, and Active Ayah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سورة ${currentSurah.nameArabic}',
                          style: const TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الجزء ${currentSurah.juzNumber} • الآية الجارية: $activeAyahNumber من ${currentSurah.ayahCount}',
                          style: const TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Waveform Visualizer
                    Row(
                      children: List.generate(5, (index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: isPlaying ? (10.0 + (index % 3) * 12) : 6.0,
                          decoration: BoxDecoration(
                            color: isPlaying ? DesignSystem.goldLight : DesignSystem.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Live Scrub Progress Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: DesignSystem.gold,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                        thumbColor: DesignSystem.goldLight,
                        overlayColor: DesignSystem.gold.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          audio.seekTo(Duration(seconds: (val * total.inSeconds).toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            audio.formatDuration(pos),
                            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                          ),
                          Text(
                            audio.formatDuration(total),
                            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: DesignSystem.goldLight, size: 28),
                      onPressed: audio.previousSurah,
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: audio.togglePlayPause,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: DesignSystem.goldGradient,
                          boxShadow: DesignSystem.goldGlow,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: DesignSystem.bgDarkest,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: DesignSystem.goldLight, size: 28),
                      onPressed: audio.nextSurah,
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
