import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/audio_quran_service.dart';

class IqraAudioHero extends StatelessWidget {
  final SurahMeta currentSurah;
  final int activeAyahNumber;
  final String activeAyahText;
  final VoidCallback onReciterChangeTap;
  final VoidCallback onSurahChangeTap;
  final VoidCallback? onPrevAyah;
  final VoidCallback? onNextAyah;
  final bool isRepeat;
  final VoidCallback? onToggleRepeat;

  const IqraAudioHero({
    super.key,
    required this.currentSurah,
    required this.activeAyahNumber,
    this.activeAyahText = '',
    required this.onReciterChangeTap,
    required this.onSurahChangeTap,
    this.onPrevAyah,
    this.onNextAyah,
    this.isRepeat = false,
    this.onToggleRepeat,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final audio = AudioQuranService();
    final reciter = audio.currentReciter;
    final isPlaying = audio.isPlaying;
    final pos = audio.currentPosition;
    final total = audio.totalDuration;
    final progress = (total.inSeconds > 0 ? pos.inSeconds / total.inSeconds : 0.0).clamp(0.0, 1.0);

    final displayAyahText = activeAyahText.trim().isNotEmpty
        ? activeAyahText.trim()
        : 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.4),
          width: 1.2,
        ),
        gradient: isLight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFDF8),
                  Color(0xFFFAF5EB),
                  Color(0xFFF5EBD7),
                ],
              )
            : const RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF261D0F),
                  Color(0xFF131A26),
                  Color(0xFF070B11),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFFC89B3C).withValues(alpha: 0.1)
                : const Color(0xFFC89B3C).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Opacity(
              opacity: isLight ? 0.35 : 0.45,
              child: Image.asset(
                isLight ? 'assets/daylight_mosque_bg.jpg' : 'assets/audio_hero.jpg',
                height: 330,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/surah_info_iqra_banner.png',
                  height: 330,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 330),
                ),
              ),
            ),
          ),

          // Soft Gradient Overlay
          Container(
            height: 330,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
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
                        Colors.black.withValues(alpha: 0.2),
                        const Color(0xFF070B11).withValues(alpha: 0.8),
                        const Color(0xFF070B11).withValues(alpha: 0.98),
                      ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Content Layer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Pills Row: [سورة ...] on left, [القارئ ...] on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reciter Selector Pill (Right)
                      InkWell(
                        onTap: onReciterChangeTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF101722).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLight ? const Color(0xFFE5A83B) : const Color(0xFFFFD56B),
                                ),
                                child: Icon(Icons.person, color: isLight ? Colors.white : const Color(0xFF070B11), size: 14),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 130),
                                child: Text(
                                  reciter.nameArabic,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA),
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B), size: 18),
                            ],
                          ),
                        ),
                      ),

                      // Surah Selector Pill (Left)
                      InkWell(
                        onTap: onSurahChangeTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF101722).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.format_list_bulleted_rounded, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'سورة ${currentSurah.nameArabic}',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA),
                                  fontSize: 11,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Center Preview Calligraphic Verse
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$displayAyahText ($activeAyahNumber)',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Surah Name Title
                  Center(
                    child: Text(
                      'سورة ${currentSurah.nameArabic}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Juz & Ayah details
                  Center(
                    child: Text(
                      'الجزء ${currentSurah.juzNumber} • الآية $activeAyahNumber من ${currentSurah.ayahCount}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Golden Audio Progress Slider
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                          inactiveTrackColor: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.15),
                          thumbColor: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                          overlayColor: (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B)).withValues(alpha: 0.2),
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
                              style: TextStyle(color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Cairo'),
                            ),
                            Text(
                              audio.formatDuration(total),
                              style: TextStyle(color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Audio Playback Controls matching screenshot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Repeat / Loop button
                      IconButton(
                        icon: Icon(
                          isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                          color: isRepeat
                              ? (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))
                              : (isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8)),
                          size: 22,
                        ),
                        onPressed: onToggleRepeat,
                        tooltip: 'تكرار التلاوة',
                      ),

                      // Previous Ayah / Surah
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFE8D29A), size: 28),
                        onPressed: onPrevAyah ?? audio.previousSurah,
                        tooltip: 'السابق',
                      ),

                      // Central Big Golden Play / Pause Button
                      InkWell(
                        onTap: audio.togglePlayPause,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isLight
                                  ? const [Color(0xFFFFDF7D), Color(0xFFE5A83B), Color(0xFFC89B3C)]
                                  : const [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B)).withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: isLight ? const Color(0xFF1C1917) : const Color(0xFF070B11),
                            size: 34,
                          ),
                        ),
                      ),

                      // Next Ayah / Surah
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFE8D29A), size: 28),
                        onPressed: onNextAyah ?? audio.nextSurah,
                        tooltip: 'التالي',
                      ),

                      // Speed Selector Pill Button
                      InkWell(
                        onTap: () {
                          final speeds = [1.0, 1.25, 1.5, 0.75];
                          final curIdx = speeds.indexOf(audio.playbackSpeed);
                          final nextIdx = (curIdx + 1) % speeds.length;
                          audio.setPlaybackSpeed(speeds[nextIdx]);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF161F2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${audio.playbackSpeed}x',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                              fontSize: 11,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
