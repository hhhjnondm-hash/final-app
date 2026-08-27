import 'package:flutter/foundation.dart';
import '../data/reciters_data.dart';
import '../models/audio_models.dart';
import 'advanced_audio_engine.dart';

/// خدمة صوتية قوية للقرآن مع مصادر متعددة
/// تحتوي على روابط احتياطية من مصادر مختلفة
class RobustQuranAudioService {
  final AdvancedAudioEngine _audioEngine = AdvancedAudioEngine();
  
  // مصادر الصوت الاحتياطية لكل قارئ
  static const Map<String, List<String>> _backupServers = {
    'maher': [
      'https://server12.mp3quran.net/maher/',
      'https://everyayah.com/data/Maher_Al_Muaiqly_128kbps/',
    ],
    'afs': [
      'https://server8.mp3quran.net/afs/',
      'https://everyayah.com/data/Mishary_Rashid_Alafasy_128kbps/',
    ],
    'sudais': [
      'https://server6.mp3quran.net/sudais/',
      'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
    ],
    'husary': [
      'https://server7.mp3quran.net/husary/',
      'https://everyayah.com/data/Mahmoud_Khalil_Al-Husary_128kbps/',
    ],
    'minshawi': [
      'https://server10.mp3quran.net/minsh/',
      'https://everyayah.com/data/Mohamed_Siddiq_Al-Minshawi_128kbps/',
    ],
    'abdurrahmaan_as_sudais': [
      'https://server6.mp3quran.net/sudais/',
      'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
    ],
    'mishary_rashid_alafasy': [
      'https://server8.mp3quran.net/afs/',
      'https://everyayah.com/data/Mishary_Rashid_Alafasy_128kbps/',
    ],
    'maher_al_muaiqly': [
      'https://server12.mp3quran.net/maher/',
      'https://everyayah.com/data/Maher_Al_Muaiqly_128kbps/',
    ],
    'abdul_basit': [
      'https://server11.mp3quran.net/basit/',
      'https://everyayah.com/data/Abdul_Basit_Murattal_128kbps/',
    ],
    'saad_ghamdi': [
      'https://server9.mp3quran.net/ghamdi/',
      'https://everyayah.com/data/Saad_Al-Ghamdi_128kbps/',
    ],
    'yasser_dossari': [
      'https://server13.mp3quran.net/yasser/',
      'https://everyayah.com/data/Yasser_Ad-Dossary_128kbps/',
    ],
    'hani_ar_rifai': [
      'https://server14.mp3quran.net/hani/',
      'https://everyayah.com/data/Hani_Ar-Rifai_128kbps/',
    ],
    'mahmoud_ali_al_banna': [
      'https://server15.mp3quran.net/banna/',
      'https://everyayah.com/data/Mahmoud_Ali_Al-Banna_128kbps/',
    ],
    'karim_mansoori': [
      'https://server16.mp3quran.net/karim/',
      'https://everyayah.com/data/Karim_Mansoori_128kbps/',
    ],
    'ali_jaber': [
      'https://server17.mp3quran.net/ali/',
      'https://everyayah.com/data/Ali_Jaber_128kbps/',
    ],
    'fares_abbad': [
      'https://server18.mp3quran.net/fares/',
      'https://everyayah.com/data/Fares_Abbad_128kbps/',
    ],
    'salah_bukhatir': [
      'https://server19.mp3quran.net/salah/',
      'https://everyayah.com/data/Salah_Bukhatir_128kbps/',
    ],
    'bandar_baleela': [
      'https://server20.mp3quran.net/bandar/',
      'https://everyayah.com/data/Bandar_Baleela_128kbps/',
    ],
    'ahmed_neana': [
      'https://server21.mp3quran.net/ahmed/',
      'https://everyayah.com/data/Ahmed_Neana_128kbps/',
    ],
    'khalid_al_juhani': [
      'https://server22.mp3quran.net/khalid/',
      'https://everyayah.com/data/Khalid_Al-Juhani_128kbps/',
    ],
    'mohamed_taha': [
      'https://server23.mp3quran.net/taha/',
      'https://everyayah.com/data/Mohamed_Taha_128kbps/',
    ],
    'hazza_al_balushi': [
      'https://server24.mp3quran.net/hazza/',
      'https://everyayah.com/data/Hazza_Al-Balushi_128kbps/',
    ],
    'mohamed_al_luhaidan': [
      'https://server25.mp3quran.net/luhaidan/',
      'https://everyayah.com/data/Mohamed_Al-Luhaidan_128kbps/',
    ],
    'mahmoud_khalil_al_husary': [
      'https://server7.mp3quran.net/husary/',
      'https://everyayah.com/data/Mahmoud_Khalil_Al-Husary_128kbps/',
    ],
    'abdulrahman_sudais': [
      'https://server6.mp3quran.net/sudais/',
      'https://everyayah.com/data/Abdurrahman_Sudais_192kbps/',
    ],
    'shuraim': [
      'https://server5.mp3quran.net/shuraim/',
      'https://everyayah.com/data/Saud_Ash-Shuraim_128kbps/',
    ],
    'parhizgar': [
      'https://server4.mp3quran.net/parhizgar/',
      'https://everyayah.com/data/Parhizgar_128kbps/',
    ],
    'abdulaziz_zahrani': [
      'https://server3.mp3quran.net/zahrani/',
      'https://everyayah.com/data/Abdulaziz_Zahrani_128kbps/',
    ],
    'yasser_fahmy': [
      'https://server2.mp3quran.net/yasser_fahmy/',
      'https://everyayah.com/data/Yasser_Fahmy_128kbps/',
    ],
    'ahmed_ibn_ali_al_ajmi': [
      'https://server1.mp3quran.net/ajmi/',
      'https://everyayah.com/data/Ahmed_Ibn_Ali_Al-Ajmi_128kbps/',
    ],
    'obaid_an_safi': [
      'https://server1.mp3quran.net/obaid/',
      'https://everyayah.com/data/Obaid_An-Safi_128kbps/',
    ],
    'sahl_yasin': [
      'https://server2.mp3quran.net/sahl/',
      'https://everyayah.com/data/Sahl_Yasin_128kbps/',
    ],
    'tariq_ibn_ali': [
      'https://server3.mp3quran.net/tariq/',
      'https://everyayah.com/data/Tariq_Ibn_Ali_128kbps/',
    ],
    'mahmoud_ali_hassan': [
      'https://server4.mp3quran.net/mahmoud_hassan/',
      'https://everyayah.com/data/Mahmoud_Ali_Hassan_128kbps/',
    ],
    'abdulaziz_bukhari': [
      'https://server5.mp3quran.net/bukhari/',
      'https://everyayah.com/data/Abdulaziz_Bukhari_128kbps/',
    ],
    'mohamed_siddiq_minshawi': [
      'https://server10.mp3quran.net/minsh/',
      'https://everyayah.com/data/Mohamed_Siddiq_Minshawi_128kbps/',
    ],
    'mahmoud_khalil_husary_mujawwad': [
      'https://server7.mp3quran.net/husary_mujawwad/',
      'https://everyayah.com/data/Mahmoud_Khalil_Husary_Mujawwad_128kbps/',
    ],
    'mohamed_tablawi': [
      'https://server11.mp3quran.net/tablawi/',
      'https://everyayah.com/data/Mohamed_Tablawi_128kbps/',
    ],
    'nasser_al_qatami': [
      'https://server12.mp3quran.net/qatami/',
      'https://everyayah.com/data/Nasser_Al-Qatami_128kbps/',
    ],
    'jibril_muhammad': [
      'https://server13.mp3quran.net/jibril/',
      'https://everyayah.com/data/Jibril_Muhammad_128kbps/',
    ],
    'basit_mujawwad': [
      'https://server14.mp3quran.net/basit_mujawwad/',
      'https://everyayah.com/data/Basit_Mujawwad_128kbps/',
    ],
    'husary_mujawwad': [
      'https://server15.mp3quran.net/husary_mujawwad/',
      'https://everyayah.com/data/Husary_Mujawwad_128kbps/',
    ],
    'khaled_mujahid': [
      'https://server16.mp3quran.net/khaled/',
      'https://everyayah.com/data/Khaled_Mujahid_128kbps/',
    ],
    'abdullah_basfar': [
      'https://server17.mp3quran.net/basfar/',
      'https://everyayah.com/data/Abdullah_Basfar_128kbps/',
    ],
    'adil_kalbani': [
      'https://server18.mp3quran.net/kalbani/',
      'https://everyayah.com/data/Adil_Kalbani_128kbps/',
    ],
    'waleed_almoghai': [
      'https://server19.mp3quran.net/waleed/',
      'https://everyayah.com/data/Waleed_Almoghai_128kbps/',
    ],
    'mohamed_youssef': [
      'https://server20.mp3quran.net/youssef/',
      'https://everyayah.com/data/Mohamed_Youssef_128kbps/',
    ],
  };
  
