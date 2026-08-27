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
