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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Navigation Bar: [< Back, Bookmark] | [Share, Search, Settings]
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildTopNavBar(context, surah, isFav),
                  ),
                ),

                // 2. Main Hero Card (Clean, elegant, non-overlapping design)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildMainHeroCard(context, surah),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 3. 4 Action Buttons Grid: [الاستماع, التفسير, حفظ السورة, مشاركة]
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildFourActionsGrid(context, surah, isFav),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 4. Surah Information Grid Card: [معلومات السورة: 4 Stats]
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildSurahInfoCard(surah),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 5. Quranic Banner: [اقرأ باسم ربك الذي خلق]
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildIqraBanner(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 6. About Surah Card: [نبذة عن السورة]
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                    child: _buildAboutSurahCard(surah),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Top Navigation Bar
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
            const SizedBox(width: 8),
            _buildCircularIconButton(
              icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFav ? const Color(0xFFFFD56B) : const Color(0xFFCBD5E1),
              onTap: () => _storage.toggleFavorite(surah.number),
            ),
          ],
        ),

        // Right: Share + Search + Reader
        Row(
          children: [
            _buildCircularIconButton(
              icon: Icons.share_outlined,
              onTap: () {
                Clipboard.setData(ClipboardData(text: 'سورة ${surah.nameArabic} - تطبيق رفيق'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF151C28),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: const Text(
                      'تم نسخ مشاركة السورة بنجاح',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
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
    Color color = const Color(0xFFCBD5E1),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131B26).withValues(alpha: 0.8),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  /// 2. Main Hero Cinematic Banner (Clean, centered, no colliding text)
  Widget _buildMainHeroCard(BuildContext context, SurahMeta surah) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFFFD56B).withValues(alpha: 0.1),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Artwork
            Positioned.fill(
              child: Image.asset(
                'assets/quran_viewer_left_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/home_hero_mosque.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F1722)),
                ),
              ),
            ),

            // Dark gradient overlay for ultra-crisp text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF070B11).withValues(alpha: 0.85),
                      const Color(0xFF0D131E).withValues(alpha: 0.92),
                      const Color(0xFF070B11).withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),

            // Content Column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Star Emblem
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 20, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.6)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('❖ سورة ❖', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Container(width: 20, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.6)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Surah Name (Large, clear Amiri calligraphy)
                  Text(
                    surah.nameArabic,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFD56B),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),

                  // English transliteration
                  Text(
                    surah.nameEnglish,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Meta Pills Row: [مكية | 7 آيات | رقم 1]
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeroMetaBadge(surah.isMeccan ? 'مكية' : 'مدنية'),
                      const SizedBox(width: 8),
                      _buildHeroMetaBadge('${surah.ayahCount} آيات'),
                      const SizedBox(width: 8),
                      _buildHeroMetaBadge('سورة رقم ${surah.number}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // "ابدأ القراءة" Glowing Golden Action Button
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
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: Color(0xFF070B11),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ابدأ القراءة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF070B11),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: Color(0xFF070B11),
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

  Widget _buildHeroMetaBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF151C28).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD56B),
        ),
      ),
    );
  }

  /// 3. 4 Action Buttons Grid: [الاستماع, التفسير, حفظ السورة, مشاركة]
  Widget _buildFourActionsGrid(BuildContext context, SurahMeta surah, bool isFav) {
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
      onTap: () => _storage.toggleFavorite(surah.number),
    );

    final btnShare = _buildActionCard(
      icon: Icons.share_outlined,
      title: 'مشاركة',
      subtitle: 'شارك السورة',
      onTap: () {
        Clipboard.setData(ClipboardData(text: 'سورة ${surah.nameArabic} - رفيق المسلم'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF151C28),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text(
              'تم نسخ مشاركة السورة بنجاح',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
          ),
        );
      },
    );

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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1722).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF162130),
                border: Border.all(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: const Color(0xFFFFD56B)),
              ),
            ),
            const SizedBox(width: 10),
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
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

  /// 4. Surah Information Grid Card: [معلومات السورة]
  Widget _buildSurahInfoCard(SurahMeta surah) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'معلومات السورة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFFFFD56B),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Proportional Stat Pills (RTL layout)
          Row(
            children: [
              _buildStatPill('ترتيبها بالمصحف', _toArabicOrdinal(surah.number), Icons.menu_book_rounded),
              const SizedBox(width: 8),
              _buildStatPill('مكان النزول', surah.isMeccan ? 'مكية' : 'مدنية', Icons.mosque_rounded),
              const SizedBox(width: 8),
              _buildStatPill('رقم السورة', '# ${surah.number}', Icons.tag_rounded),
              const SizedBox(width: 8),
              _buildStatPill('عدد الآيات', '${surah.ayahCount}', Icons.format_list_numbered_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF131B26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: const Color(0xFFFFD56B)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
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
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Iqra Quranic Banner (Without duplicated text on top of graphic)
  Widget _buildIqraBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '﴿ اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD56B),
              height: 1.4,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '« سورة العلق : الآية 1 »',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. About Surah Card: [نبذة عن السورة]
  Widget _buildAboutSurahCard(SurahMeta surah) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'نبذة عن السورة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Color(0xFFFFD56B),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'سورة ${surah.nameArabic} هي السورة رقم (${surah.number}) في المصحف الشريف، وهي سورة ${surah.isMeccan ? 'مكية نزلت قبل الهجرة النبوية المباركة' : 'مدنية نزلت بعد الهجرة النبوية المباركة'}، ويبلغ عدد آياتها ${surah.ayahCount} آيات كريمة من كلام الله العظيم.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              height: 1.6,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}
