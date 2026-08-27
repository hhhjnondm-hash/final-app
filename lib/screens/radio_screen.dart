import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/radio_data.dart';
import '../models/radio_models.dart';
import '../services/radio_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/audio_diagnostic_dialog.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> with SingleTickerProviderStateMixin {
  final RadioService _radioService = RadioService();
  RadioCategory _selectedCategory = RadioCategory.all;
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _radioService.addListener(_onServiceUpdate);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _radioService.removeListener(_onServiceUpdate);
    _waveController.dispose();
    super.dispose();
  }

  void _showSleepTimerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(DesignSystem.spacingL),
        decoration: BoxDecoration(
          color: DesignSystem.bgDarkest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.bedtime_rounded, color: DesignSystem.goldLight, size: 36),
            const SizedBox(height: 12),
            const Text('مؤقت النوم', style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('سيتم إيقاف الإذاعة تلقائيًا بعد انتهاء المدة المحددة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [15, 30, 45, 60, 90].map((mins) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignSystem.goldLight,
                    side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                  ),
                  onPressed: () {
                    _radioService.setSleepTimer(Duration(minutes: mins));
                    Navigator.pop(ctx);
                  },
                  child: Text('$mins دقيقة'),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _radioService.setSleepTimer(Duration.zero);
                Navigator.pop(ctx);
              },
              child: const Text('إلغاء المؤقت', style: TextStyle(color: Color(0xFFE11D48))),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          decoration: BoxDecoration(
            color: DesignSystem.bgDarkest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Center(
                child: Text('إعدادات الصوت والبث', style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text('جودة الصوت للبث المباشر', style: TextStyle(color: DesignSystem.goldLight, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['جودة عالية (128 kbps)', 'جودة متوسطة (64 kbps)'].map((q) {
                  final isSelected = _radioService.selectedQuality == q;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          _radioService.setQuality(q);
                          setSheetState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? DesignSystem.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? DesignSystem.gold : Colors.white12),
                          ),
                          child: Text(
                            q,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isSelected ? DesignSystem.goldLight : DesignSystem.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مستوى الصوت', style: TextStyle(color: DesignSystem.goldLight, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${(_radioService.volume * 100).toInt()}%', style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12)),
                ],
              ),
              Slider(
                value: _radioService.volume,
                activeColor: DesignSystem.gold,
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  _radioService.setVolume(val);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStations = RadioData.stations.where((s) {
      final matchesCategory = _selectedCategory == RadioCategory.all || s.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || s.name.contains(_searchQuery) || s.description.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header
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

                // Search Bar (if searching)
                if (_isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: DesignSystem.bgCard,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
                        ),
                        child: TextField(
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن اسم الإذاعة أو التلاوة...',
                            hintStyle: const TextStyle(color: DesignSystem.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.search_rounded, color: DesignSystem.goldLight, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                              onPressed: () => setState(() {
                                _isSearching = false;
                                _searchQuery = '';
                              }),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                    ),
                  ),

                // 2. Hero Radio Player
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 12),
                    child: _buildHeroRadioPlayer(context),
                  ),
                ),

                // 3. Category Horizontal Pills
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildCategoryPills(),
                  ),
                ),

                // 4. Live Stations Section Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(DesignSystem.spacingL, 16, DesignSystem.spacingL, 8),
                    child: Text(
                      'المحطات المباشرة',
                      style: TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 5. Live Stations List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final station = filteredStations[index];
                        final isCurrent = _radioService.currentStation.id == station.id;
                        final isPlayingThis = isCurrent && _radioService.isPlaying;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: DesignSystem.radiusLarge,
                            isSelected: isCurrent,
                            hasGlow: isPlayingThis,
                            glowColor: DesignSystem.gold,
                            onTap: () => _radioService.selectStation(station),
                            child: Row(
                              children: [
                                // Station Artwork Disc
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: DesignSystem.goldGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: isPlayingThis ? DesignSystem.goldGlow : null,
                                  ),
                                  child: ClipOval(
                                    child: station.photoUrl != null
                                        ? Image.asset(
                                            station.photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.radio_rounded, color: DesignSystem.bgDarkest, size: 26),
                                          )
                                        : Icon(
                                            isPlayingThis ? Icons.radio_rounded : Icons.cell_tower_rounded,
                                            color: DesignSystem.bgDarkest,
                                            size: 26,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              station.name,
                                              style: TextStyle(
                                                color: isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF38B982).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('مباشر', style: TextStyle(color: Color(0xFF38B982), fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        station.origin,
                                        style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        station.currentProgram,
                                        style: const TextStyle(color: DesignSystem.goldLight, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    _radioService.isFavorite(station.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _radioService.isFavorite(station.id) ? const Color(0xFFE11D48) : Colors.white30,
                                    size: 20,
                                  ),
                                  onPressed: () => _radioService.toggleFavorite(station.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredStations.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
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
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.goldLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const Column(
          children: [
            Text(
              'الإذاعة',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'استمع إلى أجمل الإذاعات الإسلامية',
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
            IconButton(
              icon: const Icon(Icons.search_rounded, color: DesignSystem.goldLight, size: 22),
              onPressed: () => setState(() => _isSearching = !_isSearching),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: DesignSystem.goldLight, size: 22),
              onPressed: () => _showSettingsSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.graphic_eq_rounded, color: DesignSystem.goldLight, size: 22),
              onPressed: () {
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

  Widget _buildHeroRadioPlayer(BuildContext context) {
    final station = _radioService.currentStation;
    final isPlaying = _radioService.isPlaying;
    final isBuffering = _radioService.isBuffering;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rotating / Glowing Visual Disc
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: isPlaying
                              ? [
                                  BoxShadow(
                                    color: DesignSystem.gold.withValues(alpha: 0.2 + 0.15 * _waveController.value),
                                    blurRadius: 20 + 10 * _waveController.value,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF020814)],
                      ),
                      border: Border.all(color: DesignSystem.gold, width: 2),
                    ),
                    child: ClipOval(
                      child: station.photoUrl != null
                          ? Image.asset(
                              station.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.mosque_rounded, color: DesignSystem.goldLight, size: 38),
                            )
                          : const Icon(Icons.mosque_rounded, color: DesignSystem.goldLight, size: 38),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38B982).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: const Color(0xFF38B982), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF38B982), size: 6),
                              SizedBox(width: 4),
                              Text('يذاع الآن', style: TextStyle(color: Color(0xFF38B982), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_radioService.sleepTimerRemaining != null)
                          Text(
                            '🌙 ${_radioService.sleepTimerRemaining!.inMinutes} د',
                            style: const TextStyle(color: DesignSystem.goldLight, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      station.name,
                      style: const TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.origin,
                      style: const TextStyle(color: DesignSystem.goldLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Waveform Equalizer
          if (isPlaying)
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(24, (index) {
                    final height = 6.0 + 16.0 * math.sin((index * 0.4) + (_waveController.value * math.pi * 2)).abs();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 3,
                      height: height,
                      decoration: BoxDecoration(
                        color: DesignSystem.gold.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            )
          else
            Container(height: 22),

          const SizedBox(height: 16),

          // Main Controls (Heart, Prev, Play/Pause, Next, Sleep)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _radioService.isFavorite(station.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _radioService.isFavorite(station.id) ? const Color(0xFFE11D48) : DesignSystem.goldLight,
                  size: 22,
                ),
                onPressed: () => _radioService.toggleFavorite(station.id),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: DesignSystem.goldLight, size: 28),
                onPressed: () => _radioService.previousStation(),
              ),
              // Giant Play/Pause Circle
              GestureDetector(
                onTap: () => _radioService.togglePlayPause(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DesignSystem.goldGradient,
                    boxShadow: DesignSystem.goldGlow,
                  ),
                  child: Center(
                    child: isBuffering
                        ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: DesignSystem.bgDarkest, strokeWidth: 2.5))
                        : Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: DesignSystem.bgDarkest,
                            size: 36,
                          ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: DesignSystem.goldLight, size: 28),
                onPressed: () => _radioService.nextStation(),
              ),
              IconButton(
                icon: const Icon(Icons.bedtime_outlined, color: DesignSystem.goldLight, size: 22),
                onPressed: () => _showSleepTimerSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = [
      {'cat': RadioCategory.all, 'label': '📻 الكل'},
      {'cat': RadioCategory.quran, 'label': '📖 القرآن الكريم'},
      {'cat': RadioCategory.hadith, 'label': '🕌 الحديث النبوي'},
      {'cat': RadioCategory.sciences, 'label': '🎓 العلوم الشرعية'},
      {'cat': RadioCategory.lessons, 'label': '🎙 الدروس'},
      {'cat': RadioCategory.nasheed, 'label': '🎧 الإنشاد'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
      child: Row(
        children: categories.map((item) {
          final cat = item['cat'] as RadioCategory;
          final label = item['label'] as String;
          final isSelected = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? DesignSystem.gold.withValues(alpha: 0.22) : DesignSystem.bgCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  border: Border.all(
                    color: isSelected ? DesignSystem.gold : Colors.white12,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected ? DesignSystem.goldGlow : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? DesignSystem.goldLight : DesignSystem.textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
