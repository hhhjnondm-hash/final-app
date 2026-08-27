import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import 'surah_viewer_screen.dart';

class SurahDetailScreen extends StatelessWidget {
  final SurahMeta surah;

  const SurahDetailScreen({
    super.key,
    required this.surah,
  });

  @override
  Widget build(BuildContext context) {
    final storage = QuranStorageService();
    final isFav = storage.isFavorite(surah.number);

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Cinematic Gradient & Surah Artwork
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: DesignSystem.bgDarkest,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isFav ? DesignSystem.gold : Colors.white,
                ),
                onPressed: () => storage.toggleFavorite(surah.number),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رابط السورة للمشاركة')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Mesh
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          surah.themeGradients.first.withValues(alpha: 0.8),
                          surah.themeGradients.last.withValues(alpha: 0.6),
                          DesignSystem.bgDarkest,
                        ],
                      ),
                    ),
                  ),

                  // Ornamental Floating Icon
                  Center(
                    child: Icon(
                      surah.themeIcon,
                      size: 90,
                      color: DesignSystem.goldLight.withValues(alpha: 0.15),
                    ),
                  ),

                  // Bottom Shadow Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          DesignSystem.bgDarkest.withValues(alpha: 0.9),
                          DesignSystem.bgDarkest,
                        ],
                      ),
                    ),
                  ),

                  // Header Titles
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DesignSystem.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                                border: Border.all(color: DesignSystem.gold),
                              ),
                              child: Text(
                                'السورة رقم ${surah.number}',
                                style: const TextStyle(
                                  color: DesignSystem.goldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              surah.isMeccan ? 'مكية' : 'مدنية',
                              style: const TextStyle(
                                color: DesignSystem.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سورة ${surah.nameArabic}',
                          style: const TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${surah.nameEnglish} • ${surah.ayahCount} آية',
                          style: const TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(DesignSystem.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary CTA Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.gold,
                            foregroundColor: DesignSystem.bgDarkest,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                            ),
                            elevation: 8,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SurahViewerScreen(
                                  surahNumber: surah.number,
                                  surahName: surah.nameArabic,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded, size: 22),
                          label: const Text(
                            'ابدأ القراءة والتلاوة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: DesignSystem.bgCard,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.headphones_rounded, color: DesignSystem.goldLight),
                          iconSize: 26,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SurahViewerScreen(
                                  surahNumber: surah.number,
                                  surahName: surah.nameArabic,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Surah Overview Grid Stats
                  Row(
                    children: [
                      _buildStatCard('عدد الآيات', '${surah.ayahCount}', Icons.format_list_numbered_rounded),
                      const SizedBox(width: 10),
                      _buildStatCard('رقم الجزء', 'الجزء ${surah.juzNumber}', Icons.auto_stories_rounded),
                      const SizedBox(width: 10),
                      _buildStatCard('الصفحة', 'صفحة ${surah.pageNumber}', Icons.bookmark_outline_rounded),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // About Surah Card
                  GlassCard(
                    borderRadius: DesignSystem.radiusLarge,
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: DesignSystem.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'نبذة وفضائل السورة',
                              style: TextStyle(
                                color: DesignSystem.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'سورة ${surah.nameArabic} هي السورة رقم ${surah.number} في المصحف الشريف، وهي سورة ${surah.isMeccan ? 'مكية نزلت قبل الهجرة' : 'مدنية نزلت بعد الهجرة'} وتتضمن ${surah.ayahCount} آية من كلام الله العظيم.',
                          style: const TextStyle(
                            color: DesignSystem.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: GlassCard(
        borderRadius: DesignSystem.radiusMedium,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: DesignSystem.goldLight, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignSystem.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
