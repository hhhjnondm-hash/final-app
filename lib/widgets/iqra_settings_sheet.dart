import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class IqraSettingsSheet extends StatelessWidget {
  final double fontSize;
  final String theme;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onThemeChanged;

  const IqraSettingsSheet({
    super.key,
    required this.fontSize,
    required this.theme,
    required this.onFontSizeChanged,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          const Text(
            'إعدادات القراءة والتلاوة',
            style: TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          // Font Size Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('حجم خط المصحف', style: TextStyle(color: DesignSystem.textWhite, fontSize: 14)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: DesignSystem.goldLight),
                    onPressed: () {
                      if (fontSize > 16) onFontSizeChanged(fontSize - 2);
                    },
                  ),
                  Text(
                    '${fontSize.toInt()}',
                    style: const TextStyle(color: DesignSystem.goldLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: DesignSystem.goldLight),
                    onPressed: () {
                      if (fontSize < 36) onFontSizeChanged(fontSize + 2);
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reading Themes
          const Text('نمط العرض والخلفية', style: TextStyle(color: DesignSystem.textWhite, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildThemeTile('داكن ملكي', 'dark', const Color(0xFF020914), theme == 'dark'),
              const SizedBox(width: 8),
              _buildThemeTile('مصحف كريمي', 'cream', const Color(0xFFFDF6E2), theme == 'cream', isDarkText: true),
              const SizedBox(width: 8),
              _buildThemeTile('أزرق نيلي', 'blue', const Color(0xFF071426), theme == 'blue'),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: DesignSystem.gold,
              foregroundColor: DesignSystem.bgDarkest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('حفظ وإغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(String title, String key, Color color, bool isSelected, {bool isDarkText = false}) {
    return Expanded(
      child: InkWell(
        onTap: () => onThemeChanged(key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isDarkText ? Colors.black87 : Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
