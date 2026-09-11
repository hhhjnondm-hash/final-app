import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quran_metadata.dart';
import '../services/quran_service.dart';
import '../services/quran_storage_service.dart';

class SurahViewerScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahViewerScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahViewerScreen> createState() => _SurahViewerScreenState();
}

class _SurahViewerScreenState extends State<SurahViewerScreen> {
  final QuranStorageService _storage = QuranStorageService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late int _currentSurahNumber;
  late String _currentSurahName;
  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;

  // Search filter inside surah
  final TextEditingController _searchController = TextEditingController();
  String _ayahSearchQuery = '';
  String _surahDialogFilter = '';

  // Settings State
  bool _isFullscreen = false;
  String _readingTheme = 'ورقي'; // 'فاتح', 'داكن', 'ورقي'
  Color _pageBackgroundColor = const Color(0xFFFBF4E4); // Default parchment
  String _selectedFont = 'Amiri';
  double _fontSize = 22.0;
  double _lineHeight = 1.9;
  bool _isSinglePage = true;
  String _selectedReciter = 'مصحف المدينة النبوية';
  double _playbackSpeed = 1.0;
  bool _showAyahNumbers = true;
  bool _showTafsir = false;
  bool _showWordMeanings = false;

  // Preset Page Colors matching screenshot
  final List<Color> _pageColors = const [
    Color(0xFFFFFFFF), // White
    Color(0xFFFBF4E4), // Parchment / Warm Cream
    Color(0xFFE8F5E9), // Soft Mint Green
    Color(0xFFFCE4EC), // Soft Rose / Peach
    Color(0xFF1E293B), // Dark Slate / Navy
  ];

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;
    _currentSurahName = widget.surahName;
    _loadSurahData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _loadSurahData() async {
    setState(() => _isLoading = true);
    await QuranService.loadQuranData();
    final list = QuranService.getSurahAyahs(_currentSurahNumber) ?? [];
    final meta = QuranMetadataProvider.getSurah(_currentSurahNumber);
    final name = meta.nameArabic;

    if (mounted) {
      setState(() {
        _ayahs = list;
        _currentSurahName = name;
        _isLoading = false;
      });

      _storage.updateReadingProgress(
        surahNumber: _currentSurahNumber,
        surahName: _currentSurahName,
        ayahNumber: 1,
        juz: meta.juzNumber,
        progress: _currentSurahNumber / 114.0,
      );
    }
  }

  void _goToNextSurah() {
    if (_currentSurahNumber < 114) {
      setState(() {
        _currentSurahNumber++;
        _ayahSearchQuery = '';
        _searchController.clear();
      });
      _loadSurahData();
    }
  }

