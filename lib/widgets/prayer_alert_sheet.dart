import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/athan_service.dart';
import '../utils/design_system.dart';

class PrayerAlertSheet extends StatefulWidget {
  final PrayerTiming timing;

  const PrayerAlertSheet({
    super.key,
    required this.timing,
  });

  @override
  State<PrayerAlertSheet> createState() => _PrayerAlertSheetState();
}

class _PrayerAlertSheetState extends State<PrayerAlertSheet> {
  final AthanService _athanService = AthanService();

  @override
  void initState() {
    super.initState();
    _athanService.addListener(_onAthanUpdate);
  }

  @override
  void dispose() {
    _athanService.removeListener(_onAthanUpdate);
    super.dispose();
  }

  void _onAthanUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _athanService.isPlayingAthan;
    final soundName = _athanService.getSoundDisplayName(_athanService.settings.sound);

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignSystem.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mosque Icon with Gold Glow
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.goldGradient,
              boxShadow: DesignSystem.goldGlow,
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: DesignSystem.bgDarkest,
              size: 36,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'اللَّهُ أَكْبَرُ • اللَّهُ أَكْبَرُ',
            style: TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'حان الآن موعد أذان صلاة ${widget.timing.nameArabic}',
            style: const TextStyle(
              color: DesignSystem.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            soundName,
            style: TextStyle(
              color: DesignSystem.gold.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.redAccent : DesignSystem.gold,
                    foregroundColor: isPlaying ? Colors.white : DesignSystem.bgDarkest,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      _athanService.stopAthan();
                    } else {
                      _athanService.playAthan(prayer: widget.timing.type.name);
                    }
                  },
                  icon: Icon(isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
                  label: Text(
                    isPlaying ? 'إيقاف صوت الأذان' : 'تشغيل صوت الأذان',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  _athanService.stopAthan();
                  Navigator.pop(context);
                },
                child: const Text('إغلاق', style: TextStyle(color: DesignSystem.textMuted)),
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
