import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service_v2.dart';
import '../utils/design_system.dart';

class PrayerHeroCard extends StatefulWidget {
  final VoidCallback? onAthanTap;

  const PrayerHeroCard({
    super.key,
    this.onAthanTap,
  });

  @override
  State<PrayerHeroCard> createState() => _PrayerHeroCardState();
}

class _PrayerHeroCardState extends State<PrayerHeroCard> {
  final PrayerServiceV2 _service = PrayerServiceV2();
  
  PrayerTiming? _nextPrayer;
  PrayerTiming? _currentPrayer;
  String _countdown = '00:00:00';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
    _loadPrayerData();
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrayerData() async {
    try {
      final nextPrayer = await _service.getNextPrayer();
      final currentPrayer = await _service.getCurrentPrayer();
      final countdown = await _service.getFormattedCountdown();
      final progress = await _service.getRemainingProgress();

      if (mounted) {
        setState(() {
          _nextPrayer = nextPrayer;
          _currentPrayer = currentPrayer;
          _countdown = countdown;
          _progress = progress;
        });
      }
    } catch (e) {
      // Use fallback values if service fails
      if (mounted) {
        setState(() {
          _countdown = '00:00:00';
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = _nextPrayer ?? PrayerTiming(
      type: PrayerType.fajr,
      nameArabic: 'الفجر',
      nameEnglish: 'Fajr',
      time: const TimeOfDay(hour: 4, minute: 0),
      icon: Icons.nightlight_round,
    );
    
    final currentPrayer = _currentPrayer ?? PrayerTiming(
      type: PrayerType.fajr,
      nameArabic: 'الفجر',
      nameEnglish: 'Fajr',
      time: const TimeOfDay(hour: 4, minute: 0),
      icon: Icons.nightlight_round,
    );

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      constraints: const BoxConstraints(minHeight: 270),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  const Color(0xFFFFFDF8),
                  const Color(0xFFFAF5EB),
                  const Color(0xFFF5EBD7),
                ]
              : [
                  const Color(0xFF0D1B36),
                  const Color(0xFF091426),
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
                ? const Color(0xFFC89B3C).withValues(alpha: 0.1)
                : DesignSystem.gold.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Islamic Mosque Artwork Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
              child: Image.asset(
                isLight ? 'assets/daylight_mosque_bg.jpg' : 'assets/prayer_hero.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Deep Dark or Daylight Smooth Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
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
                          Colors.transparent,
                          DesignSystem.bgDarkest.withValues(alpha: 0.75),
                          DesignSystem.bgDarkest.withValues(alpha: 0.98),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Hero Content
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Quranic Verse Badge & Athan Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFFBF4E4).withValues(alpha: 0.9)
                            : DesignSystem.bgDarkest.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.onAthanTap != null)
                      InkWell(
                        onTap: widget.onAthanTap,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLight
                                ? const Color(0xFFFBF4E4)
                                : DesignSystem.gold.withValues(alpha: 0.2),
                            border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold),
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),

                // Center Live Countdown Arc & Next Prayer Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular Live Countdown Arc
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 6,
                            backgroundColor: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(isLight ? const Color(0xFF854D0E) : DesignSystem.gold),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'متبقي',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _countdown,
                              style: TextStyle(
                                color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Next Prayer Titles & Timing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.gold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الصلاة القادمة',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'صلاة ${nextPrayer.nameArabic}',
                              softWrap: false,
                              style: TextStyle(
                                color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              nextPrayer.formattedTimeArabic,
                              softWrap: false,
                              style: TextStyle(
                                color: isLight ? const Color(0xFF854D0E) : DesignSystem.cyanAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Status Pill: Current Prayer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFBF4E4) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(currentPrayer.icon, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'الصلاة الحالية: صلاة ${currentPrayer.nameArabic}',
                                  softWrap: false,
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF78716C) : DesignSystem.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentPrayer.formattedTimeArabic,
                        style: TextStyle(
                          color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
