import 'package:flutter/material.dart';
import '../services/azkar_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';

class DhikrWirdCard extends StatelessWidget {
  final VoidCallback onContinueTap;

  const DhikrWirdCard({
    super.key,
    required this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = AzkarService();
    final completed = service.completedToday;
    final total = service.totalToday;
    final progress = (completed / total).clamp(0.0, 1.0);
    final streak = service.streakDays;

    return GlassCard(
      borderRadius: DesignSystem.radiusLarge,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Progress Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completed',
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'من $total',
                        style: const TextStyle(
                          color: DesignSystem.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 18),

              // Title and Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'وردك اليومي',
                          style: TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$streak أيام متتالية',
                                style: const TextStyle(
                                  color: Color(0xFFF97316),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أكمل ورد أذكار الصباح لحفظ نفسك وتيسير يومك',
                      style: TextStyle(
                        color: DesignSystem.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Continue Button
          ElevatedButton(
            onPressed: onContinueTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.gold,
              foregroundColor: DesignSystem.bgDarkest,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'متابعة الذكر والورد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
