import 'package:flutter/material.dart';

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1621),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إعدادات القراءة والمظهر',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD56B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Font Size Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حجم خط الآيات',
                  style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFF6F8FA), fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFFFD56B)),
                      onPressed: () {
                        if (fontSize > 18) onFontSizeChanged(fontSize - 2);
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${fontSize.toInt()}',
                        style: const TextStyle(color: Color(0xFFFFD56B), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFFD56B)),
                      onPressed: () {
                        if (fontSize < 38) onFontSizeChanged(fontSize + 2);
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Reading Themes Options
            const Text(
              'ألوان وخلفيات المصحف',
              style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFF6F8FA), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildThemeCard(
                    title: 'مصحف التراث',
                    subtitle: 'كريمي ذهبي',
                    themeKey: 'cream',
                    bgColor: const Color(0xFFFDF7E7),
                    textColor: const Color(0xFF231C10),
                    isSelected: theme == 'cream',
                  ),
                  const SizedBox(width: 10),
                  _buildThemeCard(
                    title: 'ليلي ملكي',
                    subtitle: 'داكن فاخر',
                    themeKey: 'dark',
                    bgColor: const Color(0xFF0B111A),
                    textColor: const Color(0xFFFFD56B),
                    isSelected: theme == 'dark',
                  ),
                  const SizedBox(width: 10),
                  _buildThemeCard(
                    title: 'أخضر مدني',
                    subtitle: 'أخضر هادئ',
                    themeKey: 'green',
                    bgColor: const Color(0xFFE8F5E9),
                    textColor: const Color(0xFF1B5E20),
                    isSelected: theme == 'green',
                  ),
                  const SizedBox(width: 10),
                  _buildThemeCard(
                    title: 'أزرق كحلي',
                    subtitle: 'نيلي مريح',
                    themeKey: 'blue',
                    bgColor: const Color(0xFF071426),
                    textColor: const Color(0xFFE2E8F0),
                    isSelected: theme == 'blue',
                  ),
                  const SizedBox(width: 10),
                  _buildThemeCard(
                    title: 'نهاري صافٍ',
                    subtitle: 'أبيض عاجي',
                    themeKey: 'ivory',
                    bgColor: const Color(0xFFFAFAFA),
                    textColor: const Color(0xFF1E293B),
                    isSelected: theme == 'ivory',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89B3C),
                foregroundColor: const Color(0xFF070B11),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'حفظ وتطبيق',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required String themeKey,
    required Color bgColor,
    required Color textColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onThemeChanged(themeKey),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 105,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.15),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD56B).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              'بِسْمِ اللَّهِ',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              subtitle,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: textColor.withValues(alpha: 0.7)),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle, color: Color(0xFFC89B3C), size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
