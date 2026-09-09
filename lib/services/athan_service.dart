import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/canonical_identities.dart';
import 'global_audio_manager.dart';

enum AthanMethod {
  muslimWorldLeague,
  islamicSocietyOfNorthAmerica,
  egyptianGeneralAuthorityOfSurvey,
  ummAlQuraUniversityMakkah,
  uaeGeneralAuthorityOfIslamicAffairsAndAwqaf,
  ministryOfAwqafKuwait,
  qatar,
  tehran,
  instituteOfGeophysicsUniversityOfTehran,
  gulfRegion,
  majlisUgamaIslamSingapura,
  unionOrganizationIslamicDeFrance,
  diyanetIslikleri,
  spiritualAdministrationOfMuslimsOfRussia,
}

enum AthanSound {
  customDownloaded, // الأذان المحمّل الجديد (أصوات متعددة للمشايخ)
  local,            // أذان الحرم المكي الافتراضي
  multiple,         // أذان الفجر المميز
  makkah,           // أذان مكة المكرمة أونلاين
  madinah,          // أذان المدينة المنورة أونلاين
  cairo,            // أذان القاهرة ومصر
  none,             // صامت / بدون صوت
}

class AthanSettings {
  final bool enabled;
  final AthanMethod method;
  final AthanSound sound;
  final double volume;
  final bool vibrate;
  final bool playFullAthan;
  final bool playFajrSpecial;
  final Map<String, bool> enabledPrayers; // Fajr, Dhuhr, Asr, Maghrib, Isha

  const AthanSettings({
    this.enabled = true,
    this.method = AthanMethod.egyptianGeneralAuthorityOfSurvey,
    this.sound = AthanSound.customDownloaded,
    this.volume = 0.9,
    this.vibrate = true,
    this.playFullAthan = true,
    this.playFajrSpecial = true,
    this.enabledPrayers = const {
      'Fajr': true,
      'Dhuhr': true,
      'Asr': true,
      'Maghrib': true,
      'Isha': true,
    },
  });

  AthanSettings copyWith({
    bool? enabled,
    AthanMethod? method,
    AthanSound? sound,
    double? volume,
    bool? vibrate,
    bool? playFullAthan,
    bool? playFajrSpecial,
    Map<String, bool>? enabledPrayers,
  }) {
    return AthanSettings(
      enabled: enabled ?? this.enabled,
      method: method ?? this.method,
      sound: sound ?? this.sound,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
      playFullAthan: playFullAthan ?? this.playFullAthan,
      playFajrSpecial: playFajrSpecial ?? this.playFajrSpecial,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'method': method.index,
      'sound': sound.index,
      'volume': volume,
      'vibrate': vibrate,
      'playFullAthan': playFullAthan,
      'playFajrSpecial': playFajrSpecial,
      'enabledPrayers': enabledPrayers,
    };
  }

  factory AthanSettings.fromJson(Map<String, dynamic> json) {
    return AthanSettings(
      enabled: json['enabled'] ?? true,
      method: AthanMethod.values[(json['method'] ?? 2).clamp(0, AthanMethod.values.length - 1)],
      sound: AthanSound.values[(json['sound'] ?? 0).clamp(0, AthanSound.values.length - 1)],
      volume: json['volume']?.toDouble() ?? 0.9,
      vibrate: json['vibrate'] ?? true,
      playFullAthan: json['playFullAthan'] ?? true,
      playFajrSpecial: json['playFajrSpecial'] ?? true,
      enabledPrayers: json['enabledPrayers'] != null
          ? Map<String, bool>.from(json['enabledPrayers'])
          : const {
              'Fajr': true,
              'Dhuhr': true,
              'Asr': true,
              'Maghrib': true,
              'Isha': true,
            },
    );
  }
}

class AthanService extends ChangeNotifier {
  static final AthanService _instance = AthanService._internal();
  factory AthanService() => _instance;
  AthanService._internal();

  final GlobalAudioManager _audioManager = GlobalAudioManager();
  AthanSettings _settings = const AthanSettings();
  Timer? _athanTimer;
  DateTime? _lastPrayerTime;
  String? _currentlyPlayingPrayer;
  final Map<String, DateTime> _prayerTimes = {};

