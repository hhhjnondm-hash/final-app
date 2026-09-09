import 'package:flutter/material.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';

class AudioHeroPlayer extends StatefulWidget {
  final VoidCallback? onReciterChangeTap;

  const AudioHeroPlayer({
    super.key,
    this.onReciterChangeTap,
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
            color: DesignSystem.gold.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
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

          // Deep Dark Gradient Overlay
          Container(
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignSystem.bgDarkest.withValues(alpha: 0.75),
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
                // Top Tag: Current Reciter & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DesignSystem.bgDarkest.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: DesignSystem.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq_rounded, color: DesignSystem.goldLight, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'المصحف الصوتي المرتل',
                            style: TextStyle(
                              color: DesignSystem.goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.onReciterChangeTap != null)
                      InkWell(
                        onTap: widget.onReciterChangeTap,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'تغيير القارئ',
                                style: TextStyle(color: DesignSystem.textWhite, fontSize: 11),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: DesignSystem.goldLight, size: 14),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 80),

                // Surah & Reciter Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سورة ${surah.nameArabic}',
                            style: const TextStyle(
                              color: DesignSystem.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'القارئ: ${reciter.nameArabic}',
                            style: const TextStyle(
                              color: DesignSystem.goldLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                            color: isPlaying ? DesignSystem.goldLight : DesignSystem.textMuted,
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
                        activeTrackColor: DesignSystem.gold,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                        thumbColor: DesignSystem.goldLight,
                        overlayColor: DesignSystem.gold.withValues(alpha: 0.2),
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
                            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                          ),
                          Text(
                            _service.formatDuration(total),
                            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
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
                      icon: const Icon(Icons.shuffle_rounded, color: DesignSystem.textMuted, size: 20),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),

                    // Previous Surah Button
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: DesignSystem.goldLight, size: 30),
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
                          gradient: DesignSystem.goldGradient,
                          boxShadow: DesignSystem.goldGlow,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: DesignSystem.bgDarkest,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Next Surah Button
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: DesignSystem.goldLight, size: 30),
                      onPressed: _service.nextSurah,
                    ),
                    const SizedBox(width: 12),

                    // Offline Download Surah Button
                    IconButton(
                      icon: Icon(
                        _service.isDownloaded(reciter.id, surah.number)
                            ? Icons.download_done_rounded
                            : Icons.download_for_offline_rounded,
                        color: _service.isDownloaded(reciter.id, surah.number)
                            ? const Color(0xFF4ADE80)
                            : DesignSystem.goldLight,
                        size: 24,
                      ),
                      tooltip: _service.isDownloaded(reciter.id, surah.number) ? 'تم التحميل أوفلاين' : 'تحميل للاستماع بدون نت',
                      onPressed: () async {
                        if (!_service.isDownloaded(reciter.id, surah.number)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('بدأ تحميل سورة ${surah.nameArabic} للقارئ ${reciter.nameArabic} للاستماع بدون إنترنت...'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF102A43),
                            ),
                          );
                          await _service.downloadCurrentSurah();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم اكتمال تحميل سورة ${surah.nameArabic} بنجاح! متاحة الآن أوفلاين.'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('سورة ${surah.nameArabic} محملة بالفعل ومتاحة بدون إنترنت.'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF102A43),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Speed Toggle
                    InkWell(
                      onTap: () {
                        final nextSpeed = _service.playbackSpeed == 1.0 ? 1.25 : (_service.playbackSpeed == 1.25 ? 1.5 : 1.0);
                        _service.setPlaybackSpeed(nextSpeed);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                        ),
                        child: Text(
                          '${_service.playbackSpeed}x',
                          style: const TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
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
