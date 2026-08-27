import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../utils/design_system.dart';

class PrayerTimelineCard extends StatelessWidget {
  final PrayerTiming timing;
  final bool isCurrent;
  final bool isNext;
  final VoidCallback onNotificationToggle;

  const PrayerTimelineCard({
    super.key,
    required this.timing,
    required this.isCurrent,
    required this.isNext,
    required this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [
                  DesignSystem.gold.withValues(alpha: 0.22),
                  DesignSystem.bgCard.withValues(alpha: 0.95),
                ]
              : [
                  DesignSystem.bgCard.withValues(alpha: 0.8),
                  DesignSystem.bgDarkest.withValues(alpha: 0.8),
                ],
        ),
        border: Border.all(
          color: isCurrent
              ? DesignSystem.gold
              : (isNext ? DesignSystem.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08)),
          width: isCurrent ? 1.6 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: DesignSystem.gold.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Prayer Icon Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCurrent ? DesignSystem.goldGradient : null,
                color: isCurrent ? null : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: isCurrent ? DesignSystem.goldGlow : null,
              ),
              child: Icon(
                timing.icon,
                color: isCurrent ? DesignSystem.bgDarkest : DesignSystem.goldLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Prayer Name & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timing.nameArabic,
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignSystem.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: DesignSystem.gold),
                          ),
                          child: const Text(
                            'الصلاة الحالية',
                            style: TextStyle(
                              color: DesignSystem.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isNext)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignSystem.cyanAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: DesignSystem.cyanAccent),
                          ),
                          child: const Text(
                            'القادمة',
                            style: TextStyle(
                              color: DesignSystem.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    timing.nameEnglish,
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Prayer Time & Notification Icon
            Row(
              children: [
                Text(
                  timing.formattedTimeArabic,
                  style: TextStyle(
                    color: isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onNotificationToggle,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Icon(
                      timing.notificationMode == NotificationMode.athan
                          ? Icons.notifications_active_rounded
                          : (timing.notificationMode == NotificationMode.notificationOnly
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_off_rounded),
                      size: 18,
                      color: timing.notificationMode == NotificationMode.silent
                          ? DesignSystem.textMuted
                          : DesignSystem.goldLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