  final Map<String, Map<String, DateTime>> _offlinePrayerCache = {};

  AthanSettings get settings => _settings;
  Map<String, DateTime> get prayerTimes => _prayerTimes;
  bool get isPlayingAthan => _audioManager.isPlaying && _audioManager.currentSource == AudioSourceType.adhan;
  String? get currentlyPlayingPrayer => _currentlyPlayingPrayer;

  Future<void> initialize() async {
    await _loadSettings();
    await _loadOfflineCache();
    debugPrint('✅ Advanced Athan Service initialized successfully');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('athan_settings');
    if (settingsJson != null) {
      try {
        _settings = AthanSettings.fromJson(jsonDecode(settingsJson));
      } catch (e) {
        debugPrint('Error parsing athan settings: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('athan_settings', jsonEncode(_settings.toJson()));
  }

  Future<void> _loadOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString('athan_cache');
    if (cacheJson != null) {
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      cacheData.forEach((date, times) {
        final timesMap = times as Map<String, dynamic>;
        _offlinePrayerCache[date] = {};
        timesMap.forEach((prayer, time) {
          _offlinePrayerCache[date]![prayer] = DateTime.parse(time);
        });
      });
    }
    _cleanOldCache();
  }

  Future<void> _saveOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = <String, dynamic>{};
    _offlinePrayerCache.forEach((date, times) {
      cacheData[date] = {};
      times.forEach((prayer, time) {
        cacheData[date][prayer] = time.toIso8601String();
      });
    });
    await prefs.setString('athan_cache', jsonEncode(cacheData));
  }

  void _cleanOldCache() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    _offlinePrayerCache.removeWhere((date, times) {
      final cacheDate = DateTime.parse(date);
      return cacheDate.isBefore(thirtyDaysAgo);
    });
  }

  Future<void> updateSettings(AthanSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  Future<Map<String, DateTime>> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    final requestDate = date ?? DateTime.now();
    final dateKey = '${requestDate.year}-${requestDate.month}-${requestDate.day}';

    if (_offlinePrayerCache.containsKey(dateKey)) {
      return _offlinePrayerCache[dateKey]!;
    }

    try {
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${requestDate.day}-${requestDate.month}-${requestDate.year}',
      ).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'method': _settings.method.index.toString(),
        },
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'] as Map<String, dynamic>;

        final prayerTimes = <String, DateTime>{};
        final prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

