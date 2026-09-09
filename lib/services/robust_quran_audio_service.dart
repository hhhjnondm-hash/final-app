import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audio_models.dart';
import 'advanced_audio_engine.dart';

/// خدمة صوتية قوية للقرآن مع مصادر متعددة
/// تحتوي على روابط احتياطية من مصادر مختلفة
class RobustQuranAudioService {
  final AdvancedAudioEngine _audioEngine = AdvancedAudioEngine();
  
  // إضافة تيار الحالة
  final StreamController<String> _statusController = StreamController.broadcast();
  
  /// تشغيل الصوت للسورة
  Future<bool> playSurah(ReciterProfile reciter, int surahNumber) async {
    try {
      final primaryUrl = _getPrimaryUrl(reciter, surahNumber);
      final backupUrls = _getBackupUrls(reciter, surahNumber);
      
      debugPrint('🎵 RobustQuranAudioService: Primary URL: $primaryUrl');
      debugPrint('🎵 RobustQuranAudioService: Backup URLs: $backupUrls');
      
      // تشغيل باستخدام AdvancedAudioEngine
      await _audioEngine.playWithBackup(primaryUrl, backupUrls: backupUrls);
      return true;
    } catch (e) {
      debugPrint('❌ Error playing surah: $e');
      return false;
    }
  }
  
  /// تشغيل ملف محلي
  Future<bool> playLocalFile(String localPath) async {
    try {
      await _audioEngine.playLocalFile(localPath);
      return true;
    } catch (e) {
      debugPrint('❌ Error playing local file: $e');
      return false;
    }
  }
  
  /// التقدم في الموضع
  Future<void> seek(Duration position) async {
    await _audioEngine.seek(position);
  }
  
  /// تغيير السرعة
  Future<void> setSpeed(double speed) async {
    // AdvancedAudioEngine doesn't have setPlaybackRate, using seek to simulate
    debugPrint('Speed change not supported in current implementation');
  }
  
  /// تيار الحالة
  Stream<String> get statusStream => _statusController.stream;
  
  /// التخلص من الموارد
  void dispose() {
    _statusController.close();
    _audioEngine.dispose();
  }
  
  /// الحصول على رابط الصوت الأساسي
  String _getPrimaryUrl(ReciterProfile reciter, int surahNumber) {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final reciterCode = _extractReciterCode(reciter);
    
    // استخدام EveryAyah كمصدر أساسي (يعمل على جميع المتصفحات)
    final everyAyahFolder = _getEveryAyahFolder(reciterCode);
    if (everyAyahFolder != null) {
      return 'https://everyayah.com/data/$everyAyahFolder/$surahPadded.mp3';
    }
    
    // رابط افتراضي موثوق - مشاري العفاسي
    return 'https://everyayah.com/data/Mishary_Rashid_Alafasy_128kbps/$surahPadded.mp3';
  }
  
  /// الحصول على روابط احتياطية متعددة
  List<String> _getBackupUrls(ReciterProfile reciter, int surahNumber) {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final backupUrls = <String>[];
    
    // روابط احتياطية من MP3Quran (كمصدر ثانوي)
    final reciterId = reciter.id;
    
    switch (reciterId) {
      case 'afasy':
        backupUrls.addAll([
          'https://server8.mp3quran.net/afs/$surahPadded.mp3',
          'https://server7.mp3quran.net/afs/$surahPadded.mp3',
        ]);
        break;
      case 'hassan_saleh':
        backupUrls.addAll([
          'https://server7.mp3quran.net/h_saleh/$surahPadded.mp3',
          'https://server12.mp3quran.net/h_saleh/$surahPadded.mp3',
        ]);
        break;
      case 'abdulbaset_murattal':
        backupUrls.addAll([
          'https://server12.mp3quran.net/basit/$surahPadded.mp3',
          'https://server6.mp3quran.net/basit/$surahPadded.mp3',
        ]);
        break;
      case 'minshawi_murattal':
        backupUrls.addAll([
          'https://server12.mp3quran.net/minsh/$surahPadded.mp3',
          'https://server11.mp3quran.net/minsh/$surahPadded.mp3',
        ]);
        break;
      case 'hussary_murattal':
        backupUrls.addAll([
          'https://server7.mp3quran.net/husr/$surahPadded.mp3',
          'https://server12.mp3quran.net/husr/$surahPadded.mp3',
        ]);
        break;
      case 'maher':
        backupUrls.addAll([
          'https://server9.mp3quran.net/maher/$surahPadded.mp3',
          'https://server12.mp3quran.net/maher/$surahPadded.mp3',
        ]);
        break;
      case 'dosari':
        backupUrls.addAll([
          'https://server12.mp3quran.net/yasser/$surahPadded.mp3',
          'https://server10.mp3quran.net/yasser/$surahPadded.mp3',
        ]);
        break;
      case 'ajmy':
        backupUrls.addAll([
          'https://server13.mp3quran.net/ajm/$surahPadded.mp3',
          'https://server12.mp3quran.net/ajm/$surahPadded.mp3',
        ]);
        break;
      case 'ghamdi':
        backupUrls.addAll([
          'https://server10.mp3quran.net/s_gmd/$surahPadded.mp3',
          'https://server12.mp3quran.net/s_gmd/$surahPadded.mp3',
        ]);
        break;
      case 'shuraim':
        backupUrls.addAll([
          'https://server13.mp3quran.net/shur/$surahPadded.mp3',
          'https://server12.mp3quran.net/shur/$surahPadded.mp3',
        ]);
        break;
      case 'banna':
        backupUrls.addAll([
          'https://server14.mp3quran.net/bna/$surahPadded.mp3',
          'https://server12.mp3quran.net/bna/$surahPadded.mp3',
        ]);
        break;
      case 'tablawi':
        backupUrls.addAll([
          'https://server15.mp3quran.net/tblwi/$surahPadded.mp3',
          'https://server12.mp3quran.net/tblwi/$surahPadded.mp3',
        ]);
        break;
      default:
        // روابط احتياطية عامة
        backupUrls.addAll([
          'https://server12.mp3quran.net/afs/$surahPadded.mp3', // Fallback to Afasy
        ]);
    }
    
    // إزالة التكرارات
    return backupUrls.toSet().toList();
  }
  
