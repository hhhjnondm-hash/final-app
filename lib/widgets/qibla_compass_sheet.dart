import 'package:flutter/material.dart';
import '../services/prayer_service.dart';
import '../utils/design_system.dart';

class QiblaCompassSheet extends StatelessWidget {
  const QiblaCompassSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final service = PrayerService();
    final location = service.currentLocation;

    final sheetBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final cardBorder = isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.3);
    final textTitle = isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite;
    final goldAccent = isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight;
    final textSub = isLight ? const Color(0xFF78716C) : DesignSystem.textSecondary;
    final dialBg1 = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1E38);
    final dialBg2 = isLight ? const Color(0xFFFBF4E4) : DesignSystem.bgDarkest;

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFD6C7A1) : DesignSystem.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'اتجاه القبلة الشريفة',
            style: TextStyle(
              color: goldAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${location.cityName}، ${location.countryName} • زاوية ${location.qiblaAngle.toInt()}° من الشمال',
            style: TextStyle(color: textSub, fontSize: 12),
          ),

          const SizedBox(height: 30),

          // Luxury Compass Dial
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [dialBg1, dialBg2],
              ),
              border: Border.all(
                color: isLight ? const Color(0xFFC89B3C) : DesignSystem.gold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLight ? const Color(0xFF854D0E) : DesignSystem.gold).withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cardinal Directions
                Positioned(
                  top: 10,
                  child: Text('N', style: TextStyle(color: goldAccent, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  bottom: 10,
                  child: Text('S', style: TextStyle(color: textSub)),
                ),
                Positioned(
                  right: 10,
                  child: Text('E', style: TextStyle(color: textSub)),
                ),
                Positioned(
                  left: 10,
                  child: Text('W', style: TextStyle(color: textSub)),
                ),

                // Center Kaaba & Gold Needle
                Transform.rotate(
                  angle: (location.qiblaAngle * 3.14159 / 180),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLight ? const Color(0xFF854D0E) : DesignSystem.gold,
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isLight
                                ? [const Color(0xFF854D0E), const Color(0xFFC89B3C)]
                                : [const Color(0xFFD4AF37), const Color(0xFFFFD56B)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Pivot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: goldAccent,
                    border: Border.all(color: sheetBg, width: 2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Kaaba Direction Guidance Text
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: isLight ? const Color(0xFF16A34A) : const Color(0xFF38B982), size: 18),
                const SizedBox(width: 8),
                Text(
                  'وجّه هاتفك نحو السهم الذهبي للتوجه للكعبة المشرفة',
                  style: TextStyle(color: textTitle, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
