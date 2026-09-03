import 'package:flutter/material.dart';
import '../screens/radio_screen.dart';
import '../screens/surah_viewer_screen.dart';
import '../services/global_audio_manager.dart';
import '../utils/design_system.dart';

class UnifiedMiniPlayer extends StatelessWidget {
  const UnifiedMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioManager = GlobalAudioManager();

    return ListenableBuilder(
      listenable: audioManager,
      builder: (context, child) {
        if (!audioManager.isPlaying) {
          return const SizedBox.shrink();
        }

        String title = '';
        String subtitle = '';
        String? artwork;
        bool isQuran = false;

        switch (audioManager.currentSource) {
          case AudioSourceType.quran:
            title = 'سورة الفاتحة';
            subtitle = 'مشاري راشد العفاسي';
            artwork = 'assets/reciters/shaikh-Mishari-Al-afasi.webP';
            isQuran = true;
            break;
          case AudioSourceType.radio:
            title = 'إذاعة القرآن الكريم';
            subtitle = 'تلاوة القرآن الكريم';
            artwork = null;
            isQuran = false;
            break;
          default:
            return const SizedBox.shrink();
        }

        final isPlaying = audioManager.isPlaying;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DesignSystem.bgCard.withValues(alpha: 0.96),
                  DesignSystem.bgDarkest.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignSystem.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.gold.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                if (isQuran) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SurahViewerScreen(
                        surahNumber: 1,
                        surahName: 'الفاتحة',
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RadioScreen()),
                  );
                }
              },
              child: Row(
                children: [
                  // Artwork Disc
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: DesignSystem.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: isPlaying ? DesignSystem.goldGlow : null,
                    ),
                    child: ClipOval(
                      child: artwork != null && artwork.startsWith('assets/')
                          ? Image.asset(
                              artwork,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                isQuran ? Icons.menu_book_rounded : Icons.radio_rounded,
                                color: DesignSystem.bgDarkest,
                                size: 20,
                              ),
                            )
                          : Icon(
                              isQuran ? Icons.menu_book_rounded : Icons.radio_rounded,
                              color: DesignSystem.bgDarkest,
                              size: 20,
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Play / Pause Button
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: DesignSystem.goldLight,
                      size: 34,
                    ),
                    onPressed: () => audioManager.togglePlayPause(),
                  ),

                  // Close Button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: DesignSystem.textMuted,
                      size: 20,
                    ),
                    onPressed: () => audioManager.stop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