  /// استخراج كود القارئ
  String _extractReciterCode(ReciterProfile reciter) {
    final id = reciter.id.toLowerCase();
    
    final idToCode = {
      'hassan_saleh': 'h_saleh',
      'afasy': 'afs',
      'abdulbaset_murattal': 'basit',
      'minshawi_murattal': 'minsh',
      'hussary_murattal': 'husr',
      'maher': 'maher',
      'dosari': 'yasser',
      'ajmy': 'ajm',
      'ghamdi': 's_gmd',
      'shuraim': 'shur',
      'banna': 'bna',
      'tablawi': 'tblwi',
    };
    
    return idToCode[id] ?? 'afs';
  }
  
  /// الحصول على مجلد EveryAyah للقارئ
  String? _getEveryAyahFolder(String reciterCode) {
    final everyAyahFolders = {
      'h_saleh': 'Hassan_Saleh_128kbps',
      'afs': 'Mishary_Rashid_Alafasy_128kbps',
      'basit': 'Abdul_Basit_Murattal_128kbps',
      'minsh': 'Mohamed_Siddiq_Al-Minshawi_128kbps',
      'husr': 'Mahmoud_Khalil_Al-Husary_128kbps',
      'maher': 'Maher_Al_Muaiqly_128kbps',
      'yasser': 'Yasser_Al-Dosary_128kbps',
      'ajm': 'Ahmed_Ibn_Ali_Al-Ajmi_128kbps',
      's_gmd': 'Saad_Al-Ghamdi_128kbps',
      'shur': 'Saud_Ash-Shuraim_128kbps',
      'bna': 'Mahmoud_Ali_Al-Banna_128kbps',
      'tblwi': 'Mohammed_Tablawi_128kbps',
    };
    
    return everyAyahFolders[reciterCode];
  }
  
  /// إيقاف الصوت
  Future<void> stop() async {
    await _audioEngine.stop();
  }
  
  /// إيقاف مؤقت
  Future<void> pause() async {
    await _audioEngine.pause();
  }
  
  /// استئناف
  Future<void> resume() async {
    // AdvancedAudioEngine doesn't have resume, this is a stub
    debugPrint('Resume not supported in current implementation');
  }
  
  /// التحقق من حالة التشغيل
  bool get isPlaying => _audioEngine.isPlaying;
  
  /// الموضع الحالي
  Duration get position => _audioEngine.position;
  
  /// المدة الكلية
  Duration? get duration => _audioEngine.duration;
  
  /// تيار حالة التشغيل
  Stream<bool> get isPlayingStream => _audioEngine.isPlayingStream;
  
  /// تيار الموضع
  Stream<Duration> get positionStream => _audioEngine.positionStream;
  
  /// تيار المدة
  Stream<Duration?> get durationStream => _audioEngine.durationStream;
  
  /// تيار الأخطاء
  Stream<String> get errorStream => _audioEngine.errorStream;
}
