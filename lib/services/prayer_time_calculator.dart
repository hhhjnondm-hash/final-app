import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../repositories/timesprayer_repository.dart';
import '../services/storage_service.dart';

/// Single source of truth for prayer time calculations
/// Handles API data + user adjustments
/// Primary source: timesprayer.com (more accurate, future dates support)
/// Fallback source: aladhan API
class PrayerTimeCalculator {
  static final PrayerTimeCalculator _instance = PrayerTimeCalculator._internal();
  factory PrayerTimeCalculator() => _instance;
  PrayerTimeCalculator._internal();

  final TimesPrayerRepository _timesPrayerRepository = TimesPrayerRepository();
  final StorageService _storage = StorageService();
  
  Map<PrayerType, int> _userAdjustments = {
    PrayerType.fajr: 0,
    PrayerType.sunrise: 0,
    PrayerType.dhuhr: 0,
    PrayerType.asr: 0,
    PrayerType.maghrib: 0,
    PrayerType.isha: 0,
  };

  /// Load user adjustments from storage
  Future<void> loadUserAdjustments() async {
    await _storage.init();
    final adjustments = _storage.getPrayerAdjustments();
    if (adjustments != null) {
      adjustments.forEach((key, value) {
        final prayerType = _parsePrayerType(key);
        if (prayerType != null) {
          _userAdjustments[prayerType] = value as int;
        }
      });
    }
  }

  /// Save user adjustments to storage
  Future<void> saveUserAdjustments() async {
    await _storage.init();
    final adjustmentsMap = <String, int>{};
    _userAdjustments.forEach((key, value) {
      adjustmentsMap[key.name] = value;
    });
    await _storage.savePrayerAdjustments(adjustmentsMap);
  }

  /// Set adjustment for a specific prayer
  Future<void> setAdjustment(PrayerType prayer, int minutes) async {
    _userAdjustments[prayer] = minutes;
    await saveUserAdjustments();
  }

  /// Get adjustment for a specific prayer
  int getAdjustment(PrayerType prayer) {
    return _userAdjustments[prayer] ?? 0;
  }

  /// Get all adjustments
  Map<PrayerType, int> get allAdjustments => Map.from(_userAdjustments);
  
  /// Clear today's cache to force fresh API call
  Future<void> clearTodayCache() async {
    // Not implemented for timesprayer.com (no cache system)
    debugPrint('⚠️ Today cache clearing not implemented for timesprayer.com');
  }

  /// Get final calculated prayer time (API time + user adjustment)
  /// Primary source: timesprayer.com
  Future<DateTime?> getFinalPrayerTime({
    required DateTime date,
    required PrayerType prayer,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    // Use timesprayer.com as primary source
    final timesPrayerDay = await _timesPrayerRepository.getPrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    if (timesPrayerDay != null) {
      final rawTime = timesPrayerDay.getPrayerTime(prayer);
      if (rawTime != null) {
        final adjustment = _userAdjustments[prayer] ?? 0;
        return rawTime.add(Duration(minutes: adjustment));
      }
    }

    return null;
  }

  /// Get all final prayer times for a date
  Future<Map<PrayerType, DateTime>> getAllFinalPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    // Try timesprayer.com first
    final timesPrayerDay = await _timesPrayerRepository.getPrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    if (timesPrayerDay != null) {
      debugPrint('✅ Using timesprayer.com data for $date');
      return _applyAdjustments(timesPrayerDay);
    }

    debugPrint('⚠️ No prayer data available for $date');
    return {};
  }
  
  /// Apply user adjustments to prayer times
  Map<PrayerType, DateTime> _applyAdjustments(PrayerDay prayerDay) {
    return {
      PrayerType.fajr: prayerDay.fajr.add(Duration(minutes: _userAdjustments[PrayerType.fajr] ?? 0)),
      PrayerType.sunrise: prayerDay.sunrise.add(Duration(minutes: _userAdjustments[PrayerType.sunrise] ?? 0)),
      PrayerType.dhuhr: prayerDay.dhuhr.add(Duration(minutes: _userAdjustments[PrayerType.dhuhr] ?? 0)),
      PrayerType.asr: prayerDay.asr.add(Duration(minutes: _userAdjustments[PrayerType.asr] ?? 0)),
      PrayerType.maghrib: prayerDay.maghrib.add(Duration(minutes: _userAdjustments[PrayerType.maghrib] ?? 0)),
      PrayerType.isha: prayerDay.isha.add(Duration(minutes: _userAdjustments[PrayerType.isha] ?? 0)),
    };
  }

