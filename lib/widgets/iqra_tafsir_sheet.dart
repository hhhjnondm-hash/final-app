import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                        fontFamily: 'Amiri',
                        color: Color(0xFFFFD56B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'التفسير الميسر وبيان المعاني',
                      style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFFE8D29A), size: 20),
                  tooltip: 'نسخ الآية',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'سورة $surahName ($ayahNumber): $ayahText'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ نص الآية إلى الحافظة', style: TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: Color(0xFF1F293D),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),

            const Divider(color: Colors.white12, height: 20),

            // Ayah Text Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161F2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
              ),
              child: Text(
                ayahText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  color: Color(0xFFF6F8FA),
                  fontSize: 18,
                  height: 1.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'بيان المعنى والتفسير:',
              style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: const Text(
                    'هذه الآية الكريمة تشتمل على هدايات ربانية عظيمة، تدعو المؤمن إلى التدبر والعمل بمقتضى كلام الله جل وعلا، واستشعار مراقبته في السر والعلن، واتباع هدي نبيه المصطفى ﷺ، والاستقامة على صراطه المستقيم لنيل رضوانه والفوز بجنات النعيم.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFF6F8FA),
                      fontSize: 13,
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
                backgroundColor: const Color(0xFFC89B3C),
                foregroundColor: const Color(0xFF070B11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

