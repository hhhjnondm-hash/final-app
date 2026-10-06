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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? (isCurrent
                  ? [
                      const Color(0xFFFFF4D6),
                      const Color(0xFFFFFDF8),
                    ]
                  : [
                      const Color(0xFFFFFDF8),
                      const Color(0xFFFAF5EB),
                    ])
              : (isCurrent
                  ? [
                      DesignSystem.gold.withValues(alpha: 0.22),
                      DesignSystem.bgCard.withValues(alpha: 0.95),
                    ]
                  : [
                      DesignSystem.bgCard.withValues(alpha: 0.8),
                      DesignSystem.bgDarkest.withValues(alpha: 0.8),
                    ]),
        ),
        border: Border.all(
          color: isLight
              ? (isCurrent
                  ? const Color(0xFFC89B3C)
                  : (isNext ? const Color(0xFFE5A83B) : const Color(0xFFE5D4B3)))
              : (isCurrent
                  ? DesignSystem.gold
                  : (isNext ? DesignSystem.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08))),
          width: isCurrent ? 1.6 : 1.0,
        ),
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: isCurrent
                  ? const Color(0xFFC89B3C).withValues(alpha: 0.15)
                  : const Color(0xFFC89B3C).withValues(alpha: 0.04),
              blurRadius: isCurrent ? 16 : 8,
              offset: const Offset(0, 3),
            )
          else if (isCurrent)
            BoxShadow(
              color: DesignSystem.gold.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
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
                gradient: isCurrent
                    ? (isLight
                        ? const LinearGradient(
                            colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)],
                          )
                        : DesignSystem.goldGradient)
                    : null,
                color: isCurrent
                    ? null
                    : (isLight ? const Color(0xFFFBF4E4) : Colors.white.withValues(alpha: 0.05)),
                border: Border.all(
                  color: isLight
                      ? (isCurrent ? const Color(0xFF854D0E) : const Color(0xFFE5D4B3))
                      : (isCurrent ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1)),
                ),
                boxShadow: isCurrent
                    ? (isLight
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC89B3C).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : DesignSystem.goldGlow)
                    : null,
              ),
              child: Icon(
                timing.icon,
                color: isCurrent
                    ? (isLight ? const Color(0xFF1C1917) : DesignSystem.bgDarkest)
                    : (isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight),
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
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            timing.nameArabic,
                            softWrap: false,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(color: isLight ? const Color(0xFFC89B3C) : DesignSystem.gold),
                          ),
                          child: Text(
                            'الصلاة الحالية',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isNext)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFE0F2FE)
                                : DesignSystem.cyanAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(
                              color: isLight ? const Color(0xFF0284C7) : DesignSystem.cyanAccent,
                            ),
                          ),
                          child: Text(
                            'القادمة',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF0284C7) : DesignSystem.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    timing.nameEnglish,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Prayer Time & Notification Icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timing.formattedTimeArabic,
                    softWrap: false,
                    style: TextStyle(
                      color: isLight
                          ? (isCurrent ? const Color(0xFF854D0E) : const Color(0xFF1C1917))
                          : (isCurrent ? DesignSystem.goldLight : DesignSystem.textWhite),
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onNotificationToggle,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLight ? const Color(0xFFFBF4E4) : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      timing.notificationMode == NotificationMode.athan
                          ? Icons.notifications_active_rounded
                          : (timing.notificationMode == NotificationMode.notificationOnly
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_off_rounded),
                      size: 18,
                      color: timing.notificationMode == NotificationMode.silent
                          ? (isLight ? const Color(0xFF78716C) : DesignSystem.textMuted)
                          : (isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight),
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
