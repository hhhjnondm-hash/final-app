import 'package:flutter/material.dart';
import '../services/prayer_service.dart';
import '../utils/design_system.dart';

class QiblaCompassSheet extends StatelessWidget {
  const QiblaCompassSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PrayerService();
    final location = service.currentLocation;

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
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
                color: DesignSystem.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'اتجاه القبلة الشريفة',
            style: TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${location.cityName}، ${location.countryName} • زاوية ${location.qiblaAngle.toInt()}° من الشمال',
            style: const TextStyle(color: DesignSystem.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 30),

          // Luxury Compass Dial
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0F1E38),
                  DesignSystem.bgDarkest,
                ],
              ),
              border: Border.all(
                color: DesignSystem.gold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.gold.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cardinal Directions
                const Positioned(
                  top: 10,
                  child: Text('N', style: TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold)),
                ),
                const Positioned(
                  bottom: 10,
                  child: Text('S', style: TextStyle(color: DesignSystem.textMuted)),
                ),
                const Positioned(
                  right: 10,
                  child: Text('E', style: TextStyle(color: DesignSystem.textMuted)),
                ),
                const Positioned(
                  left: 10,
                  child: Text('W', style: TextStyle(color: DesignSystem.textMuted)),
                ),

                // Center Kaaba & Gold Needle
                Transform.rotate(
                  angle: (location.qiblaAngle * 3.14159 / 180),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignSystem.gold,
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: DesignSystem.bgDarkest,
                          size: 28,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 60,
                        decoration: const BoxDecoration(
                          gradient: DesignSystem.goldGradient,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Hub Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignSystem.bgDarkest,
                    border: Border.all(color: DesignSystem.gold, width: 2),
                  ),
                  child: const Icon(Icons.mosque_rounded, color: DesignSystem.goldLight, size: 18),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: DesignSystem.cyanAccent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'قم بتدوير الهاتف حتى يتطابق المؤشر الذهبي مع اتجاه الكعبة المشرفة في مكة المكرمة.',
                    style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11),
                  ),
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
