import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
import '../widgets/interactive_tasbih_card.dart';
import '../widgets/islamic_background.dart';
import '../widgets/visual_effects/star_glint.dart';
import '../widgets/visual_effects/shimmer_sweep.dart';
import '../widgets/visual_effects/pulsing_halo.dart';
import '../widgets/visual_effects/islamic_decorations.dart';
import 'azkar_screen.dart';
import 'iqra_screen.dart';
import 'notification_settings_screen.dart';
import 'prayer_times_screen.dart';
import 'qibla_screen.dart';
import 'surah_viewer_screen.dart';
import 'tasbih_screen.dart';
import '../widgets/developer_credits_badge.dart';
import '../services/theme_service.dart';
import '../widgets/theme_selection_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final QuranStorageService _storage = QuranStorageService();

  PrayerTiming? _nextPrayer;
  String _hoursStr = '01';
  String _minutesStr = '46';
  String _secondsStr = '27';
  List<PrayerTiming> _allPrayers = [];
  Timer? _liveTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDefaultPrayerTimes();
    _startLiveTimer();
    _storage.addListener(_onStorageUpdate);
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _storage.removeListener(_onStorageUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _initDefaultPrayerTimes() {
    _allPrayers = [
      PrayerTiming(
        type: PrayerType.fajr,
        nameArabic: 'الفجر',
        nameEnglish: 'Fajr',
        time: const TimeOfDay(hour: 5, minute: 19),
        icon: Icons.nightlight_round,
      ),
      PrayerTiming(
        type: PrayerType.sunrise,
        nameArabic: 'الشروق',
        nameEnglish: 'Sunrise',
        time: const TimeOfDay(hour: 6, minute: 45),
        icon: Icons.wb_twilight_rounded,
      ),
      PrayerTiming(
        type: PrayerType.dhuhr,
        nameArabic: 'الظهر',
        nameEnglish: 'Dhuhr',
        time: const TimeOfDay(hour: 12, minute: 46),
        icon: Icons.wb_sunny_rounded,
      ),
      PrayerTiming(
        type: PrayerType.asr,
        nameArabic: 'العصر',
        nameEnglish: 'Asr',
        time: const TimeOfDay(hour: 16, minute: 13),
        icon: Icons.cloud_queue_rounded,
      ),
      PrayerTiming(
        type: PrayerType.maghrib,
        nameArabic: 'المغرب',
        nameEnglish: 'Maghrib',
        time: const TimeOfDay(hour: 18, minute: 47),
        icon: Icons.wb_sunny_outlined,
      ),
      PrayerTiming(
        type: PrayerType.isha,
        nameArabic: 'العشاء',
        nameEnglish: 'Isha',
        time: const TimeOfDay(hour: 20, minute: 4),
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
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    setState(() {
      _nextPrayer = next;
      _hoursStr = hours.toString().padLeft(2, '0');
      _minutesStr = minutes.toString().padLeft(2, '0');
      _secondsStr = seconds.toString().padLeft(2, '0');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IslamicBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP BAR (Brand, Search Bar, Mode Switch, Notifications, User Capsule)
                  _buildTopBar(context),

                  const SizedBox(height: 16),

                  // 2. TOP SECTION: Hero Greeting (Left) + Ayah Card (Right)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 850) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Hero Card (60%)
                            Expanded(
                              flex: 6,
                              child: _buildHeroGreetingCard(context),
                            ),
                            const SizedBox(width: 14),
                            // Right Ayah of the Day (40%)
                            Expanded(
                              flex: 4,
                              child: _buildAyahCard(context),
                            ),
                          ],
                        );
                      }
                      // Mobile Stacked View
                      return Column(
                        children: [
                          _buildHeroGreetingCard(context),
                          const SizedBox(height: 12),
                          _buildAyahCard(context),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 3. MIDDLE SECTION: Prayer Times (Left) + Electronic Tasbih (Right)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 850) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Prayer Times Card (62%)
                              Expanded(
                                flex: 62,
                                child: _buildPrayerTimesSpotlightCard(context),
                              ),
                              const SizedBox(width: 14),
                              // Right Electronic Tasbih (38%)
                              const Expanded(
                                flex: 38,
                                child: InteractiveTasbihCard(),
                              ),
                            ],
                          ),
                        );
                      }
                      // Mobile Stacked View
                      return Column(
                        children: [
                          _buildPrayerTimesSpotlightCard(context),
                          const SizedBox(height: 14),
                          const SizedBox(
                            height: 360,
                            child: InteractiveTasbihCard(),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // 4. BOTTOM TOOLS SECTION ("أدوات سريعة")
                  _buildQuickToolsSection(context),

                  const SizedBox(height: 22),

                  // 5. DEVELOPER CREDITS & RIGHTS ("Eng Ahmed Zaki")
                  const Center(
                    child: DeveloperCreditsBadge(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  // ==================== 1. TOP BAR ====================
  Widget _buildTopBar(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        // Left: Rafeeq Brand & Mosque Logo
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isLight
                        ? const Color(0xFFC89B3C).withValues(alpha: 0.15)
                        : const Color(0xFFFFD56B).withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  isLight ? 'assets/out logo app/lightapp.png' : 'assets/out logo app/darkapp.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.mosque,
                    color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rafeeq',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF1C1917) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'رفيقك في رحلتك الإيمانية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF854D0E) : const Color(0xFFC89B3C),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Center: Search Bar ("ابحث في القرآن، الأذكار، المحتوى...")
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFF1E293B),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLight
                      ? const Color(0xFFC89B3C).withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isLight ? const Color(0xFF854D0E) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      color: isLight ? const Color(0xFF1C1917) : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في القرآن، الأذكار، المحتوى...',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF64748B),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Right Group: Mode Toggle, Notification Bell, User Profile Capsule
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme Mode Toggle Pill
            InkWell(
              onTap: () {
                ThemeService.instance.toggleDarkLight();
              },
              onLongPress: () {
                ThemeSelectionModal.show(context);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFF1E293B),
                  ),
                ),
                child: Icon(
                  isLight ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                  size: 18,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Notification Bell with Yellow (1) Badge
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFF1E293B),
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: isLight ? const Color(0xFF854D0E) : Colors.white,
                      size: 19,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFD97706) : const Color(0xFFFFD56B),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: isLight ? Colors.white : const Color(0xFF07090E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // User Profile Capsule ("مرحباً بك • فارس القرآن")
            InkWell(
              onTap: () => _showEditProfileDialog(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.45),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? const Color(0xFFC89B3C).withValues(alpha: 0.08)
                          : const Color(0xFFFFD56B).withValues(alpha: 0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'مرحباً بك في',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                            fontSize: 9.5,
                          ),
                        ),
                        Text(
                          'رفيق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isLight ? const Color(0xFF1C1917) : Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                          width: 1.2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/profile_hero.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== 2. TOP HERO GREETING CARD ====================
  Widget _buildHeroGreetingCard(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ShimmerSweep(
      duration: const Duration(milliseconds: 3200),
      pauseDuration: const Duration(milliseconds: 3000),
      shimmerColor: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
      child: Container(
        height: 205,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFFC89B3C).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Mosque Panorama Artwork
              Positioned.fill(
                child: Image.asset(
                  isLight ? 'assets/daylight_mosque_bg.jpg' : 'assets/home_hero_mosque.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLight
                            ? [const Color(0xFFFFFDF8), const Color(0xFFFAF5EB)]
                            : [const Color(0xFF1B2E4B), const Color(0xFF0A121D)],
                      ),
                    ),
                  ),
                ),
              ),

              // Deep Overlay for Crisp Text Contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: isLight
                          ? [
                              const Color(0xFFFFFDF8).withValues(alpha: 0.95),
                              const Color(0xFFFFFDF8).withValues(alpha: 0.75),
                              const Color(0xFFFFFDF8).withValues(alpha: 0.20),
                            ]
                          : [
                              const Color(0xFF07090E).withValues(alpha: 0.94),
                              const Color(0xFF07090E).withValues(alpha: 0.70),
                              const Color(0xFF07090E).withValues(alpha: 0.25),
                            ],
                    ),
                  ),
                ),
              ),

              // Pointed Islamic Arch Border Trim
              Positioned.fill(
                child: CustomPaint(
                  painter: IslamicArchBorderPainter(
                    primaryColor: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                    secondaryColor: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C),
                  ),
                ),
              ),

              // Sparkle Glint at corner
              Positioned(
                top: 8,
                left: 14,
                child: StarGlint(
                  size: 18,
                  color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                ),
              ),

              // Text Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أهلاً ومرحباً بك',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'مرحباً بك في رفيق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isLight ? const Color(0xFF1C1917) : Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            shadows: isLight
                                ? null
                                : const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'بارك الله في يومك، واجعل لك فيه نصيباً من الخير والطاعة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isLight ? const Color(0xFF78716C) : Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),

                    // Date & Hijri Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF0C131D).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الاثنين 27 سبتمبر 2026 • 4 ربيع الآخر 1448 هـ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  // ==================== 2.5 AYAH OF THE DAY CARD ====================
  Widget _buildAyahCard(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: 205,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFFC89B3C).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: "★ آية اليوم"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StarGlint(
                size: 14,
                color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFFFFD56B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'آية اليوم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.menu_book_rounded,
                      size: 13,
                      color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quran Calligraphy Verse
          Text(
            '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
              shadows: [
                if (!isLight)
                  Shadow(
                    color: const Color(0xFFFFD56B).withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
              ],
            ),
          ),

          // Surah Reference & Tafsir Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tafsir Button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SurahViewerScreen(
                        surahNumber: 13,
                        surahName: 'الرعد',
                        initialAyah: 28,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF151D2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 14,
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'تفسير الآية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Text(
                'سورة الرعد • الآية 28',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 3. PRAYER TIMES SPOTLIGHT & COUNTDOWN ====================
  Widget _buildPrayerTimesSpotlightCard(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFFC89B3C).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: "مواقيت الصلاة - مكة المكرمة" + "عرض اليوم كامل >"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF151D2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE5D4B3) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 14, color: isLight ? const Color(0xFF854D0E) : const Color(0xFF94A3B8)),
                      const SizedBox(width: 2),
                      Text(
                        'عرض اليوم كامل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isLight ? const Color(0xFF854D0E) : const Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'مواقيت الصلاة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isLight ? const Color(0xFF1C1917) : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'مكة المكرمة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 6 Prayer Cards Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _allPrayers.map((prayer) {
              final isActive = _nextPrayer != null
                  ? prayer.type == _nextPrayer!.type
                  : prayer.type == PrayerType.asr;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: _buildPrayerPill(
                    prayer: prayer,
                    isActive: isActive,
                    isLight: isLight,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Golden Connecting Timeline with Node Points
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 240,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: (isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B)).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Real-time Countdown Panel over Mosque Silhouette
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isLight
                    ? [const Color(0xFFFBF4E4), const Color(0xFFF5EBD7)]
                    : [const Color(0xFF131C28), const Color(0xFF090E16)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? const Color(0xFFE5D4B3) : Colors.white10,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Digital Countdown: (ساعة : دقيقة : ثانية)
                Row(
                  children: [
                    _buildTimeBox(_secondsStr, 'ثانية', isLight),
                    _buildTimeColon(isLight),
                    _buildTimeBox(_minutesStr, 'دقيقة', isLight),
                    _buildTimeColon(isLight),
                    _buildTimeBox(_hoursStr, 'ساعة', isLight),
                  ],
                ),

                // Label: "الوقت المتبقي على ..."
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الوقت المتبقي على ${_nextPrayer?.nameArabic ?? "العصر"}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
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

  Widget _buildPrayerPill({
    required PrayerTiming prayer,
    required bool isActive,
    required bool isLight,
  }) {
    if (isActive) {
      return PulsingHalo(
        isActive: true,
        haloColor: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
        borderRadius: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [
                      const Color(0xFFFFDF7D),
                      const Color(0xFFE5A83B),
                      const Color(0xFFC89B3C),
                    ]
                  : [
                      const Color(0xFF263852),
                      const Color(0xFF132032),
                      const Color(0xFF0B1420),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B)).withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mosque_rounded,
                color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                size: 16,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  prayer.nameArabic,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  prayer.formattedTimeArabic,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF1C1917) : Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withValues(alpha: 0.5) : const Color(0xFFFFD56B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'الآن',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF121B27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            prayer.icon,
            color: isLight ? const Color(0xFF854D0E) : const Color(0xFF8E9BAE),
            size: 16,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              prayer.nameArabic,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isLight ? const Color(0xFF1C1917) : Colors.white70,
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
              prayer.formattedTimeArabic,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF8E9BAE),
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String unit, bool isLight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isLight ? const Color(0xFF1C1917) : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isLight ? const Color(0xFF78716C) : const Color(0xFF8E9BAE),
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeColon(bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== 4. QUICK TOOLS SECTION ("أدوات سريعة") ====================
  Widget _buildQuickToolsSection(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'أدوات سريعة',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isLight ? const Color(0xFF1C1917) : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.flash_on_rounded, size: 16, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B)),
          ],
        ),

        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            final tools = [
              _QuickToolData(
                title: 'القرآن الكريم',
                subtitle: 'تلاوة واستماع',
                icon: Icons.menu_book_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen())),
              ),
              _QuickToolData(
                title: 'الأذكار',
                subtitle: 'أذكار الصباح والمساء',
                icon: Icons.auto_awesome_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen())),
              ),
              _QuickToolData(
                title: 'السبحة',
                subtitle: 'سبح الآن',
                icon: Icons.all_inclusive_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen())),
              ),
              _QuickToolData(
                title: 'المساجد',
                subtitle: 'ابحث عن مسجد قريب',
                icon: Icons.mosque_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
              ),
              _QuickToolData(
                title: 'مظهر التطبيق',
                subtitle: 'تخصيص الألوان والثيم',
                icon: Icons.palette_rounded,
                onTap: () => ThemeSelectionModal.show(context),
              ),
              _QuickToolData(
                title: 'مواقيت الصلاة',
                subtitle: 'عرض جميع المواقيت',
                icon: Icons.calendar_month_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
              ),
            ];

            if (isWide) {
              return Row(
                children: tools.map((tool) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildToolPillCard(tool, isLight)))).toList(),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tools.map((tool) => Container(width: 170, margin: const EdgeInsets.only(left: 8), child: _buildToolPillCard(tool, isLight))).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolPillCard(_QuickToolData tool, bool isLight) {
    return InkWell(
      onTap: tool.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFFC89B3C).withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFFFFD56B).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tool.icon,
                color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tool.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isLight ? const Color(0xFF1C1917) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    tool.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              size: 16,
              color: isLight ? const Color(0xFF854D0E) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B), width: 1.2),
        ),
        title: Text(
          'الملف الشخصي',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', color: isLight ? const Color(0xFF1C1917) : Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF151D2A),
              child: Icon(Icons.person, size: 40, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B)),
            ),
            const SizedBox(height: 12),
            Text(
              'فارس القرآن',
              style: TextStyle(fontFamily: 'Cairo', color: isLight ? const Color(0xFF1C1917) : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'رفيقك الإيماني للقرآن والأذكار ومواقيت الصلاة',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))),
          ),
        ],
      ),
    );
  }
}

class _QuickToolData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _QuickToolData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}