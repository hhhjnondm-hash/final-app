import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';
import '../services/quran_storage_service.dart';
import '../services/global_audio_manager.dart';
import '../services/audio_quran_service.dart';
import '../widgets/iqra_tafsir_sheet.dart';
import 'audio_screen.dart';
import 'azkar_screen.dart';
import 'hadith_screen.dart';
import 'profile_screen.dart';

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
  final AudioQuranService _audioQuranService = AudioQuranService();
  final GlobalAudioManager _audioManager = GlobalAudioManager();

  late int _currentSurahNumber;
  late String _currentSurahName;
  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;

  double _fontSize = 22.0;
  String _fontFamily = 'Amiri';
  String _selectedMushafName = 'مصحف المدينة النبوية';
  String _readingMode = 'dark'; // 'light', 'dark', 'parchment'
  bool _isPlayingAudio = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;
    _currentSurahName = widget.surahName;
    _audioManager.addListener(_onAudioUpdate);
    _audioQuranService.addListener(_onAudioUpdate);
    _storage.addListener(_onStorageUpdate);
    _loadSurahData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioManager.removeListener(_onAudioUpdate);
    _audioQuranService.removeListener(_onAudioUpdate);
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onAudioUpdate() {
    if (mounted) {
      setState(() {
        _isPlayingAudio = _audioManager.isPlaying;
      });
    }
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSurahData() async {
    setState(() => _isLoading = true);
    await QuranService.loadQuranData();
    final list = QuranService.getSurahAyahs(_currentSurahNumber) ?? [];
    
    // Update surah name if navigated
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
      setState(() => _currentSurahNumber++);
      _loadSurahData();
    }
  }

  void _goToPreviousSurah() {
    if (_currentSurahNumber > 1) {
      setState(() => _currentSurahNumber--);
      _loadSurahData();
    }
  }

  void _toggleBookmark() {
    _storage.toggleFavorite(_currentSurahNumber);
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

  void _shareSurah() {
    final text = _ayahs.map((a) => a['text'] ?? '').join(' ');
    Clipboard.setData(ClipboardData(text: 'سورة $_currentSurahName:\n\n$text\n\n— تطبيق رفيق'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF151C28),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B)),
            SizedBox(width: 10),
            Text(
              'تم نسخ نص السورة إلى الحافظة بنجاح',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showTafsirModal() {
    final firstAyah = _ayahs.isNotEmpty ? (_ayahs.first['text'] ?? '') : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IqraTafsirSheet(
        surahNumber: _currentSurahNumber,
        surahName: _currentSurahName,
        ayahNumber: 1,
        ayahText: firstAyah,
      ),
    );
  }

  void _showReciterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D131E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 380,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, color: Color(0xFFFFD56B)),
                  SizedBox(width: 8),
                  Text(
                    'اختر القارئ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: RecitersData.reciters.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B)),
                  itemBuilder: (context, index) {
                    final reciter = RecitersData.reciters[index];
                    final isSelected = _audioQuranService.currentReciter.id == reciter.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF241C10),
                        child: Text(
                          reciter.nameArabic.isNotEmpty ? reciter.nameArabic[0] : 'ق',
                          style: const TextStyle(color: Color(0xFFFFD56B), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        reciter.nameArabic,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFFFFD56B) : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        reciter.style,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF8E9BAE)),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B))
                          : null,
                      onTap: () {
                        _audioQuranService.selectReciter(reciter, autoPlay: _isPlayingAudio);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMushafPicker() {
    final mushafs = [
      'مصحف المدينة النبوية',
      'مصحف التجويد الملون',
      'مصحف الشمرلي',
      'مصحف الحرم المكي',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D131E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر المصحف',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...mushafs.map(
                (name) => ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: _selectedMushafName == name ? const Color(0xFFFFD56B) : Colors.white,
                      fontWeight: _selectedMushafName == name ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedMushafName == name
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B))
                      : null,
                  onTap: () {
                    setState(() => _selectedMushafName = name);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontPicker() {
    final fonts = [
      {'name': 'خط عثماني (Amiri)', 'key': 'Amiri'},
      {'name': 'خط النسخ الواضح (Cairo)', 'key': 'Cairo'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D131E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر نوع الخط القرآني',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...fonts.map(
                (f) => ListTile(
                  title: Text(
                    f['name']!,
                    style: TextStyle(
                      fontFamily: f['key']!,
                      fontSize: 15,
                      color: _fontFamily == f['key']! ? const Color(0xFFFFD56B) : Colors.white,
                      fontWeight: _fontFamily == f['key']! ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _fontFamily == f['key']!
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B))
                      : null,
                  onTap: () {
                    setState(() => _fontFamily = f['key']!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSurahSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<SurahMeta> list = QuranMetadataProvider.getAllSurahs();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _searchFilter.isEmpty
                ? list
                : list.where((s) => s.nameArabic.contains(_searchFilter) || s.number.toString().contains(_searchFilter)).toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF0D131E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم السورة أو رقمها...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFFD56B)),
                  filled: true,
                  fillColor: const Color(0xFF151C28),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setModalState(() {
                    _searchFilter = val;
                  });
                },
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
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

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final meta = QuranMetadataProvider.getSurah(_currentSurahNumber);
    final isMeccan = meta.isMeccan;
    final ayahCount = meta.ayahCount;

    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 950;

            if (isWide) {
              return Row(
                children: [
                  // Left Mosque Cinematic Panel
                  Expanded(
                    flex: 4,
                    child: _buildLeftDecorativeMosquePanel(),
                  ),

                  // Center Mushaf Page
                  Expanded(
                    flex: 6,
                    child: _buildCenterMushafPage(meta, isMeccan, ayahCount),
                  ),

                  // Right Control & Settings Panel
                  SizedBox(
                    width: 320,
                    child: _buildRightControlPanel(meta, isMeccan, ayahCount),
                  ),
                ],
              );
            }

            // Compact/Mobile Responsive View
            return Column(
              children: [
                _buildTopHeaderBar(),
                Expanded(
                  child: _buildCenterMushafPage(meta, isMeccan, ayahCount),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Left Side Mosque Night Panel
  Widget _buildLeftDecorativeMosquePanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF06090F),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mosque Night Illustration
          Image.asset(
            'assets/quran_viewer_left_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/home_hero_mosque.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF070B11).withValues(alpha: 0.85),
                  const Color(0xFF070B11).withValues(alpha: 0.35),
                  const Color(0xFF070B11).withValues(alpha: 0.95),
                ],
              ),
            ),
          ),

          // Top Left Brand & Nav
          Positioned(
            top: 24,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rafeeq',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'رفيقك في رحلتك الإيمانية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            color: Color(0xFFFFD56B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSidebarNavItem(Icons.home_outlined, 'الرئيسية', false, () => Navigator.pop(context)),
                _buildSidebarNavItem(Icons.menu_book_rounded, 'اقرأ القرآن', true, () {}),
                _buildSidebarNavItem(Icons.headphones_outlined, 'الاستماع', false, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioScreen()));
                }),
                _buildSidebarNavItem(Icons.auto_awesome_outlined, 'الأذكار', false, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen()));
                }),
                _buildSidebarNavItem(Icons.library_books_outlined, 'المكتبة', false, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithScreen()));
                }),
                _buildSidebarNavItem(Icons.person_outline_rounded, 'حسابي', false, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
              ],
            ),
          ),

          // Bottom Islamic Inscription: "وَقُل رَّبِّ زِدْنِي عِلْمًا"
          Positioned(
            bottom: 30,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF090E17).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'وَقُل رَّبِّ زِدْنِي عِلْمًا',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD56B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '(طه : 114)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: Color(0xFF8E9BAE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF241C10) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF8E9BAE),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF8E9BAE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Center Mushaf Page Canvas with Golden Border and Pagination
  Widget _buildCenterMushafPage(SurahMeta? meta, bool isMeccan, int ayahCount) {
    final isFavorite = _storage.isFavorite(_currentSurahNumber);

    return Column(
      children: [
        // Top Search and Surah Title Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search in Surah
              InkWell(
                onTap: _showSurahSearchDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1724),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, size: 16, color: Color(0xFF8E9BAE)),
                      SizedBox(width: 8),
                      Text(
                        'ابحث في السور ...',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title: سورة الفاتحة (7 آيات · سورة رقم 1)
              Column(
                children: [
                  Text(
                    'سورة $_currentSurahName',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$ayahCount آيات · سورة رقم $_currentSurahNumber',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      color: Color(0xFFFFD56B),
                    ),
                  ),
                ],
              ),

              // Icons: Bookmark, Settings, Nightmode
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 20,
                      color: const Color(0xFFFFD56B),
                    ),
                    onPressed: _toggleBookmark,
                    tooltip: 'إضافة للمفضلة',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF8E9BAE)),
                    onPressed: _showMushafPicker,
                    tooltip: 'إعدادات المصحف',
                  ),
                  IconButton(
                    icon: Icon(
                      _readingMode == 'dark' ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      size: 20,
                      color: const Color(0xFFFFD56B),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_readingMode == 'dark') {
                          _readingMode = 'light';
                        } else if (_readingMode == 'light') {
                          _readingMode = 'parchment';
                        } else {
                          _readingMode = 'dark';
                        }
                      });
                    },
                    tooltip: 'تغيير الوضع',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main Golden Framed Mushaf Page
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mushaf Sheet Container with Authentic Ornate Frame
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 580),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EBD2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFC89B3C).withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD56B).withValues(alpha: 0.15),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Authentic High-Resolution Islamic Mushaf Frame Background
                        Image.asset(
                          'assets/quran_mushaf_frame_high.png',
                          fit: BoxFit.fill,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF6EBD2),
                          ),
                        ),

                        // 2. Surah Name inside the top Ornate Frame Header Box
                        Positioned(
                          top: 18,
                          left: 45,
                          right: 45,
                          child: Center(
                            child: Text(
                              'سُورَةُ $_currentSurahName',
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2416),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // 3. Inner Scrollable Quran Ayahs Area
                        Positioned.fill(
                          top: 55,
                          bottom: 38,
                          left: 32,
                          right: 32,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Basmalah (if not At-Tawbah and not Al-Fatihah)
                                if (_currentSurahNumber != 9 && _currentSurahNumber != 1) ...[
                                  const Text(
                                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E170A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // All Ayahs Rich Text Flow
                                if (_isLoading)
                                  const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(color: Color(0xFFC89B3C)),
                                  )
                                else
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          fontFamily: _fontFamily,
                                          fontSize: _fontSize,
                                          height: 2.1,
                                          color: const Color(0xFF1E170A),
                                          letterSpacing: 0.2,
                                        ),
                                        children: _buildAyahsSpans(const Color(0xFF1E170A)),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // 4. Bottom Ornate Badge: Surah / Page Number
                        Positioned(
                          bottom: 5,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: Text(
                                  _toArabicDigits(_currentSurahNumber),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Left Arrow Button (< السورة السابقة)
                Positioned(
                  left: 0,
                  child: InkWell(
                    onTap: _goToPreviousSurah,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F1724),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFFFD56B),
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // Right Arrow Button (السورة التالية >)
                Positioned(
                  right: 0,
                  child: InkWell(
                    onTap: _goToNextSurah,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F1724),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFFFD56B),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Navigation Bar: [السورة السابقة] | 1 / 114 | [السورة التالية >]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Next Surah Button
              InkWell(
                onTap: _goToNextSurah,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'السورة التالية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF07090E),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF07090E)),
                    ],
                  ),
                ),
              ),

              // Page / Surah Indicator (1 / 114)
              Text(
                '❖  $_currentSurahNumber / 114  ❖',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD56B),
                ),
              ),

              // Previous Surah Button
              InkWell(
                onTap: _goToPreviousSurah,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1724),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF8E9BAE)),
                      SizedBox(width: 4),
                      Text(
                        'السورة السابقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E9BAE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Right Side Control Panel (Surah Details, Reading Settings, Audio Player, Actions)
  Widget _buildRightControlPanel(SurahMeta? meta, bool isMeccan, int ayahCount) {
    final currentReciterName = _audioQuranService.currentReciter.nameArabic;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF080C14),
        border: Border(
          right: BorderSide(color: Color(0xFF151C28), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Surah Meta Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D131E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سورة $_currentSurahName',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isMeccan ? "مكية" : "مدنية"} · $ayahCount آيات · رقم $_currentSurahNumber',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Color(0xFFFFD56B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تلاوة وتدبر المصحف الشريف بدقة وترتيل عالي الجودة.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            color: Color(0xFF8E9BAE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF241C10),
                      border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFFFD56B),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Reading Settings (القراءة)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D131E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFFFFD56B)),
                      SizedBox(width: 8),
                      Text(
                        'القراءة',
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

                  // Mushaf Dropdown Pill ("مصحف المدينة النبوية")
                  InkWell(
                    onTap: _showMushafPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C28),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E9BAE), size: 18),
                          Text(
                            _selectedMushafName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Font Size Stepper [ - | + ]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _fontSize = (_fontSize - 2).clamp(16.0, 36.0)),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Text('-', style: TextStyle(color: Colors.white, fontSize: 16))),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _fontSize = (_fontSize + 2).clamp(16.0, 36.0)),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Text('+', style: TextStyle(color: Colors.white, fontSize: 16))),
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'حجم الخط',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF8E9BAE)),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.text_fields_rounded, size: 16, color: Color(0xFF8E9BAE)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Font Selection Pill (خط عثماني)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _showFontPicker,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF8E9BAE)),
                              const SizedBox(width: 4),
                              Text(
                                _fontFamily == 'Amiri' ? 'خط عثماني' : 'خط النسخ',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Text('تغيير الخط', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF8E9BAE))),
                          SizedBox(width: 6),
                          Icon(Icons.palette_outlined, size: 16, color: Color(0xFF8E9BAE)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Reading Modes: فاتح | داكن | ورقي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildModePill('فاتح', 'light'),
                          const SizedBox(width: 6),
                          _buildModePill('داكن', 'dark'),
                          const SizedBox(width: 6),
                          _buildModePill('ورقي', 'parchment'),
                        ],
                      ),
                      const Row(
                        children: [
                          Text('وضع القراءة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF8E9BAE))),
                          SizedBox(width: 6),
                          Icon(Icons.nightlight_round, size: 16, color: Color(0xFFFFD56B)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Audio Player (الاستماع)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D131E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.headphones_rounded, size: 16, color: Color(0xFFFFD56B)),
                      SizedBox(width: 8),
                      Text(
                        'الاستماع',
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

                  // Reciter Pill ("الشيخ عبد الرحمن السديس")
                  InkWell(
                    onTap: _showReciterPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C28),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E9BAE), size: 18),
                          Text(
                            currentReciterName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Audio Track & Timing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_audioQuranService.formatDuration(_audioManager.position), style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF8E9BAE))),
                      Text(_audioQuranService.formatDuration(_audioManager.duration ?? Duration.zero), style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF8E9BAE))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_audioManager.duration != null && _audioManager.duration!.inMilliseconds > 0)
                          ? (_audioManager.position.inMilliseconds / _audioManager.duration!.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: const Color(0xFF1E293B),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD56B)),
                      minHeight: 4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Player Controls: Shuffle, Prev, Big Play, Next, Repeat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded, size: 18, color: Color(0xFF8E9BAE)),
                        onPressed: () {
                          // Shuffle surah
                          final randomSurah = (1 + (113 * (DateTime.now().millisecond / 1000)).toInt()).clamp(1, 114);
                          setState(() => _currentSurahNumber = randomSurah);
                          _loadSurahData();
                          _audioQuranService.playSurah(randomSurah);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 22, color: Color(0xFFCBD5E1)),
                        onPressed: () {
                          _goToPreviousSurah();
                          _audioQuranService.playSurah(_currentSurahNumber);
                        },
                      ),
                      InkWell(
                        onTap: () {
                          if (_isPlayingAudio) {
                            _audioManager.pause();
                          } else {
                            _audioQuranService.playSurah(_currentSurahNumber);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFD56B),
                          ),
                          child: Icon(
                            _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 26,
                            color: const Color(0xFF07090E),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 22, color: Color(0xFFCBD5E1)),
                        onPressed: () {
                          _goToNextSurah();
                          _audioQuranService.playSurah(_currentSurahNumber);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat_rounded, size: 18, color: Color(0xFF8E9BAE)),
                        onPressed: () {
                          _audioQuranService.playSurah(_currentSurahNumber);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Bottom Action Buttons: [حفظ | مشاركة | تفسير]
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    Icons.bookmark_outline_rounded,
                    'حفظ',
                    onTap: _toggleBookmark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    Icons.share_outlined,
                    'مشاركة',
                    onTap: _shareSurah,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    Icons.menu_book_rounded,
                    'تفسير',
                    onTap: _showTafsirModal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String label, String modeKey) {
    final isSelected = _readingMode == modeKey;
    return InkWell(
      onTap: () => setState(() => _readingMode = modeKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF07090E) : const Color(0xFF8E9BAE),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D131E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFFFD56B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildAyahsSpans(Color textColor) {
    final List<InlineSpan> spans = [];

    for (final ayah in _ayahs) {
      final int num = (ayah['ayahNumber'] ?? ayah['number'] ?? 1) as int;
      var text = ((ayah['text'] ?? '') as String).trim();

      if (_currentSurahNumber != 1 && num == 1 && text.startsWith('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')) {
        text = text.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
      }

      // Ayah Text
      spans.add(
        TextSpan(
          text: '$text ',
          style: TextStyle(
            color: textColor,
            fontSize: _fontSize,
            height: 2.2,
            fontFamily: _fontFamily,
          ),
        ),
      );

      // Golden Ayah End Number Marker ﴿١﴾
      spans.add(
        TextSpan(
          text: ' ﴿${_toArabicDigits(num)}﴾ ',
          style: const TextStyle(
            color: Color(0xFFFFD56B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildTopHeaderBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD56B)),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'سورة $_currentSurahName',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
