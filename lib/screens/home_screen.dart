import 'dart:async';
import 'package:flutter/material.dart';
import '../data/all_azkar_data.dart';
import '../data/reciters_data.dart';
import '../models/azkar_models.dart';
import '../models/prayer_models.dart';
import '../services/audio_quran_service.dart';
import '../services/prayer_service_v2.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/visual_effects/star_glint.dart';
import '../widgets/visual_effects/shimmer_sweep.dart';
import '../widgets/visual_effects/pulsing_halo.dart';
import '../widgets/visual_effects/islamic_decorations.dart';
import '../widgets/visual_effects/sound_wave_visualizer.dart';
import '../widgets/visual_effects/interactive_motion_card.dart';
import '../widgets/visual_effects/floating_particles.dart';
import 'azkar_screen.dart';
import 'audio_screen.dart';
import 'dhikr_reader_screen.dart';
import 'iqra_screen.dart';
import 'quran_screen.dart';
import 'notification_settings_screen.dart';
import 'prayer_times_screen.dart';
import 'qibla_screen.dart';
import 'radio_screen.dart';
import 'surah_viewer_screen.dart';
import '../widgets/developer_credits_badge.dart';
import '../services/theme_service.dart';
import '../widgets/theme_selection_modal.dart';

enum SpiritualTimeContext {
  morning,
  prayerFocus,
  evening,
  sleep,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerServiceV2 _prayerService = PrayerServiceV2();
  final QuranStorageService _quranStorage = QuranStorageService();

  PrayerTiming? _nextPrayer;
  String _countdown = '00:00:00';
  List<PrayerTiming> _allPrayers = [];
  Timer? _liveTimer;
  SpiritualTimeContext? _previewTimeContext;

  @override
  void initState() {
    super.initState();
    _initDefaultPrayerTimes();
    _startLiveTimer();
    _prayerService.addListener(_onServiceUpdate);
    _quranStorage.addListener(_onQuranStorageUpdate);
    _loadPrayerData();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _prayerService.removeListener(_onServiceUpdate);
    _quranStorage.removeListener(_onQuranStorageUpdate);
    super.dispose();
  }

