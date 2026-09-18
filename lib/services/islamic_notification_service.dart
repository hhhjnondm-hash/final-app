import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_models.dart';
import 'notification_service.dart';

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
      // Auto-schedule loaded content
      unawaited(scheduleAllActiveReminders());
    } catch (e) {
      debugPrint('Error loading notification datasets: $e');
    }
  }

  void updatePreferences(NotificationPreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
    unawaited(scheduleAllActiveReminders());
  }

  void toggleMaster(bool enabled) {
    _preferences = _preferences.copyWith(masterEnabled: enabled);
    notifyListeners();
    unawaited(scheduleAllActiveReminders());
  }

  void toggleCategory(NotificationContentType type, bool enabled) {
    final currentSchedules = Map<NotificationContentType, NotificationScheduleRule>.from(_preferences.schedules);
    if (currentSchedules.containsKey(type)) {
      currentSchedules[type] = currentSchedules[type]!.copyWith(isEnabled: enabled);
      _preferences = _preferences.copyWith(schedules: currentSchedules);
      notifyListeners();
      unawaited(scheduleAllActiveReminders());
    }
  }

  void updateScheduleTime(NotificationContentType type, TimeOfDay newTime) {
    final currentSchedules = Map<NotificationContentType, NotificationScheduleRule>.from(_preferences.schedules);
    if (currentSchedules.containsKey(type)) {
      currentSchedules[type] = currentSchedules[type]!.copyWith(preferredTime: newTime);
      _preferences = _preferences.copyWith(schedules: currentSchedules);
      notifyListeners();
      unawaited(scheduleAllActiveReminders());
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

  /// Schedule daily notifications with the system for active categories
  Future<void> scheduleAllActiveReminders() async {
    if (!_preferences.masterEnabled) {
      debugPrint('🔕 Islamic notifications master switch is OFF');
      return;
    }

    final notifService = NotificationService();
    final now = DateTime.now();
    final List<Map<String, dynamic>> nativeReminders = [];

    for (final entry in _preferences.schedules.entries) {
      final type = entry.key;
      final rule = entry.value;

      if (!rule.isEnabled) continue;

      final preferredTime = rule.preferredTime;
      var targetDate = DateTime(
        now.year,
        now.month,
        now.day,
        preferredTime.hour,
        preferredTime.minute,
      );

      // If preferred time has passed today, schedule for tomorrow
      if (targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 1));
      }

      // Schedule for next 3 consecutive days so notifications fire even without opening app
      for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
        final scheduleTime = targetDate.add(Duration(days: dayOffset));
        if (isInQuietHours(scheduleTime)) continue;

        final item = getNextRotationItem(type);
        if (item == null) continue;

        final notifId = (type.index + 1) * 1000 + dayOffset;
        String title;
        switch (type) {
          case NotificationContentType.ayah:
            title = '📖 آية وتدبر';
            break;
          case NotificationContentType.dua:
            title = '🤲 دعاء مأثور';
            break;
          case NotificationContentType.dhikr:
            title = '✨ ذكر وفضيلة';
            break;
          case NotificationContentType.quote:
            title = '💎 درر إيمانية';
            break;
          case NotificationContentType.prayer:
            title = '🕌 مواقيت الصلاة';
            break;
        }

        await notifService.scheduleIslamicContentNotification(
          id: notifId,
          title: title,
          body: item.text,
          scheduledDate: scheduleTime,
          category: item.category,
        );

        nativeReminders.add({
          'id': notifId,
          'title': title,
          'body': item.text,
          'category': item.category,
          'timestampMs': scheduleTime.millisecondsSinceEpoch,
        });
      }
    }

    // Register full list in Native Android AlarmClock system (wakes screen & fires even if app killed)
    if (!kIsWeb && nativeReminders.isNotEmpty) {
      try {
        const nativeChannel = MethodChannel('com.islamyat.islamyat_app/reminders_native');
        await nativeChannel.invokeMethod('scheduleRemindersList', {
          'remindersJson': jsonEncode(nativeReminders),
        });
        debugPrint('⏰ Native AlarmClock registered for ${nativeReminders.length} Islamic reminders');
      } catch (e) {
        debugPrint('Note: Error registering native reminders list: $e');
      }
    }

    debugPrint('📅 Successfully scheduled active Islamic reminders in OS');
  }

  /// Send an immediate test notification to verify delivery
  Future<void> sendTestNotification([NotificationContentType type = NotificationContentType.ayah]) async {
    final item = getNextRotationItem(type);
    final notifService = NotificationService();

    String title;
    switch (type) {
      case NotificationContentType.ayah:
        title = '📖 آية وتدبر: قال الله تعالى';
        break;
      case NotificationContentType.dua:
        title = '🤲 دعاء مأثور مبارك';
        break;
      case NotificationContentType.dhikr:
        title = '✨ ذكر وفضيلة نبوية';
        break;
      case NotificationContentType.quote:
        title = '💎 درر وحكم إيمانية';
        break;
      case NotificationContentType.prayer:
        title = '🕌 أذان ومواقيت الصلاة';
        break;
    }

    final body = item?.text ?? 'سبحان الله وبحمده، سبحان الله العظيم ﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾';

    // 1. Show via Flutter Local Notifications
    await notifService.showIslamicContentNotification(
      id: 9999,
      title: title,
      body: body,
      category: item?.category ?? 'تذكير إيماني',
    );

    // 2. Trigger Native Lockscreen Notification test
    await notifService.testNativeReminder(
      title: title,
      body: body,
      category: item?.category ?? 'تذكير إيماني',
    );

    debugPrint('🔔 Immediate test Islamic notification triggered (Local + Native Lockscreen)!');
  }
}
