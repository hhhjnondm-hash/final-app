import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_models.dart';

class IslamicNotificationService extends ChangeNotifier {
  static final IslamicNotificationService _instance = IslamicNotificationService._internal();
  factory IslamicNotificationService() => _instance;
  IslamicNotificationService._internal() {
    _loadAllDatasets();
  }

  bool _isInitialized = false;
  NotificationPreferences _preferences = NotificationPreferences.defaultPreferences();

  final List<NotificationContentItem> _ayat = [];
  final List<NotificationContentItem> _duas = [];
  final List<NotificationContentItem> _adhkar = [];
  final List<NotificationContentItem> _quotes = [];

  final List<NotificationContentItem> _recentNotifications = [];

  bool get isInitialized => _isInitialized;
  NotificationPreferences get preferences => _preferences;
  List<NotificationContentItem> get recentNotifications => List.unmodifiable(_recentNotifications);

  int get totalAyatCount => _ayat.length;
  int get totalDuasCount => _duas.length;
  int get totalAdhkarCount => _adhkar.length;
  int get totalQuotesCount => _quotes.length;

  Future<void> _loadAllDatasets() async {
    try {
      final ayatRaw = await rootBundle.loadString('assets/data/notifications/ayat.json');
      final ayatMap = json.decode(ayatRaw);
      if (ayatMap['items'] is List) {
        _ayat.clear();
        for (final item in ayatMap['items']) {
          _ayat.add(NotificationContentItem.fromJson(item));
        }
      }

      final duasRaw = await rootBundle.loadString('assets/data/notifications/duas.json');
      final duasMap = json.decode(duasRaw);
      if (duasMap['items'] is List) {
        _duas.clear();
        for (final item in duasMap['items']) {
          _duas.add(NotificationContentItem.fromJson(item));
        }
      }

      final adhkarRaw = await rootBundle.loadString('assets/data/notifications/adhkar.json');
      final adhkarMap = json.decode(adhkarRaw);
      if (adhkarMap['items'] is List) {
        _adhkar.clear();
        for (final item in adhkarMap['items']) {
          _adhkar.add(NotificationContentItem.fromJson(item));
        }
      }

      final quotesRaw = await rootBundle.loadString('assets/data/notifications/quotes.json');
      final quotesMap = json.decode(quotesRaw);
      if (quotesMap['items'] is List) {
        _quotes.clear();
        for (final item in quotesMap['items']) {
          _quotes.add(NotificationContentItem.fromJson(item));
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification datasets: $e');
    }
  }

  void updatePreferences(NotificationPreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }

  void toggleMaster(bool enabled) {
    _preferences = _preferences.copyWith(masterEnabled: enabled);
    notifyListeners();
  }

  void toggleCategory(NotificationContentType type, bool enabled) {
    final currentSchedules = Map<NotificationContentType, NotificationScheduleRule>.from(_preferences.schedules);
    if (currentSchedules.containsKey(type)) {
      currentSchedules[type] = currentSchedules[type]!.copyWith(isEnabled: enabled);
      _preferences = _preferences.copyWith(schedules: currentSchedules);
      notifyListeners();
    }
  }

  void updateScheduleTime(NotificationContentType type, TimeOfDay newTime) {
    final currentSchedules = Map<NotificationContentType, NotificationScheduleRule>.from(_preferences.schedules);
    if (currentSchedules.containsKey(type)) {
      currentSchedules[type] = currentSchedules[type]!.copyWith(preferredTime: newTime);
      _preferences = _preferences.copyWith(schedules: currentSchedules);
      notifyListeners();
    }
  }

  void toggleQuietHours(bool enabled) {
    _preferences = _preferences.copyWith(quietHoursEnabled: enabled);
    notifyListeners();
  }

  void updateQuietHours(TimeOfDay start, TimeOfDay end) {
    _preferences = _preferences.copyWith(
      quietHoursStart: start,
      quietHoursEnd: end,
    );
    notifyListeners();
  }

  bool isInQuietHours(DateTime time) {
    if (!_preferences.quietHoursEnabled) return false;
    final nowMinutes = time.hour * 60 + time.minute;
    final startMinutes = _preferences.quietHoursStart.hour * 60 + _preferences.quietHoursStart.minute;
    final endMinutes = _preferences.quietHoursEnd.hour * 60 + _preferences.quietHoursEnd.minute;

    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  NotificationContentItem? getNextRotationItem(NotificationContentType type) {
    List<NotificationContentItem> pool = [];
    switch (type) {
      case NotificationContentType.ayah:
        pool = _ayat;
        break;
      case NotificationContentType.dua:
        pool = _duas;
        break;
      case NotificationContentType.dhikr:
        pool = _adhkar;
        break;
      case NotificationContentType.quote:
        pool = _quotes;
        break;
      case NotificationContentType.prayer:
        return null;
    }

    if (pool.isEmpty) return null;

    final sorted = List<NotificationContentItem>.from(pool);
    sorted.sort((a, b) {
      if (a.timesShown != b.timesShown) {
        return a.timesShown.compareTo(b.timesShown);
      }
      if (a.lastShownAt == null) return -1;
      if (b.lastShownAt == null) return 1;
      return a.lastShownAt!.compareTo(b.lastShownAt!);
    });

    final selected = sorted.first;
    final updated = selected.copyWith(
      lastShownAt: DateTime.now(),
      timesShown: selected.timesShown + 1,
    );

    final idx = pool.indexWhere((item) => item.id == selected.id);
    if (idx != -1) {
      pool[idx] = updated;
    }

    _recentNotifications.insert(0, updated);
    if (_recentNotifications.length > 30) {
      _recentNotifications.removeLast();
    }
    notifyListeners();

    return updated;
  }
}
