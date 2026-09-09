import 'package:flutter/material.dart';
import '../data/all_azkar_data.dart';
import '../models/azkar_models.dart';
import '../services/azkar_service.dart';
import '../utils/design_system.dart';
import '../widgets/prayer_settings_sheet.dart';
import 'dhikr_reader_screen.dart';
import 'notification_settings_screen.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  final AzkarService _azkarService = AzkarService();

  @override
  void initState() {
    super.initState();
    _azkarService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _azkarService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _openCategory(BuildContext context, AzkarCategoryMeta category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DhikrReaderScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = AllAzkarData.categories;
    final isLight = DesignSystem.isLightMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Header Bar (Rafeeq Logo + Search, Settings, Notification Buttons)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: _buildTopHeaderBar(context, isLight),
                  ),
                ),

                // 2. Panoramic Mosque Hero Banner with "الأذكار" Calligraphy
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: _buildPanoramicHeroBanner(isLight),
                  ),
                ),

                // 3. Wird Card (وردك اليومي) + Daily Reminder Card (تذكير اليوم) Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: _buildWirdAndReminderRow(context, categories, isLight),
                  ),
                ),

                // 4. Section Header: أقسام الأذكار الرئيسية
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'أقسام الأذكار الرئيسية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                        Text(
                          'اختر ما يناسبك من الأذكار في كل الأوقات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Grid of 6 Main Categories
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: _buildCategoriesGrid(context, categories, isLight),
                ),

                // 6. Bottom Dual Cards: [المفضلة] and [آخر ما قرأت]
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    child: _buildBottomDualCards(context, categories, isLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAzkarSearchDialog(BuildContext context, List<DhikrItem> allAzkar, bool isLight) {
    showDialog(
      context: context,
      builder: (ctx) {
        String currentQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final results = currentQuery.trim().isEmpty
                ? <DhikrItem>[]
                : allAzkar.where((d) {
                    return d.title.contains(currentQuery) ||
                        d.text.contains(currentQuery) ||
                        (d.fadl?.contains(currentQuery) ?? false);
                  }).toList();

            return Dialog(
              backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(18),
                constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث في كافة الأذكار والأدعية...',
                        hintStyle: TextStyle(
                          fontFamily: 'Cairo',
                          color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFFD56B)),
                        filled: true,
                        fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          currentQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: results.isEmpty
                          ? Center(
                              child: Text(
                                currentQuery.trim().isEmpty
                                    ? 'اكتب كلمة للبحث في الأذكار'
                                    : 'لا توجد نتائج مطابقة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: results.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final dhikr = results[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  title: Text(
                                    dhikr.title,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    dhikr.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Color(0xFFFFD56B),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    final cat = AllAzkarData.categories.firstWhere(
                                      (c) => c.type == dhikr.category,
                                      orElse: () => AllAzkarData.categories.first,
                                    );
                                    _openCategory(context, cat);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 1. Top Header Bar matching screenshot
  Widget _buildTopHeaderBar(BuildContext context, bool isLight) {
    final allAzkar = AllAzkarData.getAllAzkar();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand & Logo Left
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/out logo app/darkapp.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFFFFD56B),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rafeeq',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'رفيقك في رحلتك الإيمانية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFFFFD56B).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Actions: Search Pill, Settings, Notification
        Row(
          children: [
            // Search Pill
            InkWell(
              onTap: () => _showAzkarSearchDialog(context, allAzkar, isLight),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0E131C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'بحث',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Settings Icon
            _buildCircularAction(
              icon: Icons.settings_outlined,
              isLight: isLight,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const PrayerSettingsSheet(),
                );
              },
            ),
            const SizedBox(width: 8),

            // Notification Icon
            _buildCircularAction(
              icon: Icons.notifications_none_rounded,
              isLight: isLight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required bool isLight,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0E131C),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: isLight ? const Color(0xFF475569) : const Color(0xFFA0AEC0),
          ),
        ),
      ),
    );
  }

  /// 2. Panoramic Mosque Hero Banner matching the uploaded image
  Widget _buildPanoramicHeroBanner(bool isLight) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? const Color(0xFFDCE3EC) : const Color(0xFFC89B3C).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (!isLight)
            BoxShadow(
              color: const Color(0xFFFFD56B).withValues(alpha: 0.12),
              blurRadius: 16,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // High-res Mosque Sunset Panoramic Artwork
            Image.asset(
              'assets/azkar_panoramic_hero.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/home_hero_mosque.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // Deep Dark Gradient Overlay for the right typography
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: isLight
                      ? [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.96),
                          const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                          const Color(0xFFFFFFFF).withValues(alpha: 0.15),
                        ]
                      : [
                          const Color(0xFF07090E).withValues(alpha: 0.96),
                          const Color(0xFF07090E).withValues(alpha: 0.85),
                          const Color(0xFF07090E).withValues(alpha: 0.15),
                        ],
                ),
              ),
            ),

            // Calligraphy and text on Right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الأذكــــار',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: isLight ? const Color(0xFF0F172A) : const Color(0xFFFFD56B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: const Color(0xFFFFD56B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'طريقك إلى القرب من الله في كل وقت',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF334155) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '«ألا بذكر الله تطمئن القلوب»',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFFFFD56B).withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '(الرعد: 28)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

  /// 3. Wird Card (وردك اليومي) + Daily Reminder Card (تذكير اليوم)
  Widget _buildWirdAndReminderRow(
      BuildContext context, List<AzkarCategoryMeta> categories, bool isLight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        final wirdCard = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0D121B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E1708),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFFFFD56B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وردك اليومي',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          ),
                          Text(
                            'اجعل لك ورداً ثابتاً من الأذكار',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Button: متابعة الورد اليومي >
                  InkWell(
                    onTap: () {
                      final hour = DateTime.now().hour;
                      final isEveningTime = hour >= 15 || hour < 4;
                      final wirdCat = categories.firstWhere(
                        (c) => c.type == (isEveningTime ? AzkarCategoryType.evening : AzkarCategoryType.morning),
                        orElse: () => categories[0],
                      );
                      _openCategory(context, wirdCat);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'متابعة الورد اليومي',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF07090E),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: Color(0xFF07090E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Progress Bar (60%)
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0.60,
                        minHeight: 8,
                        backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1B2332),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD56B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '60%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLight ? const Color(0xFF0F172A) : const Color(0xFFFFD56B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats Row (12 تم اليوم | 20 المتبقي | 32 إجمالي الأذكار)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('تم اليوم', '12', Icons.check_circle_outline_rounded, isLight),
                  _buildMiniStat('المتبقي', '20', Icons.timelapse_rounded, isLight),
                  _buildMiniStat('إجمالي الأذكار', '32', Icons.format_list_numbered_rounded, isLight),
                ],
              ),
            ],
          ),
        );

        final reminderCard = Container(
          height: 175,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Mosque night image
                Image.asset(
                  'assets/azkar_categories.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0A0F18),
                  ),
                ),

                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF07090E).withValues(alpha: 0.95),
                        const Color(0xFF07090E).withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),

                // Reminder Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'تذكير اليوم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD56B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.nights_stay_outlined,
                            size: 16,
                            color: Color(0xFFFFD56B),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '«فَاذْكُرُونِي أَذْكُرْكُمْ»',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(البقرة: 152)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              color: const Color(0xFF8E9BAE),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              wirdCard,
              const SizedBox(height: 12),
              reminderCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: wirdCard),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: reminderCard),
          ],
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, bool isLight) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFFFFD56B),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 4. 6 Distinct Color-Coded Categories Grid matching screenshot
  Widget _buildCategoriesGrid(
      BuildContext context, List<AzkarCategoryMeta> categories, bool isLight) {
    final customCards = [
      {
        'type': AzkarCategoryType.wakingUp,
        'title': 'أذكار الاستيقاظ',
        'count': '9 ذكر',
        'desc': 'ما يقال عند الاستيقاظ',
        'icon': Icons.favorite_rounded,
        'bg': const Color(0xFF1E0E18), // Deep Burgundy / Maroon
        'accent': const Color(0xFFF43F5E),
      },
      {
        'type': AzkarCategoryType.general,
        'title': 'أذكار عامة',
        'count': '50 ذكر',
        'desc': 'في كل وقت وحال',
        'icon': Icons.auto_stories_rounded,
        'bg': const Color(0xFF0A1828), // Deep Royal Navy
        'accent': const Color(0xFF38BDF8),
      },
      {
        'type': AzkarCategoryType.afterPrayer,
        'title': 'أذكار بعد الصلاة',
        'count': '15 ذكر',
        'desc': 'أذكار مأثورة بعد كل صلاة',
        'icon': Icons.mosque_rounded,
        'bg': const Color(0xFF061E1A), // Deep Emerald Green
        'accent': const Color(0xFF2DD4BF),
      },
      {
        'type': AzkarCategoryType.morning,
        'title': 'أذكار الصباح',
        'count': '25 ذكر',
        'desc': 'بداية يومك بذكر الله',
        'icon': Icons.wb_sunny_rounded,
        'bg': const Color(0xFF241C0A), // Warm Golden Amber
        'accent': const Color(0xFFFFD56B),
      },
      {
        'type': AzkarCategoryType.evening,
        'title': 'أذكار المساء',
        'count': '24 ذكر',
        'desc': 'حصنك في نهاية يومك',
        'icon': Icons.nightlight_round,
        'bg': const Color(0xFF0D172A), // Deep Night Midnight
        'accent': const Color(0xFF60A5FA),
      },
      {
        'type': AzkarCategoryType.sleep,
        'title': 'أذكار النوم',
        'count': '12 ذكر',
        'desc': 'أذكار قبل النوم وبعده',
        'icon': Icons.bedtime_rounded,
        'bg': const Color(0xFF181028), // Deep Violet / Indigo
        'accent': const Color(0xFFA78BFA),
      },
    ];

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        int crossAxisCount = 2;
        if (width >= 1100) {
          crossAxisCount = 6;
        } else if (width >= 750) {
          crossAxisCount = 3;
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.95,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = customCards[index];
              final catType = item['type'] as AzkarCategoryType;
              final category = categories.firstWhere(
                (c) => c.type == catType,
                orElse: () => categories[0],
              );
              final bg = isLight ? (item['bg'] as Color).withValues(alpha: 0.08) : item['bg'] as Color;
              final accent = item['accent'] as Color;

              return InkWell(
                onTap: () => _openCategory(context, category),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: isLight ? 0.3 : 0.25),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon Circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.18),
                        ),
                        child: Center(
                          child: Icon(
                            item['icon'] as IconData,
                            color: accent,
                            size: 22,
                          ),
                        ),
                      ),

                      // Titles
                      Column(
                        children: [
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF151C28),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item['count'] as String,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Desc & Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['desc'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.5,
                                color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1B2332),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              size: 16,
                              color: Color(0xFFFFD56B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: customCards.length,
          ),
        );
      },
    );
  }

  /// 5. Bottom Dual Cards: [المفضلة] and [آخر ما قرأت]
  Widget _buildBottomDualCards(
      BuildContext context, List<AzkarCategoryMeta> categories, bool isLight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final morningCat = categories.firstWhere(
          (c) => c.type == AzkarCategoryType.morning,
          orElse: () => categories[0],
        );
        final eveningCat = categories.firstWhere(
          (c) => c.type == AzkarCategoryType.evening,
          orElse: () => categories.length > 1 ? categories[1] : categories[0],
        );

        final favCard = InkWell(
          onTap: () => _openCategory(context, morningCat),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0D121B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF151C28),
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFFFFD56B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المفضلة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    Text(
                      'أذكارك المحفوظة في مكان واحد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        final lastReadCard = InkWell(
          onTap: () => _openCategory(context, eveningCat),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0D121B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF151C28),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFFFD56B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آخر ما قرأت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    Text(
                      'تابع من حيث توقفت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              favCard,
              const SizedBox(height: 10),
              lastReadCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: favCard),
            const SizedBox(width: 14),
            Expanded(child: lastReadCard),
          ],
        );
      },
    );
  }
}