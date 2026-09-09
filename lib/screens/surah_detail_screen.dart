import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quran_models.dart';
import '../services/quran_storage_service.dart';
import '../services/audio_quran_service.dart';
import '../widgets/iqra_tafsir_sheet.dart';
import 'surah_viewer_screen.dart';

class SurahDetailScreen extends StatefulWidget {
  final SurahMeta surah;

  const SurahDetailScreen({
    super.key,
    required this.surah,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranStorageService _storage = QuranStorageService();
  final AudioQuranService _audioService = AudioQuranService();

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _storage.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  String _toArabicOrdinal(int num) {
    const ordinals = [
      '', 'الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة', 'السادسة', 'السابعة', 'الثامنة', 'التاسعة', 'العاشرة',
      'الحادية عشرة', 'الثانية عشرة', 'الثالثة عشرة', 'الرابعة عشرة', 'الخامسة عشرة', 'السادسة عشرة', 'السابعة عشرة',
      'الثامنة عشرة', 'التاسعة عشرة', 'العشرون', 'الحادية والعشرون', 'الثانية والعشرون', 'الثالثة والعشرون', 'الرابعة والعشرون',
      'الخامسة والعشرون', 'السادسة والعشرون', 'السبعة والعشرون', 'الثامنة والعشرون', 'التاسعة والعشرون', 'الثلاثون'
    ];
    if (num > 0 && num < ordinals.length) {
      return ordinals[num];
    }
    return '$num في المصحف';
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final isFav = _storage.isFavorite(surah.number);

    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. Top Navigation & Action Icons Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: _buildTopNavBar(context, surah, isFav),
                      ),
                    ),

                    // 2. Main Hero Cinematic Banner (Left Mosque/Quran Artwork + Center Calligraphy + Right Ayah)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildMainHeroCard(context, surah),
                      ),
                    ),

                    // 3. 4 Action Buttons Row: [الاستماع, التفسير, حفظ السورة, مشاركة]
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildFourActionsRow(context, surah, isFav),
                      ),
                    ),

                    // 4. Dual Section: [اقرأ باسم ربك Banner] + [معلومات السورة 4 Stats Grid]
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildInfoAndIqraRow(surah),
                      ),
                    ),

                    // 5. Bottom Card: [نبذة عن السورة]
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        child: _buildAboutSurahCard(surah),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 1. Top Header Actions matching screenshot
  Widget _buildTopNavBar(BuildContext context, SurahMeta surah, bool isFav) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back button + Bookmark button
        Row(
          children: [
            _buildCircularIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            _buildCircularIconButton(
              icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFav ? const Color(0xFFFFD56B) : const Color(0xFF8E9BAE),
              onTap: () => _storage.toggleFavorite(surah.number),
            ),
          ],
        ),

        // Right: Share + Search + Settings
        Row(
          children: [
            _buildCircularIconButton(
              icon: Icons.share_outlined,
              onTap: () {
                Clipboard.setData(ClipboardData(text: 'سورة ${surah.nameArabic} - تطبيق رفيق'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم نسخ مشاركة السورة بنجاح',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: Color(0xFF1E293B),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _buildCircularIconButton(
              icon: Icons.search_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahViewerScreen(
                      surahNumber: surah.number,
                      surahName: surah.nameArabic,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _buildCircularIconButton(
              icon: Icons.settings_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahViewerScreen(
                      surahNumber: surah.number,
                      surahName: surah.nameArabic,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF8E9BAE),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0F1724),
          border: Border.all(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  /// 2. Main Hero Cinematic Banner matching screenshot
  Widget _buildMainHeroCard(BuildContext context, SurahMeta surah) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFD56B).withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Left Sunset Mosque & Quran Artwork
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 400,
              child: Image.asset(
                'assets/surah_info_left_artwork.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/surah_info_quran_stand.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/home_hero_mosque.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Smooth Deep Gradient from dark background to center & right
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF080C14).withValues(alpha: 0.75),
                    const Color(0xFF080C14).withValues(alpha: 0.96),
                    const Color(0xFF080C14),
                  ],
                  stops: const [0.0, 0.35, 0.60, 1.0],
                ),
              ),
            ),

            // Right Quran Ayah: "كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ (ص : 29)"
            Positioned(
              right: 32,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'مُّبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '« ص : 29 »',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD56B).withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center: Ornate Surah Emblem, Title, Meta, and "ابدأ القراءة" Gold Button
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ornate Emblem Icon
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFFFFD56B),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'سورة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF8E9BAE),
                    ),
                  ),
                  Text(
                    surah.nameArabic,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    surah.nameEnglish,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFF8E9BAE),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surah.isMeccan ? 'مكية' : 'مدنية',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD56B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFFFFD56B), fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${surah.ayahCount} آيات',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD56B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Button: ابدأ القراءة
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahViewerScreen(
                            surahNumber: surah.number,
                            surahName: surah.nameArabic,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: Color(0xFF07090E),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ابدأ القراءة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF07090E),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: Color(0xFF07090E),
                          ),
                        ],
                      ),
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

  /// 3. 4 Action Buttons Row matching screenshot: [الاستماع, التفسير, حفظ السورة, مشاركة]
  Widget _buildFourActionsRow(BuildContext context, SurahMeta surah, bool isFav) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final btnListen = _buildActionCard(
          icon: Icons.headphones_outlined,
          title: 'الاستماع',
          subtitle: 'استمع لتلاوة السورة',
          onTap: () {
            _audioService.playSurah(surah.number);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SurahViewerScreen(
                  surahNumber: surah.number,
                  surahName: surah.nameArabic,
                ),
              ),
            );
          },
        );

        final btnTafsir = _buildActionCard(
          icon: Icons.menu_book_outlined,
          title: 'التفسير',
          subtitle: 'معاني وآيات السورة',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => IqraTafsirSheet(
                surahNumber: surah.number,
                surahName: surah.nameArabic,
                ayahNumber: 1,
                ayahText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              ),
            );
          },
        );

        final btnSave = _buildActionCard(
          icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          title: 'حفظ السورة',
          subtitle: isFav ? 'تم الحفظ في المفضلة' : 'أضف إلى محفوظاتك',
          iconColor: isFav ? const Color(0xFFFFD56B) : const Color(0xFFFFD56B),
          onTap: () => _storage.toggleFavorite(surah.number),
        );

        final btnShare = _buildActionCard(
          icon: Icons.share_outlined,
          title: 'مشاركة',
          subtitle: 'شارك السورة',
          onTap: () {
            Clipboard.setData(ClipboardData(text: 'سورة ${surah.nameArabic} - رفيق المسلم'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم نسخ رابط السورة للمشاركة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Color(0xFF1E293B),
              ),
            );
          },
        );

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: btnListen),
                  const SizedBox(width: 10),
                  Expanded(child: btnTafsir),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: btnSave),
                  const SizedBox(width: 10),
                  Expanded(child: btnShare),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: btnListen),
            const SizedBox(width: 12),
            Expanded(child: btnTafsir),
            const SizedBox(width: 12),
            Expanded(child: btnSave),
            const SizedBox(width: 12),
            Expanded(child: btnShare),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFFFD56B),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D131E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: Color(0xFF8E9BAE),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF151C28),
                border: Border.all(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.25),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Dual Row: [Iqra banner on Left] + [معلومات السورة 4 Stats Grid on Right]
  Widget _buildInfoAndIqraRow(SurahMeta surah) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        // Iqra Banner matching screenshot
        final iqraBanner = Container(
          height: 145,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/surah_info_iqra_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/home_hero_mosque.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF07090E).withValues(alpha: 0.85),
                        const Color(0xFF07090E).withValues(alpha: 0.40),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'اقْرَأْ بِاسْمِ رَبِّكَ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD56B),
                        ),
                      ),
                      Text(
                        'الَّذِي خَلَقَ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '« العلق : 1 »',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: Color(0xFF8E9BAE),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        // Stats Box: معلومات السورة
        final statsBox = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D131E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFFFD56B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'معلومات السورة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatPill('عدد الآيات', '${surah.ayahCount}', Icons.format_list_numbered_rounded),
                  const SizedBox(width: 8),
                  _buildStatPill('رقم السورة', '${surah.number}', Icons.tag_rounded),
                  const SizedBox(width: 8),
                  _buildStatPill('مكان النزول', surah.isMeccan ? 'مكية' : 'مدنية', Icons.mosque_rounded),
                  const SizedBox(width: 8),
                  _buildStatPill('ترتيبها في المصحف', _toArabicOrdinal(surah.number), Icons.menu_book_rounded),
                ],
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              statsBox,
              const SizedBox(height: 12),
              iqraBanner,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: iqraBanner),
            const SizedBox(width: 14),
            Expanded(flex: 7, child: statsBox),
          ],
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF131B28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: const Color(0xFFFFD56B)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9.5,
                color: Color(0xFF8E9BAE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Bottom Card: [نبذة عن السورة] matching screenshot
  Widget _buildAboutSurahCard(SurahMeta surah) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left artwork quote box
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 130,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/surah_info_quote_banner.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF151C28),
                    ),
                  ),
                  Container(
                    color: const Color(0xFF07090E).withValues(alpha: 0.45),
                  ),
                  const Center(
                    child: Text(
                      '"وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD56B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Right About Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Color(0xFFFFD56B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'نبذة عن السورة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'سورة ${surah.nameArabic} هي السورة رقم (${surah.number}) في المصحف الشريف، وهي سورة ${surah.isMeccan ? 'مكية نزلت قبل الهجرة' : 'مدنية نزلت بعد الهجرة'}، وتتضمن ${surah.ayahCount} آيات من كلام الله العظيم.',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    height: 1.6,
                    color: Color(0xFFCBD5E1),
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
