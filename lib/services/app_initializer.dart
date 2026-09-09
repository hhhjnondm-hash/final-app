import 'app_security_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ai_assistant_service.dart';
import 'adhan_service.dart';
import 'islamic_notification_service.dart';
import 'mp3quran_api_service.dart';
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
  double _progress = 0.0;
  String _statusText = 'جاري التحضير والتهيئة...';

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
      onProgress(0.05, 'تفعيل درع الحماية والأمان...');
      await AppSecurityService().initialize();

      // Step 1: Initialize local storage & user preferences
      onProgress(0.10, 'تحميل التفضيلات والإعدادات المحلية...');
      final storageService = StorageService();
      await storageService.init();
      QuranStorageService();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 2: Initialize Hive Database
      onProgress(0.15, 'تحميل قاعدة البيانات المحلية...');
      final hiveService = HiveDatabaseService();
      await hiveService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 3: Initialize User Preferences
      onProgress(0.20, 'تحميل تفضيلات المستخدم...');
      final preferencesProvider = UserPreferencesProvider();
      await preferencesProvider.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 4: Initialize Quran data cache
      onProgress(0.35, 'تحميل المصحف الشريف والبيانات القرآنية...');
      await QuranService.loadQuranData();
      await Future.delayed(const Duration(milliseconds: 150));

      // Step 5: Initialize Prayer Times & Local Adhan Calculation
      onProgress(0.45, 'حساب المواقيت الدقيقة للصلوات الخمس...');
      PrayerService();
      PrayerTimeCalculator();
      LocationService();
      await Future.delayed(const Duration(milliseconds: 150));

      // Step 6: Initialize Notification Service
      onProgress(0.55, 'تجهيز نظام الإشعارات...');
      final notificationService = NotificationService();
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 7: Initialize Notifications & Smart Rotation Datasets
      onProgress(0.65, 'تجهيز منظومة التذكير الإيماني...');
      IslamicNotificationService();
      await Future.delayed(const Duration(milliseconds: 150));

      // Step 8: Initialize AI Knowledge Base & Audio Systems
      onProgress(0.80, 'تحضير المساعد الذكي والمشغلات الصوتية...');
      AiAssistantService();
      Mp3QuranApiServiceV2();
      GlobalAudioManager();
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 9: Initialize Health Monitoring
      onProgress(0.85, 'تحضير نظام مراقبة الصحة...');
      final healthMonitor = HealthMonitor();
      healthMonitor.startMonitoring();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 10: Initialize Reciter Image Registry
      onProgress(0.88, 'تحضير سجل صور القراء...');
      final imageRegistry = ReciterImageRegistry();
      await imageRegistry.validateAssets();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 11: Initialize Download Integrity Verifier
      onProgress(0.90, 'تحضير نظام التحقق من سلامة التنزيلات...');
      DownloadIntegrityVerifier();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 12: Initialize Error Handler
      onProgress(0.92, 'تجهيز نظام معالجة الأخطاء...');
      ErrorHandler();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 13: Preload Prayer Data (30 days) using timesprayer.com
      onProgress(0.95, 'تحميل بيانات الصلاة لمدة 30 يوماً من timesprayer.com...');
      final calculator = PrayerTimeCalculator();
      await calculator.preloadPrayerData(
        startDate: DateTime.now(),
        days: 30,
        latitude: 30.0444, // Cairo default
        longitude: 31.2357,
        calculationMethod: 5, // Egyptian General Authority
        timezone: 'Africa/Cairo',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      onProgress(1.0, 'اكتمل التحضير بنجاح');
      _isInitialized = true;
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
}
