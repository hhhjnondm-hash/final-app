import 'dart:async';
import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/quran_models.dart';
import '../services/audio_quran_service.dart';
import '../services/quran_service.dart';
import '../services/quran_storage_service.dart';
import '../widgets/iqra_audio_hero.dart';
import '../widgets/iqra_mushaf_view.dart';
import '../widgets/iqra_settings_sheet.dart';
import '../widgets/iqra_tafsir_sheet.dart';

class IqraScreen extends StatefulWidget {
  const IqraScreen({super.key});

  @override
  State<IqraScreen> createState() => _IqraScreenState();
}

class _IqraScreenState extends State<IqraScreen> {
  final AudioQuranService _audio = AudioQuranService();
  final QuranStorageService _storage = QuranStorageService();

  late SurahMeta _currentSurah;
  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;
  int _activeAyahNumber = 1;
  double _fontSize = 24.0;
  String _readingTheme = 'cream'; // Classic Parchment Cream
  bool _isRepeat = false;

  @override
  void initState() {
    super.initState();
    _currentSurah = _audio.currentSurah;
    _audio.addListener(_onAudioUpdate);
    _loadSurah(_currentSurah);
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioUpdate);
    super.dispose();
  }

  void _onAudioUpdate() {
    if (mounted) {
      if (_currentSurah.number != _audio.currentSurah.number) {
        _loadSurah(_audio.currentSurah);
      }
      
      // Calculate active Ayah based on position & total duration
      if (_audio.isPlaying && _ayahs.isNotEmpty) {
        final posMs = _audio.currentPosition.inMilliseconds;
        final totalMs = _audio.totalDuration.inMilliseconds;
        if (totalMs > 0 && posMs > 0) {
          final fraction = (posMs / totalMs).clamp(0.0, 0.999);
          final calculatedAyah = (fraction * _ayahs.length).floor() + 1;
          if (calculatedAyah != _activeAyahNumber && calculatedAyah <= _ayahs.length) {
            _activeAyahNumber = calculatedAyah;
          }
        }
      }

      setState(() {});
    }
  }

  Future<void> _loadSurah(SurahMeta surah) async {
    setState(() => _isLoading = true);
    await QuranService.loadQuranData();
    final list = QuranService.getSurahAyahs(surah.number) ?? [];
    if (mounted) {
      setState(() {
        _currentSurah = surah;
        _ayahs = list;
        _activeAyahNumber = 1;
        _isLoading = false;
      });
      _storage.updateReadingProgress(
        surahNumber: surah.number,
        surahName: surah.nameArabic,
        ayahNumber: 1,
        juz: surah.juzNumber,
        progress: surah.number / 114.0,
      );
    }
  }

  String _getActiveAyahText() {
    if (_ayahs.isEmpty) return 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
    final target = _ayahs.firstWhere(
      (a) => (a['ayahNumber'] ?? a['number'] ?? 1) == _activeAyahNumber,
      orElse: () => _ayahs.first,
    );
    return (target['text'] ?? '') as String;
  }

  void _seekToAyah(int ayahNumber) {
    if (_ayahs.isEmpty) return;
    setState(() => _activeAyahNumber = ayahNumber);
    final totalMs = _audio.totalDuration.inMilliseconds;
    if (totalMs > 0) {
      final targetMs = (((ayahNumber - 1) / _ayahs.length) * totalMs).toInt();
      _audio.seekTo(Duration(milliseconds: targetMs));
    }
    if (!_audio.isPlaying) {
      _audio.togglePlayPause();
    }
  }

  void _nextAyah() {
    if (_activeAyahNumber < _ayahs.length) {
      _seekToAyah(_activeAyahNumber + 1);
    } else {
      _audio.nextSurah();
    }
  }

  void _prevAyah() {
    if (_activeAyahNumber > 1) {
      _seekToAyah(_activeAyahNumber - 1);
    } else {
      _audio.previousSurah();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Top Header Bar matching screenshot
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: _buildHeader(context),
                    ),
                  ),

                  // 2. Audio Player Hero Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: IqraAudioHero(
                        currentSurah: _currentSurah,
                        activeAyahNumber: _activeAyahNumber,
                        activeAyahText: _getActiveAyahText(),
                        onReciterChangeTap: () => _showReciterSelector(context),
                        onSurahChangeTap: () => _showSurahSelector(context),
                        onNextAyah: _nextAyah,
                        onPrevAyah: _prevAyah,
                        isRepeat: _isRepeat,
                        onToggleRepeat: () {
                          setState(() => _isRepeat = !_isRepeat);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isRepeat ? 'تم تفعيل تكرار التلاوة' : 'تم إلغاء تكرار التلاوة', style: const TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: const Color(0xFF1F293D),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 3. Ornate Mushaf Reading Container
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: Color(0xFFFFD56B)),
                              ),
                            )
                          : IqraMushafView(
                              ayahs: _ayahs,
                              activeAyahNumber: _activeAyahNumber,
                              fontSize: _fontSize,
                              theme: _readingTheme,
                              surahName: _currentSurah.nameArabic,
                              surahNumber: _currentSurah.number,
                              juzNumber: _currentSurah.juzNumber,
                              onAyahTap: (ayahNum, text) => _showAyahActionSheet(ayahNum, text),
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Screen Header matching the screenshot
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title and Subtitle on Right in RTL
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'اقرأ',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: Color(0xFFF6F8FA),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'اقرأ واستمع، ورتّل القرآن ترتيلًا',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Color(0xFFE8D29A),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Settings and Notification Icons on Left in RTL
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderCircleButton(
              icon: Icons.tune_rounded,
              tooltip: 'إعدادات القراءة والمظهر',
              onTap: () => _showSettingsModal(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderCircleButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'تنبيهات الأذان والأوراد',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تنبيهات ورد القرآن وأوقات الصلاة مفعلة', style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Color(0xFF1F293D),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF101722),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: const Color(0xFFE8D29A), size: 20),
      ),
    );
  }

  void _showAyahActionSheet(int ayahNumber, String text) {
    setState(() => _activeAyahNumber = ayahNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الآية رقم $ayahNumber من سورة ${_currentSurah.nameArabic}',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    color: Color(0xFFFFD56B),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAyahActionBtn(
                      icon: Icons.play_arrow_rounded,
                      label: 'استماع للآية',
                      onTap: () {
                        Navigator.pop(context);
                        _seekToAyah(ayahNumber);
                      },
                    ),
                    _buildAyahActionBtn(
                      icon: Icons.menu_book_rounded,
                      label: 'التفسير والمفردات',
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => IqraTafsirSheet(
                            surahNumber: _currentSurah.number,
                            surahName: _currentSurah.nameArabic,
                            ayahNumber: ayahNumber,
                            ayahText: text,
                          ),
                        );
                      },
                    ),
                    _buildAyahActionBtn(
                      icon: Icons.bookmark_add_rounded,
                      label: 'علامة مرجعية',
                      onTap: () {
                        _storage.addBookmark(
                          surahNumber: _currentSurah.number,
                          surahName: _currentSurah.nameArabic,
                          ayahNumber: ayahNumber,
                          ayahSnippet: text,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت إضافة العلامة المرجعية بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Color(0xFF1F293D),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyahActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161F2E),
                border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: const Color(0xFFFFD56B), size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFFF6F8FA), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showSurahSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر سورة للقراءة والاستماع',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: Color(0xFFFFD56B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: QuranMetadataProvider.getAllSurahs().length,
                    itemBuilder: (context, index) {
                      final surah = QuranMetadataProvider.getAllSurahs()[index];
                      final isCurrent = _currentSurah.number == surah.number;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF161F2E),
                          child: Text(
                            '${surah.number}',
                            style: const TextStyle(color: Color(0xFFFFD56B), fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'سورة ${surah.nameArabic}',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: isCurrent ? const Color(0xFFFFD56B) : const Color(0xFFF6F8FA),
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'الجزء ${surah.juzNumber} • ${surah.ayahCount} آية • ${surah.isMeccan ? "مكية" : "مدنية"}',
                          style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                        trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B)) : null,
                        onTap: () {
                          _audio.selectSurah(surah);
                          _loadSurah(surah);
                          Navigator.pop(context);
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
  }

  void _showReciterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر القارئ المفضل',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: Color(0xFFFFD56B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: RecitersData.reciters.length,
                    itemBuilder: (context, idx) {
                      final reciter = RecitersData.reciters[idx];
                      final isCurrent = _audio.currentReciter.id == reciter.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B2433),
                          child: Icon(Icons.person, color: isCurrent ? const Color(0xFFFFD56B) : const Color(0xFF94A3B8)),
                        ),
                        title: Text(
                          reciter.nameArabic,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isCurrent ? const Color(0xFFFFD56B) : const Color(0xFFF6F8FA),
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(reciter.style, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8), fontSize: 11)),
                        trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD56B)) : null,
                        onTap: () {
                          _audio.selectReciter(reciter, autoPlay: true);
                          Navigator.pop(context);
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
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => IqraSettingsSheet(
        fontSize: _fontSize,
        theme: _readingTheme,
        onFontSizeChanged: (val) => setState(() => _fontSize = val),
        onThemeChanged: (val) => setState(() => _readingTheme = val),
      ),
    );
  }
}