  /// الحصول على رابط الصوت الأساسي
  String _getPrimaryUrl(ReciterProfile reciter, int surahNumber) {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final surah6Digits = surahNumber.toString().padLeft(6, '0');
    final baseUrl = reciter.serverUrl;
    
    // على Android نستخدم mp3quran.net مباشرة لأنه يعمل بدون مشاكل CORS
    if (baseUrl != null && baseUrl.isNotEmpty) {
      if (baseUrl.contains('mp3quran.net')) {
        final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
        final parts = cleanBaseUrl.split('/');
        if (parts.length >= 4) {
          final serverDomain = parts[2];
          final reciterCode = parts[3];
          return 'https://$serverDomain/download/$reciterCode/$surahPadded.mp3';
        }
      }
      return '$baseUrl/$surahPadded.mp3';
    }
    
    // رابط افتراضي
    return 'https://server8.mp3quran.net/download/afs/$surahPadded.mp3';
  }
  
  /// الحصول على روابط احتياطية
  List<String> _getBackupUrls(ReciterProfile reciter, int surahNumber) {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final surah6Digits = surahNumber.toString().padLeft(6, '0');
    final reciterCode = _extractReciterCode(reciter);
    final everyAyahFolder = _getEveryAyahFolder(reciterCode);
    
    final backupUrls = <String>[];
    
    // إضافة روابط mp3quran.net كاحتياطي (قد تعمل على بعض المتصفحات)
    if (reciter.serverUrl != null && reciter.serverUrl!.contains('mp3quran.net')) {
      final cleanBaseUrl = reciter.serverUrl!.endsWith('/') 
          ? reciter.serverUrl!.substring(0, reciter.serverUrl!.length - 1) 
          : reciter.serverUrl!;
      final parts = cleanBaseUrl.split('/');
      if (parts.length >= 4) {
        final serverDomain = parts[2];
        final code = parts[3];
        backupUrls.add('https://$serverDomain/download/$code/$surahPadded.mp3');
      }
    }
    
    // إضافة روابط من خوادم mp3quran أخرى
    backupUrls.add('https://server8.mp3quran.net/download/afs/$surahPadded.mp3');
    backupUrls.add('https://server12.mp3quran.net/download/maher/$surahPadded.mp3');
    
    // إضافة روابط EveryAyah بجودات مختلفة
    if (everyAyahFolder != null) {
      // محاولة 192kbps
      final folder192 = everyAyahFolder.replaceAll('128kbps', '192kbps');
      backupUrls.add('https://everyayah.com/data/$folder192/$surah6Digits.mp3');
    }
    
    return backupUrls;
  }
  
