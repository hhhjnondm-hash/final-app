import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/quran_models.dart';
import '../services/audio_quran_service.dart';
import '../services/global_audio_manager.dart';
import '../services/quran_service.dart';
import '../services/quran_storage_service.dart';
import '../widgets/iqra_tafsir_sheet.dart';

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

class _SurahViewerScreenState extends State<SurahViewerScreen> with SingleTickerProviderStateMixin {
  final QuranStorageService _storage = QuranStorageService();
  final AudioQuranService _audioService = AudioQuranService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late int _currentSurahNumber;
  late String _currentSurahName;
  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;

  // Active / Selected Ayah
  int _activeAyahNumber = 2;

  // Search filter inside surah
  bool _isSearching = false;
  String _ayahSearchQuery = '';

  // Audio Player visibility state
  bool _showAudioPlayerBar = true;

  // Settings State
  bool _isFullscreen = false;
  double _fontSize = 22.0;
  double _lineHeight = 2.1;
  String _selectedFont = 'Amiri';
  String _currentTheme = 'داكن'; // 'داكن', 'كحلي', 'ورقي', 'أخضر', 'أبيض'

  // Theme definitions
  Color get _backgroundColor {
    switch (_currentTheme) {
      case 'كحلي':
        return const Color(0xFF0A111E);
      case 'ورقي':
        return const Color(0xFFFBF4E4);
      case 'أخضر':
        return const Color(0xFF071B13);
      case 'أبيض':
        return const Color(0xFFFAF9F6);
      case 'داكن':
      default:
        return const Color(0xFF060910);
    }
  }

  Color get _textColor {
    switch (_currentTheme) {
      case 'ورقي':
      case 'أبيض':
        return const Color(0xFF1E170A);
      case 'كحلي':
        return const Color(0xFFF1F5F9);
      case 'أخضر':
        return const Color(0xFFF0FDF4);
      case 'داكن':
      default:
        return const Color(0xFFFFFDF8);
    }
  }

  Color get _goldColor => const Color(0xFFE5B54F);
  Color get _goldDimColor => const Color(0xFFC89B3C);

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;
    _currentSurahName = widget.surahName;
    _audioService.addListener(_onAudioStateChanged);
    _loadSurahData();
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _scrollController.dispose();
    _searchController.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSurahData() async {
    setState(() => _isLoading = true);
    await QuranService.loadQuranData();
    final list = QuranService.getSurahAyahs(_currentSurahNumber) ?? [];
    final meta = QuranMetadataProvider.getSurah(_currentSurahNumber);

    if (mounted) {
      setState(() {
        _ayahs = list;
        _currentSurahName = meta.nameArabic;
        _isLoading = false;
        if (_activeAyahNumber > meta.ayahCount || _activeAyahNumber < 1) {
          _activeAyahNumber = 1;
        }
      });

      _storage.updateReadingProgress(
        surahNumber: _currentSurahNumber,
        surahName: _currentSurahName,
        ayahNumber: _activeAyahNumber,
        juz: meta.juzNumber,
        progress: _currentSurahNumber / 114.0,
      );
    }
  }

  void _goToNextSurah() {
    if (_currentSurahNumber < 114) {
      setState(() {
        _currentSurahNumber++;
        _activeAyahNumber = 1;
      });
      _loadSurahData();
      _scrollToTop();
      if (_audioService.isPlaying) {
        _audioService.playSurah(_currentSurahNumber);
      }
    }
  }

