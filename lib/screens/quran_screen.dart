import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/quran_models.dart';
import '../services/quran_storage_service.dart';
import '../services/audio_quran_service.dart';
import 'surah_viewer_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

enum SurahSortOrder { mushaf, revelation, ayahCount, alphabetical }

class _QuranScreenState extends State<QuranScreen> {
  final QuranStorageService _storage = QuranStorageService();
  final AudioQuranService _audioQuranService = AudioQuranService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late List<SurahMeta> _allSurahs;

  // Selected filter pill: 0: الكل, 1: مكية, 2: مدنية, 3: حسب الترتيب, 4: تصنيف ▾
  int _selectedPillIndex = 0;
  
  // Selected Sidebar category: 0: جميع السور (114), 1: المكية (86), 2: المدنية (28), 3: قصار السور (37), 4: أطول السور (10), 5: أكثر قراءة, 6: سور جزء عم (37), 7: سور الحزب (60)
  int _selectedSidebarCategory = 0;

  SurahSortOrder _sortOrder = SurahSortOrder.mushaf;
  int? _selectedJuz;
  String _searchQuery = '';
  int? _playingSurahNumber;

  @override
  void initState() {
    super.initState();
    _allSurahs = QuranMetadataProvider.getAllSurahs();
    _storage.addListener(_onStorageUpdate);
    _audioQuranService.addListener(_onAudioUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _storage.removeListener(_onStorageUpdate);
    _audioQuranService.removeListener(_onAudioUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _onAudioUpdate() {
    if (mounted) {
      setState(() {
        if (_audioQuranService.isPlaying) {
          _playingSurahNumber = _audioQuranService.currentSurah.number;
        } else {
          _playingSurahNumber = null;
        }
      });
    }
  }

  Future<void> _playSurah(int surahNumber) async {
    try {
      if (_playingSurahNumber == surahNumber) {
        await _audioQuranService.togglePlayPause();
      } else {
        setState(() => _playingSurahNumber = surahNumber);
        await _audioQuranService.playSurah(surahNumber);
      }
    } catch (e) {
      debugPrint('Error playing surah: $e');
    }
  }

  List<SurahMeta> _getFilteredSurahs() {
    var list = List<SurahMeta>.from(_allSurahs);

    // 1. Sidebar Category Filter
    switch (_selectedSidebarCategory) {
      case 1: // المكية
        list = list.where((s) => s.isMeccan).toList();
        break;
      case 2: // المدنية
        list = list.where((s) => !s.isMeccan).toList();
        break;
      case 3: // قصار السور (Number >= 78 to 114)
        list = list.where((s) => s.number >= 78).toList();
        break;
      case 4: // أطول السور (Top 10 by ayah count)
        final sortedByLength = List<SurahMeta>.from(_allSurahs)
          ..sort((a, b) => b.ayahCount.compareTo(a.ayahCount));
        final top10Numbers = sortedByLength.take(10).map((s) => s.number).toSet();
        list = list.where((s) => top10Numbers.contains(s.number)).toList();
        break;
      case 5: // أكثر قراءة (الفاتحة، البقرة، الكهف، يس، الواقعة، الملك، الإخلاص، الفلق، الناس)
        const popular = {1, 2, 18, 36, 55, 56, 67, 112, 113, 114};
        list = list.where((s) => popular.contains(s.number)).toList();
        break;
      case 6: // سور جزء عم (Surahs 78 to 114)
        list = list.where((s) => s.number >= 78).toList();
        break;
      case 7: // سور الحزب
        list = list.where((s) => s.number % 2 == 0).toList();
        break;
      case 0:
      default:
        break;
    }

    // 2. Top Pill Filter (الكل, مكية, مدنية)
    if (_selectedPillIndex == 1) {
      list = list.where((s) => s.isMeccan).toList();
    } else if (_selectedPillIndex == 2) {
      list = list.where((s) => !s.isMeccan).toList();
    }

    // 3. Juz filter if applied
    if (_selectedJuz != null) {
      list = list.where((s) => s.juzNumber == _selectedJuz).toList();
    }

    // 4. Search Query Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final matchAr = s.nameArabic.contains(q);
        final matchEn = s.nameEnglish.toLowerCase().contains(q);
        final matchNum = '${s.number}' == q;
        final matchAyahs = '${s.ayahCount}' == q;
        return matchAr || matchEn || matchNum || matchAyahs;
      }).toList();
    }

    // 5. Sorting
    switch (_sortOrder) {
      case SurahSortOrder.mushaf:
        list.sort((a, b) => a.number.compareTo(b.number));
        break;
      case SurahSortOrder.revelation:
        list.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
        break;
      case SurahSortOrder.ayahCount:
        list.sort((a, b) => b.ayahCount.compareTo(a.ayahCount));
        break;
      case SurahSortOrder.alphabetical:
        list.sort((a, b) => a.nameArabic.compareTo(b.nameArabic));
        break;
    }

    return list;
  }

