import 'package:flutter/material.dart';

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

enum NotificationMode {
  athan,
  notificationOnly,
  silent,
  off,
}

class PrayerTiming {
  final PrayerType type;
  final String nameArabic;
  final String nameEnglish;
  final TimeOfDay time;
  final IconData icon;
  final NotificationMode notificationMode;

  const PrayerTiming({
    required this.type,
    required this.nameArabic,
    required this.nameEnglish,
    required this.time,
    required this.icon,
    this.notificationMode = NotificationMode.athan,
  });

  String get formattedTimeArabic {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final periodStr = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour12:$minuteStr $periodStr';
  }

  PrayerTiming copyWith({
    NotificationMode? notificationMode,
    TimeOfDay? time,
  }) {
    return PrayerTiming(
      type: type,
      nameArabic: nameArabic,
      nameEnglish: nameEnglish,
      time: time ?? this.time,
      icon: icon,
      notificationMode: notificationMode ?? this.notificationMode,
    );
  }
}

class PrayerCalculationSettings {
  final String method; // e.g., 'Egyptian General Authority of Survey'
  final String juristicMethod; // 'Shafii' or 'Hanafi'
  final double fajrAngle;
  final double ishaAngle;
  final Map<PrayerType, int> manualAdjustments; // Minutes offset

  const PrayerCalculationSettings({
    this.method = 'الهيئة المصرية العامة للمساحة',
    this.juristicMethod = 'شافعي، مالكي، حنبلي',
    this.fajrAngle = 19.5,
    this.ishaAngle = 17.5,
    this.manualAdjustments = const {
      PrayerType.fajr: 0,
      PrayerType.sunrise: 0,
      PrayerType.dhuhr: 0,
      PrayerType.asr: 0,
      PrayerType.maghrib: 0,
      PrayerType.isha: 0,
    },
  });
}

class LocationProfile {
  final String cityName;
  final String countryName;
  final double latitude;
  final double longitude;
  final double qiblaAngle; // Degrees clockwise from North

  const LocationProfile({
    required this.cityName,
    required this.countryName,
    required this.latitude,
    required this.longitude,
    required this.qiblaAngle,
  });
}

/// Model for a single day's prayer times
/// Used for 30-day cache system
class PrayerDay {
  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? imsak;
  final DateTime? sunset;
  final double latitude;
  final double longitude;
  final String timezone;
  final int calculationMethod;
  final String? madhab;
  final DateTime fetchedAt;
  final String source;

  const PrayerDay({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.imsak,
    this.sunset,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.calculationMethod,
    this.madhab,
    required this.fetchedAt,
    required this.source,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'fajr': fajr.toIso8601String(),
      'sunrise': sunrise.toIso8601String(),
      'dhuhr': dhuhr.toIso8601String(),
      'asr': asr.toIso8601String(),
      'maghrib': maghrib.toIso8601String(),
      'isha': isha.toIso8601String(),
      'imsak': imsak?.toIso8601String(),
      'sunset': sunset?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'fetchedAt': fetchedAt.toIso8601String(),
      'source': source,
    };
  }

  /// Create from JSON storage
  factory PrayerDay.fromJson(Map<String, dynamic> json) {
    return PrayerDay(
      date: DateTime.parse(json['date']),
      fajr: DateTime.parse(json['fajr']),
      sunrise: DateTime.parse(json['sunrise']),
      dhuhr: DateTime.parse(json['dhuhr']),
      asr: DateTime.parse(json['asr']),
      maghrib: DateTime.parse(json['maghrib']),
      isha: DateTime.parse(json['isha']),
      imsak: json['imsak'] != null ? DateTime.parse(json['imsak']) : null,
      sunset: json['sunset'] != null ? DateTime.parse(json['sunset']) : null,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timezone: json['timezone'] as String,
      calculationMethod: json['calculationMethod'] as int,
      madhab: json['madhab'] as String?,
      fetchedAt: DateTime.parse(json['fetchedAt']),
      source: json['source'] as String,
    );
  }

  /// Get prayer time by type
  DateTime? getPrayerTime(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.sunrise:
        return sunrise;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
    }
  }

  /// Check if this prayer day is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if this prayer day is in the past
  bool get isPast {
    return date.isBefore(DateTime.now());
  }

  /// Check if this prayer day is in the future
  bool get isFuture {
    return date.isAfter(DateTime.now());
  }
}
