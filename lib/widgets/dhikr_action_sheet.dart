import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/azkar_models.dart';
import '../services/azkar_service.dart';
import '../utils/design_system.dart';

class DhikrActionSheet extends StatelessWidget {
  final DhikrItem dhikr;

  const DhikrActionSheet({
    super.key,
    required this.dhikr,
  });

  @override
  Widget build(BuildContext context) {
    final service = AzkarService();
    final isFav = service.isFavorite(dhikr.id);

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.35)),
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

          // Title
          Text(
            dhikr.title,
            style: const TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Action: Copy Dhikr
          _buildActionTile(
            icon: Icons.copy_rounded,
            title: 'نسخ نص الذكر',
            color: DesignSystem.cyanAccent,
            onTap: () {
              Clipboard.setData(ClipboardData(text: '${dhikr.text}\n\n${dhikr.fadl ?? ''}'));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ الذكر بنجاح')),
              );
            },
          ),

          // Action: Toggle Favorite
          _buildActionTile(
            icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            title: isFav ? 'إزالة من المفضلة' : 'إضافة إلى أذكاري المفضلة',
            color: const Color(0xFFE11D48),
            onTap: () {
              service.toggleFavorite(dhikr.id);
              Navigator.pop(context);
            },
          ),

          // Action: Reset Count
          _buildActionTile(
            icon: Icons.refresh_rounded,
            title: 'إعادة ضبط عداد التكرار',
            color: DesignSystem.goldLight,
            onTap: () {
              service.resetDhikr(dhikr.id);
              Navigator.pop(context);
            },
          ),

          if (dhikr.source != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: DesignSystem.goldLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المصدر: ${dhikr.source}',
                      style: const TextStyle(color: DesignSystem.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
