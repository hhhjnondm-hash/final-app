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
    _load30DayPrayerData();
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

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setLocation(LocationProfile location) {
    _currentLocation = location;
    _athanService.setupAthanTimer(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    notifyListeners();
  }

  void updateSettings(PrayerCalculationSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  void setNotificationMode(PrayerType prayer, NotificationMode mode) {
    _notificationSettings[prayer] = mode;
    notifyListeners();
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
      
      // 1. Run System Cache Cleaner to remove old cache older than 30 days and save user storage
      final storage = StorageService();
      await storage.init();
      await storage.autoCleanOldCache();

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

  /// Refresh prayer data from timesprayer.com and clean cache
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

    // Try to get from cache first
    final cachedData = getCachedPrayerData(date);
    Map<PrayerType, DateTime> finalTimes;
    
    if (cachedData != null && cachedData.isNotEmpty) {
      finalTimes = cachedData;
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
      
      // Cache the result
      if (finalTimes.isNotEmpty) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        _cachedPrayerData[normalizedDate] = finalTimes;
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
