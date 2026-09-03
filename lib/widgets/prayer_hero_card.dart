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

    return Container(
      height: 310,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B36),
            const Color(0xFF091426),
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
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Islamic Mosque Artwork Image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            child: Image.asset(
              'assets/prayer_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Deep Dark Smooth Gradient Overlays
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignSystem.bgDarkest.withValues(alpha: 0.75),
                  DesignSystem.bgDarkest.withValues(alpha: 0.98),
                ],
                stops: const [0.0, 0.5, 1.0],
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
                        color: DesignSystem.bgDarkest.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: DesignSystem.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: DesignSystem.goldLight, size: 13),
                          SizedBox(width: 6),
                          Text(
                            'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا',
                            style: TextStyle(
                              color: DesignSystem.goldLight,
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
                            color: DesignSystem.gold.withValues(alpha: 0.2),
                            border: Border.all(color: DesignSystem.gold),
                          ),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            color: DesignSystem.goldLight,
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
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'متبقي',
                              style: TextStyle(
                                color: DesignSystem.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _countdown,
                              style: const TextStyle(
                                color: DesignSystem.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(width: 24),

                    // Next Prayer Titles & Timing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: DesignSystem.gold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'الصلاة القادمة',
                              style: TextStyle(
                                color: DesignSystem.goldLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'صلاة ${nextPrayer.nameArabic}',
                          style: const TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextPrayer.formattedTimeArabic,
                          style: const TextStyle(
                            color: DesignSystem.cyanAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Bottom Status Pill: Current Prayer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(currentPrayer.icon, color: DesignSystem.goldLight, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'الصلاة الحالية: صلاة ${currentPrayer.nameArabic}',
                            style: const TextStyle(
                              color: DesignSystem.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        currentPrayer.formattedTimeArabic,
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
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
