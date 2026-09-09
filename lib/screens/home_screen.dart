import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service_v2.dart';
import '../services/audio_quran_service.dart';
import '../data/reciters_data.dart';
import 'azkar_screen.dart';
import 'audio_screen.dart';
import 'iqra_screen.dart';
import 'notification_settings_screen.dart';
import 'qibla_screen.dart';
import 'radio_screen.dart';
import 'surah_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerServiceV2 _prayerService = PrayerServiceV2();

  PrayerTiming? _nextPrayer;
  PrayerTiming? _currentPrayer;
  String _countdown = '03:55:10';
  List<PrayerTiming> _allPrayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prayerService.addListener(_onUpdate);
    _loadPrayerData();
  }

  @override
  void dispose() {
    _prayerService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() async {
    if (mounted) {
      final countdown = await _prayerService.getFormattedCountdown();
      setState(() {
        _countdown = countdown;
      });
    }
  }

  Future<void> _loadPrayerData() async {
    try {
      setState(() => _isLoading = true);
      await _prayerService.preloadPrayerData();
      final nextPrayer = await _prayerService.getNextPrayer();
      final currentPrayer = await _prayerService.getCurrentPrayer();
      final countdown = await _prayerService.getFormattedCountdown();
      final allPrayers = await _prayerService.getPrayerTimingsForDate(DateTime.now());

      if (mounted) {
        setState(() {
          _nextPrayer = nextPrayer;
          _currentPrayer = currentPrayer;
          _countdown = countdown.isNotEmpty ? countdown : '03:55:10';
          _allPrayers = allPrayers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

              // 4. Quick Access Section (الوصول السريع)
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'الوصول السريع',
                  subtitle: 'تصفح الخدمات والعبادات اليومية',
                  icon: Icons.grid_view_rounded,
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

  // ==================== 2. MAIN HERO CARD ====================
  Widget _buildHeroCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Container(
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
          color: isLight ? const Color(0xFFDCE3EC) : const Color(0xFFC89B3C).withValues(alpha: 0.35),
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
              color: const Color(0xFFC89B3C).withValues(alpha: 0.12),
              blurRadius: 16,
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

            // Right Content: Verse & Welcome Note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // "كلمة اليوم ★" Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131A26),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      border: Border.all(
                        color: const Color(0xFFC89B3C),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC89B3C).withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFC89B3C), size: 14),
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

                  // Main Quranic Verse
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
                          color: isLight ? Colors.white.withValues(alpha: 0.8) : Colors.black,
                          blurRadius: 10,
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
    );
  }

  // ==================== 2.5 DAILY AYAH SECTION ====================
  Widget _buildDailyAyahCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return GlassCard(
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: const Color(0xFFFFD56B),
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

          // Quranic Ayah Text in Amiri calligraphy
          Text(
            '﴿ وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ ﴾',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 21,
              fontWeight: FontWeight.bold,
              height: 1.6,
              color: isLight ? const Color(0xFF0F172A) : const Color(0xFFFFD56B),
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
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: const Color(0xFFFFD56B),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 3. PRAYER TIMES SECTION ====================
  Widget _buildPrayerSpotlightCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final nextPrayerTitle = _nextPrayer?.nameArabic ?? 'الظهر';
    final nextPrayerTime = _nextPrayer?.formattedTimeArabic ?? '12:54 م';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        children: [
          // Next Prayer Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Next Prayer Time & Countdown Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextPrayerTime,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF102A43) : const Color(0xFFF6F8FA),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFDCEAF4) : const Color(0xFF1C273C),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      border: Border.all(
                        color: isLight ? Colors.transparent : const Color(0xFFC89B3C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: isLight ? const Color(0xFF102A43) : const Color(0xFFE8D29A),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_countdown متبقي',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF102A43) : const Color(0xFFE8D29A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Right: Label & Title ("الصلاة القادمة - الظهر")
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الصلاة القادمة',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF667085) : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        nextPrayerTitle,
                        style: TextStyle(
                          color: isLight ? const Color(0xFF102A43) : const Color(0xFFFFD56B),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8F6F0) : const Color(0xFF161F2E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Color(0xFFC89B3C),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 6 Prayer Cards Row (الفجر، الشروق، الظهر، العصر، المغرب، العشاء)
          if (_allPrayers.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _allPrayers.map((prayer) {
                final isActive = _nextPrayer != null && _nextPrayer!.type == prayer.type;
                return _buildPrayerCard(
                  prayer.nameArabic,
                  prayer.formattedTimeArabic,
                  prayer.icon,
                  isActive,
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
        ],
      ),
    );
  }

  Widget _buildPrayerCard(String name, String time, IconData icon, bool isActive) {
    if (isActive) {
      // Highlighted Active State: Dark Navy #102A43 + Gold #C89B3C Border & Typography
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF102A43),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC89B3C), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE8D29A), size: 16),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFFE8D29A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Inactive Prayer Card: Clean White / Light Blue-Gray with Subtle Border
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF667085), size: 15),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 10,
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      borderRadius: 22,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 5. QURAN READING PROGRESS ====================
  Widget _buildContinueReadingCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          // Gold Quran / Bookmark Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: Color(0xFFC89B3C),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Details & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سورة البقرة',
                      style: TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '12%',
                      style: TextStyle(
                        color: Color(0xFFC89B3C),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'الآية 42 • الجزء الأول',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 11),
                ),
                const SizedBox(height: 8),

                // Thin Elegant Progress Bar (Navy -> Teal -> Gold indicator)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.12,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFDCE3EC),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF102A43)),
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
                      color: isCurrent ? const Color(0xFFC89B3C) : const Color(0xFFDCE3EC),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF102A43).withValues(alpha: 0.06),
                        blurRadius: 8,
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
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFC89B3C) : const Color(0xFF102A43),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
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
              style: const TextStyle(
                color: Color(0xFF172033),
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
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
