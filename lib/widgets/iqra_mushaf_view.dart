import 'package:flutter/material.dart';

class IqraMushafView extends StatelessWidget {
  final List<Map<String, dynamic>> ayahs;
  final int activeAyahNumber;
  final double fontSize;
  final String theme;
  final String surahName;
  final int surahNumber;
  final int juzNumber;
  final Function(int ayahNumber, String text) onAyahTap;

  const IqraMushafView({
    super.key,
    required this.ayahs,
    required this.activeAyahNumber,
    required this.fontSize,
    required this.theme,
    this.surahName = '',
    this.surahNumber = 1,
    this.juzNumber = 1,
    required this.onAyahTap,
  });

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color goldColor;
    Color activeBgColor;
    Color activeTextColor;
    Color headerBgColor;
    Color headerBorderColor;
    Color cardBorderColor;

    switch (theme) {
      case 'dark':
        bgColor = const Color(0xFF0C131D);
        textColor = const Color(0xFFF6F8FA);
        goldColor = const Color(0xFFFFD56B);
        activeBgColor = const Color(0xFFC89B3C).withValues(alpha: 0.28);
        activeTextColor = const Color(0xFFFFE082);
        headerBgColor = const Color(0xFF141D2B);
        headerBorderColor = const Color(0xFFC89B3C).withValues(alpha: 0.5);
        cardBorderColor = const Color(0xFFC89B3C).withValues(alpha: 0.35);
        break;
      case 'green':
        bgColor = const Color(0xFFF1F8F3);
        textColor = const Color(0xFF12381E);
        goldColor = const Color(0xFF2E7D32);
        activeBgColor = const Color(0xFFA5D6A7).withValues(alpha: 0.45);
        activeTextColor = const Color(0xFF0A4016);
        headerBgColor = const Color(0xFFE2F0E5);
        headerBorderColor = const Color(0xFF2E7D32).withValues(alpha: 0.4);
        cardBorderColor = const Color(0xFF4CAF50).withValues(alpha: 0.35);
        break;
      case 'blue':
        bgColor = const Color(0xFF071426);
        textColor = const Color(0xFFF1F5F9);
        goldColor = const Color(0xFF60A5FA);
        activeBgColor = const Color(0xFF1E3A8A).withValues(alpha: 0.45);
        activeTextColor = const Color(0xFF93C5FD);
        headerBgColor = const Color(0xFF0F223D);
        headerBorderColor = const Color(0xFF60A5FA).withValues(alpha: 0.4);
        cardBorderColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        break;
      case 'ivory':
        bgColor = const Color(0xFFFAF9F6);
        textColor = const Color(0xFF1E293B);
        goldColor = const Color(0xFF8B6914);
        activeBgColor = const Color(0xFFF1E6C8);
        activeTextColor = const Color(0xFF5C4010);
        headerBgColor = const Color(0xFFF0ECE1);
        headerBorderColor = const Color(0xFFC89B3C).withValues(alpha: 0.4);
        cardBorderColor = const Color(0xFFD4AF37).withValues(alpha: 0.35);
        break;
      case 'cream':
      default:
        bgColor = const Color(0xFFFDF7E7);
        textColor = const Color(0xFF231C10);
        goldColor = const Color(0xFFB8860B);
        activeBgColor = const Color(0xFFF3E5AB);
        activeTextColor = const Color(0xFF634107);
        headerBgColor = const Color(0xFFF5ECD0);
        headerBorderColor = const Color(0xFFC89B3C).withValues(alpha: 0.5);
        cardBorderColor = const Color(0xFFC89B3C).withValues(alpha: 0.45);
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme == 'cream' || theme == 'ivory' || theme == 'green' ? 0.08 : 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Elegant Islamic Ornate Surah Header Banner (Matching screenshot)
          if (surahName.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: headerBorderColor, width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left & Right subtle arabesque diamonds
                  Positioned(
                    right: 8,
                    child: Icon(Icons.star_rounded, color: goldColor.withValues(alpha: 0.6), size: 14),
                  ),
                  Positioned(
                    left: 8,
                    child: Icon(Icons.star_rounded, color: goldColor.withValues(alpha: 0.6), size: 14),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('✦ ', style: TextStyle(color: goldColor, fontSize: 13)),
                          Text(
                            'سُورَةُ $surahName',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: textColor,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(' ✦', style: TextStyle(color: goldColor, fontSize: 13)),
                        ],
                      ),
                      if (juzNumber > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'الجزء ${_toArabicDigits(juzNumber)}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: goldColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Basmala for all Surahs except At-Tawbah (9) and Al-Fatiha (1) where Ayah 1 is already Basmala
          if (surahNumber != 9 && surahNumber != 1) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: fontSize * 0.95,
                    fontWeight: FontWeight.bold,
                    color: goldColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],

          // Continuous Flow Text with highlighted active Ayah
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: fontSize,
                  height: 2.25,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
                children: _buildContinuousAyahSpans(
                  textColor: textColor,
                  activeTextColor: activeTextColor,
                  activeBgColor: activeBgColor,
                  goldColor: goldColor,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildContinuousAyahSpans({
    required Color textColor,
    required Color activeTextColor,
    required Color activeBgColor,
    required Color goldColor,
  }) {
    final List<InlineSpan> spans = [];

    for (final ayah in ayahs) {
      final number = (ayah['ayahNumber'] ?? ayah['number'] ?? 1) as int;
      var text = ((ayah['text'] ?? '') as String).trim();
      final isCurrent = activeAyahNumber == number;

      // Handle Basmala in Surahs other than Fatiha
      if (surahNumber != 1 && number == 1 && text.startsWith('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')) {
        text = text.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
      }

      // Ayah Text Span
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InkWell(
            onTap: () => onAyahTap(number, text),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              padding: isCurrent
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : EdgeInsets.zero,
              decoration: isCurrent
                  ? BoxDecoration(
                      color: activeBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: goldColor.withValues(alpha: 0.6), width: 1.1),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: fontSize,
                      color: isCurrent ? activeTextColor : textColor,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Octagram / Circle Ayah Badge
                  Container(
                    width: fontSize * 0.95,
                    height: fontSize * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 1.2),
                      color: isCurrent ? goldColor.withValues(alpha: 0.2) : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        _toArabicDigits(number),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: fontSize * 0.46,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? activeTextColor : goldColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return spans;
  }
}


