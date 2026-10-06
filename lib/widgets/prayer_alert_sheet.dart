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
    final isLight = DesignSystem.isLightMode;
    final isPlaying = _athanService.isPlayingAthan;
    final soundName = _athanService.getSoundDisplayName(_athanService.settings.sound);

    final sheetBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final cardBorder = isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4);
    final textTitle = isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite;
    final goldAccent = isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight;
    final textSub = isLight ? const Color(0xFF78716C) : DesignSystem.textMuted;

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: (isLight ? const Color(0xFF854D0E) : DesignSystem.gold).withValues(alpha: 0.15),
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
                color: isLight ? const Color(0xFFD6C7A1) : DesignSystem.textMuted.withValues(alpha: 0.4),
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
              gradient: LinearGradient(
                colors: isLight
                    ? [const Color(0xFF854D0E), const Color(0xFFC89B3C)]
                    : [const Color(0xFFD4AF37), const Color(0xFFFFD56B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B)).withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'اللَّهُ أَكْبَرُ • اللَّهُ أَكْبَرُ',
            style: TextStyle(
              color: goldAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'حان الآن موعد أذان صلاة ${widget.timing.nameArabic}',
            style: TextStyle(
              color: textTitle,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            soundName,
            style: TextStyle(
              color: goldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.redAccent : (isLight ? const Color(0xFF854D0E) : DesignSystem.gold),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      _athanService.stopAthan();
                    } else {
                      _athanService.playAthan(prayer: widget.timing.nameEnglish);
                    }
                  },
                  icon: Icon(isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
                  label: Text(
                    isPlaying ? 'إيقاف صوت الأذان' : 'تشغيل صوت الأذان 🔊',
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
                child: Text('إغلاق', style: TextStyle(color: textSub, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
