import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import 'ai_assistant_screen.dart';
import 'azkar_screen.dart';
import 'iqra_screen.dart';
import 'qibla_screen.dart';
import 'radio_screen.dart';
import 'surah_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildHeroCard(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildPrayerSpotlightCard(context),
                ),
              ),
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
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'نفحات اليوم',
                  subtitle: 'آية وذكر يضيئان يومك',
                  icon: Icons.auto_awesome,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingXS,
                  ),
                  child: _buildDailyInspiration(context),
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'تلاوات مختارة',
                  subtitle: 'استمع بأعذب الأصوات',
                  icon: Icons.headphones_rounded,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildRecitersHorizontal(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacingL,
                    DesignSystem.spacingM,
                    DesignSystem.spacingL,
                    DesignSystem.spacing3XL,
                  ),
                  child: _buildAIAssistantBanner(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: DesignSystem.gold.withOpacity(0.6), width: 1.5),
                boxShadow: DesignSystem.goldGlow,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mosque,
                    color: DesignSystem.goldLight,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rafeeq',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'رفيقك في رحلتك الإيمانية',
                  style: TextStyle(
                    color: DesignSystem.goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard.withOpacity(0.8),
                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: DesignSystem.cyanAccent,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'مكة المكرمة',
                    style: TextStyle(
                      color: DesignSystem.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: DesignSystem.textPrimary,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.6),
            const Color(0xFF4C1D95).withOpacity(0.4),
            DesignSystem.bgCard.withOpacity(0.9),
          ],
        ),
        border: Border.all(
          color: DesignSystem.gold.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.electricBlue.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -15,
            top: -20,
            child: Icon(
              Icons.nightlight_round,
              size: 130,
              color: DesignSystem.gold.withOpacity(0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignSystem.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: DesignSystem.gold.withOpacity(0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: DesignSystem.goldLight,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'طُمأنينة ورِفعة',
                            style: TextStyle(
                              color: DesignSystem.goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'مرحباً بك في إسلاميات — رفيقك الإيماني الذكي للقرآن، الأذكار، ومواقيت الصلاة بدقة فائقة.',
                  style: TextStyle(
                    color: DesignSystem.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSpotlightCard(BuildContext context) {
    return GlassCard(
      borderRadius: DesignSystem.radiusLarge,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      hasGlow: true,
      glowColor: DesignSystem.gold,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignSystem.gold.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DesignSystem.gold.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: DesignSystem.goldLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الصلاة القادمة',
                        style: TextStyle(
                          color: DesignSystem.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'صلاة العصر',
                        style: TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '٠٣:٣٠ م',
                    style: TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DesignSystem.electricBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    ),
                    child: const Text(
                      'متبقي ٠١:١٥:٢٠',
                      style: TextStyle(
                        color: DesignSystem.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPrayerPill('الفجر', '٠٤:٣٠', false, true),
              _buildPrayerPill('الشروق', '٠٥:٥٥', false, true),
              _buildPrayerPill('الظهر', '١٢:١٥', false, true),
              _buildPrayerPill('العصر', '٠٣:٣٠', true, false),
              _buildPrayerPill('المغرب', '٠٦:٤٢', false, false),
              _buildPrayerPill('العشاء', '٠٨:٠٥', false, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerPill(String name, String time, bool isNext, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isNext
            ? DesignSystem.gold.withOpacity(0.2)
            : (isDone
                ? Colors.white.withOpacity(0.04)
                : DesignSystem.bgCard.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        border: Border.all(
          color: isNext
              ? DesignSystem.gold
              : (isDone
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05)),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: isNext
                  ? DesignSystem.goldLight
                  : (isDone ? DesignSystem.textMuted : DesignSystem.textSecondary),
              fontSize: 11,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              color: isNext ? DesignSystem.textWhite : DesignSystem.textMuted,
              fontSize: 10,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {'title': 'المصحف الشريف', 'sub': '١١٤ سورة', 'icon': Icons.menu_book_rounded, 'color': DesignSystem.gold},
      {'title': 'حصن المسلم', 'sub': 'أذكار وأدعية', 'icon': Icons.auto_awesome, 'color': DesignSystem.cyanAccent},
      {'title': 'اتجاه القبلة', 'sub': 'بوصلة دقيقة', 'icon': Icons.explore_rounded, 'color': DesignSystem.electricBlue},
      {'title': 'إذاعة القرآن', 'sub': 'بث مباشر', 'icon': Icons.radio_rounded, 'color': DesignSystem.violet},
    ];

    return Row(
      children: actions.map((item) {
        final color = item['color'] as Color;
        final title = item['title'] as String;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              borderRadius: DesignSystem.radiusMedium,
              onTap: () {
                if (title == 'اتجاه القبلة') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()));
                } else if (title == 'المصحف الشريف') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen()));
                } else if (title == 'حصن المسلم') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen()));
                } else if (title == 'إذاعة القرآن') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RadioScreen()));
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.35),
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item['sub'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueReadingCard(BuildContext context) {
    return GlassCard(
      borderRadius: DesignSystem.radiusLarge,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: DesignSystem.goldGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              boxShadow: DesignSystem.goldGlow,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: DesignSystem.bgDarkest,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سورة البقرة — الآية ٢٥٥',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'الجزء الثالث • صفحة ٤٢',
                  style: TextStyle(
                    color: DesignSystem.goldLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: DesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              boxShadow: DesignSystem.blueGlow,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'متابعة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInspiration(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          borderRadius: DesignSystem.radiusLarge,
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote_rounded, color: DesignSystem.gold, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'آية اليوم',
                        style: TextStyle(
                          color: DesignSystem.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'سورة إبراهيم : ٧',
                    style: TextStyle(
                      color: DesignSystem.goldLight.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '﴿ وَإِذْ تَأَذَّنَ رَبُّكُمْ لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ ﴾',
                style: TextStyle(
                  color: DesignSystem.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecitersHorizontal(BuildContext context) {
    final reciters = [
      {'name': 'مشاري العفاسي', 'type': 'حفص عن عاصم'},
      {'name': 'عبد الباسط عبد الصمد', 'type': 'مجود'},
      {'name': 'ماهر المعيقلي', 'type': 'مرتل'},
      {'name': 'سعد الغامدي', 'type': 'مرتل'},
      {'name': 'ياسر الدوسري', 'type': 'مرتل'},
    ];

    return SizedBox(
      height: 115,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
        itemCount: reciters.length,
        itemBuilder: (context, index) {
          final reciter = reciters[index];
          return Container(
            width: 95,
            margin: const EdgeInsets.only(left: 10),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DesignSystem.primaryGradient,
                    border: Border.all(
                      color: DesignSystem.gold.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: DesignSystem.blueGlow,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reciter['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  reciter['type']!,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignSystem.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIAssistantBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        );
      },
      borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF0F172A),
            ],
          ),
          border: Border.all(
            color: DesignSystem.cyanAccent.withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignSystem.cyanAccent.withOpacity(0.12),
              blurRadius: 25,
            ),
          ],
        ),
        padding: const EdgeInsets.all(DesignSystem.spacingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignSystem.cyanAccent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignSystem.cyanAccent.withOpacity(0.4),
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: DesignSystem.cyanAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المساعد الإسلامي الذكي',
                    style: TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'اسأل عن معاني الآيات، أحكام التجويد، أو فضائل السور',
                    style: TextStyle(
                      color: DesignSystem.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: DesignSystem.cyanAccent,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}