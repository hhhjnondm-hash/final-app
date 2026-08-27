import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_models.dart';
import '../screens/ai_assistant_screen.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
import 'verse_share_card.dart';

class VerseActionSheet extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final VoidCallback onPlayAudio;

  const VerseActionSheet({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final storage = QuranStorageService();

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Ayah header & text snippet
          Text(
            'سورة $surahName — آية $ayahNumber',
            style: const TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '﴿ $ayahText ﴾',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DesignSystem.textWhite,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Action Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionItem(
                icon: Icons.play_arrow_rounded,
                label: 'استماع',
                color: DesignSystem.gold,
                onTap: () {
                  Navigator.pop(context);
                  onPlayAudio();
                },
              ),
              _buildActionItem(
                icon: Icons.bookmark_add_rounded,
                label: 'حفظ علامة',
                color: DesignSystem.cyanAccent,
                onTap: () {
                  storage.addBookmark(
                    surahNumber: surahNumber,
                    surahName: surahName,
                    ayahNumber: ayahNumber,
                    ayahSnippet: ayahText,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة العلامة المرجعية بنجاح')),
                  );
                },
              ),
              _buildActionItem(
                icon: Icons.copy_rounded,
                label: 'نسخ الآية',
                color: DesignSystem.electricBlue,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '﴿ $ayahText ﴾ [$surahName: $ayahNumber]'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ نص الآية للحافظة')),
                  );
                },
              ),
              _buildActionItem(
                icon: Icons.psychology_rounded,
                label: 'اسأل المساعد',
                color: const Color(0xFF536DFF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiAssistantScreen(
                        initialContext: AiContextAttachment(
                          title: 'سورة $surahName — الآية $ayahNumber',
                          content: ayahText,
                          source: 'القرآن الكريم',
                          surahNumber: surahNumber,
                          ayahNumber: ayahNumber,
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildActionItem(
                icon: Icons.auto_awesome_rounded,
                label: 'مشاركة كبطاقة',
                color: DesignSystem.goldLight,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => VerseShareCard(
                      surahName: surahName,
                      ayahNumber: ayahNumber,
                      ayahText: ayahText,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