  /// استخراج كود القارئ
  String _extractReciterCode(ReciterProfile reciter) {
    final nameArabic = reciter.nameArabic.toLowerCase();
    final nameEnglish = reciter.nameEnglish.toLowerCase();
    final url = reciter.serverUrl?.toLowerCase() ?? '';
    
    // محاولة استخراج الكود من الرابط
    if (url.contains('mp3quran.net')) {
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final parts = cleanUrl.split('/');
      if (parts.length >= 4) {
        return parts[3];
      }
    }
    
    // البحث في قائمة الخوادم
    for (final entry in _backupServers.entries) {
      if (nameArabic.contains(entry.key) || nameEnglish.contains(entry.key) || url.contains(entry.key)) {
        return entry.key;
      }
    }
    
    // تطابق خاص لبعض القراء
    if (nameArabic.contains('حسن') && nameArabic.contains('صالح')) {
      return 'h_saleh';
    }
    if (nameEnglish.contains('hassan') && nameEnglish.contains('saleh')) {
      return 'h_saleh';
    }
    
    // افتراضي
    return 'afs';
  }
  
  /// الحصول على مجلد EveryAyah للقارئ
  String? _getEveryAyahFolder(String reciterCode) {
    final everyAyahFolders = {
      'maher': 'Maher_Al_Muaiqly_128kbps',
      'afs': 'Mishary_Rashid_Alafasy_128kbps',
      'sudais': 'Abdurrahmaan_As-Sudais_192kbps',
      'husary': 'Mahmoud_Khalil_Al-Husary_128kbps',
      'minsh': 'Mohamed_Siddiq_Al-Minshawi_128kbps',
      'abdurrahmaan_as_sudais': 'Abdurrahmaan_As-Sudais_192kbps',
      'mishary_rashid_alafasy': 'Mishary_Rashid_Alafasy_128kbps',
      'maher_al_muaiqly': 'Maher_Al_Muaiqly_128kbps',
      'abdul_basit': 'Abdul_Basit_Murattal_128kbps',
      'saad_ghamdi': 'Saad_Al-Ghamdi_128kbps',
      'yasser_dossari': 'Yasser_Ad-Dossary_128kbps',
      'hani_ar_rifai': 'Hani_Ar-Rifai_128kbps',
      'mahmoud_ali_al_banna': 'Mahmoud_Ali_Al-Banna_128kbps',
      'karim_mansoori': 'Karim_Mansoori_128kbps',
      'ali_jaber': 'Ali_Jaber_128kbps',
      'fares_abbad': 'Fares_Abbad_128kbps',
      'salah_bukhatir': 'Salah_Bukhatir_128kbps',
      'bandar_baleela': 'Bandar_Baleela_128kbps',
      'ahmed_neana': 'Ahmed_Neana_128kbps',
      'khalid_al_juhani': 'Khalid_Al-Juhani_128kbps',
      'mohamed_taha': 'Mohamed_Taha_128kbps',
      'hazza_al_balushi': 'Hazza_Al-Balushi_128kbps',
      'mohamed_al_luhaidan': 'Mohamed_Al-Luhaidan_128kbps',
      'mahmoud_khalil_al_husary': 'Mahmoud_Khalil_Al-Husary_128kbps',
      'abdulrahman_sudais': 'Abdurrahman_Sudais_192kbps',
      'shuraim': 'Saud_Ash-Shuraim_128kbps',
      'parhizgar': 'Parhizgar_128kbps',
      'abdulaziz_zahrani': 'Abdulaziz_Zahrani_128kbps',
      'yasser_fahmy': 'Yasser_Fahmy_128kbps',
      'ahmed_ibn_ali_al_ajmi': 'Ahmed_Ibn_Ali_Al-Ajmi_128kbps',
      'obaid_an_safi': 'Obaid_An-Safi_128kbps',
      'sahl_yasin': 'Sahl_Yasin_128kbps',
      'tariq_ibn_ali': 'Tariq_Ibn_Ali_128kbps',
      'mahmoud_ali_hassan': 'Mahmoud_Ali_Hassan_128kbps',
      'abdulaziz_bukhari': 'Abdulaziz_Bukhari_128kbps',
      'mohamed_siddiq_minshawi': 'Mohamed_Siddiq_Minshawi_128kbps',
      'mahmoud_khalil_husary_mujawwad': 'Mahmoud_Khalil_Husary_Mujawwad_128kbps',
      'mohamed_tablawi': 'Mohamed_Tablawi_128kbps',
      'nasser_al_qatami': 'Nasser_Al-Qatami_128kbps',
      'jibril_muhammad': 'Jibril_Muhammad_128kbps',
      'basit_mujawwad': 'Basit_Mujawwad_128kbps',
      'husary_mujawwad': 'Husary_Mujawwad_128kbps',
      'khaled_mujahid': 'Khaled_Mujahid_128kbps',
      'abdullah_basfar': 'Abdullah_Basfar_128kbps',
      'adil_kalbani': 'Adil_Kalbani_128kbps',
      'waleed_almoghai': 'Waleed_Almoghai_128kbps',
      'mohamed_youssef': 'Mohamed_Youssef_128kbps',
      'h_saleh': 'Hassan_Saleh_128kbps',
      'hassan_saleh': 'Hassan_Saleh_128kbps',
      'hassan': 'Hassan_Saleh_128kbps',
    };
    
    return everyAyahFolders[reciterCode];
  }
  