  void _onQuranStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _initDefaultPrayerTimes() {
    // Default Egyptian General Authority timings for instant 0ms render
    _allPrayers = [
      PrayerTiming(
        type: PrayerType.fajr,
        nameArabic: 'الفجر',
        nameEnglish: 'Fajr',
        time: const TimeOfDay(hour: 5, minute: 3),
        icon: Icons.nightlight_round,
      ),
      PrayerTiming(
        type: PrayerType.sunrise,
        nameArabic: 'الشروق',
        nameEnglish: 'Sunrise',
        time: const TimeOfDay(hour: 6, minute: 33),
        icon: Icons.wb_twilight_rounded,
      ),
      PrayerTiming(
        type: PrayerType.dhuhr,
        nameArabic: 'الظهر',
        nameEnglish: 'Dhuhr',
        time: const TimeOfDay(hour: 12, minute: 54),
        icon: Icons.wb_sunny_rounded,
      ),
      PrayerTiming(
        type: PrayerType.asr,
        nameArabic: 'العصر',
        nameEnglish: 'Asr',
        time: const TimeOfDay(hour: 16, minute: 28),
        icon: Icons.cloud_queue_rounded,
      ),
      PrayerTiming(
        type: PrayerType.maghrib,
        nameArabic: 'المغرب',
        nameEnglish: 'Maghrib',
        time: const TimeOfDay(hour: 19, minute: 15),
        icon: Icons.wb_sunny_outlined,
      ),
      PrayerTiming(
        type: PrayerType.isha,
        nameArabic: 'العشاء',
        nameEnglish: 'Isha',
        time: const TimeOfDay(hour: 20, minute: 35),
        icon: Icons.nightlight_round,
      ),
    ];
    _updateRealtimePrayerState();
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRealtimePrayerState();
      }
    });
  }

  void _updateRealtimePrayerState() {
    if (_allPrayers.isEmpty) return;

    final now = DateTime.now();
    PrayerTiming? next;
    DateTime? nextDateTime;

    for (final prayer in _allPrayers) {
      final prayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        prayer.time.hour,
        prayer.time.minute,
      );

      if (prayerDateTime.isAfter(now)) {
        if (nextDateTime == null || prayerDateTime.isBefore(nextDateTime)) {
          nextDateTime = prayerDateTime;
          next = prayer;
        }
      }
    }

    // If all prayers today have passed (after Isha), next prayer is tomorrow's Fajr
    if (next == null || nextDateTime == null) {
      final fajrPrayer = _allPrayers.firstWhere(
        (p) => p.type == PrayerType.fajr,
        orElse: () => _allPrayers.first,
      );
      next = fajrPrayer;
      nextDateTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        fajrPrayer.time.hour,
        fajrPrayer.time.minute,
      );
    }

    final diff = nextDateTime.difference(now);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final formattedCountdown = '$hours:$minutes:$seconds';

    setState(() {
      _nextPrayer = next;
      _countdown = formattedCountdown;
    });
  }

  void _onServiceUpdate() async {
    if (mounted) {
      final allPrayers = await _prayerService.getPrayerTimingsForDate(DateTime.now());
      if (mounted && allPrayers.isNotEmpty) {
        setState(() {
          _allPrayers = allPrayers;
        });
        _updateRealtimePrayerState();
      }
    }
  }

  Future<void> _loadPrayerData() async {
    try {
      final allPrayers = await _prayerService.getPrayerTimingsForDate(DateTime.now());
      if (mounted && allPrayers.isNotEmpty) {
        setState(() {
          _allPrayers = allPrayers;
        });
        _updateRealtimePrayerState();
      }
    } catch (e) {
      debugPrint('Error loading prayer data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacingL,
                    DesignSystem.spacingM,
                    DesignSystem.spacingL,
                    DesignSystem.spacingS,
                  ),
                  child: _buildTopBar(context),
                ),
              ),

              // 1.5 Dynamic Spiritual Companion (« رفيق يفهم وقتك »)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingXS,
                  ),
                  child: _buildDynamicSpiritualCompanion(context),
                ),
              ),

              // 2. Main Hero Card with Daytime Mosque Art & Ayah
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildHeroCard(context),
                ),
              ),

              // 2.5 Daily Ayah Spotlight Card (آية اليوم وتدبر)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingXS,
                  ),
                  child: _buildDailyAyahCard(context),
                ),
              ),

              // 3. Prayer Times Spotlight Card (Next Prayer: الظهر 12:54 م)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildPrayerSpotlightCard(context),
                ),
              ),

              // 4. Quick Access Section (الوصول السريع with celestial diagonal light beam)
              SliverToBoxAdapter(
                child: CustomPaint(
                  painter: DiagonalLightBeamPainter(
                    beamColor: const Color(0xFFFFD56B),
                    opacity: DesignSystem.isLightMode ? 0.05 : 0.14,
                  ),
                  child: const SectionHeader(
                    title: 'الوصول السريع',
                    subtitle: 'تصفح الخدمات والعبادات اليومية',
                    icon: Icons.grid_view_rounded,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingXS,
                  ),
                  child: _buildQuickActionsGrid(context),
                ),
              ),

              // 5. Selected Recitations (تلاوات مختارة)
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'تلاوات مختارة',
                  subtitle: 'استمع لأعذب التلاوات القرآنية بأصوات كبار القراء',
                  icon: Icons.headphones_rounded,
                  actionText: 'عرض الكل',
                  onActionTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AudioScreen()),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: _buildSelectedRecitersSection(context),
              ),

              // 6. Quran Progress Tracking (متابعة الورد القرآني)
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'متابعة الورد القرآني',
                  subtitle: 'تابع من حيث توقفت في تلاوتك',
                  icon: Icons.bookmark_added_rounded,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingXS,
                  ),
                  child: _buildContinueReadingCard(context),
                ),
              ),

              // Developer Credits Badge
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingM,
                  ),
                  child: Center(
                    child: DeveloperCreditsBadge(),
                  ),
                ),
              ),

              // Bottom Spacing for floating navigation
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 1. TOP HEADER & SEARCH ====================
  Widget _buildTopBar(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side (in RTL): Location Pill, Theme Toggle, Notification Bell
            Row(
              children: [
                // Circular Notification Bell Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF131D2A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: isLight ? const Color(0xFF1C1917) : Colors.white,
                          size: 19,
                        ),
                        Positioned(
                          top: 8,
                          right: 9,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD56B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Theme Mode Pill (ليلي / نهاري + ضغطة مطولة لتخصيص الثيم)
                InkWell(
                  onTap: () {
                    ThemeService.instance.toggleDarkLight();
                  },
                  onLongPress: () {
                    ThemeSelectionModal.show(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF131D2A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          DesignSystem.isLightMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: const Color(0xFFFFD56B),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ThemeService.instance.isAutoMode
                              ? (DesignSystem.isLightMode ? 'نهاري ☀️' : 'ليلي 🌙')
                              : (DesignSystem.isLightMode ? 'نهاري' : 'ليلي'),
                          style: TextStyle(
                            color: isLight ? const Color(0xFF1C1917) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Location Pill ("📍 مكة المكرمة ▾")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF131D2A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFFFD56B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'مكة المكرمة',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF1C1917) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFFFD56B),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Right Side (in RTL): Brand Logo & Typography (Rafeeq / رفيق / وجهتك في رحلتك الإيمانية)
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rafeeq',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFFCBD5E1),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'رفيق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xFFFFD56B),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'وجهتك في رحلتك الإيمانية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2010), Color(0xFF130E07)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFD56B).withValues(alpha: 0.6),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.asset(
                      isLight ? 'assets/out logo app/lightapp.png' : 'assets/out logo app/darkapp.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.mosque_rounded,
                        color: Color(0xFFFFD56B),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Glass Floating Search Bar (Sunlit Alabaster in Light Mode)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF101924).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFFFD56B),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'ابحث في القرآن الكريم ..',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF78716C) : const Color(0xFF8E9BAE),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 1.5 DYNAMIC SPIRITUAL COMPANION (« رفيق يفهم وقتك ») ====================
  SpiritualTimeContext _getActiveTimeContext() {
    if (_previewTimeContext != null) return _previewTimeContext!;
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= 270 && minutes < 690) {
      // 04:30 AM to 11:30 AM -> الصباح
      return SpiritualTimeContext.morning;
    } else if (minutes >= 690 && minutes < 990) {
      // 11:30 AM to 04:30 PM -> وقت الصلاة
      return SpiritualTimeContext.prayerFocus;
    } else if (minutes >= 990 && minutes < 1290) {
      // 04:30 PM to 09:30 PM -> المساء
      return SpiritualTimeContext.evening;
    } else {
      // 09:30 PM to 04:30 AM -> قبل النوم
      return SpiritualTimeContext.sleep;
    }
  }

  Widget _buildDynamicSpiritualCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final activeContext = _getActiveTimeContext();
    final isAuto = _previewTimeContext == null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.45 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          // 3D Ambient Shadow
          BoxShadow(
            color: isLight
                ? const Color(0xFF8C7355).withValues(alpha: 0.15)
                : const Color(0xFF000000).withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (!isLight)
            BoxShadow(
              color: const Color(0xFFFFD56B).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Layer 1: Cinematic Mosque Courtyard Scenery (Daylight in Light Mode / Sunset Night in Dark Mode)
            Positioned.fill(
              child: Image.asset(
                isLight ? 'assets/daylight_mosque_bg.jpg' : 'assets/home_hero_mosque.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1E2E), Color(0xFF14273A), Color(0xFF0A131F)],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Atmospheric Gradient & Frosted Marble Scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? [
                            const Color(0xFFFFFDF8).withValues(alpha: 0.90),
                            const Color(0xFFFAF5EC).withValues(alpha: 0.85),
                            const Color(0xFFF2EADC).withValues(alpha: 0.92),
                          ]
                        : [
                            const Color(0xFF080E17).withValues(alpha: 0.90),
                            const Color(0xFF0E1A29).withValues(alpha: 0.85),
                            const Color(0xFF060B12).withValues(alpha: 0.94),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Layer 3: Ambient Golden Dust Particles
            const Positioned.fill(
              child: IgnorePointer(
                child: FloatingParticles(
                  numberOfParticles: 10,
                  particleColor: Color(0xFFFFD56B),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row with Metallic Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Companion Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          gradient: isLight
                              ? const LinearGradient(
                                  colors: [Color(0xFFFFF9EC), Color(0xFFFFECC8)],
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF281E0E), Color(0xFF161007)],
                                ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulsingHalo(
                              haloColor: const Color(0xFFFFD56B),
                              borderRadius: 10,
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD56B), size: 13),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '« رفيق يفهم وقتك »',
                              style: TextStyle(
                                color: Color(0xFFFFD56B),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Live Indicator / Reset to Live
                      if (!isAuto)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _previewTimeContext = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLight ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'استعادة التلقائي',
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_filled_rounded, color: Color(0xFF34D399), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'مباشر حسب الوقت',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Segmented Compact Time Selector Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildTimeTab(
                          type: SpiritualTimeContext.morning,
                          label: '🌅 الصباح',
                          isSelected: activeContext == SpiritualTimeContext.morning,
                        ),
                        const SizedBox(width: 6),
                        _buildTimeTab(
                          type: SpiritualTimeContext.prayerFocus,
                          label: '☀️ وقت الصلاة',
                          isSelected: activeContext == SpiritualTimeContext.prayerFocus,
                        ),
                        const SizedBox(width: 6),
                        _buildTimeTab(
                          type: SpiritualTimeContext.evening,
                          label: '🌙 المساء',
                          isSelected: activeContext == SpiritualTimeContext.evening,
                        ),
                        const SizedBox(width: 6),
                        _buildTimeTab(
                          type: SpiritualTimeContext.sleep,
                          label: '🌌 قبل النوم',
                          isSelected: activeContext == SpiritualTimeContext.sleep,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 11),

                  // Dynamic Context Body
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(activeContext),
                      child: _buildContextBody(context, activeContext),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTab({
    required SpiritualTimeContext type,
    required String label,
    required bool isSelected,
  }) {
    final isLight = DesignSystem.isLightMode;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_previewTimeContext == type) {
            _previewTimeContext = null;
          } else {
            _previewTimeContext = type;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLight
                      ? const [
                          Color(0xFFFFDF7D),
                          Color(0xFFE5A83B),
                          Color(0xFFB8860B),
                        ]
                      : const [
                          Color(0xFFFFE58F),
                          Color(0xFFE5B54F),
                          Color(0xFFB8860B),
                        ],
                )
              : null,
          color: isSelected
              ? null
              : (isLight ? const Color(0xFFFFFDF8) : Colors.white.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFF2B2)
                : (isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.1)),
            width: isSelected ? 1.3 : 0.9,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC89B3C).withValues(alpha: isLight ? 0.35 : 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF1A1002)
                : (isLight ? const Color(0xFF1C1917) : const Color(0xFFCBD5E1)),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildContextBody(BuildContext context, SpiritualTimeContext timeCtx) {
    switch (timeCtx) {
      case SpiritualTimeContext.morning:
        return _buildMorningCompanion(context);
      case SpiritualTimeContext.prayerFocus:
        return _buildPrayerFocusCompanion(context);
      case SpiritualTimeContext.evening:
        return _buildEveningCompanion(context);
      case SpiritualTimeContext.sleep:
        return _buildSleepCompanion(context);
    }
  }

  Widget _buildMorningCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final stopMark = _quranStorage.readingStopMark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'صباح مبارك ياصديقي 🌅',
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              'ابدأ يومك بنور الذكر والقرآن',
              style: TextStyle(
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFF1E2838),
                borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                title: 'أذكار الصباح',
                subtitle: '25 ذكراً للتحصين والبركة',
                btnText: 'قراءة الأذكار ←',
                imageAsset: 'assets/images/3d/hisn_muslim_3d.jpg',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.morning,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF38BDF8),
                bgColor: const Color(0xFF112538),
                borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                title: stopMark != null ? 'ورد: سورة ${stopMark.surahName}' : 'وردك القرآني',
                subtitle: stopMark != null ? 'الآية: ${stopMark.ayahNumber}' : 'أتمم وردك اليوم',
                btnText: 'متابعة الورد ←',
                imageAsset: 'assets/images/3d/quran_sphere_3d.jpg',
                onTap: () {
                  if (stopMark != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahViewerScreen(
                          surahNumber: stopMark.surahNumber,
                          surahName: stopMark.surahName,
                          initialAyah: stopMark.ayahNumber,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrayerFocusCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final nextPrayerTitle = _nextPrayer?.nameArabic ?? 'الصلاة';
    final nextPrayerTime = _nextPrayer?.formattedTimeArabic ?? '12:00 م';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Luxury 3D Prayer Focus Main Card
        InteractiveMotionCard(
          borderRadius: 16,
          borderColor: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
          glowColor: const Color(0xFFD4AF57).withValues(alpha: 0.25),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: isLight
                  ? const LinearGradient(
                      colors: [Color(0xFFFFFDF8), Color(0xFFF7F1E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF152233), Color(0xFF0D1724), Color(0xFF09101A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.45),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 3D Luxury Prayer Clock 3D Render
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF57).withValues(alpha: isLight ? 0.25 : 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.asset(
                      'assets/images/3d/prayer_focus_3d.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFFFD56B),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'الصلاة القادمة: ',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF78716C) : const Color(0xFFA5B4C7),
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            nextPrayerTitle,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFE58F),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '($nextPrayerTime)',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF78716C) : Colors.white70,
                              fontSize: 10.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'متبقي على الأذان: ',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                              fontSize: 10.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            _countdown,
                            style: TextStyle(
                              color: isLight ? const Color(0xFFB45309) : const Color(0xFFFFD56B),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLight
                          ? const [Color(0xFFFFDF7D), Color(0xFFE5A83B)]
                          : const [Color(0xFFFFE58F), Color(0xFFD4AF57)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'المواقيت ←',
                    style: TextStyle(
                      color: Color(0xFF1A1002),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 3 Compact Quick Tools
        Row(
          children: [
            Expanded(
              child: _buildMiniToolTile(
                icon: Icons.explore_rounded,
                title: 'اتجاه القبلة',
                imageAsset: 'assets/images/3d/kaaba_qibla_3d.jpg',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildMiniToolTile(
                icon: Icons.mosque_rounded,
                title: 'أذكار الصلاة',
                imageAsset: 'assets/images/3d/hisn_muslim_3d.jpg',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.afterPrayer,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildMiniToolTile(
                icon: Icons.notifications_active_rounded,
                title: 'تنبيه الأذان',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEveningCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final stopMark = _quranStorage.readingStopMark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مساء مبارك ياصديقي 🌙',
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              'حصّن نفسك بذكر الله',
              style: TextStyle(
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF60A5FA),
                bgColor: const Color(0xFF121B2B),
                borderColor: const Color(0xFF60A5FA).withValues(alpha: 0.45),
                title: 'أذكار المساء',
                subtitle: '24 ذكراً لطمأنينة النفس',
                btnText: 'قراءة الأذكار ←',
                imageAsset: 'assets/images/3d/sleep_azkar_3d.jpg',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.evening,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF38BDF8),
                bgColor: const Color(0xFF0F2236),
                borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                title: stopMark != null ? 'ورد: سورة ${stopMark.surahName}' : 'وردك القرآني',
                subtitle: stopMark != null ? 'الآية: ${stopMark.ayahNumber}' : 'أتمم وردك اليوم',
                btnText: 'متابعة الورد ←',
                imageAsset: 'assets/images/3d/quran_sphere_3d.jpg',
                onTap: () {
                  if (stopMark != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahViewerScreen(
                          surahNumber: stopMark.surahNumber,
                          surahName: stopMark.surahName,
                          initialAyah: stopMark.ayahNumber,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSleepCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'طابت ليلتك بذكر الله 🌌',
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              'السكينة والنور قبل المنام',
              style: TextStyle(
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Dual Compact Luxury Cards with 3D Imagery: Surah Al-Mulk + Sleep Azkar
        Row(
          children: [
            // Right: Surah Al-Mulk (المانعة من عذاب القبر) with 3D Quran image
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFFFFD56B),
                bgColor: const Color(0xFF1C192E),
                borderColor: const Color(0xFFFFD56B).withValues(alpha: 0.55),
                title: 'سورة الملك',
                subtitle: '٣٠ آية مانعة من العذاب',
                btnText: 'قراءة الملك ←',
                imageAsset: 'assets/images/3d/surah_mulk_3d.jpg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SurahViewerScreen(
                        surahNumber: 67,
                        surahName: 'الملك',
                        initialAyah: 1,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            // Left: أذكار النوم والتحصين with 3D Misbaha & Lantern image
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.bedtime_rounded,
                iconColor: const Color(0xFF818CF8),
                bgColor: const Color(0xFF12162E),
                borderColor: const Color(0xFF818CF8).withValues(alpha: 0.45),
                title: 'أذكار النوم',
                subtitle: 'لطمأنينة وراحة المنام',
                btnText: 'قراءة الأذكار ←',
                imageAsset: 'assets/images/3d/sleep_azkar_3d.jpg',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.sleep,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionPillCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String btnText,
    String? imageAsset,
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return InteractiveMotionCard(
      borderRadius: 16,
      borderColor: isLight ? const Color(0xFFE5D4B3) : borderColor,
      glowColor: iconColor.withValues(alpha: 0.25),
      onTap: onTap,
      child: Container(
        height: 122,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFF8C7355).withValues(alpha: 0.12)
                  : iconColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Background 3D Model Artwork if provided
              if (imageAsset != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: isLight ? 0.35 : 0.25,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // Gradient Overlay for Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLight
                          ? [
                              const Color(0xFFFFFDF8).withValues(alpha: 0.95),
                              const Color(0xFFFAF5EB).withValues(alpha: 0.85),
                              const Color(0xFFF3EADB).withValues(alpha: 0.95),
                            ]
                          : [
                              bgColor.withValues(alpha: 0.92),
                              bgColor.withValues(alpha: 0.60),
                              bgColor.withValues(alpha: 0.92),
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF1C1917) : Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFFFD56B).withValues(alpha: 0.25)
                                : iconColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFC89B3C).withValues(alpha: 0.6)
                                  : iconColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isLight ? const Color(0xFF854D0E) : iconColor,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFF854D0E) : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLight ? const Color(0xFFB45309) : iconColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        btnText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniToolTile({
    required IconData icon,
    required String title,
    String? imageAsset,
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return InteractiveMotionCard(
      borderRadius: 12,
      borderColor: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (imageAsset != null)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.5), width: 0.8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(icon, color: const Color(0xFFFFD56B), size: 18),
                  ),
                ),
              )
            else
              Icon(icon, color: isLight ? const Color(0xFFB45309) : const Color(0xFFFFD56B), size: 18),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 2. MAIN HERO CARD ====================
  Widget _buildHeroCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return ShimmerSweep(
      duration: const Duration(milliseconds: 2800),
      pauseDuration: const Duration(milliseconds: 3500),
      shimmerColor: const Color(0xFFFFD56B),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFDF8),
                    Color(0xFFFAF5EB),
                    Color(0xFFF3EADB),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF182234), // Luminous midnight
                    Color(0xFF0F1522), // Deep charcoal
                    Color(0xFF090D15),
                  ],
                ),
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFF8C7355).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            if (!isLight)
              BoxShadow(
                color: const Color(0xFFFFD56B).withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Mosque Artwork (Daylight in Light Mode / Sunset in Dark Mode)
              Positioned.fill(
                child: Image.asset(
                  isLight ? 'assets/daylight_mosque_bg.jpg' : 'assets/home_hero_mosque.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),

              // Deep Royal Gradient Overlay to ensure crisp readability for text
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: isLight
                          ? [
                              const Color(0xFFFFFDF8).withValues(alpha: 0.96),
                              const Color(0xFFFAF5EB).withValues(alpha: 0.85),
                              const Color(0xFFFAF5EB).withValues(alpha: 0.25),
                            ]
                          : [
                              const Color(0xFF07090E).withValues(alpha: 0.96),
                              const Color(0xFF07090E).withValues(alpha: 0.85),
                              const Color(0xFF07090E).withValues(alpha: 0.30),
                            ],
                    ),
                  ),
                ),
              ),

              // Architectural pointed Islamic arch dual border
              Positioned.fill(
                child: CustomPaint(
                  painter: IslamicArchBorderPainter(
                    primaryColor: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                    secondaryColor: const Color(0xFFC89B3C),
                  ),
                ),
              ),

              // Top-left corner radiant sparkle glint
              const Positioned(
                top: 8,
                left: 12,
                child: StarGlint(size: 20),
              ),

              // Right Content: Verse & Welcome Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // "كلمة اليوم ★" Pill with corner sparkle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF131A26),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.25),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StarGlint(size: 14),
                          SizedBox(width: 4),
                          Text(
                            'كلمة اليوم',
                            style: TextStyle(
                              color: Color(0xFFC89B3C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Main Quranic Verse with layered 3D golden bloom
                    Text(
                      'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: isLight
                                ? const Color(0xFFC89B3C).withValues(alpha: 0.45)
                                : const Color(0xFFFFD56B).withValues(alpha: 0.75),
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black,
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'مرحباً بك في رفيق — رفيقك الإيماني للقرآن، الأذكار، ومواقيت الصلاة بدقة وطمأنينة.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFFCBD5E1),
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 2.5 DAILY AYAH SECTION ====================
  Widget _buildDailyAyahCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 22,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SurahViewerScreen(
                  surahNumber: 2,
                  surahName: 'البقرة',
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Tag + Share / Bookmark icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1B2332),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD56B).withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'آية اليوم وتدبّر',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 20,
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF8E9BAE),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF8E9BAE),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Quranic Ayah Text in Amiri calligraphy with luminous warmth
              Text(
                '﴿ وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ ﴾',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                  color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.2 : 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Ayah Surah Ref + Meaning / Tadabbur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سورة البقرة • الآية 186',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLight ? const Color(0xFF854D0E) : const Color(0xFF38BDF8),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'قراءة وتفسير الآية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF78716C) : const Color(0xFF8E9BAE),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Corner Star Sparkle Glint
        const Positioned(
          top: -6,
          left: 12,
          child: StarGlint(size: 20),
        ),
      ],
    );
  }

  // ==================== 3. PRAYER TIMES SECTION (ROYAL 3D SPOTLIGHT) ====================
  Widget _buildPrayerSpotlightCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final nextPrayerTitle = _nextPrayer?.nameArabic ?? 'الظهر';
    final nextPrayerTime = _nextPrayer?.formattedTimeArabic ?? '12:54 م';

    return InteractiveMotionCard(
      borderRadius: 26,
      borderColor: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.45),
      glowColor: const Color(0xFFFFD56B).withValues(alpha: 0.25),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFDF8),
                    Color(0xFFFAF5EB),
                    Color(0xFFF3EADB),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E2B42),
                    Color(0xFF121B2A),
                    Color(0xFF090E17),
                  ],
                ),
          border: Border.all(
            color: isLight
                ? const Color(0xFFE5D4B3)
                : const Color(0xFFFFD56B).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFF8C7355).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.12 : 0.22),
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              // Atmospheric Floating Golden Dust Particles (60 FPS RepaintBoundary)
              const Positioned.fill(
                child: IgnorePointer(
                  child: FloatingParticles(
                    numberOfParticles: 12,
                    particleColor: Color(0xFFFFD56B),
                  ),
                ),
              ),

              // Architectural pointed Islamic arch dual border
              Positioned.fill(
                child: CustomPaint(
                  painter: IslamicArchBorderPainter(
                    primaryColor: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                    secondaryColor: const Color(0xFFC89B3C),
                  ),
                ),
              ),

              // Corner Shimmering Star Glints
              const Positioned(
                top: 14,
                left: 18,
                child: StarGlint(size: 16, color: Color(0xFFFFD56B)),
              ),
              const Positioned(
                top: 16,
                right: 22,
                child: StarGlint(size: 14, color: Color(0xFFFFF2B2)),
              ),

              // Main Card Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  children: [
                    // Top Next Prayer Presentation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: 3D Countdown Box & Pill
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3D Monospace Live Countdown Dial
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLight
                                      ? [const Color(0xFF854D0E), const Color(0xFF713F12)]
                                      : [const Color(0xFF1C2C45), const Color(0xFF0F1A2A)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isLight
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFFFD56B).withValues(alpha: 0.6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD56B).withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF10B981),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _countdown,
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      color: Color(0xFFFFD56B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.hourglass_top_rounded,
                                  color: isLight ? const Color(0xFF854D0E) : const Color(0xFFC89B3C),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'متبقي على الأذان',
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF78716C) : const Color(0xFFCBD5E1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Right: 3D Calligraphy & Glowing Mosque Medallion
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isLight
                                        ? const Color(0xFF854D0E).withValues(alpha: 0.12)
                                        : const Color(0xFFFFD56B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isLight
                                          ? const Color(0xFFC89B3C).withValues(alpha: 0.5)
                                          : const Color(0xFFFFD56B).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'الصلاة القادمة',
                                        style: TextStyle(
                                          color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: isLight
                                        ? const [
                                            Color(0xFF854D0E),
                                            Color(0xFFB45309),
                                            Color(0xFFD97706),
                                            Color(0xFF92400E),
                                          ]
                                        : const [
                                            Color(0xFFFFF7D6),
                                            Color(0xFFFFD56B),
                                            Color(0xFFE5B54F),
                                            Color(0xFFC89B3C),
                                          ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ).createShader(bounds),
                                  child: Text(
                                    nextPrayerTitle,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: isLight ? const Color(0xFF854D0E) : Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.3 : 0.5),
                                          blurRadius: 16,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  'عند $nextPrayerTime',
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF78716C) : const Color(0xFFE2E8F0),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // 3D Glowing Mosque Medallion with PulsingHalo
                            PulsingHalo(
                              haloColor: const Color(0xFFFFD56B),
                              borderRadius: 26,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE082),
                                      Color(0xFFC89B3C),
                                      Color(0xFF8D6210),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD56B).withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFFFF7D6),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mosque_rounded,
                                  color: Color(0xFF0F172A),
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 6 Prayer Cards 3D Row (الفجر، الشروق، الظهر، العصر، المغرب، العشاء)
                    if (_allPrayers.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _allPrayers.map((prayer) {
                          final isActive = _nextPrayer != null && _nextPrayer!.type == prayer.type;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1.5),
                              child: _buildPrayerCard(
                                prayer.nameArabic,
                                prayer.formattedTimeArabic,
                                prayer.icon,
                                isActive,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPrayerCard('الفجر', '5:03 ص', Icons.wb_twilight_rounded, false),
                          _buildPrayerCard('الشروق', '6:33 ص', Icons.wb_sunny_outlined, false),
                          _buildPrayerCard('الظهر', '12:54 م', Icons.wb_sunny_rounded, true),
                          _buildPrayerCard('العصر', '4:28 م', Icons.wb_sunny_outlined, false),
                          _buildPrayerCard('المغرب', '7:15 م', Icons.wb_twilight_rounded, false),
                          _buildPrayerCard('العشاء', '8:35 م', Icons.nightlight_round, false),
                        ],
                      ),

                    const SizedBox(height: 14),

                    // Bottom Spiritual Quote & Navigation Hint
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFFFFDF8)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLight
                              ? const Color(0xFFE5D4B3)
                              : const Color(0xFFFFD56B).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  color: isLight ? const Color(0xFF1C1917) : const Color(0xFFE2E8F0),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'عرض الجدول',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                                size: 10,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String name, String time, IconData icon, bool isActive) {
    final isLight = DesignSystem.isLightMode;

    if (isActive) {
      // 3D Elevated Active Prayer Tile with Pulsing Golden Aura Halo & Zero Truncation
      return PulsingHalo(
        isActive: true,
        haloColor: const Color(0xFFFFD56B),
        borderRadius: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? const [
                      Color(0xFFFFDF7D),
                      Color(0xFFE5A83B),
                      Color(0xFFB8860B),
                    ]
                  : const [
                      Color(0xFF283D5E),
                      Color(0xFF16243A),
                      Color(0xFF0D1726),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight ? const Color(0xFFFFF2B2) : const Color(0xFFFFD56B),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? const Color(0xFFC89B3C).withValues(alpha: 0.4)
                    : const Color(0xFFFFD56B).withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFF1A1002).withValues(alpha: 0.12)
                      : const Color(0xFFFFD56B).withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isLight ? const Color(0xFF1A1002) : const Color(0xFFFFD56B),
                  size: 15,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  name,
                  softWrap: false,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A1002) : const Color(0xFFFFD56B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  time,
                  softWrap: false,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF2E1C03) : Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3D Inactive Prayer Card: Elevated Glass Tile with FittedBox Scaling
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFFFFDF8)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE5D4B3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF8C7355).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isLight ? const Color(0xFF854D0E) : const Color(0xFF94A3B8),
            size: 14,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              name,
              softWrap: false,
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : const Color(0xFFF1F5F9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              time,
              softWrap: false,
              style: TextStyle(
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 4. QUICK ACCESS GRID (3D PHOTOREALISTIC MODELS) ====================
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      children: [
        // Card 1: القرآن الكريم (114 سورة) -> 3D Quran Leather & Gold
        Expanded(
          child: _buildQuickActionCard(
            title: 'القرآن الكريم',
            subtitle: '114 سورة',
            icon: Icons.menu_book_rounded,
            imageAsset: 'assets/images/3d/quran_3d.jpg',
            accentColor: const Color(0xFFC89B3C),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen())),
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: حصن المسلم (أذكار وأدعية) -> 3D Glowing Book
        Expanded(
          child: _buildQuickActionCard(
            title: 'حصن المسلم',
            subtitle: 'أذكار وأدعية',
            icon: Icons.auto_awesome_rounded,
            imageAsset: 'assets/images/3d/hisn_muslim_3d.jpg',
            accentColor: const Color(0xFF0F6B78),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen())),
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: اتجاه القبلة (بوصلة دقيقة) -> 3D Antique Compass
        Expanded(
          child: _buildQuickActionCard(
            title: 'اتجاه القبلة',
            subtitle: 'بوصلة دقيقة',
            icon: Icons.explore_rounded,
            imageAsset: 'assets/images/3d/qibla_compass_3d.jpg',
            accentColor: const Color(0xFF102A43),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
        ),
        const SizedBox(width: 8),

        // Card 4: إذاعة القرآن (بث مباشر) -> 3D Classic Radio
        Expanded(
          child: _buildQuickActionCard(
            title: 'إذاعة القرآن',
            subtitle: 'بث مباشر',
            icon: Icons.radio_rounded,
            imageAsset: 'assets/images/3d/radio_3d.jpg',
            accentColor: const Color(0xFF6956B8),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RadioScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String imageAsset,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return InteractiveMotionCard(
      borderRadius: 24,
      borderColor: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.45 : 0.35),
      glowColor: const Color(0xFFFFD56B).withValues(alpha: 0.25),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        decoration: BoxDecoration(
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFDF8),
                    Color(0xFFF7F1E6),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF162232),
                    Color(0xFF0F1824),
                  ],
                ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: isLight
                ? const Color(0xFFE5D4B3)
                : const Color(0xFFFFD56B).withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            if (!isLight)
              BoxShadow(
                color: const Color(0xFFFFD56B).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D Object Volumetric Floating Pedestal
            Stack(
              alignment: Alignment.center,
              children: [
                // Floor Shadow under 3D Object
                Positioned(
                  bottom: -2,
                  child: Container(
                    width: 44,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // 3D Model Artifact with Double Specular Ring
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD56B).withValues(alpha: 0.7),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD56B).withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        color: const Color(0xFFFFD56B),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                title,
                textAlign: TextAlign.center,
                softWrap: false,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1C1917) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                softWrap: false,
                style: TextStyle(
                  color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const SizedBox(height: 7),
            // Bottom Action Arrow Circle Button (Amber in Light mode / Gold in Dark mode)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLight ? const Color(0xFFB45309) : const Color(0xFFFFD56B).withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 5. QURAN READING PROGRESS ====================
  Widget _buildContinueReadingCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final stopMark = _quranStorage.readingStopMark;
    final progress = _quranStorage.readingProgress;
    final surahNum = stopMark?.surahNumber ?? progress.surahNumber;
    final surahName = stopMark?.surahName ?? progress.surahName;
    final ayahNum = stopMark?.ayahNumber ?? progress.ayahNumber;
    final percent = (progress.progress * 100).clamp(1, 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahViewerScreen(
              surahNumber: surahNum,
              surahName: surahName,
              initialAyah: ayahNum,
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Gold Quran / Bookmark Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1E2738),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : const Color(0xFFFFD56B).withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.bookmark_rounded,
              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Details & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سورة $surahName',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1C1917) : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stopMark != null
                      ? 'موضع التوقف: الآية $ayahNum • الجزء ${progress.juz}'
                      : 'الآية $ayahNum • الجزء ${progress.juz}',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                // Thin Elegant Progress Bar with golden shimmer glow
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.progress.clamp(0.01, 1.0),
                    minHeight: 4,
                    backgroundColor: isLight ? const Color(0xFFE5D4B3) : const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6. SELECTED RECITERS HORIZONTAL LIST ====================
  Widget _buildSelectedRecitersSection(BuildContext context) {
    final audioService = AudioQuranService();
    // Choose prominent reciters
    final famousReciterIds = ['afasy', 'abdulbaset_murattal', 'minshawi_murattal', 'hussary_murattal', 'ghamdi', 'ajmy', 'dosari'];
    final selectedReciters = RecitersData.reciters.where((r) => famousReciterIds.contains(r.id)).toList();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: selectedReciters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final reciter = selectedReciters[index];
          final isCurrent = audioService.currentReciter.id == reciter.id;

          return _buildReciterMiniCard(
            reciter: reciter,
            isCurrent: isCurrent,
            onTap: () {
              audioService.selectReciter(reciter, autoPlay: true);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AudioScreen()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReciterMiniCard({
    required dynamic reciter,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return InteractiveMotionCard(
      borderRadius: 18,
      borderColor: isCurrent
          ? (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))
          : (isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.2)),
      glowColor: const Color(0xFFFFD56B).withValues(alpha: 0.25),
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF111A26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCurrent
                ? (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))
                : (isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.2)),
            width: isCurrent ? 1.5 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent
                          ? (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))
                          : (isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B).withValues(alpha: 0.6)),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCurrent
                            ? const Color(0xFFFFD56B).withValues(alpha: 0.4)
                            : const Color(0xFFC89B3C).withValues(alpha: 0.15),
                        blurRadius: isCurrent ? 12 : 8,
                        spreadRadius: isCurrent ? 1.0 : 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: reciter.photoUrl.startsWith('assets/')
                        ? Image.asset(
                            reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                              size: 26,
                            ),
                          )
                        : Image.network(
                            reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                              size: 26,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))
                          : (isLight ? const Color(0xFFFFFDF8) : const Color(0xFF101924)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                        width: 1.2,
                      ),
                    ),
                    child: isCurrent
                        ? SoundWaveVisualizer(
                            isPlaying: true,
                            barCount: 3,
                            maxHeight: 8,
                            minHeight: 2,
                            barWidth: 1.5,
                            spacing: 1.5,
                            activeColor: isLight ? Colors.white : const Color(0xFF07090E),
                          )
                        : Icon(
                            Icons.play_arrow_rounded,
                            color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                            size: 12,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reciter.nameArabic,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reciter.style,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                fontSize: 9.5,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
