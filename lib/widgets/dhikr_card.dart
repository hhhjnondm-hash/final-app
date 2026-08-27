import 'package:flutter/material.dart';
import '../models/azkar_models.dart';
import '../services/azkar_service.dart';
import '../utils/design_system.dart';
import 'dhikr_action_sheet.dart';

class DhikrCard extends StatelessWidget {
  final DhikrItem dhikr;
  final int index;
  final VoidCallback onCountChanged;

  const DhikrCard({
    super.key,
    required this.dhikr,
    required this.index,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final service = AzkarService();
    final count = service.getRepetition(dhikr.id);
    final isCompleted = count >= dhikr.targetRepetitions;
    final isFavorite = service.isFavorite(dhikr.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [
                  const Color(0xFF19B88A).withValues(alpha: 0.15),
                  DesignSystem.bgCard.withValues(alpha: 0.95),
                ]
              : [
                  DesignSystem.bgCard.withValues(alpha: 0.85),
                  DesignSystem.bgDarkest.withValues(alpha: 0.9),
                ],
        ),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF19B88A).withValues(alpha: 0.5)
              : DesignSystem.gold.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: const Color(0xFF19B88A).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Dhikr Index Badge & Favorite/More Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Index Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF19B88A).withValues(alpha: 0.2)
                        : DesignSystem.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF19B88A)
                          : DesignSystem.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.numbers_rounded,
                        color: isCompleted ? const Color(0xFF19B88A) : DesignSystem.goldLight,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الذكر ${index + 1}',
                        style: TextStyle(
                          color: isCompleted ? const Color(0xFF19B88A) : DesignSystem.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Icons (Heart + More)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xFFE11D48) : DesignSystem.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        service.toggleFavorite(dhikr.id);
                        onCountChanged();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: DesignSystem.textMuted, size: 20),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DhikrActionSheet(dhikr: dhikr),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Main Arabic Dhikr Text
            Text(
              dhikr.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 18,
                height: 1.9,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (dhikr.fadl != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: DesignSystem.goldLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dhikr.fadl!,
                        style: const TextStyle(
                          color: DesignSystem.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Bottom Counter Controller (+ / - / Completed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Source or Repetition Text
                Text(
                  dhikr.repetitionText,
                  style: const TextStyle(
                    color: DesignSystem.textMuted,
                    fontSize: 12,
                  ),
                ),

                // Counter Box
                Row(
                  children: [
                    // Decrement Button
                    InkWell(
                      onTap: () {
                        service.decrementRepetition(dhikr);
                        onCountChanged();
                      },
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Icon(Icons.remove_rounded, color: DesignSystem.textMuted, size: 18),
                      ),
                    ),

                    // Counter Pill
                    InkWell(
                      onTap: () {
                        service.incrementRepetition(dhikr);
                        onCountChanged();
                      },
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isCompleted ? null : DesignSystem.goldGradient,
                          color: isCompleted ? const Color(0xFF19B88A) : null,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          boxShadow: isCompleted
                              ? [BoxShadow(color: const Color(0xFF19B88A).withValues(alpha: 0.3), blurRadius: 10)]
                              : DesignSystem.goldGlow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count / ${dhikr.targetRepetitions}',
                              style: TextStyle(
                                color: isCompleted ? Colors.white : DesignSystem.bgDarkest,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Increment Button
                    InkWell(
                      onTap: () {
                        service.incrementRepetition(dhikr);
                        onCountChanged();
                      },
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Icon(Icons.add_rounded, color: DesignSystem.goldLight, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
