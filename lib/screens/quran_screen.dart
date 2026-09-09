import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../models/quran_models.dart';
import '../services/quran_storage_service.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';
import '../widgets/surah_card.dart';
import 'surah_detail_screen.dart';
import 'surah_viewer_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final QuranStorageService _storage = QuranStorageService();
  final AudioQuranService _audioQuranService = AudioQuranService();
  late List<SurahMeta> _allSurahs;

  int _selectedTopTab = 0; // 0: القرآن الكريم, 1: المفضلة, 2: الختمة, 3: الإحصائيات
  int _selectedFilterIndex = 0; // 0: الكل, 1: مكية, 2: مدنية, 3: المفضلة
  String _searchQuery = '';
  int _activeSurahNumber = 2; // Default to Surah Al-Baqarah active highlight like screenshot

  @override
  void initState() {
    super.initState();
    _allSurahs = QuranMetadataProvider.getAllSurahs();
    _storage.addListener(_onStorageUpdate);
    _audioQuranService.addListener(_onAudioUpdate);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    _audioQuranService.removeListener(_onAudioUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _onAudioUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _playSurah(int surahNumber, String surahName) async {
    setState(() => _activeSurahNumber = surahNumber);
    try {
      await _audioQuranService.playSurah(surahNumber);
    } catch (e) {
      debugPrint('Error playing surah: $e');
    }
  }

  List<SurahMeta> _getFilteredSurahs() {
    var list = List<SurahMeta>.from(_allSurahs);

    // Apply Tab Filter (الكل, مكية, مدنية, المفضلة)
    if (_selectedFilterIndex == 1) {
      list = list.where((s) => s.isMeccan).toList();
    } else if (_selectedFilterIndex == 2) {
      list = list.where((s) => !s.isMeccan).toList();
    } else if (_selectedFilterIndex == 3) {
      list = list.where((s) => _storage.isFavorite(s.number)).toList();
    }

    // Apply Top Tab Filter if "المفضلة" is selected at top
    if (_selectedTopTab == 1) {
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

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = _getFilteredSurahs();
    final isLight = DesignSystem.isLightMode;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Top Royal Header Bar (Logo + Brand + Top 4 Segment Pills)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: _buildTopHeaderBar(isLight),
                ),
              ),

              // 2. Search & Filter Bar (Search input + Filter pills)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                  child: _buildSearchAndFiltersRow(isLight),
                ),
              ),

              // 3. Grid of Surah Cards (Matching exact royal screenshot)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: _buildSurahsGrid(filteredSurahs, isLight),
              ),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Bar: Logo & Brand on Left, [القرآن الكريم, المفضلة, الختمة, الإحصائيات] Pills on Right
  Widget _buildTopHeaderBar(bool isLight) {
    final topPills = [
      {'title': 'القرآن الكريم', 'icon': Icons.menu_book_rounded},
      {'title': 'المفضلة', 'icon': Icons.bookmark_border_rounded},
      {'title': 'الختمة', 'icon': Icons.tune_rounded},
      {'title': 'الإحصائيات', 'icon': Icons.bar_chart_rounded},
    ];

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

        // Top Navigation Segment Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(topPills.length, (index) {
              final isSelected = _selectedTopTab == index;
              final pill = topPills[index];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTopTab = index;
                      if (index == 1) _selectedFilterIndex = 3;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isLight ? const Color(0xFF0F172A) : const Color(0xFF241C10))
                          : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0E131C)),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD56B)
                            : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2)),
                        width: 1.1,
                      ),
                      boxShadow: isSelected && !isLight
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFD56B).withValues(alpha: 0.18),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pill['icon'] as IconData,
                          size: 15,
                          color: isSelected
                              ? const Color(0xFFFFD56B)
                              : (isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pill['title'] as String,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isLight ? Colors.white : const Color(0xFFFFD56B))
                                : (isLight ? const Color(0xFF475569) : const Color(0xFFA0AEC0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Search Input Box and Filter Chips (الكل, مكية, مدنية, المفضلة)
  Widget _buildSearchAndFiltersRow(bool isLight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final searchBox = Expanded(
          flex: isNarrow ? 0 : 1,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D121B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم السورة، القارئ، أو اكتب كلمة مفتاحية ...',
                hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF5A6678),
                  fontSize: 12.5,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
        );

        final filterChips = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterPill('الكل', 0, isLight),
            const SizedBox(width: 6),
            _buildFilterPill('مكية', 1, isLight),
            const SizedBox(width: 6),
            _buildFilterPill('مدنية', 2, isLight),
            const SizedBox(width: 6),
            _buildFilterPill('المفضلة', 3, isLight),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchBox,
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: filterChips,
              ),
            ],
          );
        }

        return Row(
          children: [
            searchBox,
            const SizedBox(width: 16),
            filterChips,
          ],
        );
      },
    );
  }

  Widget _buildFilterPill(String label, int index, bool isLight) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? const Color(0xFF0F172A) : const Color(0xFF241C10))
              : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0E131C)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD56B)
                : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFFC89B3C).withValues(alpha: 0.2)),
            width: 1,
          ),
          boxShadow: isSelected && !isLight
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? (isLight ? Colors.white : const Color(0xFFFFD56B))
                : (isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE)),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahsGrid(List<SurahMeta> surahs, bool isLight) {
    if (surahs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'لم يتم العثور على نتائج',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        int crossAxisCount = 1;
        double childAspectRatio = 1.35;

        if (width >= 1050) {
          crossAxisCount = 4; // 4 columns on large screens like screenshot
          childAspectRatio = 1.28;
        } else if (width >= 750) {
          crossAxisCount = 3;
          childAspectRatio = 1.25;
        } else if (width >= 480) {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final surah = surahs[index];
              final isFav = _storage.isFavorite(surah.number);
              final isSelected = surah.number == _activeSurahNumber;

              return SurahCard(
                surah: surah,
                isFavorite: isFav,
                isSelected: isSelected,
                progress: isSelected ? 0.45 : 0.0,
                onTap: () {
                  setState(() => _activeSurahNumber = surah.number);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(surah: surah),
                    ),
                  );
                },
                onFavoriteToggle: () => _storage.toggleFavorite(surah.number),
                onPlayAudio: () => _playSurah(surah.number, surah.nameArabic),
                onMoreOptions: () {
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
}
