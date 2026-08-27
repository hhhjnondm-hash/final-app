$lines = @"
import 'package:flutter/material.dart';
import '../models/quran_models.dart';

class QuranMetadataProvider {
  static const List<String> surahNamesAr = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر', 'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
    'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
    'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
    'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
    'المسد', 'الإخلاص', 'الفلق', 'الناس'
  ];

  static const List<String> surahNamesEn = [
    'Al-Fatihah', 'Al-Baqarah', 'Aal-Imran', 'An-Nisa', 'Al-Maidah', 'Al-Anam', 'Al-Araf', 'Al-Anfal', 'At-Tawbah', 'Yunus',
    'Hud', 'Yusuf', 'Ar-Rad', 'Ibrahim', 'Al-Hijr', 'An-Nahl', 'Al-Isra', 'Al-Kahf', 'Maryam', 'Ta-Ha',
    'Al-Anbiya', 'Al-Hajj', 'Al-Muminun', 'An-Nur', 'Al-Furqan', 'Ash-Shuara', 'An-Naml', 'Al-Qasas', 'Al-Ankabut', 'Ar-Rum',
    'Luqman', 'As-Sajdah', 'Al-Ahzab', 'Saba', 'Fatir', 'Ya-Sin', 'As-Saffat', 'Sad', 'Az-Zumar', 'Ghafir',
    'Fussilat', 'Ash-Shura', 'Az-Zukhruf', 'Ad-Dukhan', 'Al-Jathiyah', 'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf',
    'Adh-Dhariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman', 'Al-Waqiah', 'Al-Hadid', 'Al-Mujadila', 'Al-Hashr', 'Al-Mumtahanah',
    'As-Saff', 'Al-Jumuah', 'Al-Munafiqun', 'At-Taghabun', 'At-Talaq', 'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', 'Al-Maarij',
    'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddathir', 'Al-Qiyamah', 'Al-Insan', 'Al-Mursalat', 'An-Naba', 'An-Naziat', 'Abasa',
    'At-Takwir', 'Al-Infitar', 'Al-Mutaffifin', 'Al-Inshiqaq', 'Al-Buruj', 'At-Tariq', 'Al-Ala', 'Al-Ghashiyah', 'Al-Fajr', 'Al-Balad',
    'Ash-Shams', 'Al-Layl', 'Ad-Duha', 'Ash-Sharh', 'At-Tin', 'Al-Alaq', 'Al-Qadr', 'Al-Bayyinah', 'Az-Zalzalah', 'Al-Adiyat',
    'Al-Qariah', 'At-Takathur', 'Al-Asr', 'Al-Humazah', 'Al-Fil', 'Quraysh', 'Al-Maun', 'Al-Kawthar', 'Al-Kafirun', 'An-Nasr',
    'Al-Masad', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas'
  ];

  static const List<int> ayahCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6
  ];

  static const Set<int> medinanSurahs = {
    2, 3, 4, 5, 8, 9, 22, 24, 33, 47, 48, 49, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 110
  };

  static const List<int> juzStarts = [
    1, 1, 3, 4, 6, 7, 8, 9, 10, 11,
    11, 12, 13, 13, 14, 14, 15, 15, 16, 16,
    17, 17, 18, 18, 18, 19, 19, 20, 20, 21,
    21, 21, 21, 22, 22, 22, 23, 23, 23, 24,
    24, 25, 25, 25, 25, 26, 26, 26, 26, 26,
    26, 27, 27, 27, 27, 27, 27, 28, 28, 28,
    28, 28, 28, 28, 28, 28, 29, 29, 29, 29,
    29, 29, 29, 29, 29, 29, 29, 30, 30, 30,
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30
  ];

  static const List<List<Color>> paletteGradients = [
    [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFB45309)],
    [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0F172A)],
    [Color(0xFF047857), Color(0xFF10B981), Color(0xFF064E3B)],
    [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFF4C1D95)],
    [Color(0xFFB45309), Color(0xFFD97706), Color(0xFF78350F)],
    [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF115E59)],
    [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF312E81)],
    [Color(0xFFBE123C), Color(0xFFE11D48), Color(0xFF881337)],
    [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF134E4A)],
    [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF075985)],
    [Color(0xFFC2410C), Color(0xFFEA580C), Color(0xFF7C2D12)],
    [Color(0xFFCA8A04), Color(0xFFEAB308), Color(0xFF854D0E)],
  ];

  static const List<IconData> themeIcons = [
    Icons.auto_awesome_rounded,
    Icons.mosque_rounded,
    Icons.shield_rounded,
    Icons.menu_book_rounded,
    Icons.wb_sunny_rounded,
    Icons.nightlight_round,
    Icons.diamond_rounded,
    Icons.brightness_7_rounded,
    Icons.star_rounded,
    Icons.verified_rounded,
  ];

  static List<SurahMeta> getAllSurahs() {
    return List.generate(114, (i) {
      final num = i + 1;
      final isMed = medinanSurahs.contains(num);
      return SurahMeta(
        number: num,
        nameArabic: surahNamesAr[i],
        nameEnglish: surahNamesEn[i],
        meaningEnglish: 'Surah \${surahNamesEn[i]}',
        ayahCount: ayahCounts[i],
        isMeccan: !isMed,
        juzNumber: juzStarts[i],
        pageNumber: (i * 5) + 1,
        themeGradients: paletteGradients[i % paletteGradients.length],
        themeIcon: themeIcons[i % themeIcons.length],
      );
    });
  }
}
"@

[System.IO.File]::WriteAllText("lib\data\quran_metadata.dart", $lines, [System.Text.Encoding]::UTF8)