        for (final prayer in prayerNames) {
          final timeStr = timings[prayer] as String;
          final timeParts = timeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1].split(' ')[0]);
          
          prayerTimes[prayer] = DateTime(
            requestDate.year,
            requestDate.month,
            requestDate.day,
            hour,
            minute,
          );
        }

        _offlinePrayerCache[dateKey] = prayerTimes;
        await _saveOfflineCache();

        return prayerTimes;
      } else {
        throw Exception('Failed to fetch prayer times');
      }
    } catch (e) {
      debugPrint('❌ Error fetching prayer times: $e');
      if (_offlinePrayerCache.isNotEmpty) {
        final lastCacheKey = _offlinePrayerCache.keys.last;
        return _offlinePrayerCache[lastCacheKey]!;
      }
      rethrow;
    }
  }

  void setupAthanTimer({
    required double latitude,
    required double longitude,
  }) {
    _athanTimer?.cancel();
    
    _athanTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_settings.enabled) return;

      try {
        final now = DateTime.now();
        final prayerTimes = await fetchPrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: now,
        );

        final prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
        
        for (final prayer in prayerNames) {
          if (_settings.enabledPrayers[prayer] == false) continue;

          final prayerTime = prayerTimes[prayer];
          if (prayerTime != null) {
            final diffInSeconds = now.difference(prayerTime).inSeconds;
            
            // Trigger when within 0 to 45 seconds of prayer time
            if (diffInSeconds >= 0 && diffInSeconds <= 45 && 
                (_lastPrayerTime == null || 
                 _lastPrayerTime!.difference(prayerTime).inMinutes.abs() > 5)) {
              _lastPrayerTime = prayerTime;
              await playAthan(prayer: prayer);
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error in athan timer: $e');
      }
    });
  }

  String _getArabicPrayerName(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return 'الفجر';
      case 'dhuhr':
        return 'الظهر';
      case 'asr':
        return 'العصر';
      case 'maghrib':
        return 'المغرب';
      case 'isha':
        return 'العشاء';
      default:
        return prayer;
    }
  }

  String getSoundDisplayName(AthanSound sound) {
    switch (sound) {
      case AthanSound.customDownloaded:
        return 'أذان نداء الحق (المحمّل - صوت رائع)';
      case AthanSound.local:
        return 'أذان الحرم المكي الشريف';
      case AthanSound.multiple:
        return 'أذان الفجر المميز (الصلاة خير من النوم)';
      case AthanSound.makkah:
        return 'أذان الشيخ مشاري العفاسي';
      case AthanSound.madinah:
        return 'أذان المسجد النبوي الشريف';
      case AthanSound.cairo:
        return 'أذان مصر وجامع الأزهر';
      case AthanSound.none:
        return 'صامت (بدون صوت أذان)';
    }
  }

  Future<void> playAthan({required String prayer}) async {
    if (!_settings.enabled || _settings.sound == AthanSound.none) {
      debugPrint('🔇 Athan disabled or set to silent');
      return;
    }

    try {
      _currentlyPlayingPrayer = prayer;
      notifyListeners();

      String audioPath;
      bool isRemote = false;

      // Special handling for Fajr if enabled
      if (prayer.toLowerCase() == 'fajr' && _settings.playFajrSpecial) {
        audioPath = 'assets/audio/athan/athan_multiple.mp3';
      } else {
        switch (_settings.sound) {
          case AthanSound.customDownloaded:
            audioPath = 'assets/audio/athan/athan_custom.mp3';
            break;
          case AthanSound.local:
            audioPath = 'assets/audio/athan/athan_general.mp3';
            break;
          case AthanSound.multiple:
            audioPath = 'assets/audio/athan/athan_multiple.mp3';
            break;
          case AthanSound.makkah:
            audioPath = 'https://media.blubrry.com/muslim_central_quran/podcasts.quran-central.com/mishari-rashid-al-afasy/mishari-rashid-al-afasy-athan.mp3';
            isRemote = true;
            break;
          case AthanSound.madinah:
            audioPath = 'https://server12.mp3quran.net/athan/001.mp3';
            isRemote = true;
            break;
          case AthanSound.cairo:
            audioPath = 'https://server7.mp3quran.net/athan/002.mp3';
            isRemote = true;
            break;
          case AthanSound.none:
            return;
        }
      }

      final arabicName = _getArabicPrayerName(prayer);
      final descriptor = AudioSourceDescriptor(
        id: 'athan_$prayer',
        type: AudioSourceType.adhan,
        title: 'أذان صلاة $arabicName',
        subtitle: getSoundDisplayName(_settings.sound),
        provider: 'تطبيق رفيق',
        localPath: isRemote ? null : audioPath,
        remoteUrl: isRemote ? audioPath : null,
        metadata: {
          'prayer': prayer,
          'sound': _settings.sound.name,
        },
      );

      debugPrint('🎵 Triggering unified Athan for $prayer with sound $audioPath');
      await _audioManager.play(descriptor);
    } catch (e) {
      debugPrint('❌ Error playing athan: $e');
    }
  }

  Future<void> stopAthan() async {
    if (isPlayingAthan) {
      await _audioManager.stop();
    }
    _currentlyPlayingPrayer = null;
    notifyListeners();
  }

  Future<void> testAthan({AthanSound? testSound}) async {
    final previousSound = _settings.sound;
    if (testSound != null) {
      _settings = _settings.copyWith(sound: testSound);
    }
    await playAthan(prayer: 'Dhuhr');
    _settings = _settings.copyWith(sound: previousSound);
  }

  @override
  void dispose() {
    _athanTimer?.cancel();
    super.dispose();
  }
}
