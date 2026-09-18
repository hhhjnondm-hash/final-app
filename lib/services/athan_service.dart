import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/canonical_identities.dart';
import '../models/audio_playback.dart';
import 'global_audio_manager.dart';
import 'notification_service.dart';
import '../widgets/prayer_athan_dialog.dart';

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
  final bool respectSilentMode;
  final Map<String, bool> enabledPrayers; // Fajr, Dhuhr, Asr, Maghrib, Isha

  const AthanSettings({
    this.enabled = true,
    this.method = AthanMethod.egyptianGeneralAuthorityOfSurvey,
    this.sound = AthanSound.customDownloaded,
    this.volume = 0.9,
    this.vibrate = true,
    this.playFullAthan = true,
    this.playFajrSpecial = true,
    this.respectSilentMode = true,
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
    bool? respectSilentMode,
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
      respectSilentMode: respectSilentMode ?? this.respectSilentMode,
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
      'respectSilentMode': respectSilentMode,
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
      respectSilentMode: json['respectSilentMode'] ?? true,
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
  final NotificationService _notificationService = NotificationService();
  static GlobalKey<NavigatorState>? globalNavigatorKey;

  static const MethodChannel _systemChannel = MethodChannel('com.islamyat.islamyat_app/system_status');
  static const MethodChannel _nativeAthanChannel = MethodChannel('com.islamyat.islamyat_app/athan_native');

  /// Check if the Android device is currently in Silent or Vibrate mode
  static Future<bool> isDeviceInSilentMode() async {
    if (kIsWeb) return false;
    try {
      final bool? isSilent = await _systemChannel.invokeMethod<bool>('isSilentMode');
      return isSilent ?? false;
    } catch (e) {
      debugPrint('Error checking silent mode via system channel: $e');
      return false;
    }
  }

  AthanSettings _settings = const AthanSettings();
  Timer? _athanTimer;
  DateTime? _lastPrayerTime;
  String? _currentlyPlayingPrayer;
  final Map<String, DateTime> _prayerTimes = {};
  final Map<String, Map<String, DateTime>> _offlinePrayerCache = {};
  final Set<String> _triggeredPrayersToday = {};
  String _lastTimerCheckedDate = '';
  bool _hasScheduledUpcomingToday = false;
  String _lastScheduledDate = '';

  AthanSettings get settings => _settings;
  Map<String, DateTime> get prayerTimes => _prayerTimes;
  DateTime? get lastPrayerTime => _lastPrayerTime;
  bool get isPlayingAthan => _audioManager.isPlaying && _audioManager.currentSource == AudioSourceType.adhan;
  String? get currentlyPlayingPrayer => _currentlyPlayingPrayer;

  Future<void> initialize() async {
    await _loadSettings();
    await _loadOfflineCache();
    await _notificationService.initialize();

    // Listen for notification action clicks (e.g. stop sound button on notification)
    _notificationService.onActionStream.listen((action) {
      if (action == 'stop_athan') {
        debugPrint('🔕 Notification action stop_athan received');
        stopAthan();
      }
    });

    // Listen to audio manager completion
    _audioManager.playbackStateStream.listen((state) {
      if (state == PlaybackState.completed && _currentlyPlayingPrayer != null) {
        debugPrint('✅ Athan playback finished for $_currentlyPlayingPrayer');
        final prayer = _currentlyPlayingPrayer!;
        final arabicName = _getArabicPrayerName(prayer);
        // Show follow-up reminder
        _notificationService.showMissedPrayerNotification(
          id: _getPrayerIndex(prayer) + 500,
          prayerName: prayer,
          arabicName: arabicName,
        );
        _currentlyPlayingPrayer = null;
        notifyListeners();
      }
    });

    // Start mandatory timer immediately on startup with default coordinates
    setupAthanTimer(latitude: 30.0444, longitude: 31.2357);

    debugPrint('✅ Advanced Mandatory Athan Service initialized successfully');
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
      // Safe offline fallback prayer times for Middle East / Cairo
      return {
        'Fajr': DateTime(requestDate.year, requestDate.month, requestDate.day, 4, 45),
        'Dhuhr': DateTime(requestDate.year, requestDate.month, requestDate.day, 12, 0),
        'Asr': DateTime(requestDate.year, requestDate.month, requestDate.day, 15, 25),
        'Maghrib': DateTime(requestDate.year, requestDate.month, requestDate.day, 18, 5),
        'Isha': DateTime(requestDate.year, requestDate.month, requestDate.day, 19, 25),
      };
    }
  }

  /// Schedule upcoming notifications in the OS so they trigger even if the app is closed
  Future<void> scheduleUpcomingNotifications(Map<String, DateTime> prayerTimes) async {
    if (!_settings.enabled) return;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (_hasScheduledUpcomingToday && _lastScheduledDate == todayStr) {
      return;
    }

    for (final entry in prayerTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;

      if (_settings.enabledPrayers[prayer] == false) continue;

      if (prayerTime.isAfter(now)) {
        final isFajr = prayer.toLowerCase() == 'fajr';
        final arabicName = _getArabicPrayerName(prayer);
        final prayerIndex = _getPrayerIndex(prayer);

        // Schedule Athan exact alarm
        await _notificationService.schedulePrayerAthan(
          id: prayerIndex + 100,
          prayerName: prayer,
          arabicName: arabicName,
          scheduledDate: prayerTime,
          isFajr: isFajr,
        );

        // Schedule Missed Prayer Follow-up (15 min after athan)
        await _notificationService.scheduleMissedPrayerReminder(
          id: prayerIndex + 500,
          prayerName: prayer,
          arabicName: arabicName,
          prayerTime: prayerTime,
          delayMinutes: 15,
        );
      }
    }

    // Schedule native background Android AlarmClock alarms (fires even when app is killed or phone is locked)
    await scheduleNativeAthanAlarms(prayerTimes);

    _hasScheduledUpcomingToday = true;
    _lastScheduledDate = todayStr;
    debugPrint('📅 Scheduled all remaining daily prayer notifications in OS');
  }

  /// Schedule exact background Alarms in Android native AlarmManager
  /// This ensures Athan audio & notification fire even if the app is killed and phone is locked.
  Future<void> scheduleNativeAthanAlarms(Map<String, DateTime> prayerTimes) async {
    if (kIsWeb) return;
    try {
      final List<Map<String, dynamic>> alarmsList = [];
      final now = DateTime.now();

      for (final entry in prayerTimes.entries) {
        final prayer = entry.key;
        final prayerTime = entry.value;

        if (_settings.enabledPrayers[prayer] == false) continue;

        if (prayerTime.isAfter(now)) {
          alarmsList.add({
            'prayer': prayer,
            'arabicName': _getArabicPrayerName(prayer),
            'timestampMs': prayerTime.millisecondsSinceEpoch,
            'isFajr': prayer.toLowerCase() == 'fajr',
          });
        }
      }

      if (alarmsList.isNotEmpty) {
        await _nativeAthanChannel.invokeMethod('scheduleAthanAlarms', {
          'alarmsJson': jsonEncode(alarmsList),
          'respectSilentMode': _settings.respectSilentMode,
        });
        debugPrint('⏰ Native AlarmClock scheduled for ${alarmsList.length} prayers (Screen locked / App killed)');
      }
    } catch (e) {
      debugPrint('⚠️ Error scheduling native athan alarms: $e');
    }
  }

  void setupAthanTimer({
    required double latitude,
    required double longitude,
  }) {
    _athanTimer?.cancel();
    
    // Check frequently (every 5 seconds) to guarantee the prayer time is NEVER missed
    _athanTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_settings.enabled) return;

      try {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        if (_lastTimerCheckedDate != todayStr) {
          _triggeredPrayersToday.removeWhere((k) => !k.startsWith(todayStr));
          _lastTimerCheckedDate = todayStr;
        }

        final prayerTimes = await fetchPrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: now,
        );

        // Schedule upcoming notifications for when app is closed
        await scheduleUpcomingNotifications(prayerTimes);

        final prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
        
        for (final prayer in prayerNames) {
          if (_settings.enabledPrayers[prayer] == false) continue;

          final prayerTime = prayerTimes[prayer];
          if (prayerTime != null) {
            final key = '${todayStr}_$prayer';
            if (_triggeredPrayersToday.contains(key)) continue;

            final diffInSeconds = now.difference(prayerTime).inSeconds;
            final isSameMinute = now.year == prayerTime.year &&
                now.month == prayerTime.month &&
                now.day == prayerTime.day &&
                now.hour == prayerTime.hour &&
                now.minute == prayerTime.minute;

            // Trigger when within the prayer minute or between 0 and 90 seconds past prayer time
            if (isSameMinute || (diffInSeconds >= 0 && diffInSeconds <= 90)) {
              _triggeredPrayersToday.add(key);
              _lastPrayerTime = prayerTime;
              debugPrint('🚨 MANDATORY ATHAN TRIGGERED: $prayer at $now (scheduled: $prayerTime)');
              await playAthan(prayer: prayer, prayerTime: prayerTime);
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error in athan timer: $e');
      }
    });
  }

  int _getPrayerIndex(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return 0;
      case 'dhuhr':
        return 1;
      case 'asr':
        return 2;
      case 'maghrib':
        return 3;
      case 'isha':
        return 4;
      default:
        return 0;
    }
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

  Future<void> playAthan({
    required String prayer,
    DateTime? prayerTime,
    bool showDialog = true,
  }) async {
    if (!_settings.enabled) {
      debugPrint('🔇 Athan service is disabled');
      return;
    }

    try {
      _currentlyPlayingPrayer = prayer;
      notifyListeners();

      final isFajr = prayer.toLowerCase() == 'fajr';
      final arabicName = _getArabicPrayerName(prayer);
      final prayerIndex = _getPrayerIndex(prayer);
      final time = prayerTime ?? DateTime.now();

      // Check if device is in Silent or Vibrate mode
      bool isSilent = false;
      if (_settings.respectSilentMode) {
        isSilent = await isDeviceInSilentMode();
      }

      // 1. Trigger High-Priority OS Notification (With Athan Sound, works when screen locked)
      await _notificationService.showPrayerAthanNotification(
        id: prayerIndex + 100,
        prayerName: prayer,
        arabicName: arabicName,
        isFajr: isFajr,
      );

      // 2. Schedule Missed Prayer Follow-up Notification (15 min after prayer time)
      await _notificationService.scheduleMissedPrayerReminder(
        id: prayerIndex + 500,
        prayerName: prayer,
        arabicName: arabicName,
        prayerTime: time,
        delayMinutes: 15,
      );

      // 3. If in-app and context available, pop up the luxury PrayerAthanDialog
      if (showDialog && globalNavigatorKey?.currentContext != null) {
        final context = globalNavigatorKey!.currentContext!;
        if (context.mounted) {
          PrayerAthanDialog.show(
            context,
            prayerName: prayer,
            arabicName: arabicName,
          );
        }
      }

      // 4. Play in-app audio if device is not silent and sound is not set to none
      if (isSilent) {
        debugPrint('🔕 Phone is in silent/vibrate mode: In-app athan sound suppressed per user settings');
        // Still trigger missed prayer follow-up reminder after athan normal duration
        Future.delayed(const Duration(minutes: 3), () {
          _notificationService.showMissedPrayerNotification(
            id: prayerIndex + 500,
            prayerName: prayer,
            arabicName: arabicName,
          );
        });
      } else if (_settings.sound != AthanSound.none) {
        String audioPath;
        bool isRemote = false;

        if (isFajr && _settings.playFajrSpecial) {
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
              audioPath =
                  'https://media.blubrry.com/muslim_central_quran/podcasts.quran-central.com/mishari-rashid-al-afasy/mishari-rashid-al-afasy-athan.mp3';
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
      }
    } catch (e) {
      debugPrint('❌ Error playing athan: $e');
    }
  }

  Future<void> stopAthan() async {
    if (isPlayingAthan) {
      await _audioManager.stop();
    }
    if (!kIsWeb) {
      try {
        await _nativeAthanChannel.invokeMethod('stopAthanSound');
      } catch (e) {
        debugPrint('Error stopping native athan sound: $e');
      }
    }
    _currentlyPlayingPrayer = null;
    notifyListeners();
  }

  /// Test native Android background athan (triggers native foreground service)
  Future<void> testNativeBackgroundAthan({String prayer = 'Dhuhr'}) async {
    if (kIsWeb) return;
    try {
      await _nativeAthanChannel.invokeMethod('testNativeAthan', {
        'prayer': prayer,
        'arabicName': _getArabicPrayerName(prayer),
        'isFajr': prayer.toLowerCase() == 'fajr',
        'respectSilentMode': _settings.respectSilentMode,
      });
      debugPrint('🔔 Triggered native background athan service test for $prayer');
    } catch (e) {
      debugPrint('❌ Error testing native background athan: $e');
    }
  }

  Future<void> testAthan({AthanSound? testSound, BuildContext? context}) async {
    final previousSound = _settings.sound;
    if (testSound != null) {
      _settings = _settings.copyWith(sound: testSound);
    }
    if (context != null && context.mounted) {
      PrayerAthanDialog.show(
        context,
        prayerName: 'Dhuhr',
        arabicName: 'الظهر',
      );
    }
    await playAthan(prayer: 'Dhuhr', showDialog: context == null);
    _settings = _settings.copyWith(sound: previousSound);
  }

  @override
  void dispose() {
    _athanTimer?.cancel();
    super.dispose();
  }
}
