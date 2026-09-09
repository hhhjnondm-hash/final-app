import 'app_security_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ai_assistant_service.dart';
import 'islamic_notification_service.dart';
import 'mp3quran_api_service_v2.dart';
import 'prayer_service.dart';
import 'prayer_time_calculator.dart';
import 'global_audio_manager.dart';
import 'quran_service.dart';
import 'quran_storage_service.dart';
import 'storage_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'hive_database_service.dart';
import 'error_handler.dart';
import 'health_monitor.dart';
import 'reciter_image_registry.dart';
import 'download_integrity_verifier.dart';
import '../providers/user_preferences_provider.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  bool _isInitialized = false;
  final double _progress = 0.0;
  final String _statusText = 'جاري التحضير والتهيئة...';

  bool get isInitialized => _isInitialized;
  double get progress => _progress;
  String get statusText => _statusText;

  static Future<void> initializeServices() async {
    try {
      debugPrint('🚀 Starting AppInitializer...');

      // Step 0: Initialize Security Shield (with jailbreak detection)
      debugPrint('🛡️ Initializing App Security Shield...');
      final securityService = AppSecurityService();
      await securityService.initialize();
      final isSecure = await securityService.isDeviceSecure();
      if (!isSecure) {
        debugPrint('⚠️ Security Warning: Device may be rooted/jailbroken');
      }
      debugPrint('✅ Security Shield active');

      // Step 1: Initialize Storage Service
      debugPrint('📦 Initializing Storage Service...');
      final storageService = StorageService();
      await storageService.init();
      QuranStorageService();
      debugPrint('✅ Storage Service initialized');

      // Step 2: Initialize Hive Database
      debugPrint('🗄️ Initializing Hive Database...');
      final hiveService = HiveDatabaseService();
      await hiveService.initialize();
      debugPrint('✅ Hive Database initialized');

      // Step 3: Initialize User Preferences
      debugPrint('⚙️ Initializing User Preferences...');
      final preferencesProvider = UserPreferencesProvider();
      await preferencesProvider.initialize();
      debugPrint('✅ User Preferences initialized');

      // Step 4: Initialize Quran data cache
      debugPrint('📖 Initializing Quran Data...');
      await QuranService.loadQuranData();
      debugPrint('✅ Quran Data initialized');

      // Step 5: Initialize Prayer Times & Location Service
      debugPrint('🕌 Initializing Prayer & Location Services...');
      PrayerService();
      PrayerTimeCalculator();
      LocationService();
      debugPrint('✅ Prayer & Location Services initialized');

      // Step 6: Initialize Notification Service
      debugPrint('🔔 Initializing Notification Service...');
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('✅ Notification Service initialized');

      // Step 7: Initialize Islamic Notification Service
      debugPrint('🕌 Initializing Islamic Notification Service...');
      IslamicNotificationService();
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('✅ Islamic Notification Service initialized');

      // Step 8: Initialize AI Knowledge Base & Audio Systems
      debugPrint('🤖 Initializing AI & Audio Services...');
      AiAssistantService();
      Mp3QuranApiServiceV2();
      GlobalAudioManager();
      debugPrint('✅ AI & Audio Services initialized');

      // Step 9: Initialize Health Monitoring
      debugPrint('🔍 Initializing Health Monitoring...');
      final healthMonitor = HealthMonitor();
      healthMonitor.startMonitoring();
      debugPrint('✅ Health Monitoring initialized');

      // Step 10: Initialize Reciter Image Registry
      debugPrint('🖼️ Initializing Reciter Image Registry...');
      final imageRegistry = ReciterImageRegistry();
      await imageRegistry.validateAssets();
      debugPrint('✅ Reciter Image Registry initialized');

      // Step 11: Initialize Download Integrity Verifier
      debugPrint('🔐 Initializing Download Integrity Verifier...');
      DownloadIntegrityVerifier();
      debugPrint('✅ Download Integrity Verifier initialized');

      // Step 12: Initialize Error Handler
      debugPrint('🛡️ Initializing Error Handler...');
      ErrorHandler();
      debugPrint('✅ Error Handler initialized');

      // Step 13: Preload Prayer Data (30 days) using timesprayer.com
      debugPrint('📅 Preloading 30 days of prayer data from timesprayer.com...');
      final calculator = PrayerTimeCalculator();
      await calculator.preloadPrayerData(
        startDate: DateTime.now(),
        days: 30,
        latitude: 30.0444, // Cairo default
        longitude: 31.2357,
        calculationMethod: 5, // Egyptian General Authority
        timezone: 'Africa/Cairo',
      );
      debugPrint('✅ Prayer data preloaded');

      debugPrint('🎉 AppInitializer: All services initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error during AppInitializer: $e');
      ErrorHandler().handleError(
        e,
        type: ErrorType.unknown,
        severity: ErrorSeverity.critical,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> initialize({
    required Function(double progress, String status) onProgress,
  }) async {
    if (_isInitialized) {
      onProgress(1.0, 'مرحباً بك في رفيق');
      return;
    }

    try {
      // Step 0: Initialize Security Shield
      onProgress(0.10, 'تفعيل درع الحماية والأمان...');
      await AppSecurityService().initialize();

      // Step 1: Initialize local storage & user preferences
      onProgress(0.25, 'تحميل التفضيلات والإعدادات المحلية...');
      final storageService = StorageService();
      await storageService.init();
      QuranStorageService();

      // Step 2 & 3: Initialize Hive Database & User Preferences concurrently
      onProgress(0.40, 'تحميل قاعدة البيانات المحلية...');
      await Future.wait([
        HiveDatabaseService().initialize(),
        UserPreferencesProvider().initialize(),
      ]);

      // Step 4: Initialize Quran data cache
      onProgress(0.60, 'تحميل المصحف الشريف والبيانات القرآنية...');
      await QuranService.loadQuranData();

      // Step 5 & 6: Initialize Core Services concurrently
      onProgress(0.80, 'تجهيز الخدمات والمنظومة الإيمانية...');
      PrayerService();
      PrayerTimeCalculator();
      LocationService();
      await NotificationService().initialize();
      IslamicNotificationService();
      AiAssistantService();
      Mp3QuranApiServiceV2();
      GlobalAudioManager();

      // Step 7: Background non-blocking initializations
      onProgress(1.0, 'اكتمل التحضير بنجاح');
      _isInitialized = true;

      // Run remaining heavy background jobs asynchronously without delaying app launch
      unawaited(_runBackgroundInitializations());
    } catch (e, stackTrace) {
      debugPrint('Graceful app initialization fallback: $e');
      ErrorHandler().handleError(
        e,
        type: ErrorType.unknown,
        severity: ErrorSeverity.critical,
        stackTrace: stackTrace,
      );
      onProgress(1.0, 'اكتمل التحضير بنجاح');
      _isInitialized = true;
    }
  }

  static Future<void> _runBackgroundInitializations() async {
    try {
      // 1. Synchronize Dynamic Launcher Icon based on Device Local Time
      // 6:00 AM - 5:59 PM: lightapp.png (Day)
      // 6:00 PM - 5:59 AM: darkapp.png (Night)
      await syncDynamicLauncherIconByTime();

      // 2. Health monitor & Integrity
      HealthMonitor().startMonitoring();
      DownloadIntegrityVerifier();
      ErrorHandler();
      
      // 3. Async preload of prayer times for offline cache
      final calculator = PrayerTimeCalculator();
      await calculator.preloadPrayerData(
        startDate: DateTime.now(),
        days: 30,
        latitude: 30.0444, // Cairo default
        longitude: 31.2357,
        calculationMethod: 5, // Egyptian General Authority
        timezone: 'Africa/Cairo',
      );
    } catch (e) {
      debugPrint('Background init non-fatal error: $e');
    }
  }

  /// Communicates with Android MainActivity to switch the active launcher icon alias
  static Future<String?> syncDynamicLauncherIconByTime() async {
    if (kIsWeb) return null;
    try {
      const platform = MethodChannel('com.islamyat.islamyat_app/dynamic_icon');
      final currentHour = DateTime.now().hour;
      final mode = await platform.invokeMethod<String>('updateIconByTime', {'hour': currentHour});
      debugPrint('🎨 Launcher Icon synced for hour $currentHour -> Mode: $mode');
      return mode;
    } catch (e) {
      debugPrint('Dynamic icon sync non-fatal error: $e');
      return null;
    }
  }
}
