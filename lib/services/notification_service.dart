import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _exactAlarmsPermissionGranted = false;

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get exactAlarmsPermissionGranted => _exactAlarmsPermissionGranted;

  // Stream for notification actions (e.g., stopping athan sound)
  final StreamController<String> _actionController = StreamController<String>.broadcast();
  Stream<String> get onActionStream => _actionController.stream;

  // Channels
  static const String athanChannelId = 'athan_channel_v2';
  static const String athanFajrChannelId = 'athan_fajr_channel_v2';
  static const String missedPrayerChannelId = 'missed_prayer_channel_v2';
  static const String remindersChannelId = 'islamic_reminders_v2';

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('🌐 Web detected: Local notifications initialized in web mode');
      notifyListeners();
      return;
    }

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();

      // 2. Platform initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      // 3. Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // 4. Create Android Channels & Request Permissions
      await _setupAndroidChannelsAndPermissions();

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully with Android channels & sound');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Notification clicked: actionId=${response.actionId}, payload=${response.payload}');
    if (response.actionId != null) {
      _actionController.add(response.actionId!);
    } else if (response.payload != null) {
      _actionController.add(response.payload!);
    }
  }

  Future<void> _setupAndroidChannelsAndPermissions() async {
    if (kIsWeb) return;

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Request POST_NOTIFICATIONS on Android 13+
      final granted = await androidImplementation.requestNotificationsPermission();
      _notificationsEnabled = granted ?? true;

      // Request exact alarms permission
      final exactGranted = await androidImplementation.requestExactAlarmsPermission();
      _exactAlarmsPermissionGranted = exactGranted ?? false;

      // Channel 1: General Athan (with raw athan_sound resource)
      // Note: audioAttributesUsage: AudioAttributesUsage.notification ensures the OS
      // silences the sound when the user's phone is set to Silent or Vibrate mode!
      const AndroidNotificationChannel athanChannel = AndroidNotificationChannel(
        athanChannelId,
        'أذان الصلوات المفروضة',
        description: 'تشغيل صوت الأذان والتنبيه عند دخول وقت الصلاة',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('athan_sound'),
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      );

      // Channel 2: Fajr Athan (with special Fajr athan sound)
      const AndroidNotificationChannel fajrChannel = AndroidNotificationChannel(
        athanFajrChannelId,
        'أذان صلاة الفجر',
        description: 'صوت أذان الفجر المميز (الصلاة خير من النوم)',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('athan_fajr'),
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      );

      // Channel 3: Missed Prayer Reminder Channel
      const AndroidNotificationChannel missedPrayerChannel = AndroidNotificationChannel(
        missedPrayerChannelId,
        'تذكير بالصلوات الفائتة',
        description: 'تنبيه بعد انتهاء الأذان لتذكيرك بأداء الصلاة الفائتة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      );

      // Channel 4: Daily Islamic Reminders
      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        remindersChannelId,
        'التذكيرات الإيمانية اليومية',
        description: 'آيات وأدعية وأذكار يومية مباركة',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation.createNotificationChannel(athanChannel);
      await androidImplementation.createNotificationChannel(fajrChannel);
      await androidImplementation.createNotificationChannel(missedPrayerChannel);
      await androidImplementation.createNotificationChannel(reminderChannel);
    }
  }

  /// Trigger immediate prayer Athan notification
  Future<void> showPrayerAthanNotification({
    required int id,
    required String prayerName,
    required String arabicName,
    bool isFajr = false,
  }) async {
    if (kIsWeb) {
      debugPrint('🌐 Web: Athan notification simulated for $arabicName');
      return;
    }

    try {
      final channelId = isFajr ? athanFajrChannelId : athanChannelId;
      final rawSoundName = isFajr ? 'athan_fajr' : 'athan_sound';

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        isFajr ? 'أذان صلاة الفجر' : 'أذان الصلوات المفروضة',
        channelDescription: 'حان الآن موعد الصلاة',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(rawSoundName),
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(
          'حان الآن موعد أذان صلاة $arabicName - قال تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾',
          contentTitle: '🕌 حان الآن أَذَان $arabicName',
          summaryText: 'تطبيق رفيق المسلم',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'stop_athan',
            'إيقاف الصوت 🔕',
            cancelNotification: false,
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'open_app',
            'هيا إلى الصلاة 🧎',
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'athan_sound.aiff',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: '🕌 حان الآن أَذَان $arabicName',
        body: 'حان وقت صلاة $arabicName - أقم صلاتك يرحمك الله',
        notificationDetails: notificationDetails,
        payload: 'prayer_$prayerName',
      );

      debugPrint('✅ Prayer Athan Notification shown successfully for $arabicName (ID: $id)');
    } catch (e) {
      debugPrint('❌ Error showing prayer notification: $e');
    }
  }

  /// Schedule Athan notification for future prayer time (Works even when app is closed)
  Future<void> schedulePrayerAthan({
    required int id,
    required String prayerName,
    required String arabicName,
    required DateTime scheduledDate,
    bool isFajr = false,
  }) async {
    if (kIsWeb) return;

    try {
      final channelId = isFajr ? athanFajrChannelId : athanChannelId;
      final rawSoundName = isFajr ? 'athan_fajr' : 'athan_sound';

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        isFajr ? 'أذان صلاة الفجر' : 'أذان الصلوات المفروضة',
        channelDescription: 'حان الآن موعد الصلاة',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(rawSoundName),
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'stop_athan',
            'إيقاف الصوت 🔕',
            cancelNotification: false,
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'open_app',
            'هيا إلى الصلاة 🧎',
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'athan_sound.aiff',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return; // Don't schedule past events
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: '🕌 حان الآن أَذَان $arabicName',
        body: 'حان وقت صلاة $arabicName - ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾',
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'prayer_$prayerName',
      );

      debugPrint('⏰ Scheduled Athan notification for $arabicName at $scheduledDate (ID: $id)');
    } catch (e) {
      debugPrint('❌ Error scheduling prayer athan: $e');
    }
  }

  /// Show Missed Prayer Notification (When Athan finishes or 15 minutes after prayer)
  Future<void> showMissedPrayerNotification({
    required int id,
    required String prayerName,
    required String arabicName,
  }) async {
    if (kIsWeb) {
      debugPrint('🌐 Web: Missed prayer reminder simulated for $arabicName');
      return;
    }

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        missedPrayerChannelId,
        'تذكير بالصلوات الفائتة',
        channelDescription: 'تذكير بأداء الفريضة لمن فاتته',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        styleInformation: BigTextStyleInformation(
          'قال الله تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ [طه : 14]\nسارع بأداء صلاة $arabicName يرحمك الله، فالصلاة أحب الأعمال إلى الله.',
          contentTitle: '⏰ تذكير: هل صليت صلاة $arabicName؟',
          summaryText: 'الصلاة نور',
        ),
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: '⏰ تذكير: هل صليت صلاة $arabicName؟',
        body: 'قال تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ - سارع بأداء صلاتك',
        notificationDetails: notificationDetails,
        payload: 'missed_$prayerName',
      );

      debugPrint('✅ Missed prayer notification sent for $arabicName (ID: $id)');
    } catch (e) {
      debugPrint('❌ Error showing missed prayer notification: $e');
    }
  }

  /// Schedule Missed Prayer Notification (e.g. 15 minutes after prayer time)
  Future<void> scheduleMissedPrayerReminder({
    required int id,
    required String prayerName,
    required String arabicName,
    required DateTime prayerTime,
    int delayMinutes = 15,
  }) async {
    if (kIsWeb) return;

    try {
      final scheduledTime = prayerTime.add(Duration(minutes: delayMinutes));
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        missedPrayerChannelId,
        'تذكير بالصلوات الفائتة',
        channelDescription: 'تذكير بأداء الفريضة لمن فاتته',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        styleInformation: BigTextStyleInformation(
          'قال الله تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ [طه : 14]\nسارع بأداء صلاة $arabicName يرحمك الله، فالصلاة أحب الأعمال إلى الله.',
          contentTitle: '⏰ تذكير: هل صليت صلاة $arabicName؟',
          summaryText: 'الصلاة نور',
        ),
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: '⏰ تذكير: هل صليت صلاة $arabicName؟',
        body: 'قال تعالى: ﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ - سارع بأداء صلاتك',
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'missed_$prayerName',
      );

      debugPrint('⏰ Scheduled missed prayer reminder for $arabicName at $scheduledTime (ID: $id)');
    } catch (e) {
      debugPrint('❌ Error scheduling missed prayer reminder: $e');
    }
  }

  /// Show daily Islamic reminder (Ayah, Hadith, Dua, Dhikr)
  Future<void> showIslamicContentNotification({
    required int id,
    required String title,
    required String body,
    String? category,
  }) async {
    if (kIsWeb) return;

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        remindersChannelId,
        'التذكيرات الإيمانية اليومية',
        channelDescription: 'آيات وأدعية وأذكار يومية مباركة',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: category ?? 'رفيق المسلم',
        ),
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'content_${category ?? "reminder"}',
      );
    } catch (e) {
      debugPrint('❌ Error showing content notification: $e');
    }
  }

  // Backward-compatible method
  Future<void> showPrayerNotification({
    required String prayerName,
    required TimeOfDay prayerTime,
    required PrayerType prayerType,
  }) async {
    final arabicNames = {
      PrayerType.fajr: 'الفجر',
      PrayerType.sunrise: 'الشروق',
      PrayerType.dhuhr: 'الظهر',
      PrayerType.asr: 'العصر',
      PrayerType.maghrib: 'المغرب',
      PrayerType.isha: 'العشاء',
    };
    final ar = arabicNames[prayerType] ?? prayerName;
    await showPrayerAthanNotification(
      id: prayerType.index + 100,
      prayerName: prayerName,
      arabicName: ar,
      isFajr: prayerType == PrayerType.fajr,
    );
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification $id: $e');
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🧹 All notifications canceled');
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  @override
  void dispose() {
    _actionController.close();
    super.dispose();
  }
}