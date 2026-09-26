import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../widgets/developer_credits_badge.dart';
import '../widgets/visual_effects/floating_particles.dart';
import '../widgets/visual_effects/interactive_motion_card.dart';
import '../widgets/visual_effects/star_glint.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Stack(
          children: [
            // Background subtle floating particles
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
                constraints: const BoxConstraints(maxWidth: 900),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Top Royal Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(DesignSystem.spacingL),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                StarGlint(color: DesignSystem.goldLight, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'المكتبة والقراءة',
                                  style: TextStyle(
                                    color: DesignSystem.textWhite,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DesignSystem.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                                border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'تلاوة وتدبر',
                                style: TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reading Content Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                        child: InteractiveMotionCard(
                          borderRadius: 24,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: DesignSystem.bgCard.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: DesignSystem.gold.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'سورة الفاتحة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: DesignSystem.goldLight,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(10, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(left: 10),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: DesignSystem.gold.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: DesignSystem.goldLight,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            _getAyahText(index),
                                            style: const TextStyle(
                                              color: DesignSystem.textWhite,
                                              fontSize: 18,
                                              height: 1.8,
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Developer Rights Badge
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 24),
                        child: DeveloperCreditsBadge(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getAyahText(int index) {
    final ayat = [
      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      'الرَّحْمَنِ الرَّحِيمِ',
      'مَالِكِ يَوْمِ الدِّينِ',
      'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
      'غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ',
      'وَلَا الضَّالِّينَ',
      'آمِينَ',
    ];
    return ayat[index];
  }
}