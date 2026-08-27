import 'package:flutter/material.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';

class QuranAudioPlayer extends StatefulWidget {
  final String surahName;
  final int currentAyah;
  final int totalAyahs;
  final VoidCallback? onClose;

  const QuranAudioPlayer({
    super.key,
    required this.surahName,
    required this.currentAyah,
    required this.totalAyahs,
    this.onClose,
  });

  @override
  State<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends State<QuranAudioPlayer> {
  final QuranStorageService _storage = QuranStorageService();
  bool _isPlaying = false;
  double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: DesignSystem.gold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Info Row: Reciter Name, Surah Info, Close Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.gold.withValues(alpha: 0.15),
                  border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.headphones_rounded, color: DesignSystem.goldLight, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سورة ${widget.surahName} • الآية ${widget.currentAyah}',
                      style: const TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _storage.selectedReciter,
                      style: const TextStyle(
                        color: DesignSystem.goldLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Reciter Selector Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.person_pin_rounded, color: DesignSystem.textSecondary, size: 20),
                color: DesignSystem.bgCard,
                onSelected: (reciter) {
                  _storage.setReciter(reciter);
                  setState(() {});
                },
                itemBuilder: (context) => [
                  'مشاري بن راشد العفاسي',
                  'عبد الباسط عبد الصمد',
                  'محمود خليل الحصري',
                  'ماهر المعيقلي',
                  'سعد الغامدي',
                ].map((name) => PopupMenuItem(
                  value: name,
                  child: Text(
                    name,
                    style: TextStyle(
                      color: _storage.selectedReciter == name ? DesignSystem.goldLight : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                )).toList(),
              ),

              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: DesignSystem.textMuted, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onClose,
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Slider & Audio Controls Row
          Row(
            children: [
              const Text(
                '0:45',
                style: TextStyle(color: DesignSystem.textMuted, fontSize: 10),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: DesignSystem.gold,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: DesignSystem.goldLight,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (v) => setState(() => _progress = v),
                  ),
                ),
              ),
              const Text(
                '1:20',
                style: TextStyle(color: DesignSystem.textMuted, fontSize: 10),
              ),
            ],
          ),

          // Controls (Previous, Play/Pause, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: DesignSystem.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: DesignSystem.goldGradient,
                  boxShadow: DesignSystem.goldGlow,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: DesignSystem.bgDarkest,
                    size: 24,
                  ),
                  onPressed: () => setState(() => _isPlaying = !_isPlaying),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: DesignSystem.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