  /// تشغيل سورة معينة
  Future<bool> playSurah(ReciterProfile reciter, int surahNumber) async {
    final primaryUrl = _getPrimaryUrl(reciter, surahNumber);
    final backupUrls = _getBackupUrls(reciter, surahNumber);
    
    debugPrint('RobustQuranAudioService: Primary URL: $primaryUrl');
    debugPrint('RobustQuranAudioService: Backup URLs: $backupUrls');
    
    return await _audioEngine.playWithBackup(
      primaryUrl,
      backupUrls: backupUrls,
    );
  }
  
  /// إيقاف مؤقت
  Future<void> pause() async {
    await _audioEngine.pause();
  }
  
  /// إيقاف
  Future<void> stop() async {
    await _audioEngine.stop();
  }
  
  /// الانتقال
  Future<void> seek(Duration position) async {
    await _audioEngine.seek(position);
  }
  
  /// ضبط الصوت
  Future<void> setVolume(double volume) async {
    await _audioEngine.setVolume(volume);
  }
  
  /// ضبط السرعة
  Future<void> setSpeed(double speed) async {
    await _audioEngine.setSpeed(speed);
  }
  
  /// ضبط التكرار
  Future<void> setLoopMode(LoopMode mode) async {
    await _audioEngine.setLoopMode(mode);
  }
  
  /// التخلص
  Future<void> dispose() async {
    await _audioEngine.dispose();
  }
  
  // Getters
  Stream<bool> get isPlayingStream => _audioEngine.isPlayingStream;
  Stream<Duration> get positionStream => _audioEngine.positionStream;
  Stream<Duration?> get durationStream => _audioEngine.durationStream;
  Stream<String> get errorStream => _audioEngine.errorStream;
  Stream<String> get statusStream => _audioEngine.statusStream;
  
  bool get isPlaying => _audioEngine.isPlaying;
  Duration get position => _audioEngine.position;
  Duration? get duration => _audioEngine.duration;
}