  /// Get next prayer with final calculated time
  Future<PrayerTiming?> getNextPrayer({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    final finalTimes = await getAllFinalPrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    if (finalTimes.isEmpty) return null;

    final now = DateTime.now();
    PrayerType? nextPrayer;
    DateTime? nextTime;

    for (final entry in finalTimes.entries) {
      if (entry.value.isAfter(now)) {
        if (nextTime == null || entry.value.isBefore(nextTime)) {
          nextTime = entry.value;
          nextPrayer = entry.key;
        }
      }
    }

    // If no prayer found for today, return tomorrow's Fajr
    if (nextPrayer == null) {
      final tomorrow = date.add(const Duration(days: 1));
      final tomorrowTimes = await getAllFinalPrayerTimes(
        date: tomorrow,
        latitude: latitude,
        longitude: longitude,
        calculationMethod: calculationMethod,
        timezone: timezone,
      );
      if (tomorrowTimes.isNotEmpty) {
        nextPrayer = PrayerType.fajr;
        nextTime = tomorrowTimes[PrayerType.fajr];
      }
    }

    if (nextPrayer == null || nextTime == null) return null;

    return _createPrayerTiming(nextPrayer, nextTime);
  }

  /// Get current prayer with final calculated time
  Future<PrayerTiming?> getCurrentPrayer({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    final finalTimes = await getAllFinalPrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    if (finalTimes.isEmpty) return null;

    final now = DateTime.now();
    PrayerType? currentPrayer;
    DateTime? currentPrayerTime;

    for (final entry in finalTimes.entries) {
      if (entry.value.isBefore(now)) {
        if (currentPrayerTime == null || entry.value.isAfter(currentPrayerTime)) {
          currentPrayerTime = entry.value;
          currentPrayer = entry.key;
        }
      }
    }

    if (currentPrayer == null || currentPrayerTime == null) return null;

    return _createPrayerTiming(currentPrayer, currentPrayerTime);
  }

  /// Get remaining time until next prayer
  Future<Duration?> getRemainingTime({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    final nextPrayer = await getNextPrayer(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    if (nextPrayer == null) return null;

    final now = DateTime.now();
    var nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      nextPrayer.time.hour,
      nextPrayer.time.minute,
    );

    if (nextTime.isBefore(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    return nextTime.difference(now);
  }

  /// Get countdown progress (0.0 to 1.0)
  Future<double> getCountdownProgress({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    final current = await getCurrentPrayer(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    final next = await getNextPrayer(
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      timezone: timezone,
    );

    if (current == null || next == null) return 0.0;

    final now = DateTime.now();
    final currentDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      current.time.hour,
      current.time.minute,
    );
    var nextDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      next.time.hour,
      next.time.minute,
    );

    if (nextDateTime.isBefore(currentDateTime)) {
      nextDateTime = nextDateTime.add(const Duration(days: 1));
    }

    final totalSeconds = nextDateTime.difference(currentDateTime).inSeconds;
    if (totalSeconds <= 0) return 0.0;

    final passedSeconds = now.difference(currentDateTime).inSeconds;
    return (passedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// Preload prayer data for date range using timesprayer.com
  Future<void> preloadPrayerData({
    required DateTime startDate,
    required int days,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    String? timezone,
  }) async {
    debugPrint('📅 Preloading $days days of prayer data from timesprayer.com...');
    
    try {
      final prayerDays = await _timesPrayerRepository.getPrayerTimesRange(
        startDate: startDate,
        days: days,
        latitude: latitude,
        longitude: longitude,
        calculationMethod: calculationMethod,
        timezone: timezone,
      );
      
      debugPrint('✅ Successfully preloaded ${prayerDays.length} days of prayer data');
    } catch (e) {
      debugPrint('❌ Failed to preload prayer data: $e');
    }
  }

  /// Invalidate cache for specific date
  Future<void> invalidateCache(DateTime date) async {
    // Not implemented for timesprayer.com (no cache system)
    debugPrint('⚠️ Cache invalidation not implemented for timesprayer.com');
  }

  /// Clear all prayer cache
  Future<void> clearCache() async {
    // Not implemented for timesprayer.com (no cache system)
    debugPrint('⚠️ Cache clearing not implemented for timesprayer.com');
  }

  /// Get cache coverage information
  Future<Map<String, dynamic>> getCacheCoverage() async {
    return {
      'source': 'timesprayer_com',
      'cache_enabled': false,
      'message': 'timesprayer.com does not use caching',
    };
  }

  PrayerType? _parsePrayerType(String name) {
    try {
      return PrayerType.values.firstWhere((type) => type.name == name);
    } catch (e) {
      return null;
    }
  }

  PrayerTiming _createPrayerTiming(PrayerType type, DateTime time) {
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

    return PrayerTiming(
      type: type,
      nameArabic: namesAr[type]!,
      nameEnglish: namesEn[type]!,
      time: TimeOfDay.fromDateTime(time),
      icon: icons[type]!,
    );
  }
}
