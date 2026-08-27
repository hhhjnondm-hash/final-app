import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
import '../widgets/quran_audio_player.dart';
import '../widgets/verse_action_sheet.dart';

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
  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;
  int? _activeAyah;
  bool _showAudioPlayer = false;

  @override
  void initState() {
    super.initState();
    _loadSurahData();
  }

  Future<void> _loadSurahData() async {
    await QuranService.loadQuranData();
    final list = QuranService.getSurahAyahs(widget.surahNumber) ?? [];
    if (mounted) {
      setState(() {
        _ayahs = list;
        _isLoading = false;
      });

      // Update Reading Progress
      _storage.updateReadingProgress(
        surahNumber: widget.surahNumber,
        surahName: widget.surahName,
        ayahNumber: 1,
        juz: 1,
        progress: widget.surahNumber / 114.0,
      );
    }
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _storage.readingTheme == 'oled'
        ? Colors.black
        : (_storage.readingTheme == 'sepia'
            ? const Color(0xFFFBF0D9)
            : DesignSystem.bgDarkest);

    final textColor = _storage.readingTheme == 'sepia'
        ? const Color(0xFF2C2416)
        : DesignSystem.textWhite;

    final isFav = _storage.isFavorite(widget.surahNumber);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _storage.readingTheme == 'sepia' ? Colors.brown.shade900 : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'سورة ${widget.surahName}',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_ayahs.isNotEmpty)
              Text(
                '${_ayahs.length} آيات',
                style: const TextStyle(
                  color: DesignSystem.goldLight,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFav ? DesignSystem.gold : DesignSystem.textMuted,
            ),
            onPressed: () => setState(() => _storage.toggleFavorite(widget.surahNumber)),
          ),
          IconButton(
            icon: Icon(
              _showAudioPlayer ? Icons.headphones_rounded : Icons.headphones_outlined,
              color: _showAudioPlayer ? DesignSystem.gold : DesignSystem.textMuted,
            ),
            onPressed: () => setState(() => _showAudioPlayer = !_showAudioPlayer),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: DesignSystem.textMuted),
            onPressed: _showReadingSettingsSheet,
          ),
        ],
      ),
      bottomNavigationBar: _showAudioPlayer
          ? QuranAudioPlayer(
              surahName: widget.surahName,
              currentAyah: _activeAyah ?? 1,
              totalAyahs: _ayahs.length,
              onClose: () => setState(() => _showAudioPlayer = false),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DesignSystem.gold))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Surah Header Banner (Basmala & Surah Title Frame)
                      _buildSurahOrnamentalBanner(),

                      const SizedBox(height: 24),

                      // Continuous Mushaf Reading Flow
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: _storage.readingTheme == 'sepia'
                              ? const Color(0xFFFDF7E7)
                              : DesignSystem.bgCard.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _storage.readingTheme == 'sepia'
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.45)
                                : DesignSystem.gold.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: _storage.fontSize,
                                height: 2.3,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                              children: _buildMushafSpans(textColor),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSurahOrnamentalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignSystem.bgCard,
            DesignSystem.bgDarkest,
          ],
        ),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'سورة ${widget.surahName}',
            style: const TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.surahNumber != 9 && widget.surahNumber != 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                color: DesignSystem.gold.withValues(alpha: 0.1),
                border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.25)),
              ),
              child: const Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: DesignSystem.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<InlineSpan> _buildMushafSpans(Color textColor) {
    final List<InlineSpan> spans = [];
    final activeBgColor = DesignSystem.gold.withValues(alpha: 0.22);
    final activeTextColor = _storage.readingTheme == 'sepia' ? const Color(0xFF8B5A00) : DesignSystem.goldLight;
    final goldColor = _storage.readingTheme == 'sepia' ? const Color(0xFFB8860B) : DesignSystem.gold;

    for (final ayah in _ayahs) {
      final int num = (ayah['ayahNumber'] ?? ayah['number'] ?? 1) as int;
      var text = ((ayah['text'] ?? '') as String).trim();
      final bool isActive = _activeAyah == num;

      if (widget.surahNumber != 1 && num == 1 && text.startsWith('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')) {
        text = text.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
      }

      // Ayah Text
      spans.add(
        TextSpan(
          text: '$text ',
          style: TextStyle(
            color: isActive ? activeTextColor : textColor,
            backgroundColor: isActive ? activeBgColor : Colors.transparent,
            fontSize: _storage.fontSize,
            height: 2.3,
            fontFamily: 'Amiri',
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              setState(() => _activeAyah = num);
              _openAyahActionSheet(num, text);
            },
        ),
      );

      // Golden Ayah End Marker ﴿١﴾
      spans.add(
        TextSpan(
          text: ' ﴿${_toArabicDigits(num)}﴾ ',
          style: TextStyle(
            color: isActive ? DesignSystem.goldLight : goldColor,
            backgroundColor: isActive ? activeBgColor : Colors.transparent,
            fontSize: _storage.fontSize * 0.82,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              setState(() => _activeAyah = num);
              _openAyahActionSheet(num, text);
            },
        ),
      );
    }

    return spans;
  }

  void _openAyahActionSheet(int ayahNumber, String ayahText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseActionSheet(
        surahNumber: widget.surahNumber,
        surahName: widget.surahName,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
        onPlayAudio: () {
          setState(() {
            _activeAyah = ayahNumber;
            _showAudioPlayer = true;
          });
        },
      ),
    );
  }

  void _showReadingSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignSystem.bgDarkest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(DesignSystem.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'إعدادات القراءة',
                      style: TextStyle(
                        color: DesignSystem.goldLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Font Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('حجم الخط', style: TextStyle(color: Colors.white)),
                      Text('${_storage.fontSize.toInt()}', style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _storage.fontSize,
                    min: 16,
                    max: 36,
                    divisions: 10,
                    activeColor: DesignSystem.gold,
                    onChanged: (val) {
                      _storage.setFontSize(val);
                      setSheetState(() {});
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Reading Themes
                  const Text('سمة العرض والخلفية', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildThemeOption('dark', 'ليلي فاخر', DesignSystem.bgDarkest, Colors.white, setSheetState),
                      const SizedBox(width: 8),
                      _buildThemeOption('oled', 'أسود خالص', Colors.black, Colors.white, setSheetState),
                      const SizedBox(width: 8),
                      _buildThemeOption('sepia', 'مصحف تقليدي', const Color(0xFFFBF0D9), const Color(0xFF2C2416), setSheetState),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption(String key, String label, Color bg, Color text, StateSetter setSheetState) {
    final isSelected = _storage.readingTheme == key;
    return Expanded(
      child: InkWell(
        onTap: () {
          _storage.setReadingTheme(key);
          setSheetState(() {});
          setState(() {});
        },
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            border: Border.all(
              color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'بسم الله',
                style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: text.withValues(alpha: 0.7), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

