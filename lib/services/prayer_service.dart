import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import 'athan_service.dart';
import 'prayer_time_calculator.dart';
import 'storage_service.dart';

class PrayerService extends ChangeNotifier {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal() {
    _startTimer();
    _athanService = AthanService();
    _athanService.initialize();
    _calculator = PrayerTimeCalculator();
    _storage = StorageService();
    _load30DayPrayerData();
  }

  Timer? _timer;
  DateTime _selectedDate = DateTime.now();
  LocationProfile _currentLocation = const LocationProfile(
    cityName: 'القاهرة',
    countryName: 'مصر',
    latitude: 30.0444,
    longitude: 31.2357,
    qiblaAngle: 136.0,
  );

  PrayerCalculationSettings _settings = const PrayerCalculationSettings();
  late AthanService _athanService;
  late PrayerTimeCalculator _calculator;
  late StorageService _storage;
  
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
  LocationProfile get currentLocation => _currentLocation;
  PrayerCalculationSettings get settings => _settings;
  Map<PrayerType, NotificationMode> get notificationSettings => _notificationSettings;
  AthanService get athanService => _athanService;

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

  /// Load 30 days of prayer data from timesprayer.com
  Future<void> _load30DayPrayerData() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      
      debugPrint('📅 Loading 30 days of prayer data from timesprayer.com...');
      
      await _calculator.preloadPrayerData(
        startDate: startDate,
        days: 30,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        calculationMethod: 5, // Egyptian General Authority
        timezone: 'Africa/Cairo',
      );
      
      // Cache the data
      for (int i = 0; i < 30; i++) {
        final date = startDate.add(Duration(days: i));
        final finalTimes = await _calculator.getAllFinalPrayerTimes(
          date: date,
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
          calculationMethod: 5,
          timezone: 'Africa/Cairo',
        );
        
        if (finalTimes.isNotEmpty) {
          _cachedPrayerData[date] = finalTimes;
        }
      }
      
      debugPrint('✅ Cached ${_cachedPrayerData.length} days of prayer data');
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

  /// Refresh prayer data from timesprayer.com
  Future<void> refreshPrayerData() async {
    _cachedPrayerData.clear();
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

  // Calculate Prayer Timings for a specific Date using PrayerTimeCalculator
  List<PrayerTiming> getPrayerTimingsForDate(DateTime date) {
    // Try to get from cache first (synchronous)
    final cachedData = getCachedPrayerData(date);
    Map<PrayerType, DateTime> prayerTimes;
    
    if (cachedData != null && cachedData.isNotEmpty) {
      prayerTimes = cachedData;
      debugPrint('✅ Using cached prayer data for $date');
    } else {
      // Use default times if not cached yet (will be updated async)
      prayerTimes = _getDefaultPrayerTimesMap();
      // Trigger async loading in background
      _loadPrayerDataForDate(date);
    }

    final icons = <PrayerType, IconData>{
      PrayerType.fajr: Icons.nightlight_round,
      PrayerType.sunrise: Icons.wb_twilight_rounded,
      PrayerType.dhuhr: Icons.wb_sunny_rounded,
      PrayerType.asr: Icons.cloud_queue_rounded,
      PrayerType.maghrib: Icons.wb_sunny_outlined,
      PrayerType.isha: Icons.nights_stay,
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
      final prayerTime = prayerTimes[type];
      final timeOfDay = prayerTime != null 
          ? TimeOfDay(hour: prayerTime.hour, minute: prayerTime.minute)
          : const TimeOfDay(hour: 0, minute: 0);
      
      // Apply manual adjustments
      final adj = _settings.manualAdjustments[type] ?? 0;
      final totalMinutes = (timeOfDay.hour * 60 + timeOfDay.minute + adj) % 1440;
      final adjustedTime = TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);

      return PrayerTiming(
        type: type,
        nameArabic: namesAr[type]!,
        nameEnglish: namesEn[type]!,
        time: adjustedTime,
        icon: icons[type]!,
        notificationMode: _notificationSettings[type] ?? NotificationMode.athan,
      );
    }).toList();
  }

  /// Load prayer data for a specific date asynchronously
  Future<void> _loadPrayerDataForDate(DateTime date) async {
    try {
      final prayerTimes = await _calculator.getAllFinalPrayerTimes(
        date: date,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        calculationMethod: 5,
        timezone: 'Africa/Cairo',
      );
      
      if (prayerTimes.isNotEmpty) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        _cachedPrayerData[normalizedDate] = prayerTimes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading prayer data for $date: $e');
    }
  }

  /// Get default prayer times as DateTime map
  Map<PrayerType, DateTime> _getDefaultPrayerTimesMap() {
    final now = DateTime.now();
    return {
      PrayerType.fajr: DateTime(now.year, now.month, now.day, 5, 3),
      PrayerType.sunrise: DateTime(now.year, now.month, now.day, 6, 33),
      PrayerType.dhuhr: DateTime(now.year, now.month, now.day, 12, 54),
      PrayerType.asr: DateTime(now.year, now.month, now.day, 16, 28),
      PrayerType.maghrib: DateTime(now.year, now.month, now.day, 19, 15),
      PrayerType.isha: DateTime(now.year, now.month, now.day, 20, 35),
    };
  }

  // Get Next and Current Prayer
  PrayerTiming getNextPrayer() {
    final now = DateTime.now();
    final timings = getPrayerTimingsForDate(now);
    final nowMinutes = now.hour * 60 + now.minute;

    for (final timing in timings) {
      final prayerMinutes = timing.time.hour * 60 + timing.time.minute;
      if (prayerMinutes > nowMinutes) {
        return timing;
      }
    }
    return timings.first; // Next day's Fajr
  }

  PrayerTiming getCurrentPrayer() {
    final now = DateTime.now();
    final timings = getPrayerTimingsForDate(now);
    final nowMinutes = now.hour * 60 + now.minute;

    PrayerTiming current = timings.last;
    for (int i = 0; i < timings.length; i++) {
      final prayerMinutes = timings[i].time.hour * 60 + timings[i].time.minute;
      if (nowMinutes >= prayerMinutes) {
        current = timings[i];
      }
    }
    return current;
  }

  Duration getRemainingDuration() {
    final now = DateTime.now();
    final next = getNextPrayer();
    var nextDateTime = DateTime(now.year, now.month, now.day, next.time.hour, next.time.minute);
    if (nextDateTime.isBefore(now)) {
      nextDateTime = nextDateTime.add(const Duration(days: 1));
    }
    return nextDateTime.difference(now);
  }

  double getRemainingProgress() {
    final now = DateTime.now();
    final current = getCurrentPrayer();
    final next = getNextPrayer();

    var currentDateTime = DateTime(now.year, now.month, now.day, current.time.hour, current.time.minute);
    var nextDateTime = DateTime(now.year, now.month, now.day, next.time.hour, next.time.minute);

    if (nextDateTime.isBefore(currentDateTime)) {
      nextDateTime = nextDateTime.add(const Duration(days: 1));
    }

    final totalSeconds = nextDateTime.difference(currentDateTime).inSeconds;
    if (totalSeconds <= 0) return 0.0;

    final passedSeconds = now.difference(currentDateTime).inSeconds;
    return (passedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  // Format countdown string: HH:MM:SS
  String getFormattedCountdown() {
    final rem = getRemainingDuration();
    final hours = rem.inHours.toString().padLeft(2, '0');
    final minutes = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Get Hijri Date String
  String getFormattedHijriDate() {
    return '15 ربيع الآخر 1447 هـ';
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
}
