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
import '../widgets/islamic_background.dart';
import '../utils/design_system.dart';

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
  final List<int> _cumulativeAyahWeights = [];
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
        return;
      }

      // Calculate active Ayah proportionally based on Ayah text lengths
      if (_audio.isPlaying && _ayahs.isNotEmpty && _cumulativeAyahWeights.isNotEmpty) {
        final posMs = _audio.currentPosition.inMilliseconds;
        final totalMs = _audio.totalDuration.inMilliseconds;
        if (totalMs > 0 && posMs > 0) {
          final fraction = (posMs / totalMs).clamp(0.0, 0.999);
          final targetWeight = fraction * _cumulativeAyahWeights.last;

          int foundIndex = 0;
          for (int i = 0; i < _cumulativeAyahWeights.length; i++) {
            if (_cumulativeAyahWeights[i] >= targetWeight) {
              foundIndex = i;
              break;
            }
          }

          final calculatedAyah = (foundIndex < _ayahs.length)
              ? (_ayahs[foundIndex]['ayahNumber'] ?? _ayahs[foundIndex]['number'] ?? (foundIndex + 1)) as int
              : 1;

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
    
    // Calculate cumulative weights for accurate proportional timeline synchronization
    _cumulativeAyahWeights.clear();
    int runningSum = 0;
    for (final a in list) {
      final text = ((a['text'] ?? '') as String).trim();
      final weight = text.length > 5 ? text.length : 15;
      runningSum += weight;
      _cumulativeAyahWeights.add(runningSum);
    }

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
    if (totalMs > 0 && _cumulativeAyahWeights.isNotEmpty) {
      final prevWeight = ayahNumber > 1 && (ayahNumber - 2) < _cumulativeAyahWeights.length
          ? _cumulativeAyahWeights[ayahNumber - 2]
          : 0;
      final targetMs = ((prevWeight / _cumulativeAyahWeights.last) * totalMs).toInt();
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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IslamicBackground(
        child: Directionality(
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
                        child: _buildHeader(context, isLight),
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
                                backgroundColor: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1F293D),
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
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: CircularProgressIndicator(color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B)),
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
      ),
    );
  }

  /// Top Screen Header matching the screenshot
  Widget _buildHeader(BuildContext context, bool isLight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title and Subtitle on Right in RTL
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اقرأ',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'اقرأ واستمع، ورتّل القرآن ترتيلًا',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isLight ? const Color(0xFF854D0E) : const Color(0xFFE8D29A),
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
              isLight: isLight,
              onTap: () => _showSettingsModal(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderCircleButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'تنبيهات الأذان والأوراد',
              isLight: isLight,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تنبيهات ورد القرآن وأوقات الصلاة مفعلة', style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1F293D),
                    duration: const Duration(seconds: 2),
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
    required bool isLight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF101722),
          shape: BoxShape.circle,
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.35),
          ),
          boxShadow: [
            if (isLight)
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.08),
                blurRadius: 6,
              ),
          ],
        ),
        child: Icon(icon, color: isLight ? const Color(0xFF854D0E) : const Color(0xFFE8D29A), size: 20),
      ),
    );
  }

  void _showAyahActionSheet(int ayahNumber, String text) {
    setState(() => _activeAyahNumber = ayahNumber);
    final isLight = DesignSystem.isLightMode;
    final sheetBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final goldAccent = isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: goldAccent,
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
                      isLight: isLight,
                      onTap: () {
                        Navigator.pop(context);
                        _seekToAyah(ayahNumber);
                      },
                    ),
                    _buildAyahActionBtn(
                      icon: Icons.menu_book_rounded,
                      label: 'التفسير والمفردات',
                      isLight: isLight,
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
                      isLight: isLight,
                      onTap: () {
                        _storage.addBookmark(
                          surahNumber: _currentSurah.number,
                          surahName: _currentSurah.nameArabic,
                          ayahNumber: ayahNumber,
                          ayahSnippet: text,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تمت إضافة العلامة المرجعية بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: isLight ? const Color(0xFF854D0E) : const Color(0xFF1F293D),
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

  Widget _buildAyahActionBtn({required IconData icon, required String label, required VoidCallback onTap, required bool isLight}) {
    final circleBg = isLight ? const Color(0xFFFBF4E4) : const Color(0xFF161F2E);
    final border = isLight ? const Color(0xFFE5D4B3) : const Color(0xFFC89B3C).withValues(alpha: 0.4);
    final iconColor = isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B);
    final textColor = isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA);

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
                color: circleBg,
                border: Border.all(color: border),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontFamily: 'Cairo', color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showSurahSelector(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final sheetBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final goldAccent = isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B);
    final textTitle = isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA);
    final textSub = isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8);
    final circleBg = isLight ? const Color(0xFFFBF4E4) : const Color(0xFF161F2E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
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
                Text(
                  'اختر سورة للقراءة والاستماع',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: goldAccent,
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
                          backgroundColor: circleBg,
                          child: Text(
                            '${surah.number}',
                            style: TextStyle(color: goldAccent, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'سورة ${surah.nameArabic}',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: isCurrent ? goldAccent : textTitle,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'الجزء ${surah.juzNumber} • ${surah.ayahCount} آية • ${surah.isMeccan ? "مكية" : "مدنية"}',
                          style: TextStyle(fontFamily: 'Cairo', color: textSub, fontSize: 10),
                        ),
                        trailing: isCurrent ? Icon(Icons.check_circle_rounded, color: goldAccent) : null,
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
    final isLight = DesignSystem.isLightMode;
    final sheetBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final goldAccent = isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B);
    final textTitle = isLight ? const Color(0xFF1C1917) : const Color(0xFFF6F8FA);
    final textSub = isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8);
    final circleBg = isLight ? const Color(0xFFFBF4E4) : const Color(0xFF1B2433);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                Text(
                  'اختر القارئ المفضل',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: goldAccent,
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
                          backgroundColor: circleBg,
                          child: Icon(Icons.person, color: isCurrent ? goldAccent : textSub),
                        ),
                        title: Text(
                          reciter.nameArabic,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isCurrent ? goldAccent : textTitle,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(reciter.style, style: TextStyle(fontFamily: 'Cairo', color: textSub, fontSize: 11)),
                        trailing: isCurrent ? Icon(Icons.check_circle_rounded, color: goldAccent) : null,
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
