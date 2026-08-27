import 'package:flutter/material.dart';

enum NotificationContentType {
  ayah,
  dua,
  dhikr,
  quote,
  prayer,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

class NotificationContentItem {
  final String id;
  final NotificationContentType type;
  final String title;
  final String text;
  final String source;
  final String? category;
  final String? deepLink;
  final int? surahNumber;
  final int? ayahNumber;
  final DateTime? lastShownAt;
  final int timesShown;

  const NotificationContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.source,
    this.category,
    this.deepLink,
    this.surahNumber,
    this.ayahNumber,
    this.lastShownAt,
    this.timesShown = 0,
  });

  factory NotificationContentItem.fromJson(Map<String, dynamic> json) {
    return NotificationContentItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      type: _typeFromString(json['type']?.toString()),
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      source: json['source'] ?? '',
      category: json['category'],
      deepLink: json['deepLink'],
      surahNumber: json['surahNumber'] as int?,
      ayahNumber: json['ayahNumber'] as int?,
      timesShown: (json['timesShown'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'text': text,
      'source': source,
      'category': category,
      'deepLink': deepLink,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'lastShownAt': lastShownAt?.toIso8601String(),
      'timesShown': timesShown,
    };
  }

  NotificationContentItem copyWith({
    DateTime? lastShownAt,
    int? timesShown,
  }) {
    return NotificationContentItem(
      id: id,
      type: type,
      title: title,
      text: text,
      source: source,
      category: category,
      deepLink: deepLink,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      lastShownAt: lastShownAt ?? this.lastShownAt,
      timesShown: timesShown ?? this.timesShown,
    );
  }

  static NotificationContentType _typeFromString(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'ayah':
        return NotificationContentType.ayah;
      case 'dua':
        return NotificationContentType.dua;
      case 'dhikr':
        return NotificationContentType.dhikr;
      case 'quote':
        return NotificationContentType.quote;
      case 'prayer':
        return NotificationContentType.prayer;
      default:
        return NotificationContentType.dhikr;
    }
  }
}

class NotificationScheduleRule {
  final NotificationContentType type;
  final bool isEnabled;
  final TimeOfDay preferredTime;
  final String labelArabic;

  const NotificationScheduleRule({
    required this.type,
    required this.isEnabled,
    required this.preferredTime,
    required this.labelArabic,
  });

  NotificationScheduleRule copyWith({
    bool? isEnabled,
    TimeOfDay? preferredTime,
  }) {
    return NotificationScheduleRule(
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      preferredTime: preferredTime ?? this.preferredTime,
      labelArabic: labelArabic,
    );
  }
}

class NotificationPreferences {
  final bool masterEnabled;
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final int maxDailyNotifications;
  final int minIntervalMinutes;
  final Map<NotificationContentType, NotificationScheduleRule> schedules;

  const NotificationPreferences({
    this.masterEnabled = true,
    this.quietHoursEnabled = true,
    this.quietHoursStart = const TimeOfDay(hour: 23, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.maxDailyNotifications = 8,
    this.minIntervalMinutes = 90,
    required this.schedules,
  });

  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      masterEnabled: true,
      quietHoursEnabled: true,
      quietHoursStart: const TimeOfDay(hour: 23, minute: 0),
      quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
      maxDailyNotifications: 8,
      minIntervalMinutes: 90,
      schedules: {
        NotificationContentType.ayah: const NotificationScheduleRule(
          type: NotificationContentType.ayah,
          isEnabled: true,
          preferredTime: TimeOfDay(hour: 8, minute: 30),
          labelArabic: 'آية اليوم وتدبر قرآني',
        ),
        NotificationContentType.dua: const NotificationScheduleRule(
          type: NotificationContentType.dua,
          isEnabled: true,
          preferredTime: TimeOfDay(hour: 12, minute: 30),
          labelArabic: 'دعاء مأثور ومستجاب',
        ),
        NotificationContentType.dhikr: const NotificationScheduleRule(
          type: NotificationContentType.dhikr,
          isEnabled: true,
          preferredTime: TimeOfDay(hour: 17, minute: 30),
          labelArabic: 'أذكار وفوائد إيمانية',
        ),
        NotificationContentType.quote: const NotificationScheduleRule(
          type: NotificationContentType.quote,
          isEnabled: true,
          preferredTime: TimeOfDay(hour: 20, minute: 30),
          labelArabic: 'حكم وخواطر من السلف',
        ),
      },
    );
  }

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    int? maxDailyNotifications,
    int? minIntervalMinutes,
    Map<NotificationContentType, NotificationScheduleRule>? schedules,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      maxDailyNotifications: maxDailyNotifications ?? this.maxDailyNotifications,
      minIntervalMinutes: minIntervalMinutes ?? this.minIntervalMinutes,
      schedules: schedules ?? this.schedules,
    );
  }
}
