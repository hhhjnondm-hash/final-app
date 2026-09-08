import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'adhan_asset_mapper.dart';
import '../models/prayer_models.dart';

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
  none,
  local,
  multiple,
  makkah,
  madinah,
  cairo,
}

class AthanSettings {
  final bool enabled;
  final AthanMethod method;
  final AthanSound sound;
  final double volume;
  final bool vibrate;

  const AthanSettings({
    this.enabled = true,
    this.method = AthanMethod.muslimWorldLeague,
    this.sound = AthanSound.local,
    this.volume = 0.8,
    this.vibrate = true,
  });

  AthanSettings copyWith({
    bool? enabled,
    AthanMethod? method,
    AthanSound? sound,
    double? volume,
    bool? vibrate,
  }) {
    return AthanSettings(
      enabled: enabled ?? this.enabled,
      method: method ?? this.method,
      sound: sound ?? this.sound,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'method': method.index,
      'sound': sound.index,
      'volume': volume,
      'vibrate': vibrate,
    };
  }

  factory AthanSettings.fromJson(Map<String, dynamic> json) {
    return AthanSettings(
      enabled: json['enabled'] ?? true,
      method: AthanMethod.values[json['method'] ?? 0],
      sound: AthanSound.values[json['sound'] ?? 1],
      volume: json['volume']?.toDouble() ?? 0.8,
      vibrate: json['vibrate'] ?? true,
    );
  }
}

class AthanService extends ChangeNotifier {
  static final AthanService _instance = AthanService._internal();
  factory AthanService() => _instance;
  AthanService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  AthanSettings _settings = const AthanSettings();
  Timer? _athanTimer;
  DateTime? _lastPrayerTime;
  final Map<String, DateTime> _prayerTimes = {};

  // Offline storage for prayer times (30 days)
  final Map<String, Map<String, DateTime>> _offlinePrayerCache = {};

  AudioPlayer get audioPlayer => _audioPlayer;
  AthanSettings get settings => _settings;
  Map<String, DateTime> get prayerTimes => _prayerTimes;

  Future<void> initialize() async {
    await _loadSettings();
    await _loadOfflineCache();
    debugPrint('✅ Athan Service initialized');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('athan_settings');
    if (settingsJson != null) {
      _settings = AthanSettings.fromJson(jsonDecode(settingsJson));
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

    // Check offline cache first
    if (_offlinePrayerCache.containsKey(dateKey)) {
      debugPrint('📅 Using cached prayer times for $dateKey');
      return _offlinePrayerCache[dateKey]!;
    }

    try {
      final url = Uri.parse(
        'http://api.aladhan.com/v1/timings/${requestDate.day}-${requestDate.month}-${requestDate.year}',
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

        // Save to cache
        _offlinePrayerCache[dateKey] = prayerTimes;
        await _saveOfflineCache();

        debugPrint('✅ Prayer times fetched and cached for $dateKey');
        return prayerTimes;
      } else {
        throw Exception('Failed to fetch prayer times');
      }
    } catch (e) {
      debugPrint('❌ Error fetching prayer times: $e');
      // Return cached times if available, even if old
      if (_offlinePrayerCache.isNotEmpty) {
        final lastCacheKey = _offlinePrayerCache.keys.last;
        debugPrint('📅 Using last cached prayer times as fallback');
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
    
    _athanTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
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
          final prayerTime = prayerTimes[prayer];
          if (prayerTime != null) {
            final timeDiff = prayerTime.difference(now);
            
            // Trigger athan 1 minute before prayer time
            if (timeDiff.inMinutes == 1 && 
                (_lastPrayerTime == null || 
                 _lastPrayerTime!.difference(prayerTime).inMinutes.abs() > 2)) {
              _lastPrayerTime = prayerTime;
              await playAthan(prayer: prayer);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error in athan timer: $e');
      }
    });
  }

  Future<void> playAthan({required String prayer}) async {
    if (!_settings.enabled || _settings.sound == AthanSound.none) {
      debugPrint('🔇 Athan disabled or sound set to none');
      return;
    }

    try {
      String audioPath;
      
      switch (_settings.sound) {
        case AthanSound.local:
          audioPath = AdhanAssetMapper.getAssetPath(PrayerType.fajr);
          break;
        case AthanSound.multiple:
          audioPath = AdhanAssetMapper.getAssetPath(PrayerType.fajr, useSpecial: true);
          break;
        case AthanSound.makkah:
          audioPath = 'https://media.blubrry.com/muslim_central_quran/podcasts.quran-central.com/mishari-rashid-al-afasy/mishari-rashid-al-afasy-athan.mp3';
          break;
        case AthanSound.madinah:
          audioPath = 'https://server12.mp3quran.net/athan/';
          break;
        case AthanSound.cairo:
          audioPath = 'https://server7.mp3quran.net/athan/';
          break;
        case AthanSound.none:
          return;
      }

      await _audioPlayer.setVolume(_settings.volume);
      
      if (audioPath.startsWith('http')) {
        await _audioPlayer.setUrl(audioPath);
      } else {
        await _audioPlayer.setAsset(audioPath);
      }
      
      await _audioPlayer.play();

      debugPrint('🎵 Playing athan for $prayer: $audioPath');
      
      // Handle completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          debugPrint('✅ Athan completed for $prayer');
        }
      });
    } catch (e) {
      debugPrint('❌ Error playing athan: $e');
    }
  }

  Future<void> stopAthan() async {
    await _audioPlayer.stop();
    debugPrint('⏹️ Athan stopped');
  }

  Future<void> testAthan() async {
    await playAthan(prayer: 'Test');
  }

  void dispose() {
    _athanTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}