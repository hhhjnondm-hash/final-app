import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import '../services/audio_quran_service.dart';
import '../services/quran_audio_downloader.dart';
import '../services/robust_quran_audio_service.dart';
import '../adapters/reciter_adapter.dart';
import '../utils/design_system.dart';
import '../widgets/audio_hero_player.dart';
import '../widgets/audio_mini_player.dart';
import '../widgets/reciter_card.dart';
import '../widgets/audio_diagnostic_dialog.dart';
import '../widgets/developer_credits_badge.dart';
import '../widgets/floating_download_tracker.dart';
import '../widgets/quran_download_progress_sheet.dart';
import '../widgets/visual_effects/floating_particles.dart';
import '../widgets/visual_effects/interactive_motion_card.dart';
import '../widgets/visual_effects/star_glint.dart';
import '../widgets/islamic_background.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final AudioQuranService _audioService = AudioQuranService();
  String _searchQuery = '';
  ReciterCategory _selectedCategory = ReciterCategory.all;
  bool _useRealApi = false; // Toggle for real API vs local data

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_onServiceUpdate);
    _initializeReciters();
  }

  Future<void> _initializeReciters() async {
    // Optionally fetch from real API
    if (_useRealApi) {
      try {
        final apiReciters = await ReciterAdapter.fetchReciterProfiles();
        if (apiReciters.isNotEmpty) {
          debugPrint('✅ Loaded ${apiReciters.length} reciters from API');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load from API, using local data: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allReciters = RecitersData.reciters;
    final popularReciters = allReciters.where((r) => r.category == ReciterCategory.popular).toList();

    // Filter reciters
    final filteredReciters = allReciters.where((r) {
      final matchesCategory = _selectedCategory == ReciterCategory.all || r.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          r.nameArabic.contains(_searchQuery) ||
          r.nameEnglish.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.country.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    final isLight = DesignSystem.isLightMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IslamicBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Background subtle floating golden particles (GPU-isolated)
              const Positioned.fill(
                child: RepaintBoundary(
                  child: FloatingParticles(
                    numberOfParticles: 14,
                    particleColor: DesignSystem.goldLight,
                  ),
                ),
              ),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Top Luxury Header
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

                      // Search Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignSystem.spacingL,
                            vertical: DesignSystem.spacingS,
                          ),
                          child: _buildSearchBar(),
                        ),
                      ),

                      // Hero Audio Player
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignSystem.spacingL,
                            vertical: DesignSystem.spacingS,
                          ),
                          child: AudioHeroPlayer(
                            onSurahChangeTap: () => _showSurahSelectorModal(context),
                            onReciterChangeTap: () => _showSurahSelectorModal(context),
                          ),
                        ),
                      ),

                      // Horizontal Category Filter Pills
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacingM),
                          child: _buildCategoryPills(),
                        ),
                      ),

                      // Section Title: القراء المشهورون
                      if (_selectedCategory == ReciterCategory.all && _searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              DesignSystem.spacingL,
                              DesignSystem.spacingS,
                              DesignSystem.spacingL,
                              DesignSystem.spacingS,
                            ),
                            child: Row(
                              children: [
                                StarGlint(
                                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'القراء المشهورون',
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Horizontal Cards for Popular Reciters
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 170,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                              itemCount: popularReciters.length,
                              itemBuilder: (context, index) {
                                final reciter = popularReciters[index];
                                return _buildPopularReciterCard(reciter);
                              },
                            ),
                          ),
                        ),
                      ],

                      // Section Title: جميع القراء والمصاحف
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DesignSystem.spacingL,
                            DesignSystem.spacingL,
                            DesignSystem.spacingL,
                            DesignSystem.spacingS,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'جميع القراء والمصاحف',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${filteredReciters.length} قارئ',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // All Reciters List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reciter = filteredReciters[index];
                            return ReciterCard(
                              reciter: reciter,
                              onPlayTap: () {
                                _audioService.selectReciter(reciter, autoPlay: true);
                              },
                            );
                          },
                          childCount: filteredReciters.length,
                        ),
                      ),
                    ),

                    // Developer Rights Badge
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 16),
                        child: DeveloperCreditsBadge(),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Download Tracker (Appears while downloading with live logs & progress)
            const Positioned(
              bottom: 96,
              left: 8,
              right: 8,
              child: FloatingDownloadTracker(),
            ),

            // Floating Mini Player
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: AudioMiniPlayer(
                onTap: () {
                  _showSurahSelectorModal(context);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المصاحف الصوتية',
              style: TextStyle(
                color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'استمع للقرآن الكريم بأجمل أصوات العالم الإسلامي',
              style: TextStyle(
                color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderCircleButton(
              icon: Icons.cloud_download_outlined,
              isLight: isLight,
              onTap: () {
                QuranDownloadProgressSheet.show(context);
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderCircleButton(
              icon: Icons.format_list_bulleted_rounded,
              isLight: isLight,
              onTap: () => _showSurahSelectorModal(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderCircleButton(
              icon: Icons.graphic_eq_rounded,
              isLight: isLight,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const AudioDiagnosticDialog(),
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
    required bool isLight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : DesignSystem.bgCard.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black26,
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isLight = DesignSystem.isLightMode;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : DesignSystem.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.08) : Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: 'ابحث عن اسم القارئ، الدولة، أو الرواية...',
          hintStyle: TextStyle(
            color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    final isLight = DesignSystem.isLightMode;
    final categories = [
      {'title': 'كل القراء', 'cat': ReciterCategory.all},
      {'title': 'القراء المشهورون', 'cat': ReciterCategory.popular},
      {'title': 'القراء الشباب', 'cat': ReciterCategory.youth},
      {'title': 'المدارس القرآنية القديمة', 'cat': ReciterCategory.schools},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = _selectedCategory == item['cat'];

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategory = item['cat'] as ReciterCategory);
              },
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? (isLight
                          ? const LinearGradient(colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)])
                          : DesignSystem.goldGradient)
                      : null,
                  color: isSelected
                      ? null
                      : (isLight ? const Color(0xFFFFFDF8) : DesignSystem.bgCard.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? (isLight ? const Color(0xFFB8860B) : DesignSystem.gold)
                        : (isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.1)),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.35 : 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1A1002)
                          : (isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularReciterCard(ReciterProfile reciter) {
    final isLight = DesignSystem.isLightMode;
    final isCurrent = _audioService.currentReciter.id == reciter.id;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(left: 12),
      child: InteractiveMotionCard(
        onTap: () {
          _audioService.selectReciter(reciter, autoPlay: true);
        },
        borderRadius: 20,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFFFFDF8) : DesignSystem.bgCard.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent
                  ? (isLight ? const Color(0xFF854D0E) : DesignSystem.gold)
                  : (isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08)),
              width: isCurrent ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? const Color(0xFF8C7355).withValues(alpha: 0.08)
                    : (isCurrent ? DesignSystem.gold.withValues(alpha: 0.15) : Colors.black26),
                blurRadius: isCurrent ? 14 : 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? (isLight ? const Color(0xFF854D0E) : DesignSystem.gold)
                        : (isLight ? const Color(0xFFC89B3C) : Colors.white.withValues(alpha: 0.2)),
                    width: 2,
                  ),
                  boxShadow: isCurrent ? DesignSystem.goldGlow : null,
                ),
                child: ClipOval(
                  child: reciter.photoUrl.startsWith('assets/')
                      ? Image.asset(
                          reciter.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                          ),
                        )
                      : Image.network(
                          reciter.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reciter.nameArabic,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1C1917) : (isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reciter.country,
                style: TextStyle(
                  color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSurahSelectorModal(BuildContext context) {
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignSystem.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر سورة للاستماع',
                style: TextStyle(
                  color: DesignSystem.goldLight,
                  fontSize: 18,
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
                    final isCurrent = _audioService.currentSurah.number == surah.number;

                    return InkWell(
                      onTap: () {
                        _audioService.selectSurah(surah);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent ? DesignSystem.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                          border: Border.all(
                            color: isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${surah.number}.',
                                  style: TextStyle(
                                    color: isCurrent ? DesignSystem.goldLight : DesignSystem.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'سورة ${surah.nameArabic}',
                                  style: TextStyle(
                                    color: isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${surah.ayahCount} آية',
                                  style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(
                                    _audioService.isDownloaded(_audioService.currentReciter.id, surah.number)
                                        ? Icons.download_done_rounded
                                        : Icons.download_rounded,
                                    color: _audioService.isDownloaded(_audioService.currentReciter.id, surah.number)
                                        ? const Color(0xFF4ADE80)
                                        : DesignSystem.goldLight,
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    if (!_audioService.isDownloaded(_audioService.currentReciter.id, surah.number)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('جاري تنزيل سورة ${surah.nameArabic}...'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      final success = await QuranAudioDownloader().downloadSingleSurah(
                                        reciter: _audioService.currentReciter,
                                        surah: surah,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? 'تم تنزيل وحفظ سورة ${surah.nameArabic} بنجاح ✅'
                                                  : 'تعذر تنزيل سورة ${surah.nameArabic}',
                                            ),
                                            backgroundColor: success ? const Color(0xFF0F5132) : const Color(0xFF842029),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}