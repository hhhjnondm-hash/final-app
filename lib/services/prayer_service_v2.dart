import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import 'athan_service.dart';
import 'prayer_time_calculator.dart';
import 'storage_service.dart';

class PrayerServiceV2 extends ChangeNotifier {
  static final PrayerServiceV2 _instance = PrayerServiceV2._internal();
  factory PrayerServiceV2() => _instance;
  PrayerServiceV2._internal() {
    _startTimer();
    _athanService = AthanService();
    _athanService.initialize();
    _calculator.loadUserAdjustments();
    _initService();
  }

  Timer? _timer;
  DateTime _selectedDate = DateTime.now();
  LocationProfile? _currentLocation;
  PrayerCalculationSettings _settings = const PrayerCalculationSettings();
  late AthanService _athanService;
  final PrayerTimeCalculator _calculator = PrayerTimeCalculator();
  
  // Cache for 30 days of prayer data
  final Map<DateTime, Map<PrayerType, DateTime>> _cachedPrayerData = {};

  final Map<PrayerType, NotificationMode> _notificationSettings = {
    PrayerType.fajr: NotificationMode.athan,
    PrayerType.sunrise: NotificationMode.silent,
    PrayerType.dhuhr: NotificationMode.athan,
    PrayerType.asr: NotificationMode.athan,
    PrayerType.maghrib: NotificationMode.athan,
    PrayerType.isha: NotificationMode.athan,
  };

  DateTime get selectedDate => _selectedDate;
  LocationProfile? get currentLocation => _currentLocation;
  PrayerCalculationSettings get settings => _settings;
  Map<PrayerType, NotificationMode> get notificationSettings => _notificationSettings;
  AthanService get athanService => _athanService;
  PrayerTimeCalculator get calculator => _calculator;

