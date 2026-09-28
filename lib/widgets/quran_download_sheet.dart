import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import '../services/quran_audio_downloader.dart';
import '../services/audio_quran_service.dart';
import '../utils/design_system.dart';
import 'quran_download_progress_sheet.dart';

class QuranDownloadSheet extends StatefulWidget {
  final ReciterProfile reciter;
  final SurahMeta currentSurah;

  const QuranDownloadSheet({
    super.key,
    required this.reciter,
    required this.currentSurah,
  });

  static void show(
    BuildContext context, {
    required ReciterProfile reciter,
    required SurahMeta currentSurah,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuranDownloadSheet(
        reciter: reciter,
        currentSurah: currentSurah,
      ),
    );
  }

  @override
  State<QuranDownloadSheet> createState() => _QuranDownloadSheetState();
}

class _QuranDownloadSheetState extends State<QuranDownloadSheet> {
  final QuranAudioDownloader _downloader = QuranAudioDownloader();
  final AudioQuranService _audioService = AudioQuranService();
  String _searchQuery = '';
  final Set<int> _downloadingSurahNumbers = {};
  final Set<int> _downloadedSurahNumbers = {};

  bool _isFullDownloading = false;
  int _fullDownloadedCount = 0;
  String _fullCurrentSurahName = '';
  double _fullCurrentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkInitialDownloadedSurahs();
  }

  void _checkInitialDownloadedSurahs() {
    final allSurahs = QuranMetadataProvider.getAllSurahs();
    for (final s in allSurahs) {
      if (_audioService.isDownloaded(widget.reciter.id, s.number)) {
        _downloadedSurahNumbers.add(s.number);
      }
    }
  }

  Future<void> _downloadSurah(SurahMeta surah) async {
    if (_downloadingSurahNumbers.contains(surah.number)) return;

    setState(() {
      _downloadingSurahNumbers.add(surah.number);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: DesignSystem.goldLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'جاري تنزيل سورة ${surah.nameArabic} للقارئ ${widget.reciter.nameArabic} في مجلد الموسيقى...',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF101D2C),
      ),
    );

    final success = await _downloader.downloadSingleSurah(
      reciter: widget.reciter,
      surah: surah,
    );

    if (mounted) {
      setState(() {
        _downloadingSurahNumbers.remove(surah.number);
        if (success) {
          _downloadedSurahNumbers.add(surah.number);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: success ? const Color(0xFF38B982) : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'تم تنزيل سورة ${surah.nameArabic} بنجاح! متاحة الآن في تطبيق الموسيقى على هاتفك.'
                      : 'تعذر تنزيل سورة ${surah.nameArabic}، تأكد من الاتصال بالإنترنت.',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: success ? const Color(0xFF0C2417) : const Color(0xFF361014),
        ),
      );
    }
  }

  void _downloadFullQuran() {
    Navigator.pop(context);
    QuranDownloadProgressSheet.show(context);
    _downloader.downloadFullQuran(
      reciter: widget.reciter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSurahs = QuranMetadataProvider.getAllSurahs();
    final filteredSurahs = _searchQuery.trim().isEmpty
        ? allSurahs
        : allSurahs.where((s) {
            return s.nameArabic.contains(_searchQuery.trim()) ||
                s.number.toString() == _searchQuery.trim() ||
                s.nameEnglish.toLowerCase().contains(_searchQuery.trim().toLowerCase());
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: DesignSystem.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Reciter Info Banner
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DesignSystem.gold, width: 1.5),
                  ),
                  child: ClipOval(
                    child: widget.reciter.photoUrl.startsWith('assets/')
                        ? Image.asset(
                            widget.reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: DesignSystem.goldLight),
                          )
                        : Image.network(
                            widget.reciter.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: DesignSystem.goldLight),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تنزيل سور القارئ: ${widget.reciter.nameArabic}',
                        style: const TextStyle(
                          color: DesignSystem.goldLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.reciter.country} • ${widget.reciter.style} • 114 سورة متوفرة للتنزيل',
                        style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'سجل التنزيلات المباشر 📜',
                  icon: const Icon(Icons.history_rounded, color: DesignSystem.goldLight),
                  onPressed: () {
                    Navigator.pop(context);
                    QuranDownloadProgressSheet.show(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: DesignSystem.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Top Two Main Options
            Row(
              children: [
                // Option 1: تنزيل السورة الحالية
                Expanded(
                  child: InkWell(
                    onTap: () => _downloadSurah(widget.currentSurah),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: DesignSystem.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DesignSystem.gold.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🎧', style: TextStyle(fontSize: 18)),
                              Icon(Icons.download_rounded, color: DesignSystem.goldLight, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تنزيل سورة ${widget.currentSurah.nameArabic}',
                            style: const TextStyle(
                              color: DesignSystem.textWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'السورة الحالية المحددة',
                            style: TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Option 2: تنزيل المصحف كاملًا
                Expanded(
                  child: InkWell(
                    onTap: _isFullDownloading ? null : _downloadFullQuran,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: DesignSystem.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF38B982).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('📥', style: TextStyle(fontSize: 18)),
                              Icon(Icons.cloud_download_rounded, color: Color(0xFF38B982), size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'تنزيل المصحف كاملًا',
                            style: TextStyle(
                              color: DesignSystem.textWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isFullDownloading
                                ? 'جاري: $_fullDownloadedCount/114 ($_fullCurrentSurahName)'
                                : 'جميع الـ 114 سورة دفعة واحدة',
                            style: TextStyle(
                              color: _isFullDownloading ? const Color(0xFF38B982) : DesignSystem.textMuted,
                              fontSize: 10,
                              fontWeight: _isFullDownloading ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isFullDownloading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _fullDownloadedCount / 114.0,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38B982)),
                  minHeight: 6,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Search Bar for 114 Surahs
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: DesignSystem.bgCard.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن أي سورة لتنزيلها (مثال: البقرة، الكهف، يس، الملك...)',
                  hintStyle: TextStyle(color: DesignSystem.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: DesignSystem.goldLight, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Surahs Count Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اختر أي سورة للتنزيل المباشر في هاتفك:',
                    style: TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${filteredSurahs.length} سورة',
                    style: const TextStyle(color: DesignSystem.goldLight, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 114 Surahs List with Direct Download
            Expanded(
              child: ListView.builder(
                itemCount: filteredSurahs.length,
                itemBuilder: (context, index) {
                  final surah = filteredSurahs[index];
                  final isDownloading = _downloadingSurahNumbers.contains(surah.number);
                  final isDownloaded = _downloadedSurahNumbers.contains(surah.number);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: DesignSystem.bgCard.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDownloaded
                            ? const Color(0xFF38B982).withValues(alpha: 0.4)
                            : (isDownloading
                                ? DesignSystem.gold.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.06)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Surah Number
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: DesignSystem.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              surah.number.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: DesignSystem.goldLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Surah Meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سورة ${surah.nameArabic}',
                                style: const TextStyle(
                                  color: DesignSystem.textWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${surah.isMeccan ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آية • ${surah.nameEnglish}',
                                style: const TextStyle(
                                  color: DesignSystem.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons: Play & Download
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline_rounded, color: DesignSystem.goldLight, size: 22),
                              tooltip: 'استماع',
                              onPressed: () {
                                _audioService.selectSurah(surah);
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 4),
                            if (isDownloading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DesignSystem.goldLight,
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                                  color: isDownloaded ? const Color(0xFF38B982) : DesignSystem.goldLight,
                                  size: 22,
                                ),
                                tooltip: isDownloaded ? 'تم التنزيل في جهازك' : 'تنزيل السورة',
                                onPressed: () => _downloadSurah(surah),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
