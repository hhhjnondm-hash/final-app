import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script to update reciters data from MP3Quran API
/// Run: dart update_reciters.dart
void main() async {
  print('🔄 Fetching reciters from MP3Quran API...');
  
  try {
    final response = await http.get(Uri.parse('https://www.mp3quran.net/api/v3/reciters'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final recitersJson = data['reciters'] as List;
      
      print('✅ Found ${recitersJson.length} reciters');
      
      // Generate reciters data
      final buffer = StringBuffer();
      buffer.writeln("import '../models/audio_models.dart';");
      buffer.writeln();
      buffer.writeln("class RecitersData {");
      buffer.writeln("  static List<ReciterProfile> reciters = [");
      
      for (var reciter in recitersJson) {
        final name = reciter['name'];
        final moshafList = reciter['moshaf'] as List;
        
        // Find primary moshaf (Hafs Murattal - type 11)
        String? serverUrl;
        for (var moshaf in moshafList) {
          if (moshaf['moshaf_type'] == 11) {
            serverUrl = moshaf['server'];
            break;
          }
        }
        
        // Fallback to first moshaf if no Hafs found
        serverUrl ??= moshafList.first['server'];
        
        final id = _generateId(name);
        final englishName = _toEnglishName(name);
        final arabicName = name;
        final country = _guessCountry(englishName);
        final style = 'حفص عن عاصم - مرتل';
        final photoUrl = _guessPhotoUrl(id);
        final surahCount = 114;
        
        buffer.writeln("    ReciterProfile(");
        buffer.writeln("      id: '$id',");
        buffer.writeln("      nameArabic: '$arabicName',");
        buffer.writeln("      nameEnglish: '$englishName',");
        buffer.writeln("      country: '$country',");
        buffer.writeln("      style: '$style',");
        buffer.writeln("      photoUrl: '$photoUrl',");
        buffer.writeln("      surahCount: $surahCount,");
        buffer.writeln("      category: ReciterCategory.popular,");
        buffer.writeln("      serverUrl: '$serverUrl',");
        buffer.writeln("    ),");
        
        print('  ✓ Processed: $name ($serverUrl)');
      }
      
      buffer.writeln("  ];");
      buffer.writeln("}");
      
      // Write to file
      final file = File('lib/data/reciters_data.dart');
      await file.writeAsString(buffer.toString());
      
      print('✅ Successfully updated reciters_data.dart');
      print('📁 File: lib/data/reciters_data.dart');
    } else {
      print('❌ Failed to fetch: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

String _generateId(String arabicName) {
  // Convert Arabic name to ID
  final map = {
    'مشاري بن راشد العفاسي': 'afasy',
    'ماهر المعيقلي': 'maher',
    'ياسر الدوسري': 'dosari',
    'أحمد بن علي العجمي': 'ajmy',
    'سعود الشريم': 'shuraim',
    'محمود خليل الحصري': 'hussary_murattal',
    'عبد الباسط عبد الصمد': 'abdulbaset_murattal',
    'محمد صديق المنشاوي': 'minshawi_murattal',
    'حسن صالح': 'hassan_saleh',
    'سعد الغامدي': 'ghamdi',
    'محمود علي البنا': 'banna',
    'محمد الطبلاوي': 'tablawi',
    'خالد الجليل': 'khaled_jileel',
    'أبو بكر الشاطري': 'abu_bakr_shatri',
    'عبدالله جوهني': 'abdullah_juhany',
    'صلاح البخاتير': 'salah_bukhatir',
    'محمد جبريل': 'muhammad_jibreel',
    'محمد أيوب': 'muhammad_ayyoub',
    'ناصر القطامي': 'naser_katamy',
    'نائل الرضاوي': 'nail_arradawi',
    'هزاع البلوشي': 'hazza_baloushi',
  };
  
  return map[arabicName] ?? arabicName.toLowerCase().replaceAll(' ', '_');
}

String _toEnglishName(String arabicName) {
  final map = {
    'مشاري بن راشد العفاسي': 'Mishary Rashid Alafasy',
    'ماهر المعيقلي': 'Maher Al-Muaiqly',
    'ياسر الدوسري': 'Yasser Al-Dosary',
    'أحمد بن علي العجمي': 'Ahmed Ben Ali Elagme',
    'سعود الشريم': 'Saud Al-Shuraim',
    'محمود خليل الحصري': 'Mahmoud Khalil Al-Hosary',
    'عبد الباسط عبد الصمد': 'Abdul Basit Abdul Samad',
    'محمد صديق المنشاوي': 'Mohammad Siddiq Al-Minshawi',
    'حسن صالح': 'Hasan Saleh',
    'سعد الغامدي': 'Saad Al-Ghamdi',
    'محمود علي البنا': 'Mahmoud Ali Al-Banna',
    'محمد الطبلاوي': 'Mohammad Al-Tablawi',
    'خالد الجليل': 'Khaled Al-Jleel',
    'أبو بكر الشاطري': 'Abu Bakr Ash-Shatri',
    'عبدالله جوهني': 'Abdullah Awad Al-Juhany',
    'صلاح البخاتير': 'Salah Bukhatir',
    'محمد جبريل': 'Mohammad Jibril',
    'محمد أيوب': 'Mohammad Ayyoub',
    'ناصر القطامي': 'Naser Al-Katamy',
    'نائل الرضاوي': 'Nail Arradawi',
    'هزاع البلوشي': 'Hazza Baloushi',
  };
  
  return map[arabicName] ?? arabicName;
}

String _guessCountry(String englishName) {
  if (englishName.contains('Alafasy') || englishName.contains('Muaiqly')) return 'الكويت';
  if (englishName.contains('Dosary') || englishName.contains('Jleel') || 
      englishName.contains('Juhany') || englishName.contains('Baloushi')) return 'السعودية';
  if (englishName.contains('Saleh') || englishName.contains('Basit') || 
      englishName.contains('Minshawi') || englishName.contains('Hosary') ||
      englishName.contains('Banna') || englishName.contains('Tablawi')) return 'مصر';
  return 'غير محدد';
}

String _guessPhotoUrl(String id) {
  final map = {
    'afasy': 'assets/reciters/shaikh-Mishari-Al-afasi.webP',
    'maher': 'assets/reciters/shaikh-Maher-Almaikula.webP',
    'dosari': 'assets/reciters/shaikh-Yasser-Al-Dosary.webP',
    'ajmy': 'assets/reciters/shaikh-ben-ali-elagme.webP',
    'shuraim': 'assets/reciters/shaikh-saood-el-shoram.webP',
    'hussary_murattal': 'assets/reciters/shaikh-Mahmoud-Khalil-Al-Hosary.webP',
    'abdulbaset_murattal': 'assets/reciters/shaikh-Abdul-Basit-Abdul-Samad.webP',
    'minshawi_murattal': 'assets/reciters/shaikh-Muhammad-Siddiq_Al-Minshawi.webP',
    'hassan_saleh': 'assets/reciters/shaikh-Hassan-Saleh.webP',
    'ghamdi': 'assets/reciters/shaikh-saad-el-3amde.webP',
    'banna': 'assets/reciters/shaikh-Mahmoud-Ali_Al-Banna.webP',
    'tablawi': 'assets/reciters/shaikh-Muhammad-Al-Tablawi.webP',
    'khaled_jileel': 'assets/reciters/shaikh-Khaled-Aljleel.webP',
    'abu_bakr_shatri': 'assets/reciters/shaikh-Abu-Bakr-Ash-Shatri.webP',
    'abdullah_juhany': 'assets/reciters/shaikh-Abdullah-Awad-Al-Juhany.webP',
    'salah_bukhatir': 'assets/reciters/shaikh-Salah-Bukhatir.webP',
    'muhammad_jibreel': 'assets/reciters/shaikh-Mohammad-Jibril.webP',
    'muhammad_ayyoub': 'assets/reciters/shaikh-Mohammad-Ayyoub.webP',
    'naser_katamy': 'assets/reciters/shaikh-Naser-Al-Katamy.webP',
    'nail_arradawi': 'assets/reciters/shaikh-Nail-Arradawi.webP',
    'hazza_baloushi': 'assets/reciters/shaikh-Hazza-Baloushi.webP',
  };
  
  return map[id] ?? 'assets/reciters/default.webP';
}