  void _goToPreviousSurah() {
    if (_currentSurahNumber > 1) {
      setState(() {
        _currentSurahNumber--;
        _ayahSearchQuery = '';
        _searchController.clear();
      });
      _loadSurahData();
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleBookmark() {
    _storage.toggleFavorite(_currentSurahNumber);
    setState(() {});
    final isFav = _storage.isFavorite(_currentSurahNumber);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF151C28),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isFav ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
              color: const Color(0xFFFFD56B),
            ),
            const SizedBox(width: 10),
            Text(
              isFav
                  ? 'تمت إضافة سورة $_currentSurahName إلى المفضلة'
                  : 'تمت إزالة سورة $_currentSurahName من المفضلة',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _readingTheme = 'ورقي';
      _pageBackgroundColor = const Color(0xFFFBF4E4);
      _selectedFont = 'Amiri';
      _fontSize = 22.0;
      _lineHeight = 1.9;
      _isSinglePage = true;
      _selectedReciter = 'مصحف المدينة النبوية';
      _playbackSpeed = 1.0;
      _showAyahNumbers = true;
      _showTafsir = false;
      _showWordMeanings = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF151C28),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Color(0xFFFFD56B)),
            SizedBox(width: 10),
            Text(
              'تمت إعادة ضبط الإعدادات الافتراضية',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  void _showSurahSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final list = QuranMetadataProvider.getAllSurahs();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _surahDialogFilter.isEmpty
                ? list
                : list.where((s) => s.nameArabic.contains(_surahDialogFilter) || s.number.toString().contains(_surahDialogFilter)).toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF0D131E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFFD56B)),
                  filled: true,
                  fillColor: const Color(0xFF151C28),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setModalState(() {
                    _surahDialogFilter = val;
                  });
                },
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return ListTile(
                      title: Text(
                        '${s.number}. سورة ${s.nameArabic}',
                        style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${s.isMeccan ? "مكية" : "مدنية"} · ${s.ayahCount} آية',
                        style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8E9BAE), fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentSurahNumber = s.number;
                          _currentSurahName = s.nameArabic;
                          _ayahSearchQuery = '';
                          _searchController.clear();
                        });
                        _loadSurahData();
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Get dynamic text and container colors based on theme & page background
  Color get _textColor {
    if (_readingTheme == 'داكن' || _pageBackgroundColor == const Color(0xFF1E293B)) {
      return const Color(0xFFF1F5F9);
    }
    return const Color(0xFF1E170A);
  }

  Color get _secondaryTextColor {
    if (_readingTheme == 'داكن' || _pageBackgroundColor == const Color(0xFF1E293B)) {
      return const Color(0xFF94A3B8);
    }
    return const Color(0xFF5A4A32);
  }

  @override
  Widget build(BuildContext context) {
    final meta = QuranMetadataProvider.getSurah(_currentSurahNumber);
    final ayahCount = meta.ayahCount;
    final isFavorite = _storage.isFavorite(_currentSurahNumber);

    // Filter ayahs if user typed in the surah search bar
    final displayedAyahs = _ayahSearchQuery.trim().isEmpty
        ? _ayahs
        : _ayahs.where((a) => ((a['text'] ?? '') as String).contains(_ayahSearchQuery.trim())).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF070B11),
      endDrawer: _buildSettingsDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Cinematic Lanterns & Dark Atmosphere matching the screenshot
          Image.asset(
            'assets/quran_viewer_left_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/home_hero_mosque.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF070B11)),
            ),
          ),

          // Dark overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF04070D).withValues(alpha: 0.88),
                  const Color(0xFF070B11).withValues(alpha: 0.75),
                  const Color(0xFF030508).withValues(alpha: 0.94),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // 2. Top Bar: [Back Button] | [❖ سورة الأنفال ❖ \n 75 آية - سورة رقم 8] | [Bookmark, Settings, Search, Fullscreen]
                _buildExactTopBar(ayahCount, isFavorite),

                const SizedBox(height: 12),

                // 3. Middle Search & View Controls Row:
                // [Moon / Book toggle pill] | [ابحث في السورة ... Search bar with Magnifier]
                _buildSearchAndModeRow(),

                const SizedBox(height: 14),

                // 4. Center Golden-Framed Royal Parchment Mushaf Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildExactMushafCard(displayedAyahs),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Bottom Navigation Bar matching exact screenshot:
                // [السورة السابقة button] | [ 8 / 114 with floral star ] | [السورة التالية > gold button]
                _buildExactBottomBar(),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Bar: [< Back] | [سورة الأنفال] | [Bookmark] [Settings] [Search] [Fullscreen]
  Widget _buildExactTopBar(int ayahCount, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Circular Back Button
          _buildCircleIconButton(
            icon: Icons.chevron_left_rounded,
            size: 24,
            onTap: () => Navigator.pop(context),
          ),

          const Spacer(),

          // Center Surah Title
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('❖ ', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 11)),
                  Text(
                    'سورة $_currentSurahName',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(' ❖', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                '$ayahCount آية - سورة رقم $_currentSurahNumber',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Right Action Buttons: [Bookmark, Settings, Search, Fullscreen]
          Row(
            children: [
              // Bookmark
              _buildCircleIconButton(
                icon: isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                iconColor: isFavorite ? const Color(0xFFFFD56B) : const Color(0xFFCBD5E1),
                onTap: _toggleBookmark,
              ),
              const SizedBox(width: 8),

              // Settings Button -> Opens Settings Drawer
              _buildCircleIconButton(
                icon: Icons.settings_outlined,
                onTap: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
              const SizedBox(width: 8),

              // Search Button
              _buildCircleIconButton(
                icon: Icons.search_rounded,
                onTap: _showSurahSearchDialog,
              ),
              const SizedBox(width: 8),

              // Fullscreen Mode Button
              _buildCircleIconButton(
                icon: _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                iconColor: _isFullscreen ? const Color(0xFFFFD56B) : const Color(0xFFCBD5E1),
                onTap: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Circular Icon Button with subtle dark border
  Widget _buildCircleIconButton({
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
    double size = 18,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131B26).withValues(alpha: 0.7),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size,
            color: iconColor ?? const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  /// Search and Mode Row: [Moon | Book] + [Search input box]
  Widget _buildSearchAndModeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left Pill: [Moon (night) | Book]
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_readingTheme == 'داكن') {
                        _readingTheme = 'ورقي';
                        _pageBackgroundColor = const Color(0xFFFBF4E4);
                      } else {
                        _readingTheme = 'داكن';
                        _pageBackgroundColor = const Color(0xFF1E293B);
                      }
                    });
                  },
                  child: Icon(
                    Icons.nightlight_round,
                    size: 18,
                    color: _readingTheme == 'داكن' ? const Color(0xFFFFD56B) : const Color(0xFF64748B),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(width: 1, height: 16, color: const Color(0xFF334155)),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSinglePage = !_isSinglePage;
                    });
                  },
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: _isSinglePage ? const Color(0xFFFFD56B) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right: "ابحث في السورة ..." Input Box with Search Icon
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1722).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '... ابحث في السورة',
                        hintStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _ayahSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_ayahSearchQuery.isNotEmpty)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _ayahSearchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                    )
                  else
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Center Card with Ornate Golden Islamic Frame and Traditional Mushaf Layout
  Widget _buildExactMushafCard(List<Map<String, dynamic>> displayedAyahs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _pageBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC89B3C),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Ornate Border Frame Artwork
            Positioned.fill(
              child: Image.asset(
                'assets/quran_mushaf_frame_high.png',
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => Container(
                  color: _pageBackgroundColor,
                ),
              ),
            ),

            // 2. Inner Mushaf Content (Surah Header Box + Basmalah + Ayahs Line-by-Line with circular Ayah Numbers)
            Positioned.fill(
              top: 14,
              bottom: 14,
              left: 20,
              right: 20,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFC89B3C)))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top Traditional Surah Title Banner: ﴿ سُورَةُ الأَنْفَالِ ﴾
                          _buildSurahOrnamentalTitle(),

                          const SizedBox(height: 12),

                          // Basmalah: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
                          if (_currentSurahNumber != 9 && _currentSurahNumber != 1) ...[
                            Text(
                              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _selectedFont,
                                fontSize: _fontSize + 1,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Ayahs formatted exactly like traditional Quran with ornate end-number badges
                          _buildAyahsList(displayedAyahs),
                        ],
                      ),
                    ),
            ),

            // Left Page Chevron Arrow
            Positioned(
              left: 4,
              child: InkWell(
                onTap: _goToPreviousSurah,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F1724).withValues(alpha: 0.85),
                    border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFFFFD56B),
                    size: 22,
                  ),
                ),
              ),
            ),

            // Right Page Chevron Arrow
            Positioned(
              right: 4,
              child: InkWell(
                onTap: _goToNextSurah,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F1724).withValues(alpha: 0.85),
                    border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFFD56B),
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Surah Name Traditional Calligraphic Box
  Widget _buildSurahOrnamentalTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Center(
        child: Text(
          'سُورَةُ $_currentSurahName',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _selectedFont,
            fontSize: _fontSize + 3,
            fontWeight: FontWeight.bold,
            color: _textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Ayahs formatted line by line with ornate golden circle numbers
  Widget _buildAyahsList(List<Map<String, dynamic>> ayahs) {
    if (ayahs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'لا توجد نتائج مطابقة للبحث',
            style: TextStyle(fontFamily: 'Cairo', color: _secondaryTextColor, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: ayahs.map((ayah) {
        final int num = (ayah['ayahNumber'] ?? ayah['number'] ?? 1) as int;
        var text = ((ayah['text'] ?? '') as String).trim();

        // Remove Basmalah duplicate in first ayah
        if (_currentSurahNumber != 1 && num == 1 && text.startsWith('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')) {
          text = text.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Ornate Circular Ayah Number Badge matching screenshot
                  if (_showAyahNumbers) ...[
                    _buildAyahNumberBadge(num),
                    const SizedBox(width: 10),
                  ],

                  // Right: Arabic Ayah Text
                  Expanded(
                    child: Text(
                      text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: _selectedFont,
                        fontSize: _fontSize,
                        height: _lineHeight,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Optional Tafsir Box
              if (_showTafsir) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'تفسير ميسر للآية ($num): قال الإمام الطبري في تأويل هذه الآية...',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
              ],

              // Optional Word Meanings Box
              if (_showWordMeanings) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC89B3C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'معاني الكلمات: يثبت الله الذين آمنوا بالقول الثابت.',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Ornate Ayah Badge (Golden patterned ring with Arabic digit inside)
  Widget _buildAyahNumberBadge(int ayahNumber) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _pageBackgroundColor,
        border: Border.all(
          color: const Color(0xFFC89B3C),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _toArabicDigits(ayahNumber),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ),
    );
  }

  /// Bottom Navigation Bar: [السورة السابقة] | [ 8 / 114 ] | [السورة التالية >]
  Widget _buildExactBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Surah Button with Hamburger Lines Icon
          InkWell(
            onTap: _goToPreviousSurah,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1722).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.format_list_bulleted_rounded, size: 16, color: Color(0xFFFFD56B)),
                  SizedBox(width: 8),
                  Text(
                    'السورة السابقة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Page / Surah Indicator with Star Ornaments: ❖ 8 / 114 ❖
          Row(
            children: [
              const Text('❖', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 11)),
              const SizedBox(width: 6),
              Text(
                '$_currentSurahNumber / 114',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD56B),
                ),
              ),
              const SizedBox(width: 6),
              const Text('❖', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 11)),
            ],
          ),

          // Next Surah Button with Right Chevron Arrow
          InkWell(
            onTap: _goToNextSurah,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1722).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
              ),
              child: const Row(
                children: [
                  Text(
                    'السورة التالية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFFFD56B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SETTINGS DRAWER (Exact match to screenshot)
  // ==========================================
  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0B1019),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Drawer Header: [✕ Close] | [الإعدادات]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C28),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                    ),
                  ),
                  const Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E293B), height: 1),

            // 2. Settings Content List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // --- SECTION: المظهر (Appearance) ---
                  _buildSectionHeader('المظهر'),
                  const SizedBox(height: 8),

                  // وضع القراءة: [فاتح | داكن | ورقي]
                  _buildSubLabel('وضع القراءة'),
                  const SizedBox(height: 6),
                  _buildThemeSegmentedControl(),

                  const SizedBox(height: 14),

                  // ألوان الصفحة (Page Color Circles)
                  _buildSubLabel('ألوان الصفحة'),
                  const SizedBox(height: 8),
                  _buildPageColorPalette(),

                  const SizedBox(height: 20),

                  // --- SECTION: الخط (Typography) ---
                  _buildSectionHeader('الخط'),
                  const SizedBox(height: 8),

                  // نوع الخط
                  _buildSubLabel('نوع الخط'),
                  const SizedBox(height: 6),
                  _buildFontDropdown(),

                  const SizedBox(height: 12),

                  // حجم الخط Stepper: [-] 28 [+]
                  _buildSubLabel('حجم الخط'),
                  const SizedBox(height: 6),
                  _buildFontSizeStepper(),

                  const SizedBox(height: 12),

                  // تباعد الأسطر
                  _buildSubLabel('تباعد الأسطر'),
                  const SizedBox(height: 6),
                  _buildLineHeightSelector(),

                  const SizedBox(height: 20),

                  // --- SECTION: الصفحة (Page Layout & Fullscreen) ---
                  _buildSectionHeader('الصفحة'),
                  const SizedBox(height: 8),

                  // وضع الصفحة: [صفحة واحدة | صفحتان]
                  _buildSubLabel('وضع الصفحة'),
                  const SizedBox(height: 6),
                  _buildPageModeSegmentedControl(),

                  const SizedBox(height: 12),

                  // تفعيل ملء الشاشة Toggle
                  _buildSwitchRow(
                    title: 'تفعيل ملء الشاشة',
                    value: _isFullscreen,
                    onChanged: (val) {
                      _toggleFullscreen();
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- SECTION: الصوت (Audio & Reciter) ---
                  _buildSectionHeader('الصوت'),
                  const SizedBox(height: 8),

                  // القارئ
                  _buildSubLabel('القارئ'),
                  const SizedBox(height: 6),
                  _buildReciterDropdown(),

                  const SizedBox(height: 12),

                  // سرعة التلاوة Slider
                  _buildSubLabel('سرعة التلاوة (${_playbackSpeed.toStringAsFixed(2)}x)'),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFFD56B),
                      inactiveTrackColor: const Color(0xFF1E293B),
                      thumbColor: const Color(0xFFFFD56B),
                      overlayColor: const Color(0xFFFFD56B).withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _playbackSpeed,
                      min: 0.75,
                      max: 1.75,
                      divisions: 4,
                      label: '${_playbackSpeed}x',
                      onChanged: (val) {
                        setState(() {
                          _playbackSpeed = val;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- SECTION: المزيد (More toggles) ---
                  _buildSectionHeader('المزيد'),
                  const SizedBox(height: 8),

                  _buildSwitchRow(
                    title: 'إظهار أرقام الآيات',
                    value: _showAyahNumbers,
                    onChanged: (val) => setState(() => _showAyahNumbers = val),
                  ),
                  _buildSwitchRow(
                    title: 'إظهار التفسير',
                    value: _showTafsir,
                    onChanged: (val) => setState(() => _showTafsir = val),
                  ),
                  _buildSwitchRow(
                    title: 'إظهار معاني الكلمات',
                    value: _showWordMeanings,
                    onChanged: (val) => setState(() => _showWordMeanings = val),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION: إعادة ضبط الإعدادات (Reset Button) ---
                  InkWell(
                    onTap: _resetSettings,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C28),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: Color(0xFFFFD56B), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'إعادة ضبط الإعدادات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFD56B),
      ),
    );
  }

  Widget _buildSubLabel(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildThemeSegmentedControl() {
    final options = ['فاتح', 'داكن', 'ورقي'];
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF151C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _readingTheme == opt;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _readingTheme = opt;
                  if (opt == 'فاتح') {
                    _pageBackgroundColor = const Color(0xFFFFFFFF);
                  } else if (opt == 'داكن') {
                    _pageBackgroundColor = const Color(0xFF1E293B);
                  } else {
                    _pageBackgroundColor = const Color(0xFFFBF4E4);
                  }
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFC89B3C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageColorPalette() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _pageColors.map((color) {
        final isSelected = _pageBackgroundColor == color;
        return InkWell(
          onTap: () {
            setState(() {
              _pageBackgroundColor = color;
              if (color == const Color(0xFF1E293B)) {
                _readingTheme = 'داكن';
              } else if (color == const Color(0xFFFFFFFF)) {
                _readingTheme = 'فاتح';
              } else {
                _readingTheme = 'ورقي';
              }
            });
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF475569),
                width: isSelected ? 2.5 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD56B).withValues(alpha: 0.4),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: color == const Color(0xFF1E293B) ? Colors.white : const Color(0xFF1E170A),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontDropdown() {
    final fonts = [
      {'name': 'Amiri', 'label': 'خط عثماني (Amiri)'},
      {'name': 'Cairo', 'label': 'خط النسخ (Cairo)'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFont,
          isExpanded: true,
          dropdownColor: const Color(0xFF151C28),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFD56B)),
          items: fonts.map((f) {
            return DropdownMenuItem<String>(
              value: f['name'],
              child: Text(
                f['label']!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedFont = val);
          },
        ),
      ),
    );
  }

  Widget _buildFontSizeStepper() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minus Button
          IconButton(
            onPressed: () {
              if (_fontSize > 16) {
                setState(() => _fontSize -= 2);
              }
            },
            icon: const Icon(Icons.remove_rounded, color: Color(0xFFFFD56B), size: 20),
          ),

          // Size Value Display
          Text(
            '${_fontSize.toInt()} pt',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Plus Button
          IconButton(
            onPressed: () {
              if (_fontSize < 38) {
                setState(() => _fontSize += 2);
              }
            },
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFFD56B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLineHeightSelector() {
    final heights = [
      {'val': 1.6, 'label': 'ضيق'},
      {'val': 1.9, 'label': 'متوسط'},
      {'val': 2.3, 'label': 'واسع'},
    ];

    return Row(
      children: heights.map((h) {
        final isSelected = (_lineHeight - (h['val'] as double)).abs() < 0.1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _lineHeight = h['val'] as double),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFC89B3C) : const Color(0xFF151C28),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  h['label'] as String,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPageModeSegmentedControl() {
    final modes = [
      {'val': true, 'label': 'صفحة واحدة'},
      {'val': false, 'label': 'صفحتان'},
    ];

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF151C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: modes.map((m) {
          final isSelected = _isSinglePage == m['val'];
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _isSinglePage = m['val'] as bool),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFC89B3C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  m['label'] as String,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReciterDropdown() {
    final reciters = [
      'مصحف المدينة النبوية',
      'الشيخ مشاري بن راشد العفاسي',
      'الشيخ عبد الباسط عبد الصمد',
      'الشيخ محمود خليل الحصري',
      'الشيخ سعد بن سعيد الغامدي',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReciter,
          isExpanded: true,
          dropdownColor: const Color(0xFF151C28),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFD56B)),
          items: reciters.map((r) {
            return DropdownMenuItem<String>(
              value: r,
              child: Text(
                r,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedReciter = val);
          },
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFFFD56B),
            activeTrackColor: const Color(0xFFC89B3C),
            inactiveThumbColor: const Color(0xFF64748B),
            inactiveTrackColor: const Color(0xFF1E293B),
            onChanged: onChanged,
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}
