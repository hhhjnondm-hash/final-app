import 'package:flutter/material.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';
import 'visual_effects/floating_particles.dart';
import 'quran_download_sheet.dart';

class AudioHeroPlayer extends StatefulWidget {
  final VoidCallback? onReciterChangeTap;
  final VoidCallback? onSurahChangeTap;

  const AudioHeroPlayer({
    super.key,
    this.onReciterChangeTap,
    this.onSurahChangeTap,
  });

  @override
  State<AudioHeroPlayer> createState() => _AudioHeroPlayerState();
}

class _AudioHeroPlayerState extends State<AudioHeroPlayer> {
  final AudioQuranService _service = AudioQuranService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reciter = _service.currentReciter;
    final surah = _service.currentSurah;
    final isPlaying = _service.isPlaying;
    final pos = _service.currentPosition;
    final total = _service.totalDuration;
    final progress = (total.inSeconds > 0 ? pos.inSeconds / total.inSeconds : 0.0).clamp(0.0, 1.0);

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFFFFDF8),
                  const Color(0xFFFAF4E8),
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
                ? const Color(0xFFC89B3C).withValues(alpha: 0.15)
                : DesignSystem.gold.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: isLight
                ? const Color(0xFF854D0E).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Islamic Quran & Microphone Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/audio_hero.jpg',
              height: 380,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox(height: 380),
            ),
          ),

          // Deep Gradient Overlay
          Container(
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isLight
                    ? [
                        Colors.white.withValues(alpha: 0.15),
                        const Color(0xFFFFFDF8).withValues(alpha: 0.88),
                        const Color(0xFFFFFDF8).withValues(alpha: 0.98),
                      ]
                    : [
                        Colors.transparent,
                        DesignSystem.bgDarkest.withValues(alpha: 0.75),
                        DesignSystem.bgDarkest.withValues(alpha: 0.98),
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Subtle Floating Golden Particles on Hero (GPU-isolated)
          const Positioned.fill(
            child: RepaintBoundary(
              child: FloatingParticles(
                numberOfParticles: 12,
                particleColor: DesignSystem.goldLight,
              ),
            ),
          ),

          // Content Layer
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tag: Current Reciter & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFFBF4E4)
                            : DesignSystem.bgDarkest.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: isLight
                              ? const Color(0xFFE5D4B3)
                              : DesignSystem.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'المصحف الصوتي المرتل',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        if (widget.onSurahChangeTap != null) ...[
                          InkWell(
                            onTap: widget.onSurahChangeTap,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? const Color(0xFFFBF4E4)
                                    : DesignSystem.gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                                border: Border.all(
                                  color: isLight
                                      ? const Color(0xFFE5D4B3)
                                      : DesignSystem.gold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'السور (114)',
                                    style: TextStyle(
                                      color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (widget.onReciterChangeTap != null)
                          InkWell(
                            onTap: widget.onReciterChangeTap,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? const Color(0xFFF1EAD8)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                                border: Border.all(
                                  color: isLight
                                      ? const Color(0xFFE5D4B3)
                                      : Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'القراء',
                                    style: TextStyle(
                                      color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 70),

                // Surah & Reciter Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: widget.onSurahChangeTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'سورة ${surah.nameArabic}',
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.touch_app_rounded,
                                    color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'القارئ: ${reciter.nameArabic}',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Audio Visualizer Indicator
                    Row(
                      children: List.generate(5, (index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: isPlaying ? (12.0 + (index % 3) * 10) : 6.0,
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? (isLight ? const Color(0xFFD97706) : DesignSystem.goldLight)
                                : (isLight ? const Color(0xFFC4B5A5) : DesignSystem.textMuted),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Live Scrub Progress Bar & Durations
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: isLight ? const Color(0xFFD97706) : DesignSystem.gold,
                        inactiveTrackColor: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.12),
                        thumbColor: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                        overlayColor: isLight
                            ? const Color(0xFFD97706).withValues(alpha: 0.2)
                            : DesignSystem.gold.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          _service.seekTo(Duration(seconds: (val * total.inSeconds).toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _service.formatDuration(pos),
                            style: TextStyle(
                              color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _service.formatDuration(total),
                            style: TextStyle(
                              color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Main Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle / Repeat
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),

                    // Previous Surah Button
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                        size: 30,
                      ),
                      onPressed: _service.previousSurah,
                    ),
                    const SizedBox(width: 14),

                    // Big Play / Pause Central Button
                    InkWell(
                      onTap: _service.togglePlayPause,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isLight
                              ? const LinearGradient(
                                  colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : DesignSystem.goldGradient,
                          boxShadow: isLight
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE5A83B).withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : DesignSystem.goldGlow,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Next Surah Button
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                        size: 30,
                      ),
                      onPressed: _service.nextSurah,
                    ),
                    const SizedBox(width: 12),

                    // Dedicated Royal Download Button (Icon + "تنزيل" text beneath)
                    InkWell(
                      onTap: () {
                        QuranDownloadSheet.show(
                          context,
                          reciter: reciter,
                          currentSurah: surah,
                        );
                      },
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFFBF4E4)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFFE5D4B3)
                                : DesignSystem.gold.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'تنزيل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Speed Toggle
                    InkWell(
                      onTap: () {
                        final nextSpeed = _service.playbackSpeed == 1.0 ? 1.25 : (_service.playbackSpeed == 1.25 ? 1.5 : 1.0);
                        _service.setPlaybackSpeed(nextSpeed);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFF1EAD8)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE5D4B3) : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '${_service.playbackSpeed}x',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                            fontSize: 11,
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
        ],
      ),
    );
  }
}
