import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/design_system.dart';

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
    final isCream = theme == 'cream';
    final isBlue = theme == 'blue';

    final bgColor = isCream
        ? const Color(0xFFFDF7E7)
        : (isBlue ? const Color(0xFF061426) : const Color(0xFF030A16));

    final textColor = isCream ? const Color(0xFF231C10) : const Color(0xFFF3F4F6);
    final goldColor = isCream ? const Color(0xFFB8860B) : DesignSystem.gold;
    final activeBgColor = isCream ? const Color(0xFFD4AF37).withValues(alpha: 0.3) : DesignSystem.gold.withValues(alpha: 0.22);
    final activeTextColor = isCream ? const Color(0xFF8B5A00) : DesignSystem.goldLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCream ? const Color(0xFFD4AF37).withValues(alpha: 0.45) : DesignSystem.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCream ? Colors.brown.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Elegant Surah Banner Header
          if (surahName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isCream ? const Color(0xFFF5ECD0) : DesignSystem.bgCard.withValues(alpha: 0.8),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✦ ─── ', style: TextStyle(color: goldColor.withValues(alpha: 0.6), fontSize: 12)),
                  Text(
                    'سورة $surahName',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: isCream ? const Color(0xFF5C4010) : DesignSystem.goldLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (juzNumber > 0) ...[
                    Text(' • الجزء ${_toArabicDigits(juzNumber)}', style: TextStyle(color: isCream ? Colors.brown : DesignSystem.textMuted, fontSize: 12)),
                  ],
                  Text(' ─── ✦', style: TextStyle(color: goldColor.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Basmala (except for At-Tawbah)
          // Basmala (except for At-Tawbah 9 and Al-Fatiha 1 where Ayah 1 is the Basmala)
          if (surahNumber != 9 && surahNumber != 1) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
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

          // Continuous Quran Reading Flow (Text.rich with pure RTL wrapping)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: fontSize,
                  height: 2.3,
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

      // If surah is not Fatiha and ayah 1 starts with Basmala in source text, handle cleanly
      if (surahNumber != 1 && number == 1 && text.startsWith('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')) {
        text = text.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
      }

      // Ayah Text Span with tap recognizer and active background highlight
      spans.add(
        TextSpan(
          text: '$text ',
          style: TextStyle(
            color: isCurrent ? activeTextColor : textColor,
            backgroundColor: isCurrent ? activeBgColor : Colors.transparent,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => onAyahTap(number, text),
        ),
      );

      // Traditional Quranic End-of-Ayah Bracket ﴿١﴾
      spans.add(
        TextSpan(
          text: ' ﴿${_toArabicDigits(number)}﴾ ',
          style: TextStyle(
            color: isCurrent ? DesignSystem.goldLight : goldColor,
            backgroundColor: isCurrent ? activeBgColor : Colors.transparent,
            fontSize: fontSize * 0.82,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => onAyahTap(number, text),
        ),
      );
    }

    return spans;
  }
}

