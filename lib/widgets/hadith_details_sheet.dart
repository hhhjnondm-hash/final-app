import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../utils/design_system.dart';

class HadithDetailsSheet extends StatelessWidget {
  final HadithItem hadith;

  const HadithDetailsSheet({
    super.key,
    required this.hadith,
  });

  @override
  Widget build(BuildContext context) {
    final service = HadithService();
    final isFav = service.isFavorite(hadith.id);

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4),
        ),
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
                color: isLight
                    ? const Color(0xFF78716C).withValues(alpha: 0.3)
                    : DesignSystem.textMuted.withValues(alpha: 0.4),
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
                    hadith.book,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الحديث رقم ${hadith.number} • ${hadith.grade}',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav
                      ? const Color(0xFFE11D48)
                      : (isLight ? const Color(0xFF78716C) : DesignSystem.textWhite),
                ),
                onPressed: () => service.toggleFavorite(hadith.id),
              ),
            ],
          ),

          Divider(
            color: isLight ? const Color(0xFFE5D4B3) : Colors.white12,
            height: 24,
          ),

          // Scrollable Hadith Text & Explanation
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Hadith Card
                  Container(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFFBF4E4)
                          : DesignSystem.bgCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      hadith.text,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                        fontSize: 18,
                        height: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Narrator & Source Info
                  Container(
                    padding: const EdgeInsets.all(DesignSystem.spacingM),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF5EFE0) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'الراوي: ${hadith.narrator}',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark_outline_rounded,
                              color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'الباب: ${hadith.chapter}',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (hadith.explanation.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'شرح وبيان الحديث:',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(DesignSystem.spacingM),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF5EFE0) : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      ),
                      child: Text(
                        hadith.explanation,
                        style: TextStyle(
                          color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Action Bar (Copy & Share)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isLight ? const Color(0xFFE5D4B3) : Colors.white24,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                  ),
                  icon: Icon(
                    Icons.copy_rounded,
                    color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                    size: 16,
                  ),
                  label: Text(
                    'نسخ الحديث',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${hadith.text}\n[${hadith.book} - ${hadith.narrator}]'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ الحديث بنجاح'),
                        backgroundColor: Color(0xFF064E3B),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isLight ? const Color(0xFFE5A83B) : DesignSystem.gold,
                    foregroundColor: const Color(0xFF1A1002),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('مشاركة الحديث', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاهز للمشاركة'),
                        backgroundColor: Color(0xFF064E3B),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
