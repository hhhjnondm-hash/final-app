import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../models/quran_models.dart';
import '../services/quran_storage_service.dart';
import '../services/global_audio_manager.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/surah_card.dart';
import 'surah_detail_screen.dart';
import 'surah_viewer_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  final QuranStorageService _storage = QuranStorageService();
  final GlobalAudioManager _audioManager = GlobalAudioManager();
  late List<SurahMeta> _allSurahs;

  int _selectedNavTab = 0; // 0: السور, 1: الأجزاء, 2: العلامات, 3: الختمة, 4: الإحصائيات
  int _selectedFilterIndex = 0; // 0: الكل, 1: مكية, 2: مدنية, 3: المفضلة
  String _searchQuery = '';
  String _sortBy = 'quran'; // quran, alpha, ayahs, progress

  @override
  void initState() {
    super.initState();
    _allSurahs = QuranMetadataProvider.getAllSurahs();
    _storage.addListener(_onStorageUpdate);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  /// Play surah using GlobalAudioManager
  Future<void> _playSurah(int surahNumber, String surahName) async {
    try {
      // Use AudioQuranService for Quran playback
      final audioQuranService = AudioQuranService();
      await audioQuranService.playSurah(surahNumber);
      
      debugPrint('🎵 Playing Surah $surahNumber: $surahName');
    } catch (e) {
      debugPrint('❌ Error playing surah: $e');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تشغيل السورة: $e')),
        );
      }
    }
  }

  List<SurahMeta> _getFilteredSurahs() {
    var list = List<SurahMeta>.from(_allSurahs);

    // Apply Tab Filter
    if (_selectedFilterIndex == 1) {
      list = list.where((s) => s.isMeccan).toList();
    } else if (_selectedFilterIndex == 2) {
      list = list.where((s) => !s.isMeccan).toList();
    } else if (_selectedFilterIndex == 3) {
      list = list.where((s) => _storage.isFavorite(s.number)).toList();
    }

    // Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final matchAr = s.nameArabic.contains(q);
        final matchEn = s.nameEnglish.toLowerCase().contains(q);
        final matchNum = '${s.number}' == q;
        final matchAyahs = '${s.ayahCount}' == q;
        final matchType = (s.isMeccan ? 'مكية' : 'مدنية').contains(q);
        return matchAr || matchEn || matchNum || matchAyahs || matchType;
      }).toList();
    }

    // Apply Sorting
    if (_sortBy == 'alpha') {
      list.sort((a, b) => a.nameArabic.compareTo(b.nameArabic));
    } else if (_sortBy == 'ayahs') {
      list.sort((a, b) => b.ayahCount.compareTo(a.ayahCount));
    } else if (_sortBy == 'progress') {
      list.sort((a, b) => b.number.compareTo(a.number));
    } else {
      list.sort((a, b) => a.number.compareTo(b.number));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = _getFilteredSurahs();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Luxury Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacingL,
                    DesignSystem.spacingM,
                    DesignSystem.spacingL,
                    DesignSystem.spacingS,
                  ),
                  child: _buildTopHeader(context),
                ),
              ),

              // Cinematic Quran Hero Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildHeroSection(context),
                ),
              ),

              // Continue Reading Spotlight Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildContinueReadingSpotlight(context),
                ),
              ),

              // Category Navigation Tabs (السور • الأجزاء • العلامات • الختمة • الإحصائيات)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildCategoryTabs(),
                ),
              ),

              // Tab View Content Rendering
              if (_selectedNavTab == 0) ...[
                // Search & Filter Bar for Surahs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spacingL,
                      DesignSystem.spacingS,
                      DesignSystem.spacingL,
                      DesignSystem.spacingM,
                    ),
                    child: _buildSearchAndFilterControls(),
                  ),
                ),

                // Responsive 114 Surahs Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                  sliver: _buildSurahsGrid(filteredSurahs),
                ),
              ] else if (_selectedNavTab == 1) ...[
                // Juzs View
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: _buildJuzsView(),
                  ),
                ),
              ] else if (_selectedNavTab == 2) ...[
                // Bookmarks View
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: _buildBookmarksView(),
                  ),
                ),
              ] else if (_selectedNavTab == 3) ...[
                // Khatmah View
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: _buildKhatmahView(),
                  ),
                ),
              ] else if (_selectedNavTab == 4) ...[
                // Statistics View
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: _buildStatsView(),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: DesignSystem.goldGradient,
                boxShadow: DesignSystem.goldGlow,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: DesignSystem.bgDarkest,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'كلام الله • ١١٤ سورة • ٣٠ جزء',
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
            _buildHeaderIconButton(
              icon: Icons.bookmark_added_rounded,
              badgeCount: _storage.bookmarks.length,
              onTap: () => setState(() => _selectedNavTab = 2),
            ),
            const SizedBox(width: 8),
            _buildHeaderIconButton(
              icon: Icons.pie_chart_outline_rounded,
              onTap: () => setState(() => _selectedNavTab = 4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DesignSystem.bgCard.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: DesignSystem.goldLight, size: 20),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: DesignSystem.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: DesignSystem.bgDarkest,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2042),
            const Color(0xFF1E3A8A).withValues(alpha: 0.6),
            DesignSystem.bgDarkest,
          ],
        ),
        border: Border.all(
          color: DesignSystem.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.electricBlue.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Starry Decorative Art
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            child: Image.asset(
              'assets/quran_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Deep Dark Gradient Overlay for optimal contrast
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  DesignSystem.bgDarkest.withValues(alpha: 0.95),
                  DesignSystem.bgDarkest.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Hero Content
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignSystem.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: DesignSystem.goldLight, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'نورٌ وهداية للعالمين',
                        style: TextStyle(
                          color: DesignSystem.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '١١٤ سورة • ٦٢٣٦ آية • ٣٠ جزء',
                  style: TextStyle(
                    color: DesignSystem.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.gold,
                    foregroundColor: DesignSystem.bgDarkest,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SurahViewerScreen(
                          surahNumber: 1,
                          surahName: 'الفاتحة',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(
                    'ابدأ القراءة والتلاوة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingSpotlight(BuildContext context) {
    final prog = _storage.readingProgress;

    return GlassCard(
      borderRadius: DesignSystem.radiusLarge,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahViewerScreen(
              surahNumber: prog.lastSurahNumber,
              surahName: prog.lastSurahName,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: DesignSystem.goldGradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                  boxShadow: DesignSystem.goldGlow,
                ),
                child: const Icon(
                  Icons.bookmark_added_rounded,
                  color: DesignSystem.bgDarkest,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'متابعة القراءة',
                          style: TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(prog.progressPercentage * 100).toInt()}% منجز',
                          style: const TextStyle(
                            color: DesignSystem.cyanAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سورة ${prog.lastSurahName} — الآية ${prog.lastAyahNumber}',
                      style: const TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'الجزء ${prog.lastJuz}',
                      style: const TextStyle(
                        color: DesignSystem.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prog.progressPercentage,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = [
      {'title': 'السور (١١٤)', 'icon': Icons.grid_view_rounded},
      {'title': 'الأجزاء (٣٠)', 'icon': Icons.auto_stories_rounded},
      {'title': 'العلامات', 'icon': Icons.bookmarks_rounded},
      {'title': 'الختمة', 'icon': Icons.calendar_month_rounded},
      {'title': 'الإحصائيات', 'icon': Icons.bar_chart_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedNavTab == i;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedNavTab = i),
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? DesignSystem.goldGradient : null,
                  color: isSelected ? null : DesignSystem.bgCard.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? DesignSystem.gold
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: isSelected ? DesignSystem.goldGlow : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      size: 16,
                      color: isSelected ? DesignSystem.bgDarkest : DesignSystem.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i]['title'] as String,
                      style: TextStyle(
                        color: isSelected ? DesignSystem.bgDarkest : DesignSystem.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchAndFilterControls() {
    return Column(
      children: [
        // Live Search Input Box
        Container(
          decoration: BoxDecoration(
            color: DesignSystem.bgCard.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: DesignSystem.textWhite),
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم السورة، رقمها، مكية/مدنية...',
              hintStyle: const TextStyle(color: DesignSystem.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: DesignSystem.gold),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: DesignSystem.textMuted),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Filter Chips & Sorting Menu Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Filter Chips
            Row(
              children: [
                _buildFilterChip('الكل', 0),
                const SizedBox(width: 6),
                _buildFilterChip('مكية', 1),
                const SizedBox(width: 6),
                _buildFilterChip('مدنية', 2),
                const SizedBox(width: 6),
                _buildFilterChip('المفضلة', 3),
              ],
            ),

            // Sorting Popup Button
            PopupMenuButton<String>(
              initialValue: _sortBy,
              onSelected: (val) => setState(() => _sortBy = val),
              icon: const Icon(Icons.sort_rounded, color: DesignSystem.goldLight, size: 22),
              color: DesignSystem.bgCard,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'quran', child: Text('ترتيب المصحف', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'alpha', child: Text('أبجدياً', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'ayahs', child: Text('عدد الآيات', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'progress', child: Text('نسبة الإنجاز', style: TextStyle(color: Colors.white))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignSystem.gold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          border: Border.all(
            color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? DesignSystem.goldLight : DesignSystem.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahsGrid(List<SurahMeta> surahs) {
    if (surahs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 60, color: DesignSystem.gold.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'لم يتم العثور على نتائج مطابقة',
                  style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'جرب البحث باسم آخر أو تغيير الفلتر',
                  style: TextStyle(color: DesignSystem.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Dynamic Column Count: 2 Mobile, 3 Tablet, 4 Desktop
        final width = constraints.crossAxisExtent;
        int crossAxisCount = 2;
        if (width >= 1000) {
          crossAxisCount = 4;
        } else if (width >= 650) {
          crossAxisCount = 3;
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final surah = surahs[index];
              final isFav = _storage.isFavorite(surah.number);

              return SurahCard(
                surah: surah,
                isFavorite: isFav,
                progress: surah.number == _storage.readingProgress.lastSurahNumber
                    ? _storage.readingProgress.progressPercentage
                    : (surah.number < _storage.readingProgress.lastSurahNumber ? 1.0 : 0.0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(surah: surah),
                    ),
                  );
                },
                onFavoriteToggle: () => _storage.toggleFavorite(surah.number),
                onPlayAudio: () {
                  // Play audio using GlobalAudioManager
                  _playSurah(surah.number, surah.nameArabic);
                  
                  // Also navigate to surah viewer
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
            },
            childCount: surahs.length,
          ),
        );
      },
    );
  }

  Widget _buildJuzsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أجزاء القرآن الكريم (٣٠ جزء)',
          style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 30,
          itemBuilder: (context, index) {
            final juzNum = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                borderRadius: DesignSystem.radiusMedium,
                padding: const EdgeInsets.all(14),
                onTap: () {
                  final surahForJuz = _allSurahs.firstWhere((s) => s.juzNumber == juzNum, orElse: () => _allSurahs.first);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahViewerScreen(
                        surahNumber: surahForJuz.number,
                        surahName: surahForJuz.nameArabic,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignSystem.gold.withValues(alpha: 0.15),
                        border: Border.all(color: DesignSystem.gold),
                      ),
                      child: Center(
                        child: Text(
                          '$juzNum',
                          style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الجزء $juzNum',
                            style: const TextStyle(color: DesignSystem.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'يبدأ من صفحة ${(index * 20) + 1}',
                            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: DesignSystem.goldLight, size: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookmarksView() {
    final bookmarks = _storage.bookmarks;
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.bookmark_border_rounded, size: 60, color: DesignSystem.gold.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              const Text(
                'لم تحفظ أي علامات مرجعية بعد',
                style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك حفظ أي آية أثناء القراءة للرجوع إليها لاحقاً بسهولة',
                textAlign: TextAlign.center,
                style: TextStyle(color: DesignSystem.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'العلامات المرجعية (${bookmarks.length})',
              style: const TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bm = bookmarks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                borderRadius: DesignSystem.radiusLarge,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahViewerScreen(
                        surahNumber: bm.surahNumber,
                        surahName: bm.surahName,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سورة ${bm.surahName} — الآية ${bm.ayahNumber}',
                          style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: DesignSystem.textMuted, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _storage.removeBookmark(bm.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bm.ayahSnippet,
                      style: const TextStyle(color: DesignSystem.textWhite, fontSize: 14, height: 1.5),
                    ),
                    if (bm.note != null && bm.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ملاحظة: ${bm.note}',
                        style: const TextStyle(color: DesignSystem.cyanAccent, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKhatmahView() {
    final khatmah = _storage.khatmahPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'خطة ختم القرآن الكريم',
          style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        GlassCard(
          borderRadius: DesignSystem.radiusLarge,
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          hasGlow: true,
          glowColor: DesignSystem.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ختمة الـ ٣٠ يوماً',
                        style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'اليوم ${khatmah.currentDay} من ${khatmah.totalDays}',
                        style: const TextStyle(color: DesignSystem.goldLight, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DesignSystem.gold.withValues(alpha: 0.2),
                      border: Border.all(color: DesignSystem.gold),
                    ),
                    child: Text(
                      '${(khatmah.progress * 100).toInt()}%',
                      style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: khatmah.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: DesignSystem.cyanAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ورد اليوم المقرر:',
                            style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                          ),
                          Text(
                            'الجزء ${khatmah.todayTargetJuz} كاملاً',
                            style: const TextStyle(color: DesignSystem.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.gold,
                        foregroundColor: DesignSystem.bgDarkest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                      ),
                      onPressed: () {
                        final surah = _allSurahs.firstWhere((s) => s.juzNumber == khatmah.todayTargetJuz, orElse: () => _allSurahs.first);
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
                      child: const Text('ابدأ ورد اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إحصائيات القراءة والتلاوة',
          style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: DesignSystem.radiusMedium,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.menu_book_rounded, color: DesignSystem.gold, size: 26),
                    SizedBox(height: 8),
                    Text('١٢ سورة', style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('تمت قراءتها', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                borderRadius: DesignSystem.radiusMedium,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: DesignSystem.cyanAccent, size: 26),
                    SizedBox(height: 8),
                    Text('١,٦٨٠ آية', style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('آيات مقروءة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: DesignSystem.radiusMedium,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 26),
                    SizedBox(height: 8),
                    Text('٨ أيام', style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('سلسلة القراءة المتواصلة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                borderRadius: DesignSystem.radiusMedium,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.timer_rounded, color: DesignSystem.electricBlue, size: 26),
                    SizedBox(height: 8),
                    Text('٤.٥ ساعات', style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('إجمالي وقت القراءة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


