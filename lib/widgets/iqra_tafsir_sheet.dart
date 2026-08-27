import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/design_system.dart';

class IqraTafsirSheet extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;

  const IqraTafsirSheet({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سورة $surahName • الآية $ayahNumber',
                    style: const TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'التفسير الميسر وبيان المعاني',
                    style: TextStyle(color: DesignSystem.textMuted, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: DesignSystem.textWhite, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'سورة $surahName ($ayahNumber): $ayahText'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الآية'), backgroundColor: Color(0xFF064E3B)),
                  );
                },
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 20),

          // Ayah Text Box
          Container(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            decoration: BoxDecoration(
              color: DesignSystem.bgCard.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.25)),
            ),
            child: Text(
              ayahText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                color: DesignSystem.textWhite,
                fontSize: 17,
                height: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'بيان المعنى والتفسير:',
            style: TextStyle(color: DesignSystem.goldLight, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(DesignSystem.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'هذه الآية الكريمة تشتمل على هدايات ربانية عظيمة، تدعو المؤمن إلى التدبر والعمل بمقتضى كلام الله جل وعلا، واستشعار مراقبته في السر والعلن، واتباع هدي نبيه المصطفى ﷺ.',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: DesignSystem.gold,
              foregroundColor: DesignSystem.bgDarkest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