  void _showReciterSelectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentReciter = _audioQuranService.currentReciter;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'اختر القارئ المفضل',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD56B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: RecitersData.reciters.length,
                    itemBuilder: (c, idx) {
                      final r = RecitersData.reciters[idx];
                      final isSelected = r.id == currentReciter.id;
                      return ListTile(
                        onTap: () {
                          _audioQuranService.selectReciter(r);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم اختيار القارئ: ${r.nameArabic}', style: const TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: const Color(0xFF1F293D),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B2433),
                          child: Icon(
                            Icons.person_rounded,
                            color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        title: Text(
                          r.nameArabic,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFFF6F8FA),
                          ),
                        ),
                        subtitle: Text(
                          r.style,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B))
                            : null,
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
  }

  void _showJuzSelectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الانتقال إلى الجزء (30 جزء)',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD56B),
                      ),
                    ),
                    if (_selectedJuz != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedJuz = null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('إلغاء التحديد', style: TextStyle(color: Color(0xFFE8D29A), fontFamily: 'Cairo')),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 30,
                    itemBuilder: (c, idx) {
                      final juzNum = idx + 1;
                      final isSelected = _selectedJuz == juzNum;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedJuz = juzNum);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFC89B3C) : const Color(0xFF161F2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFFC89B3C).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'جزء $juzNum',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF070B11) : const Color(0xFFF6F8FA),
                              ),
                            ),
                          ),
                        ),
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
  }

  void _showSortOrderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ترتيب السور',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD56B),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.format_list_numbered, color: Color(0xFFFFD56B)),
                  title: const Text('الترتيب المصحفي (1 إلى 114)', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  trailing: _sortOrder == SurahSortOrder.mushaf ? const Icon(Icons.check, color: Color(0xFFFFD56B)) : null,
                  onTap: () {
                    setState(() => _sortOrder = SurahSortOrder.mushaf);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu_rounded, color: Color(0xFFFFD56B)),
                  title: const Text('حسب ترتيب النزول', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  trailing: _sortOrder == SurahSortOrder.revelation ? const Icon(Icons.check, color: Color(0xFFFFD56B)) : null,
                  onTap: () {
                    setState(() => _sortOrder = SurahSortOrder.revelation);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.format_line_spacing_rounded, color: Color(0xFFFFD56B)),
                  title: const Text('حسب عدد الآيات (الأطول أولاً)', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  trailing: _sortOrder == SurahSortOrder.ayahCount ? const Icon(Icons.check, color: Color(0xFFFFD56B)) : null,
                  onTap: () {
                    setState(() => _sortOrder = SurahSortOrder.ayahCount);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha_rounded, color: Color(0xFFFFD56B)),
                  title: const Text('الترتيب الأبجدي (أ - ي)', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  trailing: _sortOrder == SurahSortOrder.alphabetical ? const Icon(Icons.check, color: Color(0xFFFFD56B)) : null,
                  onTap: () {
                    setState(() => _sortOrder = SurahSortOrder.alphabetical);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClassificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final categories = [
          {'title': 'جميع السور (114 سورة)', 'id': 0, 'icon': Icons.menu_book_rounded},
          {'title': 'السور المكية (86 سورة)', 'id': 1, 'icon': Icons.mosque_rounded},
          {'title': 'السور المدنية (28 سورة)', 'id': 2, 'icon': Icons.location_city_rounded},
          {'title': 'قصار السور (37 سورة)', 'id': 3, 'icon': Icons.auto_stories_rounded},
          {'title': 'أطول 10 سور', 'id': 4, 'icon': Icons.format_list_numbered_rounded},
          {'title': 'السور الأكثر قراءة وتلاوة', 'id': 5, 'icon': Icons.bar_chart_rounded},
          {'title': 'سور جزء عمّ', 'id': 6, 'icon': Icons.menu_book_outlined},
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تصنيف السور',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD56B),
                  ),
                ),
                const SizedBox(height: 12),
                ...categories.map((c) {
                  final id = c['id'] as int;
                  final isSelected = _selectedSidebarCategory == id;
                  return ListTile(
                    leading: Icon(c['icon'] as IconData, color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF94A3B8)),
                    title: Text(
                      c['title'] as String,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFFF6F8FA),
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFFD56B)) : null,
                    onTap: () {
                      setState(() {
                        _selectedSidebarCategory = id;
                        _selectedPillIndex = 4;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = _getFilteredSurahs();

    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Royal Hero Mosque Arch Banner with Navigation Icons
              _buildTopHeroMosqueBanner(context),

              const SizedBox(height: 10),

              // 2. Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBox(),
              ),

              const SizedBox(height: 10),

              // 3. Top Filter Pills Row (الكل, مكية, مدنية, حسب الترتيب, تصنيف)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilterPillsRow(),
              ),

              const SizedBox(height: 12),

              // 4. Main Body: Left Sidebar (Quran Navigation Categories) + Right Surah Cards List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Quran Categories Sidebar
                      _buildLeftCategorySidebar(),

                      const SizedBox(width: 10),

                      // Right Surahs List
                      Expanded(
                        child: filteredSurahs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off_rounded, color: Color(0xFF64748B), size: 48),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'لا توجد نتائج مطابقة',
                                      style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                                    ),
                                    if (_selectedJuz != null || _searchQuery.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedJuz = null;
                                            _searchQuery = '';
                                            _searchController.clear();
                                            _selectedPillIndex = 0;
                                            _selectedSidebarCategory = 0;
                                          });
                                        },
                                        child: const Text('إعادة الضبط', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B))),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: filteredSurahs.length,
                                itemBuilder: (context, index) {
                                  final surah = filteredSurahs[index];
                                  final isFav = _storage.isFavorite(surah.number);
                                  final isPlaying = _playingSurahNumber == surah.number;

                                  return _buildSurahRowCard(surah, isFav, isPlaying);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _audioQuranService.isPlaying ? _buildLiveAudioPlayerBar() : null,
    );
  }

  /// Interactive Audio Mini Player Bar shown when any Surah is playing
  Widget _buildLiveAudioPlayerBar() {
    final curSurah = _audioQuranService.currentSurah;
    final curReciter = _audioQuranService.currentReciter;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Rotating / Pulsing Icon
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)]),
              ),
              child: const Icon(Icons.volume_up_rounded, color: Color(0xFF070B11), size: 22),
            ),
            const SizedBox(width: 12),

            // Surah & Reciter Details
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سورة ${curSurah.nameArabic}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF6F8FA),
                    ),
                  ),
                  Text(
                    curReciter.nameArabic,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFFE8D29A),
                    ),
                  ),
                ],
              ),
            ),

            // Play/Pause button
            IconButton(
              icon: Icon(
                _audioQuranService.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: const Color(0xFFFFD56B),
                size: 34,
              ),
              onPressed: () => _audioQuranService.togglePlayPause(),
            ),

            // Stop button
            IconButton(
              icon: const Icon(Icons.stop_rounded, color: Color(0xFF94A3B8), size: 24),
              onPressed: () => _audioQuranService.stop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Mosque Arch Hero Banner matching the screenshot
  Widget _buildTopHeroMosqueBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 175,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.35), width: 1.2),
        gradient: const RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF261D0F),
            Color(0xFF131A26),
            Color(0xFF070B11),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle lantern and crescent effects
          Positioned(
            left: 12,
            top: 40,
            child: Icon(Icons.light_mode_rounded, color: const Color(0xFFE8D29A).withValues(alpha: 0.6), size: 28),
          ),
          Positioned(
            right: 12,
            top: 40,
            child: Icon(Icons.light_mode_rounded, color: const Color(0xFFE8D29A).withValues(alpha: 0.6), size: 28),
          ),
          const Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.nightlight_round, color: Color(0xFFFFD56B), size: 28),
            ),
          ),

          // Top Header Icons Bar (Back, Search, Settings, Mosque Emblem)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right: Back arrow button
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE8D29A), size: 18),
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: 'رجوع',
                ),

                // Left: Icons (Search, Reciter Settings, Mosque Juz/Hizb)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Color(0xFFE8D29A), size: 20),
                      tooltip: 'البحث عن سورة',
                      onPressed: () {
                        _searchFocusNode.requestFocus();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_pin_rounded, color: Color(0xFFE8D29A), size: 20),
                      tooltip: 'اختيار القارئ',
                      onPressed: _showReciterSelectSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.mosque_outlined, color: Color(0xFFE8D29A), size: 20),
                      tooltip: 'الأجزاء والأحزاب',
                      onPressed: _showJuzSelectSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center Calligraphy: ﴿ القُرْآن الكَرِيم ﴾ & كلام الله .. هدايةٌ لكُلّ قلب
          Positioned(
            top: 55,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('✦ ', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 13)),
                    Text(
                      'القُرْآن الكَرِيم',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF6F8FA),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(' ✦', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'كلام الله .. هدايةٌ لكُلّ قلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Color(0xFFE8D29A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Right Quran Quote inside Arch Banner: ﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾ [الإسراء: 9]
          Positioned(
            right: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي\nلِلَّتِي هِيَ أَقْوَمُ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF6F8FA),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '[الإسراء : 9]',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    color: Color(0xFFC89B3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search Bar with Magnifier Icon & "ابحث عن سورة ..."
  Widget _buildSearchBox() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF101722),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Color(0xFFF6F8FA),
              ),
              decoration: const InputDecoration(
                hintText: 'ابحث عن سورة ...',
                hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            InkWell(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
            ),
        ],
      ),
    );
  }

  /// Top Filter Pills Row (الكل, مكية, مدنية, حسب الترتيب, تصنيف)
  Widget _buildFilterPillsRow() {
    final pills = [
      {'title': 'الكل', 'id': 0},
      {'title': 'مكية', 'id': 1},
      {'title': 'مدنية', 'id': 2},
      {'title': 'حسب الترتيب', 'id': 3},
      {'title': 'تصنيف ▾', 'id': 4},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: pills.map((p) {
          final id = p['id'] as int;
          final isSelected = _selectedPillIndex == id;

          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              onTap: () {
                setState(() => _selectedPillIndex = id);
                if (id == 3) {
                  _showSortOrderSheet();
                } else if (id == 4) {
                  _showClassificationSheet();
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF101722),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD56B)
                        : const Color(0xFFC89B3C).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  p['title'] as String,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF070B11) : const Color(0xFFF6F8FA),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Left Categories Navigation Sidebar
  Widget _buildLeftCategorySidebar() {
    final categories = [
      {'title': 'جميع السور', 'count': '114', 'icon': Icons.menu_book_rounded, 'id': 0},
      {'title': 'المكية', 'count': '86', 'icon': Icons.mosque_rounded, 'id': 1},
      {'title': 'المدنية', 'count': '28', 'icon': Icons.location_city_rounded, 'id': 2},
      {'title': 'قصار السور', 'count': '37', 'icon': Icons.auto_stories_rounded, 'id': 3},
      {'title': 'أطول السور', 'count': '10', 'icon': Icons.format_list_numbered_rounded, 'id': 4},
      {'title': 'أكثر قراءة', 'count': '', 'icon': Icons.bar_chart_rounded, 'id': 5},
      {'title': 'سور جزء عم', 'count': '37', 'icon': Icons.menu_book_outlined, 'id': 6},
      {'title': 'سور الحزب', 'count': '60', 'icon': Icons.star_border_rounded, 'id': 7},
    ];

    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Sidebar category items
          ...categories.map((cat) {
            final id = cat['id'] as int;
            final isSelected = _selectedSidebarCategory == id;

            return InkWell(
              onTap: () => setState(() => _selectedSidebarCategory = id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2A2012), Color(0xFF161C26)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.6))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFFF6F8FA),
                      ),
                    ),
                    if ((cat['count'] as String).isNotEmpty)
                      Text(
                        cat['count'] as String,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          color: isSelected ? const Color(0xFFE8D29A) : const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // Bottom Arch Mini Emblem "ورتل القرآن ترتيلا"
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF131A26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: const [
                Text(
                  '﴿ وَرَتِّلِ الْقُرْآنَ\nتَرْتِيلًا ﴾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8D29A),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '[المزمل: 4]',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 7,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Surah Card Row matching the screenshot layout
  Widget _buildSurahRowCard(SurahMeta surah, bool isFav, bool isPlaying) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1621),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFFFFD56B)
              : const Color(0xFFC89B3C).withValues(alpha: 0.25),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // Star/Octagram Number Badge: 1, 2, 3...
                _buildOctagramNumberBadge(surah.number),

                const SizedBox(width: 10),

                // Surah Name Arabic & English
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'سُورَةُ ${surah.nameArabic}',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF6F8FA),
                        ),
                      ),
                      Text(
                        surah.nameEnglish,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Ayahs Count & Type (7 آيات / مكية)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${surah.ayahCount} آيات',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFFE8D29A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      surah.isMeccan ? 'مكية' : 'مدنية',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // Circular Audio Play Button
                InkWell(
                  onTap: () => _playSurah(surah.number),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141C28),
                      border: Border.all(
                        color: isPlaying
                            ? const Color(0xFFFFD56B)
                            : const Color(0xFFC89B3C).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFFFFD56B),
                      size: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Favorite Star Icon Button
                IconButton(
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFav ? const Color(0xFFFFD56B) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => _storage.toggleFavorite(surah.number),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Octagram Number Emblem
  Widget _buildOctagramNumberBadge(int number) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF131A26),
        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD56B),
          ),
        ),
      ),
    );
  }
}

