import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/design_system.dart';
import 'developer_credits_badge.dart';
import 'visual_effects/floating_particles.dart';
import 'visual_effects/interactive_motion_card.dart';
import 'visual_effects/pulsing_halo.dart';
import 'visual_effects/shimmer_sweep.dart';
import 'visual_effects/star_glint.dart';

class CelebrationAchievementDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String achievementText;
  final IconData icon;
  final VoidCallback? onContinue;
  final VoidCallback? onShare;

  const CelebrationAchievementDialog({
    super.key,
    this.title = 'هنيئاً لك! تَقَبَّلَ اللَّهُ طَاعَتَك',
    this.subtitle = '﴿وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُمْ مَغْفِرَةً وَأَجْرًا عَظِيمًا﴾',
    this.achievementText = 'لقد أتممت وردك المبارك بنجاح اليوم، نسأل الله أن يجعله في ميزان حسناتك ونوراً في دربك.',
    this.icon = Icons.stars_rounded,
    this.onContinue,
    this.onShare,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    String? achievementText,
    IconData? icon,
    VoidCallback? onContinue,
    VoidCallback? onShare,
  }) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => CelebrationAchievementDialog(
        title: title ?? 'هنيئاً لك! تَقَبَّلَ اللَّهُ طَاعَتَك',
        subtitle: subtitle ?? '﴿وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُمْ مَغْفِرَةً وَأَجْرًا عَظِيمًا﴾',
        achievementText: achievementText ?? 'لقد أتممت وردك المبارك بنجاح اليوم، نسأل الله أن يجعله في ميزان حسناتك ونوراً في دربك.',
        icon: icon ?? Icons.stars_rounded,
        onContinue: onContinue,
        onShare: onShare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DesignSystem.gold.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.gold.withValues(alpha: 0.25),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Floating Gold Particles in background
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: FloatingParticles(
                        particleCount: 16,
                        particleColor: DesignSystem.gold,
                        maxSize: 4.5,
                        minSpeed: 0.15,
                        maxSpeed: 0.45,
                      ),
                    ),
                  ),

                  // Sparkle glints in top corners
                  const Positioned(
                    top: 16,
                    left: 20,
                    child: StarGlint(size: 20, color: DesignSystem.gold),
                  ),
                  const Positioned(
                    top: 24,
                    right: 24,
                    child: StarGlint(size: 16, color: DesignSystem.goldLight),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Hero Emblem
                        PulsingHalo(
                          haloColor: DesignSystem.gold,
                          borderRadius: 38,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [DesignSystem.gold, DesignSystem.goldDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DesignSystem.gold.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? DesignSystem.goldLight : DesignSystem.goldDark,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Quranic Subtitle
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14,
                            height: 1.6,
                            color: isDark ? Colors.white70 : DesignSystem.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Achievement Details Card
                        InteractiveMotionCard(
                          borderRadius: 18,
                          child: ShimmerSweep(
                            shimmerColor: DesignSystem.gold.withValues(alpha: 0.12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : DesignSystem.gold.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: DesignSystem.gold.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: DesignSystem.gold.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: DesignSystem.gold,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      achievementText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white.withValues(alpha: 0.9) : DesignSystem.lightPrimaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onContinue?.call();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignSystem.gold,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: DesignSystem.gold.withValues(alpha: 0.4),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.done_all_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'متابعة الأجر',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Developer Badge
                        const DeveloperCreditsBadge(compact: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
