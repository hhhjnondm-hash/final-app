import 'dart:async';
import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import '../services/audio_quran_service.dart';
import '../services/quran_service.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
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
  String _readingTheme = 'dark'; // dark, cream, blue
  Timer? _ayahSyncTimer;

  @override
  void initState() {
    super.initState();
    _currentSurah = QuranMetadataProvider.getAllSurahs().first;
    _audio.addListener(_onAudioUpdate);
    _loadSurah(_currentSurah);
    _startLiveAyahTracker();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioUpdate);
    _ayahSyncTimer?.cancel();
    super.dispose();
  }

  void _onAudioUpdate() {
    if (mounted) {
      if (_currentSurah.number != _audio.currentSurah.number) {
        _loadSurah(_audio.currentSurah);
      }
      setState(() {});
    }
  }

  void _startLiveAyahTracker() {
    _ayahSyncTimer?.cancel();
    _ayahSyncTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_audio.isPlaying && _ayahs.isNotEmpty) {
        setState(() {
          _activeAyahNumber = (_activeAyahNumber % _ayahs.length) + 1;
        });
      }
    });
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
      _storage.updateProgress(
        surahNumber: surah.number,
        surahName: surah.nameArabic,
        ayahNumber: 1,
        juz: surah.juzNumber,
        progress: surah.number / 114.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Header Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spacingL,
                      DesignSystem.spacingM,
                      DesignSystem.spacingL,
                      DesignSystem.spacingS,
                    ),
                    child: _buildHeader(context),
                  ),
                ),

                // 2. Continuous Audio Player Hero
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingL,
                      vertical: DesignSystem.spacingS,
                    ),
                    child: IqraAudioHero(
                      currentSurah: _currentSurah,
                      activeAyahNumber: _activeAyahNumber,
                      onReciterChangeTap: () => _showReciterSelector(context),
                      onSurahChangeTap: () => _showSurahSelector(context),
                    ),
                  ),
                ),

                // 4. Continuous Mushaf Reader with Live Ayah Highlight
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingL,
                      vertical: DesignSystem.spacingS,
                    ),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: DesignSystem.gold),
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
                            onAyahTap: (num, text) => _showAyahActionSheet(num, text),
                          ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اقْرَأْ',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'اقرأ واستمع، ورتّل القرآن ترتيلاً',
              style: TextStyle(
                color: DesignSystem.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIconButton(
              icon: Icons.tune_rounded,
              onTap: () => _showSettingsModal(context),
            ),
            const SizedBox(width: 8),
            _buildCircleIconButton(
              icon: Icons.format_list_bulleted_rounded,
              onTap: () => _showSurahSelector(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DesignSystem.bgCard.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: DesignSystem.goldLight, size: 20),
      ),
    );
  }

  void _showAyahActionSheet(int ayahNumber, String text) {
    setState(() => _activeAyahNumber = ayahNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          decoration: BoxDecoration(
            color: DesignSystem.bgDarkest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الآية رقم $ayahNumber من سورة ${_currentSurah.nameArabic}',
                style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAyahActionBtn(
                    icon: Icons.play_arrow_rounded,
                    label: 'تشغيل من هنا',
                    onTap: () {
                      _audio.togglePlayPause();
                      Navigator.pop(context);
                    },
                  ),
                  _buildAyahActionBtn(
                    icon: Icons.menu_book_rounded,
                    label: 'التفسير',
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
                        const SnackBar(content: Text('تمت إضافة العلامة المرجعية'), backgroundColor: Color(0xFF064E3B)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAyahActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.bgCard,
                border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: DesignSystem.goldLight, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: DesignSystem.textWhite, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showSurahSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          decoration: BoxDecoration(
            color: DesignSystem.bgDarkest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر سورة للقراءة والاستماع',
                style: TextStyle(color: DesignSystem.goldLight, fontSize: 18, fontWeight: FontWeight.bold),
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
                      title: Text(
                        '${surah.number}. سورة ${surah.nameArabic}',
                        style: TextStyle(
                          color: isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('الجزء ${surah.juzNumber} • ${surah.ayahCount} آية',
                          style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                      trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: DesignSystem.gold) : null,
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
        );
      },
    );
  }

  void _showReciterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          decoration: BoxDecoration(
            color: DesignSystem.bgDarkest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر القارئ المفضل',
                style: TextStyle(color: DesignSystem.goldLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...RecitersData.reciters.take(6).map((reciter) {
                final isCurrent = _audio.currentReciter.id == reciter.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: reciter.photoUrl.startsWith('assets/')
                        ? AssetImage(reciter.photoUrl)
                        : NetworkImage(reciter.photoUrl),
                  ),
                  title: Text(
                    reciter.nameArabic,
                    style: TextStyle(
                      color: isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(reciter.country, style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                  trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: DesignSystem.gold) : null,
                  onTap: () {
                    _audio.selectReciter(reciter);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => IqraSettingsSheet(
        fontSize: _fontSize,
        theme: _readingTheme,
        onFontSizeChanged: (val) => setState(() => _fontSize = val),
        onThemeChanged: (val) => setState(() => _readingTheme = val),
      ),
    );
  }
}
