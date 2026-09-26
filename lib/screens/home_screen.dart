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
import 'notification_settings_screen.dart';
import 'prayer_times_screen.dart';
import 'qibla_screen.dart';
import 'radio_screen.dart';
import 'surah_viewer_screen.dart';
import '../widgets/developer_credits_badge.dart';

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

  // ==================== 1. TOP HEADER ====================
  Widget _buildTopBar(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Side: Notification, Theme Switcher & Location Selector (RTL friendly)
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
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDCE3EC)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF102A43).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF102A43),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Prominent Theme Mode Toggle Pill (Light / Dark Switcher)
            InkWell(
              onTap: () {
                setState(() {
                  DesignSystem.isLightMode = !DesignSystem.isLightMode;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF102A43),
                    content: Row(
                      children: [
                        Icon(
                          DesignSystem.isLightMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: const Color(0xFFC89B3C),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DesignSystem.isLightMode
                              ? 'تم تفعيل الوضع النهاري المشرق (Light Mode) ☀️'
                              : 'تم تفعيل الوضع الليلي الفاخر (Dark Mode) 🌙',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: DesignSystem.isLightMode
                        ? [const Color(0xFFFFF7E6), const Color(0xFFFFFFFF)]
                        : [const Color(0xFF102A43), const Color(0xFF0D1B2A)],
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  border: Border.all(
                    color: const Color(0xFFC89B3C).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC89B3C).withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      DesignSystem.isLightMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: const Color(0xFFC89B3C),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DesignSystem.isLightMode ? 'نهاري' : 'ليلي',
                      style: TextStyle(
                        color: DesignSystem.isLightMode ? const Color(0xFF172033) : const Color(0xFFE8D29A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Location Selector Pill ("مكة المكرمة")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                border: Border.all(color: const Color(0xFFDCE3EC)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF102A43).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF102A43),
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'مكة المكرمة',
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF102A43),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Right Side: Brand Logo & Typography (Rafeeq / رفيقك في رحلتك الإيمانية)
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rafeeq',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF102A43) : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'رفيقك في رحلتك الإيمانية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: const Color(0xFFC89B3C),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  isLight ? 'assets/out logo app/lightapp.png' : 'assets/out logo app/darkapp.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mosque,
                    color: Color(0xFFC89B3C),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(24),
        gradient: isLight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7F9FC),
                  Color(0xFFEEF3F8),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1E2D),
                  Color(0xFF13283B),
                  Color(0xFF091420),
                ],
              ),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: isLight ? 0.35 : 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF102A43).withValues(alpha: 0.06)
                : const Color(0xFF050B11).withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Companion Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFC89B3C), size: 14),
                    SizedBox(width: 5),
                    Text(
                      '« رفيق يفهم وقتك »',
                      style: TextStyle(
                        color: Color(0xFFC89B3C),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled_rounded, color: Color(0xFF10B981), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'مباشر حسب الوقت',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Context Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTimeTab(
                  type: SpiritualTimeContext.morning,
                  label: '🌅 الصبح',
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

          const SizedBox(height: 14),

          // Dynamic Body
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(activeContext),
              child: _buildContextBody(context, activeContext),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC89B3C)
              : (isLight ? const Color(0xFFEDF2F7) : Colors.white.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE5B54F)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF0B1724)
                : (isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
      children: [
        Text(
          'صباح مبارك بذكر الله 🌅',
          style: TextStyle(
            color: isLight ? const Color(0xFF102A43) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'ابدأ يومك بنور الذكر والتحصين وقراءة وردك القرآني اليومي',
          style: TextStyle(
            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                title: 'أذكار الصباح',
                subtitle: '25 ذكراً للتحصين والبركة',
                btnText: 'ابدأ الأذكار ←',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.morning,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                title: stopMark != null ? 'ورد: سورة ${stopMark.surahName}' : 'ورد القرآن',
                subtitle: stopMark != null ? 'موضع التوقف: الآية ${stopMark.ayahNumber}' : 'اقرأ القرآن فإنه شفيع لأهله',
                btnText: 'متابعة الورد ←',
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen()));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_twilight_rounded, color: Color(0xFFE5B54F), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🕊️ صلاة الضحى: صلاة الأوابين • ركعتان تجزئان عن صدقة 360 مفصل في جسدك',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerFocusCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حيّ على الصلاة والفلاح ☀️',
          style: TextStyle(
            color: isLight ? const Color(0xFF102A43) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'الصلاة عماد الدين وأحب الأعمال إلى الله في وقتها',
          style: TextStyle(
            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),
        InteractiveMotionCard(
          borderRadius: 18,
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.5),
          glowColor: const Color(0xFF10B981).withValues(alpha: 0.25),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3B2C), Color(0xFF07241A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                PulsingHalo(
                  haloColor: const Color(0xFF34D399),
                  borderRadius: 22,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Color(0xFF34D399), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الصلاة القادمة: ${_nextPrayer?.nameArabic ?? "الصلاة"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'متبقي $_countdown بالثواني',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'المواقيت ←',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMiniToolTile(
                icon: Icons.explore_rounded,
                title: 'اتجاه القبلة',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniToolTile(
                icon: Icons.mosque_rounded,
                title: 'أذكار الصلاة',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.afterPrayer,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
            const SizedBox(width: 8),
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
      children: [
        Text(
          'مساء مبارك بالسكينة 🌙',
          style: TextStyle(
            color: isLight ? const Color(0xFF102A43) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'حصنك المسائي وراحة لقلبك في ختام اليوم وتجديد العهد مع القرآن',
          style: TextStyle(
            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF60A5FA),
                bgColor: const Color(0xFF60A5FA).withValues(alpha: 0.12),
                borderColor: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                title: 'أذكار المساء',
                subtitle: '24 ذكراً لطمأنينة النفس',
                btnText: 'قراءة الأذكار ←',
                onTap: () {
                  final cat = AllAzkarData.categories.firstWhere(
                    (c) => c.type == AzkarCategoryType.evening,
                    orElse: () => AllAzkarData.categories.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionPillCard(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF38BDF8),
                bgColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                title: stopMark != null ? 'ورد: سورة ${stopMark.surahName}' : 'وردك القرآني',
                subtitle: stopMark != null ? 'موضع التوقف: الآية ${stopMark.ayahNumber}' : 'أتمم ورد اليوم بطمأنينة',
                btnText: 'متابعة الورد ←',
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen()));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFE5B54F), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🌙 سنن المساء: صلاة المغرب والعشاء في جماعة وأداء سنة الوتر ونيل بركة الليل',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepCompanion(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طابت ليلتك بذكر الله 🌌',
          style: TextStyle(
            color: isLight ? const Color(0xFF102A43) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'حصّن نفسك بأذكار النوم ونوّر ليلتك وقبرك بسورة الملك المنجية',
          style: TextStyle(
            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1C0A), Color(0xFF181005)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5B54F), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC89B3C).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE5B54F), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'سورة الملك (المانعة من عذاب القبر)',
                            style: TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        '٣٠ آية تشفع لصاحبها • افتح واقرأ بنقرة واحدة',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B54F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'اقرأ الآن',
                        style: TextStyle(
                          color: Color(0xFF1E1303),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1E1303), size: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildActionPillCard(
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFFA78BFA),
          bgColor: const Color(0xFFA78BFA).withValues(alpha: 0.12),
          borderColor: const Color(0xFFA78BFA).withValues(alpha: 0.35),
          title: 'أذكار النوم والتحصين',
          subtitle: 'سنة الحبيب المصطفى ﷺ قبل إغماض عينيك لطمأنينة وراحة المنام',
          btnText: 'قراءة أذكار النوم ←',
          onTap: () {
            final cat = AllAzkarData.categories.firstWhere(
              (c) => c.type == AzkarCategoryType.sleep,
              orElse: () => AllAzkarData.categories.first,
            );
            Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrReaderScreen(category: cat)));
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.nightlight_outlined, color: Color(0xFFE5B54F), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🌌 صلاة الوتر: اجعلوا آخر صلاتكم بالليل وتراً • ركعة واحدة تكفيك وتكتبك من القائمين',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
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
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFFFF) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (isLight)
              BoxShadow(
                color: const Color(0xFF102A43).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF172033) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              btnText,
              style: TextStyle(
                color: iconColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniToolTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFFFF) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC89B3C), size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF172033) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
                    Color(0xFFDCEAF4), // Soft sky blue
                    Color(0xFFF3F8FB), // Very pale blue-white
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
            color: isLight ? const Color(0xFFDCE3EC) : const Color(0xFFC89B3C).withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFF102A43).withValues(alpha: 0.06)
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
              // Background Mosque Sunset Artwork
              Positioned.fill(
                child: Image.asset(
                  'assets/home_hero_mosque.jpg',
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
                              const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                              const Color(0xFFFFFFFF).withValues(alpha: 0.82),
                              const Color(0xFFFFFFFF).withValues(alpha: 0.20),
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
                        color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131A26),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: const Color(0xFFFFD56B),
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
                        color: isLight ? const Color(0xFF102A43) : const Color(0xFFFFD56B),
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
                        color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1B2332),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD56B).withValues(alpha: 0.5),
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
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: Color(0xFFFFD56B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'آية اليوم وتدبّر',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLight ? const Color(0xFF0F172A) : const Color(0xFFFFD56B),
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
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
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
                  color: isLight ? const Color(0xFF0F172A) : const Color(0xFFFFD56B),
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
                      color: isLight ? const Color(0xFF0F6B78) : const Color(0xFF38BDF8),
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
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFFFFD56B),
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
      borderColor: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.6 : 0.45),
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
                    Color(0xFFFFFFFF),
                    Color(0xFFF6FAFD),
                    Color(0xFFEAF2F8),
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
                ? const Color(0xFFC89B3C).withValues(alpha: 0.45)
                : const Color(0xFFFFD56B).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFF102A43).withValues(alpha: 0.08)
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
                padding: const EdgeInsets.all(20),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLight
                                      ? [const Color(0xFF102A43), const Color(0xFF0D1B2A)]
                                      : [const Color(0xFF1C2C45), const Color(0xFF0F1A2A)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFD56B).withValues(alpha: 0.6),
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
                                  const SizedBox(width: 8),
                                  Text(
                                    _countdown,
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      color: Color(0xFFFFD56B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Color(0xFFC89B3C),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'متبقي على الأذان',
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                                    color: const Color(0xFFFFD56B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFD56B).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars_rounded, color: Color(0xFFFFD56B), size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'الصلاة القادمة',
                                        style: TextStyle(
                                          color: isLight ? const Color(0xFF0F2B48) : const Color(0xFFFFD56B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
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
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFFD56B).withValues(alpha: 0.5),
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
                                    color: isLight ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // 3D Glowing Mosque Medallion with PulsingHalo
                            PulsingHalo(
                              haloColor: const Color(0xFFFFD56B),
                              borderRadius: 28,
                              child: Container(
                                width: 56,
                                height: 56,
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
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
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
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 6 Prayer Cards 3D Row (الفجر، الشروق، الظهر، العصر، المغرب، العشاء)
                    if (_allPrayers.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _allPrayers.map((prayer) {
                          final isActive = _nextPrayer != null && _nextPrayer!.type == prayer.type;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFC89B3C).withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Color(0xFFFFD56B), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                color: isLight ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'عرض الجدول',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
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
      // 3D Elevated Active Prayer Tile with Pulsing Golden Aura Halo
      return PulsingHalo(
        isActive: true,
        haloColor: const Color(0xFFFFD56B),
        borderRadius: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF283D5E),
                Color(0xFF16243A),
                Color(0xFF0D1726),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD56B),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD56B).withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFFD56B), size: 16),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD56B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFD56B),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD56B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3D Inactive Prayer Card: Elevated Glass Tile with Top Highlight & Soft Shadow
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFFFFFFF)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE3EC)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF102A43).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            size: 15,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLight ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 4. QUICK ACCESS GRID ====================
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      children: [
        // Card 1: المصحف الشريف (Gold)
        Expanded(
          child: _buildQuickActionCard(
            title: 'المصحف الشريف',
            subtitle: '114 سورة',
            icon: Icons.menu_book_rounded,
            iconBg: const Color(0xFFFFF7E6),
            accentColor: const Color(0xFFC89B3C),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen())),
          ),
        ),
        const SizedBox(width: 10),

        // Card 2: حصن المسلم (Teal)
        Expanded(
          child: _buildQuickActionCard(
            title: 'حصن المسلم',
            subtitle: 'أذكار وأدعية',
            icon: Icons.auto_awesome_rounded,
            iconBg: const Color(0xFFE8F3F3),
            accentColor: const Color(0xFF0F6B78),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen())),
          ),
        ),
        const SizedBox(width: 10),

        // Card 3: اتجاه القبلة (Navy / Sky Blue)
        Expanded(
          child: _buildQuickActionCard(
            title: 'اتجاه القبلة',
            subtitle: 'بوصلة دقيقة',
            icon: Icons.explore_rounded,
            iconBg: const Color(0xFFDCEAF4),
            accentColor: const Color(0xFF102A43),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
        ),
        const SizedBox(width: 10),

        // Card 4: إذاعة القرآن (Purple)
        Expanded(
          child: _buildQuickActionCard(
            title: 'إذاعة القرآن',
            subtitle: 'بث مباشر',
            icon: Icons.radio_rounded,
            iconBg: const Color(0xFFF0ECFA),
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
    required Color iconBg,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isLight = DesignSystem.isLightMode;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      borderRadius: 22,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Icon Container with glowing ring
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isLight ? iconBg : iconBg.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isLight ? 0.15 : 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isLight ? accentColor : const Color(0xFFFFD56B),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLight ? const Color(0xFF172033) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLight ? const Color(0xFF667085) : const Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
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
              color: isLight ? const Color(0xFFFFF7E6) : const Color(0xFF1E2738),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.35 : 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: Color(0xFFFFD56B),
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
                        color: isLight ? const Color(0xFF172033) : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Color(0xFFFFD56B),
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
                    color: isLight ? const Color(0xFF667085) : const Color(0xFF94A3B8),
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
                    backgroundColor: isLight ? const Color(0xFFDCE3EC) : const Color(0xFF1E293B),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD56B)),
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

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      onTap: onTap,
      child: SizedBox(
        width: 105,
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
                      color: isCurrent ? const Color(0xFFFFD56B) : const Color(0xFFDCE3EC),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCurrent
                            ? const Color(0xFFFFD56B).withValues(alpha: 0.35)
                            : const Color(0xFF102A43).withValues(alpha: 0.06),
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF102A43),
                              size: 26,
                            ),
                          )
                        : Image.network(
                            reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF102A43),
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
                      color: isCurrent ? const Color(0xFFFFD56B) : const Color(0xFF102A43),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: isCurrent
                        ? const SoundWaveVisualizer(
                            isPlaying: true,
                            barCount: 3,
                            maxHeight: 8,
                            minHeight: 2,
                            barWidth: 1.5,
                            spacing: 1.5,
                            activeColor: Color(0xFF07090E),
                          )
                        : const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 11,
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
                color: isLight ? const Color(0xFF172033) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reciter.style,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF667085) : const Color(0xFF94A3B8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