  void _goToPreviousSurah() {
    if (_currentSurahNumber > 1) {
      setState(() {
        _currentSurahNumber--;
        _activeAyahNumber = 1;
      });
      _loadSurahData();
      _scrollToTop();
      if (_audioService.isPlaying) {
        _audioService.playSurah(_currentSurahNumber);
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _toggleSurahAudio() async {
    final isCurPlaying = _audioService.isPlaying && _audioService.currentSurah.number == _currentSurahNumber;
    if (isCurPlaying) {
      await _audioService.togglePlayPause();
    } else {
      await _audioService.playSurah(_currentSurahNumber);
    }
    setState(() {
      _showAudioPlayerBar = true;
    });
  }

  void _toggleBookmark() {
    final isFav = _storage.isFavorite(_currentSurahNumber);
    _storage.toggleFavorite(_currentSurahNumber);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav ? 'تمت إزالة السورة من المحفوظات' : 'تم حفظ سورة $_currentSurahName في العلامات المرجعية',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF141C2B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _goldColor),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final meta = QuranMetadataProvider.getSurah(_currentSurahNumber);
    final isFavorite = _storage.isFavorite(_currentSurahNumber);
    final isAudioPlaying = _audioService.isPlaying && _audioService.currentSurah.number == _currentSurahNumber;

    final displayedAyahs = _ayahSearchQuery.trim().isEmpty
        ? _ayahs
        : _ayahs.where((a) => ((a['text'] ?? '') as String).contains(_ayahSearchQuery.trim())).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // 1. Top App Bar
              if (!_isFullscreen) ...[
                const SizedBox(height: 6),
                _buildTopAppBar(meta, isFavorite),
                const SizedBox(height: 10),

                // 2. Action Toolbar Pills Row with Dedicated Audio Button
                _buildActionToolbarPills(),
                const SizedBox(height: 10),
              ],

              // Inline Ayah Search Bar if active
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121927),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _goldColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Color(0xFFE5B54F), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'ابحث عن آية في هذه السورة...',
                              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) => setState(() => _ayahSearchQuery = val),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isSearching = false;
                              _ayahSearchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Verses Reader Body
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: _goldColor))
                    : Stack(
                        children: [
                          // Center Mosque Watermark Silhouette near bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 140,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.18,
                                child: Image.asset(
                                  'assets/img_coran/pack/scene_window_mosque.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/home_hero_mosque.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Scrollable Verses List
                          ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: displayedAyahs.length + (_currentSurahNumber != 9 ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Item 0: Basmalah (except for Surah At-Tawbah)
                              if (_currentSurahNumber != 9 && index == 0) {
                                return _buildBasmalahHeader();
                              }

                              final ayahIndex = _currentSurahNumber != 9 ? index - 1 : index;
                              final ayah = displayedAyahs[ayahIndex];
                              final int num = (ayah['ayahNumber'] ?? ayah['number'] ?? (ayahIndex + 1)) as int;
                              var text = ((ayah['text'] ?? '') as String).trim();

                              // Clean duplicate Basmalah from Ayah 1 in other surahs
                              if (_currentSurahNumber != 1 && num == 1 && text.startsWith('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')) {
                                text = text.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
                              }

                              final isActive = _activeAyahNumber == num;

                              return Column(
                                children: [
                                  _buildAyahItem(num, text, isActive),
                                  if (ayahIndex < displayedAyahs.length - 1)
                                    _buildAyahDivider(),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
              ),

              // 4. Floating Audio Player Bar (when audio is active / toggled)
              if (_showAudioPlayerBar && (isAudioPlaying || _audioService.currentPosition.inSeconds > 0)) ...[
                _buildLiveAudioPlayerFloatingBar(),
              ],

              // 5. Surah Navigation Row
              if (!_isFullscreen) ...[
                _buildSurahNavigationRow(),
                const SizedBox(height: 6),

                // 6. App Bottom Navigation Bar
                _buildAppBottomNavBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Top Bar: [< Back] [Bookmark] | [❖ سورة الأنفال ❖ / Subtitle] | [Search] [Settings] [Fullscreen]
  Widget _buildTopAppBar(SurahMeta meta, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Circular Back Button
          _buildCircularButton(
            icon: Icons.chevron_left_rounded,
            size: 26,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),

          // Bookmark Button
          _buildCircularButton(
            icon: isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            iconColor: isFavorite ? _goldColor : const Color(0xFFCBD5E1),
            size: 20,
            onTap: _toggleBookmark,
          ),

          const Spacer(),

          // Center: Title + Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('❖ ', style: TextStyle(color: _goldColor, fontSize: 11)),
                  Text(
                    'سُورَةُ $_currentSurahName',
                    style: TextStyle(
                      fontFamily: _selectedFont,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(' ❖', style: TextStyle(color: _goldColor, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('❖ ', style: TextStyle(color: _goldColor.withValues(alpha: 0.7), fontSize: 9)),
                  Text(
                    'الجزء ${meta.juzNumber} • صفحة ${meta.pageNumber} • ${meta.ayahCount} آية',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(' ❖', style: TextStyle(color: _goldColor.withValues(alpha: 0.7), fontSize: 9)),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Right action buttons: [Search] [Settings] [Fullscreen]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircularButton(
                icon: Icons.search_rounded,
                size: 20,
                onTap: () => setState(() => _isSearching = !_isSearching),
              ),
              const SizedBox(width: 8),
              _buildCircularButton(
                icon: Icons.settings_outlined,
                size: 20,
                onTap: _showSettingsBottomSheet,
              ),
              const SizedBox(width: 8),
              _buildCircularButton(
                icon: _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                iconColor: _isFullscreen ? _goldColor : const Color(0xFFCBD5E1),
                size: 22,
                onTap: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Circular Icon Button with subtle dark border
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    double size = 20,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF101725).withValues(alpha: 0.8),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.7),
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

  /// Quick Action Toolbar Pills: [حجم الخط A A] [ألوان القراءة 🎨] [الوضع الليلي 🌙] [▶ مِشَارِي العَفَاسِي ˅]
  Widget _buildActionToolbarPills() {
    final isPlaying = _audioService.isPlaying && _audioService.currentSurah.number == _currentSurahNumber;
    final reciterName = _audioService.currentReciter.nameArabic.replaceAll('مشاري بن راشد العفاسي', 'مشاري العفاسي');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Pill 1: Font size
          _buildToolbarPill(
            icon: Icons.text_fields_rounded,
            label: 'حجم الخط',
            trailing: const Text('A A', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5B54F))),
            onTap: _showFontSizeSheet,
          ),
          const SizedBox(width: 8),

          // Pill 2: Reading Colors
          _buildToolbarPill(
            icon: Icons.palette_outlined,
            label: 'ألوان القراءة',
            onTap: _showReadingColorsSheet,
          ),
          const SizedBox(width: 8),

          // Pill 3: Night Mode
          _buildToolbarPill(
            icon: _currentTheme == 'داكن' ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            label: 'الوضع الليلي',
            onTap: () {
              setState(() {
                if (_currentTheme == 'داكن') {
                  _currentTheme = 'ورقي';
                } else {
                  _currentTheme = 'داكن';
                }
              });
            },
          ),
          const SizedBox(width: 8),

          // Pill 4: Dedicated Live Reciter & Audio Play Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isPlaying ? const Color(0xFF231B0A) : const Color(0xFF101725).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isPlaying ? _goldColor : const Color(0xFF334155).withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: _goldColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio Play/Pause Direct Button
                InkWell(
                  onTap: _toggleSurahAudio,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isPlaying
                            ? [_goldColor, const Color(0xFFC89B3C)]
                            : [const Color(0xFF263345), const Color(0xFF192230)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: isPlaying ? const Color(0xFF070B11) : _goldColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Reciter Name & Dropdown
                InkWell(
                  onTap: _showReciterSelectionSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reciterName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPlaying ? _goldColor : const Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarPill({
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF101725).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _goldColor, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  /// Live Floating Audio Player Bar with seek bar and controls
  Widget _buildLiveAudioPlayerFloatingBar() {
    final isPlaying = _audioService.isPlaying && _audioService.currentSurah.number == _currentSurahNumber;
    final pos = _audioService.currentPosition;
    final dur = _audioService.totalDuration;
    final totalMs = dur.inMilliseconds.toDouble();
    final curMs = pos.inMilliseconds.toDouble().clamp(0.0, totalMs > 0 ? totalMs : 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121A28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _goldColor.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (isPlaying)
            BoxShadow(
              color: _goldColor.withValues(alpha: 0.15),
              blurRadius: 18,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Large Play/Pause Button
              InkWell(
                onTap: _toggleSurahAudio,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_goldColor, const Color(0xFFC89B3C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _goldColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF070B11),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Reciter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'تلاوة سورة $_currentSurahName',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.graphic_eq_rounded, color: Color(0xFFE5B54F), size: 16),
                        ],
                      ],
                    ),
                    Text(
                      _audioService.currentReciter.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFFE8D29A),
                      ),
                    ),
                  ],
                ),
              ),

              // Timestamps
              Text(
                '${_audioService.formatDuration(pos)} / ${_audioService.formatDuration(dur)}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: 8),

              // Close Bar Button
              InkWell(
                onTap: () => setState(() => _showAudioPlayerBar = false),
                child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
              ),
            ],
          ),

          // Mini Seek Track
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.0,
              activeTrackColor: _goldColor,
              inactiveTrackColor: const Color(0xFF334155),
              thumbColor: _goldColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: curMs,
              min: 0.0,
              max: totalMs > 0 ? totalMs : 1.0,
              onChanged: (val) {
                final target = Duration(milliseconds: val.toInt());
                GlobalAudioManager().seek(target);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Basmalah Header
  Widget _buildBasmalahHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _selectedFont,
                fontSize: _fontSize + 2,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            if (_currentSurahNumber == 1) ...[
              const SizedBox(width: 8),
              _buildAyahRosetteBadge(1),
            ],
          ],
        ),
      ),
    );
  }

  /// Individual Ayah Item with Gold Rosette and Active Gold Encasement matching media_1789448573582.png
  Widget _buildAyahItem(int ayahNum, String text, bool isActive) {
    return InkWell(
      onTap: () {
        setState(() => _activeAyahNumber = ayahNum);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _goldDimColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _goldColor : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _goldColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Top and Bottom ornamental mini diamond nodes when active
            if (isActive) ...[
              Positioned(
                top: -16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 14, height: 1, color: _goldColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text('❖', style: TextStyle(color: _goldColor, fontSize: 8)),
                    ),
                    Container(width: 14, height: 1, color: _goldColor),
                  ],
                ),
              ),
              Positioned(
                bottom: -16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 14, height: 1, color: _goldColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text('❖', style: TextStyle(color: _goldColor, fontSize: 8)),
                    ),
                    Container(width: 14, height: 1, color: _goldColor),
                  ],
                ),
              ),
            ],

            // Verse Content Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Right Islamic Floral Star
                Text(
                  '❖',
                  style: TextStyle(
                    color: isActive ? _goldColor : _goldDimColor.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),

                // Center Verse Arabic Text
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
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
                const SizedBox(width: 10),

                // Left Ornate Islamic Ayah Rosette Medallion
                _buildAyahRosetteBadge(ayahNum, isActive: isActive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Subtle gold divider between non-active ayahs
  Widget _buildAyahDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: _goldDimColor.withValues(alpha: 0.18),
              thickness: 0.6,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '❖',
              style: TextStyle(color: _goldDimColor.withValues(alpha: 0.4), fontSize: 8),
            ),
          ),
          Expanded(
            child: Divider(
              color: _goldDimColor.withValues(alpha: 0.18),
              thickness: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Golden Islamic Rosette Medallion Badge for Ayah Number
  Widget _buildAyahRosetteBadge(int ayahNumber, {bool isActive = false}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _AyahRosettePainter(
          borderColor: isActive ? _goldColor : _goldDimColor,
          glow: isActive,
        ),
        child: Center(
          child: Text(
            _toArabicDigits(ayahNumber),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? _goldColor : _textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Surah Navigation Row: [< السورة السابقة] | [ 8 / 114 Slider ] | [السورة التالية >]
  Widget _buildSurahNavigationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Previous Surah Button
          InkWell(
            onTap: _goToPreviousSurah,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF101725).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chevron_right_rounded, color: Color(0xFFE5B54F), size: 18),
                  SizedBox(width: 4),
                  Text(
                    'السورة السابقة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Center Slider & Surah Counter
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.5,
                    activeTrackColor: _goldColor,
                    inactiveTrackColor: const Color(0xFF334155),
                    thumbColor: _goldColor,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayColor: _goldColor.withValues(alpha: 0.2),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _currentSurahNumber.toDouble(),
                    min: 1.0,
                    max: 114.0,
                    onChanged: (val) {
                      final newNum = val.round();
                      if (newNum != _currentSurahNumber) {
                        setState(() {
                          _currentSurahNumber = newNum;
                          _activeAyahNumber = 1;
                        });
                        _loadSurahData();
                        if (_audioService.isPlaying) {
                          _audioService.playSurah(_currentSurahNumber);
                        }
                      }
                    },
                  ),
                ),
                Text(
                  '$_currentSurahNumber / 114',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Next Surah Button
          InkWell(
            onTap: _goToNextSurah,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF101725).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'السورة التالية',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_left_rounded, color: Color(0xFFE5B54F), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// App Bottom Navigation Bar matching media_1789448573582.png
  Widget _buildAppBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'الرئيسية', false, () => Navigator.pop(context)),
          // Active Quran Tab with Luxurious Gold Gradient Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE5B54F), Color(0xFFC89B3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5B54F).withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.menu_book_rounded, color: Color(0xFF070B11), size: 18),
                SizedBox(width: 6),
                Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF070B11),
                  ),
                ),
              ],
            ),
          ),
          _buildNavItem(Icons.groups_outlined, 'المصاحف', false, () {
            Navigator.pop(context);
          }),
          _buildNavItem(Icons.radio_outlined, 'الراديو', false, () {
            Navigator.pop(context);
          }),
          _buildNavItem(Icons.access_time_outlined, 'المواعيد', false, () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8E9BAE)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: Color(0xFF8E9BAE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Font Size Adjustment Bottom Sheet
  void _showFontSizeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Text('تخصيص حجم ونمط الخط', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('حجم الخط', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
                        Text('${_fontSize.toInt()}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _goldColor)),
                      ],
                    ),
                    Slider(
                      value: _fontSize,
                      min: 18.0,
                      max: 36.0,
                      activeColor: _goldColor,
                      onChanged: (val) {
                        setSheetState(() => _fontSize = val);
                        setState(() => _fontSize = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تباعد الأسطر', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
                        Text(_lineHeight.toStringAsFixed(1), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _goldColor)),
                      ],
                    ),
                    Slider(
                      value: _lineHeight,
                      min: 1.6,
                      max: 3.0,
                      activeColor: _goldColor,
                      onChanged: (val) {
                        setSheetState(() => _lineHeight = val);
                        setState(() => _lineHeight = val);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Reading Colors Bottom Sheet
  void _showReadingColorsSheet() {
    final themes = [
      {'id': 'داكن', 'name': 'الوضع الداكن الملكي', 'color': const Color(0xFF060910)},
      {'id': 'كحلي', 'name': 'الوضع الليلي الكحلي', 'color': const Color(0xFF0A111E)},
      {'id': 'ورقي', 'name': 'الورقي الدافئ', 'color': const Color(0xFFFBF4E4)},
      {'id': 'أخضر', 'name': 'أخضر الروضة', 'color': const Color(0xFF071B13)},
      {'id': 'أبيض', 'name': 'الأبيض النقي', 'color': const Color(0xFFFAF9F6)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('ألوان وثيم القراءة', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ...themes.map((t) {
                  final isSel = _currentTheme == t['id'];
                  return ListTile(
                    onTap: () {
                      setState(() => _currentTheme = t['id'] as String);
                      Navigator.pop(ctx);
                    },
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: t['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: _goldColor),
                      ),
                    ),
                    title: Text(t['name'] as String, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13)),
                    trailing: isSel ? Icon(Icons.check_circle_rounded, color: _goldColor) : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Reciter Selection Bottom Sheet
  void _showReciterSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final currentReciter = _audioService.currentReciter;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('اختر القارئ المفضل', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: RecitersData.reciters.length,
                    itemBuilder: (c, idx) {
                      final r = RecitersData.reciters[idx];
                      final isSel = r.id == currentReciter.id;
                      return ListTile(
                        onTap: () async {
                          await _audioService.selectReciter(r, autoPlay: true);
                          await _audioService.playSurah(_currentSurahNumber);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          setState(() {
                            _showAudioPlayerBar = true;
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B2433),
                          child: Icon(Icons.person_rounded, color: isSel ? _goldColor : const Color(0xFF94A3B8)),
                        ),
                        title: Text(
                          r.nameArabic,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? _goldColor : Colors.white,
                          ),
                        ),
                        subtitle: Text(r.style, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF94A3B8))),
                        trailing: isSel ? Icon(Icons.check_circle_rounded, color: _goldColor) : null,
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

  /// General Settings Bottom Sheet
  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('إعدادات المصحف الشريف', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.volume_up_rounded, color: _goldColor),
                  title: const Text('تشغيل / إيقاف الصوت', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleSurahAudio();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.text_fields_rounded, color: _goldColor),
                  title: const Text('حجم ونمط الخط', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFontSizeSheet();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: _goldColor),
                  title: const Text('ثيم وألوان القراءة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReadingColorsSheet();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.record_voice_over_outlined, color: _goldColor),
                  title: const Text('اختيار القارئ الصوتي', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReciterSelectionSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom Painter for 12-lobed Ornate Islamic Ayah Rosette Medallion
class _AyahRosettePainter extends CustomPainter {
  final Color borderColor;
  final bool glow;

  _AyahRosettePainter({required this.borderColor, this.glow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Optional Glow Aura
    if (glow) {
      final glowPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius - 2, glowPaint);
    }

    // Outer Scalloped Petal Path (12 Petals)
    final path = Path();
    const int lobes = 12;
    for (int i = 0; i < lobes * 2; i++) {
      final angle = (i * math.pi) / lobes;
      final r = (i % 2 == 0) ? radius - 1.5 : radius - 4.5;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final outerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, outerPaint);

    // Inner Concentric Circle
    final innerCirclePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 6.5, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant _AyahRosettePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor || oldDelegate.glow != glow;
  }
}
