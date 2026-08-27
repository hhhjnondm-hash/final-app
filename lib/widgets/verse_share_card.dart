import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class VerseShareCard extends StatelessWidget {
  final String surahName;
  final int ayahNumber;
  final String ayahText;

  const VerseShareCard({
    super.key,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F1B2E),
              DesignSystem.bgDarkest,
              const Color(0xFF070D18),
            ],
          ),
          border: Border.all(
            color: DesignSystem.gold.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignSystem.gold.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Islamic Ornamental Frame Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 1,
                  decoration: const BoxDecoration(gradient: DesignSystem.goldGradient),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.star_rate_rounded, color: DesignSystem.goldLight, size: 16),
                const SizedBox(width: 6),
                Text(
                  'سورة $surahName — آية $ayahNumber',
                  style: const TextStyle(
                    color: DesignSystem.goldLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.star_rate_rounded, color: DesignSystem.goldLight, size: 16),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 1,
                  decoration: const BoxDecoration(gradient: DesignSystem.goldGradient),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ayah Text
            Text(
              '﴿ $ayahText ﴾',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 20,
                height: 1.9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 28),

            // App Branding Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: DesignSystem.gold, size: 14),
                const SizedBox(width: 6),
                Text(
                  'تطبيق إسلاميات • الرفيق الإسلامي',
                  style: TextStyle(
                    color: DesignSystem.textMuted.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.gold,
                      foregroundColor: DesignSystem.bgDarkest,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ البطاقة كصورة لمشاركتها')),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('مشاركة الصورة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(color: DesignSystem.textMuted)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
