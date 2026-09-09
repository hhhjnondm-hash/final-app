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
    final isLight = DesignSystem.isLightMode;

    return ListenableBuilder(
      listenable: audioManager,
      builder: (context, child) {
        if (!audioManager.isPlaying && audioManager.currentDescriptor == null) {
          return const SizedBox.shrink();
        }

        final descriptor = audioManager.currentDescriptor;
        final title = descriptor?.title ?? (audioManager.currentSource == AudioSourceType.quran ? 'سورة البقرة' : 'الإذاعة المباشرة');
        final subtitle = descriptor?.subtitle ?? (audioManager.currentSource == AudioSourceType.quran ? 'الشيخ عبد الرحمن السديس' : 'بث مباشر');
        final isQuran = audioManager.currentSource == AudioSourceType.quran;
        final isPlaying = audioManager.isPlaying;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF090E17),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withOpacity(0.35),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? const Color(0xFF0F172A).withOpacity(0.06)
                          : Colors.black.withOpacity(0.8),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                    if (!isLight)
                      BoxShadow(
                        color: const Color(0xFFFFD56B).withOpacity(0.12),
                        blurRadius: 14,
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Close miniplayer button
                    InkWell(
                      onTap: () => audioManager.stop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF151C28),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Title & Subtitle Info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // Playback Duration (12:34)
                    Text(
                      '12:34',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Central Control Cluster: Shuffle, Prev, Big Play/Pause, Next, Repeat + Progress
                    Expanded(
                      child: Row(
                        children: [
                          // Progress Bar
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 60,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD56B),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Shuffle
                          Icon(
                            Icons.shuffle_rounded,
                            size: 17,
                            color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),

                          const SizedBox(width: 10),

                          // Prev
                          Icon(
                            Icons.skip_previous_rounded,
                            size: 20,
                            color: isLight ? const Color(0xFF475569) : const Color(0xFFA0AEC0),
                          ),

                          const SizedBox(width: 10),

                          // Play / Pause Circle (Gold Solid)
                          InkWell(
                            onTap: () {
                              if (isPlaying) {
                                audioManager.pause();
                              } else {
                                audioManager.resume();
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFD56B),
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: const Color(0xFF07090E),
                                size: 22,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Next
                          Icon(
                            Icons.skip_next_rounded,
                            size: 20,
                            color: isLight ? const Color(0xFF475569) : const Color(0xFFA0AEC0),
                          ),

                          const SizedBox(width: 10),

                          // Repeat
                          Icon(
                            Icons.repeat_rounded,
                            size: 17,
                            color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Total Duration (1:28:05)
                    Text(
                      '1:28:05',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Action Icons: Like, Playlist, Volume, Fullscreen
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 18,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.queue_music_rounded,
                          size: 18,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                        ),
                        const SizedBox(width: 8),
                        // Volume level bar
                        Container(
                          width: 50,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD56B),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.fullscreen_rounded,
                          size: 19,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
