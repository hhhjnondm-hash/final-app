import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer_models.dart';
import 'storage_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _init();
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();
  
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  Map<PrayerType, NotificationMode> _prayerNotificationModes = {};

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  Map<PrayerType, NotificationMode> get prayerNotificationModes => _prayerNotificationModes;

  Future<void> _init() async {
    await _storage.init();
    await initialize();
    _loadNotificationSettings();
  }

  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Combined initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      _notificationsEnabled = granted ?? false;
    }
  }

  void _loadNotificationSettings() {
    final settings = _storage.getNotificationSettings();
    if (settings != null) {
      _notificationsEnabled = settings['enabled'] as bool? ?? true;
      
      final prayerModes = settings['prayerModes'] as Map<String, dynamic>?;
      if (prayerModes != null) {
        prayerModes.forEach((key, value) {
          final prayerType = _parsePrayerType(key);
          if (prayerType != null) {
            _prayerNotificationModes[prayerType] = _parseNotificationMode(value);
          }
        });
      }
    }
    
    // Set default modes if not loaded
    if (_prayerNotificationModes.isEmpty) {
      _prayerNotificationModes = {
        PrayerType.fajr: NotificationMode.athan,
        PrayerType.sunrise: NotificationMode.silent,
        PrayerType.dhuhr: NotificationMode.athan,
        PrayerType.asr: NotificationMode.athan,
        PrayerType.maghrib: NotificationMode.athan,
        PrayerType.isha: NotificationMode.athan,
      };
    }
  }

  Future<void> _saveNotificationSettings() async {
    final prayerModesMap = <String, String>{};
    _prayerNotificationModes.forEach((key, value) {
      prayerModesMap[key.name] = value.name;
    });

    await _storage.saveNotificationSettings({
      'enabled': _notificationsEnabled,
      'prayerModes': prayerModesMap,
    });
  }

  PrayerType? _parsePrayerType(String name) {
    try {
      return PrayerType.values.firstWhere((type) => type.name == name);
    } catch (e) {
      return null;
    }
  }

  NotificationMode _parseNotificationMode(String name) {
    try {
      return NotificationMode.values.firstWhere((mode) => mode.name == name);
    } catch (e) {
      return NotificationMode.athan;
    }
  }

  // ==================== NOTIFICATION CHANNELS ====================

  Future<void> createPrayerNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_notifications',
      'إشعارات الصلاة',
      description: 'إشعارات مواقيت الصلاة',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('athan'),
      enableVibration: true,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(channel);
  }

  Future<void> createGeneralNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'general_notifications',
      'إشعارات عامة',
      description: 'إشعارات التذكير والمحتوى العام',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(channel);
  }

  // ==================== SHOW NOTIFICATIONS ====================

  Future<void> showPrayerNotification({
    required PrayerType prayerType,
    required String prayerName,
    required TimeOfDay prayerTime,
  }) async {
    if (!_notificationsEnabled) return;

    final mode = _prayerNotificationModes[prayerType];
    if (mode == NotificationMode.silent || mode == NotificationMode.off) return;

    final String channelId = mode == NotificationMode.athan 
        ? 'prayer_notifications' 
        : 'general_notifications';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      'إشعارات الصلاة',
      channelDescription: 'إشعارات مواقيت الصلاة',
      importance: Importance.high,
      priority: Priority.high,
      sound: mode == NotificationMode.athan 
          ? const RawResourceAndroidNotificationSound('athan')
          : null,
      enableVibration: true,
      playSound: mode == NotificationMode.athan,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'athan.aiff',
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final timeString = '${prayerTime.hour.toString().padLeft(2, '0')}:${prayerTime.minute.toString().padLeft(2, '0')}';
    
    await _notificationsPlugin.show(
      prayerType.index + 1000, // Unique ID for each prayer
      'حان الآن وقت صلاة $prayerName',
      'الوقت: $timeString',
      platformDetails,
      payload: 'prayer_${prayerType.name}',
    );
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;

    await createGeneralNotificationChannel();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'إشعارات عامة',
      channelDescription: 'إشعارات التذكير والمحتوى العام',
      importance: Importance.defaultImportance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> showIslamicReminder({
    required String type, // 'ayah', 'dhikr', 'dua', 'quote'
    required String content,
    required String source,
  }) async {
    if (!_notificationsEnabled) return;

    final titles = {
      'ayah': 'آية قرآنية',
      'dhikr': 'ذكر إيماني',
      'dua': 'دعاء',
      'quote': 'حكمة إسلامية',
    };

    await showGeneralNotification(
      title: titles[type] ?? 'تذكير إيماني',
      body: content,
      payload: 'islamic_reminder_$type',
    );
  }

  // ==================== SCHEDULED NOTIFICATIONS ====================

  Future<void> schedulePrayerNotification({
    required PrayerType prayerType,
    required String prayerName,
    required DateTime scheduledTime,
  }) async {
    if (!_notificationsEnabled) return;

    final mode = _prayerNotificationModes[prayerType];
    if (mode == NotificationMode.silent || mode == NotificationMode.off) return;

    final String channelId = mode == NotificationMode.athan 
        ? 'prayer_notifications' 
        : 'general_notifications';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      'إشعارات الصلاة',
      channelDescription: 'إشعارات مواقيت الصلاة',
      importance: Importance.high,
      priority: Priority.high,
      sound: mode == NotificationMode.athan 
          ? const RawResourceAndroidNotificationSound('athan')
          : null,
      enableVibration: true,
      playSound: mode == NotificationMode.athan,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final timeString = '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    await _notificationsPlugin.zonedSchedule(
      prayerType.index + 2000, // Unique ID for scheduled notifications
      'حان الآن وقت صلاة $prayerName',
      'الوقت: $timeString',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'prayer_${prayerType.name}',
    );
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_notificationsEnabled) return;

    await createGeneralNotificationChannel();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'إشعارات عامة',
      channelDescription: 'إشعارات التذكير والمحتوى العام',
      importance: Importance.defaultImportance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ==================== NOTIFICATION MANAGEMENT ====================

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelPrayerNotifications() async {
    for (final prayerType in PrayerType.values) {
      await cancelNotification(prayerType.index + 1000);
      await cancelNotification(prayerType.index + 2000);
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // ==================== SETTINGS MANAGEMENT ====================

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveNotificationSettings();
    notifyListeners();
  }

  Future<void> setPrayerNotificationMode(PrayerType prayerType, NotificationMode mode) async {
    _prayerNotificationModes[prayerType] = mode;
    await _saveNotificationSettings();
    notifyListeners();
  }

  NotificationMode getPrayerNotificationMode(PrayerType prayerType) {
    return _prayerNotificationModes[prayerType] ?? NotificationMode.athan;
  }

  // ==================== NOTIFICATION TAP HANDLING ====================

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to specific screen
    // This would typically be handled by a navigation service
  }

  // ==================== BADGE MANAGEMENT ====================

  Future<void> setBadgeNumber(int number) async {
    // Badge functionality not available in current version
    // Can be implemented with flutter_local_notifications_plus package
  }

  Future<void> clearBadge() async {
    await setBadgeNumber(0);
  }
}