  Future<void> _initService() async {
    try {
      final storage = StorageService();
      await storage.init();

      // 1. Load saved user location if available
      final savedLoc = await storage.getLocation();
      if (savedLoc != null) {
        _currentLocation = LocationProfile(
          cityName: savedLoc['cityName'] as String? ?? 'القاهرة',
          countryName: savedLoc['countryName'] as String? ?? 'مصر',
          latitude: (savedLoc['latitude'] as num?)?.toDouble() ?? 30.0444,
          longitude: (savedLoc['longitude'] as num?)?.toDouble() ?? 31.2357,
          qiblaAngle: (savedLoc['qiblaAngle'] as num?)?.toDouble() ?? 136.0,
        );
      } else {
        _currentLocation = const LocationProfile(
          cityName: 'القاهرة',
          countryName: 'مصر',
          latitude: 30.0444,
          longitude: 31.2357,
          qiblaAngle: 136.0,
        );
      }

      // 2. Load saved notification preferences
      await _loadNotificationSettings();

      // 3. Purge past expired records and check/refresh 30-day cache
      await checkAndRefresh30DayCache();
    } catch (e) {
      debugPrint('⚠️ Error in PrayerServiceV2._initService: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final storage = StorageService();
      await storage.init();
      final saved = await storage.getNotificationSettings();
      if (saved != null) {
        for (final entry in saved.entries) {
          try {
            final pType = PrayerType.values.firstWhere((e) => e.name == entry.key);
            final nMode = NotificationMode.values.firstWhere((e) => e.name == entry.value);
            _notificationSettings[pType] = nMode;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> setLocation(LocationProfile location) async {
    _currentLocation = location;
    notifyListeners();

    try {
      final storage = StorageService();
      await storage.init();
      await storage.saveLocation(
        cityName: location.cityName,
        countryName: location.countryName,
        latitude: location.latitude,
        longitude: location.longitude,
        qiblaAngle: location.qiblaAngle,
      );

      _athanService.setupAthanTimer(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      // Refresh 30-day cache for new coordinates
      await refreshPrayerData();
    } catch (e) {
      debugPrint('⚠️ Error updating location: $e');
    }
  }

  void updateSettings(PrayerCalculationSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> setNotificationMode(PrayerType prayer, NotificationMode mode) async {
    _notificationSettings[prayer] = mode;
    notifyListeners();

    try {
      final storage = StorageService();
      await storage.init();
      final notifMap = _notificationSettings.map((k, v) => MapEntry(k.name, v.name));
      await storage.saveNotificationSettings(notifMap);

      // Sync with AthanService
      final prayerNameMap = {
        PrayerType.fajr: 'Fajr',
        PrayerType.dhuhr: 'Dhuhr',
        PrayerType.asr: 'Asr',
        PrayerType.maghrib: 'Maghrib',
        PrayerType.isha: 'Isha',
      };

      final prayerKey = prayerNameMap[prayer];
      if (prayerKey != null) {
        final updatedPrayers = Map<String, bool>.from(_athanService.settings.enabledPrayers);
        updatedPrayers[prayerKey] = (mode != NotificationMode.silent && mode != NotificationMode.off);
        await _athanService.updateSettings(
          _athanService.settings.copyWith(enabledPrayers: updatedPrayers),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error saving notification mode: $e');
    }
  }

  /// Check existing 30-day cache, purge old past dates, and refresh if needed
  Future<void> checkAndRefresh30DayCache() async {
    try {
      final storage = StorageService();
      await storage.init();

      // 1. Force purge any expired records from past days before today
      final cleanedCount = await storage.autoCleanOldCache(force: true);
      if (cleanedCount > 0) {
        debugPrint('🧹 Auto-purged $cleanedCount old past prayer records from local storage.');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 2. Count how many valid future days exist in local storage
      final keys = storage.getPrayerCacheKeys();
      int futureValidDays = 0;
      final Map<DateTime, Map<PrayerType, DateTime>> restoredCache = {};

      for (final key in keys) {
        try {
          final parts = key.split('-');
          if (parts.length == 3) {
            final cDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            if (!cDate.isBefore(today)) {
              futureValidDays++;
              final cacheMap = storage.getPrayerCache(key);
              if (cacheMap != null) {
                final prayerMap = <PrayerType, DateTime>{};
                cacheMap.forEach((pName, pTimeStr) {
                  try {
                    final pType = PrayerType.values.firstWhere((e) => e.name == pName);
                    prayerMap[pType] = DateTime.parse(pTimeStr as String);
                  } catch (_) {}
                });
                if (prayerMap.isNotEmpty) {
                  restoredCache[cDate] = prayerMap;
                }
              }
            }
          }
        } catch (_) {}
      }

      _cachedPrayerData.addAll(restoredCache);

      // 3. If fewer than 7 days remain or storage is empty, fetch fresh 30 days
      if (futureValidDays < 7) {
        debugPrint('📅 Cache has only $futureValidDays days remaining. Fetching full 30-day window...');
        await _load30DayPrayerData();
      } else {
        debugPrint('✅ Found $futureValidDays future days cached locally. Pre-loaded into memory.');

        // Schedule OS alarms for today if available
        final todayTimes = _cachedPrayerData[today];
        if (todayTimes != null) {
          final stringMap = <String, DateTime>{};
          if (todayTimes[PrayerType.fajr] != null) stringMap['Fajr'] = todayTimes[PrayerType.fajr]!;
          if (todayTimes[PrayerType.dhuhr] != null) stringMap['Dhuhr'] = todayTimes[PrayerType.dhuhr]!;
          if (todayTimes[PrayerType.asr] != null) stringMap['Asr'] = todayTimes[PrayerType.asr]!;
          if (todayTimes[PrayerType.maghrib] != null) stringMap['Maghrib'] = todayTimes[PrayerType.maghrib]!;
          if (todayTimes[PrayerType.isha] != null) stringMap['Isha'] = todayTimes[PrayerType.isha]!;
          _athanService.scheduleUpcomingNotifications(stringMap);
        }

        if (_currentLocation != null) {
          _athanService.setupAthanTimer(
            latitude: _currentLocation!.latitude,
            longitude: _currentLocation!.longitude,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error checking 30-day cache: $e');
    }
  }

  /// Load 30 days of prayer data from timesprayer.com and clean old cache
  Future<void> _load30DayPrayerData() async {
    try {
      if (_currentLocation == null) {
        _currentLocation = const LocationProfile(
          cityName: 'القاهرة',
          countryName: 'مصر',
          latitude: 30.0444,
          longitude: 31.2357,
          qiblaAngle: 136.0,
        );
      }
      
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      
      // 1. Run System Cache Cleaner to remove old past cache
      final storage = StorageService();
      await storage.init();
      await storage.autoCleanOldCache(force: true);

      debugPrint('📅 Loading and synchronizing 30 days of prayer data...');
      
      await _calculator.preloadPrayerData(
        startDate: startDate,
        days: 30,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        calculationMethod: _getCalculationMethodIndex(),
        timezone: 'Africa/Cairo',
      );
      
      // 2. Clear old cached memory map when refreshing with a new 30-day window
      _cachedPrayerData.removeWhere((key, _) => key.isBefore(startDate));

      // Cache the new 30 days of data
      for (int i = 0; i < 30; i++) {
        final date = startDate.add(Duration(days: i));
        final finalTimes = await _calculator.getAllFinalPrayerTimes(
          date: date,
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          calculationMethod: _getCalculationMethodIndex(),
          timezone: 'Africa/Cairo',
        );
        
        if (finalTimes.isNotEmpty) {
          _cachedPrayerData[date] = finalTimes;
          
          // Persist to local storage cache for offline retrieval
          final dateKey = '${date.year}-${date.month}-${date.day}';
          final prayerMap = finalTimes.map((k, v) => MapEntry(k.name, v.toIso8601String()));
          await storage.savePrayerCache(dateKey, prayerMap);
        }
      }
      
      debugPrint('✅ Synced & Cached ${_cachedPrayerData.length} days of prayer data with clean storage.');
      
      // Schedule OS exact alarms and notifications for today's prayers
      final todayTimes = _cachedPrayerData[startDate];
      if (todayTimes != null) {
        final stringMap = <String, DateTime>{};
        if (todayTimes[PrayerType.fajr] != null) stringMap['Fajr'] = todayTimes[PrayerType.fajr]!;
        if (todayTimes[PrayerType.dhuhr] != null) stringMap['Dhuhr'] = todayTimes[PrayerType.dhuhr]!;
        if (todayTimes[PrayerType.asr] != null) stringMap['Asr'] = todayTimes[PrayerType.asr]!;
        if (todayTimes[PrayerType.maghrib] != null) stringMap['Maghrib'] = todayTimes[PrayerType.maghrib]!;
        if (todayTimes[PrayerType.isha] != null) stringMap['Isha'] = todayTimes[PrayerType.isha]!;
        _athanService.scheduleUpcomingNotifications(stringMap);
      }

      if (_currentLocation != null) {
        _athanService.setupAthanTimer(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading 30-day prayer data: $e');
    }
  }

  /// Get cached prayer data for a specific date
  Map<PrayerType, DateTime>? getCachedPrayerData(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _cachedPrayerData[normalizedDate];
  }

  /// Refresh prayer data and clean cache
  Future<void> refreshPrayerData() async {
    _cachedPrayerData.clear();
    final storage = StorageService();
    await storage.init();
    await storage.clearPrayerCache();
    await _load30DayPrayerData();
  }

  int _activeListenersCount = 0;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _activeListenersCount++;
    if (_activeListenersCount == 1) {
      _startTimer();
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _activeListenersCount--;
    if (_activeListenersCount <= 0) {
      _activeListenersCount = 0;
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // Calculate Prayer Timings for a specific Date using real API
  Future<List<PrayerTiming>> getPrayerTimingsForDate(DateTime date) async {
    if (_currentLocation == null) {
      // Fallback to Cairo if no location set
      _currentLocation = const LocationProfile(
        cityName: 'القاهرة',
        countryName: 'مصر',
        latitude: 30.0444,
        longitude: 31.2357,
        qiblaAngle: 136.0,
      );
    }

    debugPrint('Getting prayer times for date: $date');
    debugPrint('Location: ${_currentLocation!.cityName} (${_currentLocation!.latitude}, ${_currentLocation!.longitude})');

    final normalizedDate = DateTime(date.year, date.month, date.day);
    Map<PrayerType, DateTime> finalTimes = getCachedPrayerData(normalizedDate) ?? {};
    
    // Check persistent storage cache if memory cache missed
    if (finalTimes.isEmpty) {
      try {
        final storage = StorageService();
        await storage.init();
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final cachedJson = storage.getPrayerCache(dateKey);
        if (cachedJson != null) {
          final restored = <PrayerType, DateTime>{};
          cachedJson.forEach((pName, pTimeStr) {
            try {
              final pType = PrayerType.values.firstWhere((e) => e.name == pName);
              restored[pType] = DateTime.parse(pTimeStr as String);
            } catch (_) {}
          });
          if (restored.isNotEmpty) {
            finalTimes = restored;
            _cachedPrayerData[normalizedDate] = restored;
            debugPrint('✅ Loaded prayer times from persistent storage cache for $dateKey');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error reading prayer cache from storage: $e');
      }
    }

    if (finalTimes.isNotEmpty) {
      debugPrint('✅ Using cached prayer data for $date');
    } else {
      // Fetch from PrayerTimeCalculator
      finalTimes = await _calculator.getAllFinalPrayerTimes(
        date: date,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        calculationMethod: _getCalculationMethodIndex(),
        timezone: 'Africa/Cairo',
      );
      
      // Cache the result in memory and persistent storage
      if (finalTimes.isNotEmpty) {
        _cachedPrayerData[normalizedDate] = finalTimes;
        try {
          final storage = StorageService();
          await storage.init();
          final dateKey = '${date.year}-${date.month}-${date.day}';
          final prayerMap = finalTimes.map((k, v) => MapEntry(k.name, v.toIso8601String()));
          await storage.savePrayerCache(dateKey, prayerMap);
        } catch (_) {}
      }
    }

    debugPrint('Final times from calculator: $finalTimes');

    final icons = <PrayerType, IconData>{
      PrayerType.fajr: Icons.nightlight_round,
      PrayerType.sunrise: Icons.wb_twilight_rounded,
      PrayerType.dhuhr: Icons.wb_sunny_rounded,
      PrayerType.asr: Icons.cloud_queue_rounded,
      PrayerType.maghrib: Icons.wb_sunny_outlined,
      PrayerType.isha: Icons.nightlight_round,
    };

    final namesAr = <PrayerType, String>{
      PrayerType.fajr: 'الفجر',
      PrayerType.sunrise: 'الشروق',
      PrayerType.dhuhr: 'الظهر',
      PrayerType.asr: 'العصر',
      PrayerType.maghrib: 'المغرب',
      PrayerType.isha: 'العشاء',
    };

    final namesEn = <PrayerType, String>{
      PrayerType.fajr: 'Fajr',
      PrayerType.sunrise: 'Sunrise',
      PrayerType.dhuhr: 'Dhuhr',
      PrayerType.asr: 'Asr',
      PrayerType.maghrib: 'Maghrib',
      PrayerType.isha: 'Isha',
    };

    return PrayerType.values.map((type) {
      final time = finalTimes[type];
      final timeOfDay = time != null 
          ? TimeOfDay(hour: time.hour, minute: time.minute)
          : const TimeOfDay(hour: 0, minute: 0);

      debugPrint('Processing ${type.name}: $time -> $timeOfDay');

      return PrayerTiming(
        type: type,
        nameArabic: namesAr[type]!,
        nameEnglish: namesEn[type]!,
        time: timeOfDay,
        icon: icons[type]!,
        notificationMode: _notificationSettings[type] ?? NotificationMode.athan,
      );
    }).toList();
  }

  // Get Next and Current Prayer using real API data
  Future<PrayerTiming?> getNextPrayer() async {
    if (_currentLocation == null) {
      _currentLocation = const LocationProfile(
        cityName: 'القاهرة',
        countryName: 'مصر',
        latitude: 30.0444,
        longitude: 31.2357,
        qiblaAngle: 136.0,
      );
    }

    return await _calculator.getNextPrayer(
      date: DateTime.now(),
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      calculationMethod: _getCalculationMethodIndex(),
      timezone: 'Africa/Cairo',
    );
  }

  Future<PrayerTiming?> getCurrentPrayer() async {
    if (_currentLocation == null) {
      _currentLocation = const LocationProfile(
        cityName: 'القاهرة',
        countryName: 'مصر',
        latitude: 30.0444,
        longitude: 31.2357,
        qiblaAngle: 136.0,
      );
    }

    return await _calculator.getCurrentPrayer(
      date: DateTime.now(),
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      calculationMethod: _getCalculationMethodIndex(),
      timezone: 'Africa/Cairo',
    );
  }

  Future<Duration> getRemainingDuration() async {
    if (_currentLocation == null) {
      _currentLocation = const LocationProfile(
        cityName: 'القاهرة',
        countryName: 'مصر',
        latitude: 30.0444,
        longitude: 31.2357,
        qiblaAngle: 136.0,
      );
    }

    final remaining = await _calculator.getRemainingTime(
      date: DateTime.now(),
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      calculationMethod: _getCalculationMethodIndex(),
      timezone: 'Africa/Cairo',
    );

    return remaining ?? Duration.zero;
  }

  Future<double> getRemainingProgress() async {
    if (_currentLocation == null) {
      _currentLocation = const LocationProfile(
        cityName: 'القاهرة',
        countryName: 'مصر',
        latitude: 30.0444,
        longitude: 31.2357,
        qiblaAngle: 136.0,
      );
    }

    return await _calculator.getCountdownProgress(
      date: DateTime.now(),
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      calculationMethod: _getCalculationMethodIndex(),
      timezone: 'Africa/Cairo',
    );
  }

  // Format countdown string: HH:MM:SS
  Future<String> getFormattedCountdown() async {
    final rem = await getRemainingDuration();
    final hours = rem.inHours.toString().padLeft(2, '0');
    final minutes = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Get Hijri Date String (simplified - should use real hijri calculation)
  String getFormattedHijriDate() {
    // TODO: Implement real Hijri date calculation
    // For now, return a placeholder
    return 'التاريخ الهجري'; // Placeholder until real implementation
  }

  String getFormattedGregorianDate() {
    const daysAr = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final dayName = daysAr[_selectedDate.weekday - 1];
    final monthName = monthsAr[_selectedDate.month - 1];
    return '$dayName، ${_selectedDate.day} $monthName ${_selectedDate.year}';
  }

  // Preload prayer data for 30 days using timesprayer.com
  Future<void> preloadPrayerData() async {
    debugPrint('📅 Preloading 30 days of prayer data from timesprayer.com...');
    await _load30DayPrayerData();
  }

  // Get cache coverage information
  Future<Map<String, dynamic>> getCacheCoverage() async {
    return await _calculator.getCacheCoverage();
  }

  // Clear prayer cache
  Future<void> clearCache() async {
    await _calculator.clearCache();
  }

  int _getCalculationMethodIndex() {
    // Map method name to AlAdhan API method index
    // https://aladhan.com/prayer-times-api
    final methodMap = {
      'الهيئة المصرية العامة للمساحة': 5,
      'رابطة العالم الإسلامي': 3,
      'جامعة أم القرى': 1,
      'الهيئة العامة للشؤون الإسلامية والأوقاف': 8,
      'وزارة الأوقاف الكويتية': 10,
      'قطر': 12,
      'طهران': 7,
      'معهد الجيوفيزياء بجامعة طهران': 7,
      'منطقة الخليج': 10,
      'مجلس أوجاما الإسلامي سنغافورة': 11,
      'الاتحاد الإسلامي بفرنسا': 12,
      'ديانيت التركية': 13,
      'الإدارة الروحية لمسلمي روسيا': 14,
    };
    return methodMap[_settings.method] ?? 5;
  }
}
