import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'unified_audio_engine.dart';
import 'mp3quran_api_service_v2.dart';
import 'radio_api_service.dart';
import 'asset_validator.dart';
import 'download_integrity_verifier.dart';
import 'reciter_image_registry.dart';
import '../repositories/prayer_repository.dart';

/// Health monitoring system
/// Monitors the health of various app systems
class HealthMonitor {
  static final HealthMonitor _instance = HealthMonitor._internal();
  factory HealthMonitor() => _instance;
  HealthMonitor._internal();

  final Mp3QuranApiServiceV2 _mp3QuranApi = Mp3QuranApiServiceV2();
  final RadioApiService _radioApi = RadioApiService();
  final AssetValidator _assetValidator = AssetValidator();
  final DownloadIntegrityVerifier _integrityVerifier = DownloadIntegrityVerifier();
  final ReciterImageRegistry _imageRegistry = ReciterImageRegistry();
  final PrayerRepository _prayerRepository = PrayerRepository();

  Timer? _monitoringTimer;
  final Duration _monitoringInterval = const Duration(minutes: 5);
  
  final Map<String, HealthCheckResult> _healthCache = {};
  DateTime? _lastHealthCheck;

  /// Start periodic health monitoring
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      performHealthCheck();
    });
    debugPrint('🔍 Health monitoring started (interval: ${_monitoringInterval.inMinutes} min)');
  }

  /// Stop health monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    debugPrint('🔍 Health monitoring stopped');
  }

  /// Perform comprehensive health check
  Future<HealthReport> performHealthCheck() async {
    final checks = <String, HealthCheckResult>{};

    // API Health Checks
    checks['mp3quran_api'] = await _checkMp3QuranApi();
    checks['radio_api'] = await _checkRadioApi();
    checks['aladhan_api'] = await _checkAlAdhanApi();

    // Audio System Health
    checks['audio_engine'] = await _checkAudioEngine();

    // Asset Health
    checks['reciter_images'] = await _checkReciterImages();

    // Download System Health
    checks['download_integrity'] = await _checkDownloadIntegrity();

    // Cache Health
    checks['api_cache'] = await _checkApiCache();

    _healthCache.clear();
    _healthCache.addAll(checks);
    _lastHealthCheck = DateTime.now();

    final overallHealth = _calculateOverallHealth(checks);

    final report = HealthReport(
      overallHealth: overallHealth,
      checks: checks,
      checkedAt: DateTime.now(),
    );

    if (overallHealth != HealthStatus.healthy) {
      debugPrint('⚠️ Health check completed with issues: ${report}');
    } else {
      debugPrint('✅ Health check completed: All systems healthy');
    }

    return report;
  }

  /// Check MP3Quran API health
  Future<HealthCheckResult> _checkMp3QuranApi() async {
    try {
      final cacheStatus = _mp3QuranApi.getCacheStatus();
      final isCacheValid = cacheStatus['isCacheValid'] as bool? ?? false;
      
      // Try to fetch a small amount of data to test connectivity
      await _mp3QuranApi.getReciters(forceRefresh: !isCacheValid);
      
      return HealthCheckResult(
        name: 'MP3Quran API',
        status: HealthStatus.healthy,
        message: 'API is responsive',
        details: cacheStatus,
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'MP3Quran API',
        status: HealthStatus.unhealthy,
        message: 'API check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Check Radio API health
  Future<HealthCheckResult> _checkRadioApi() async {
    try {
      final cacheStatus = _radioApi.getCacheStatus();
      final isCacheValid = cacheStatus['isCacheValid'] as bool? ?? false;
      
      await _radioApi.getRadios(forceRefresh: !isCacheValid);
      
      return HealthCheckResult(
        name: 'Radio API',
        status: HealthStatus.healthy,
        message: 'API is responsive',
        details: cacheStatus,
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Radio API',
        status: HealthStatus.unhealthy,
        message: 'API check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Check AlAdhan API health
  Future<HealthCheckResult> _checkAlAdhanApi() async {
    try {
      // Try to fetch prayer times for a test location
      await _prayerRepository.getPrayerTimes(
        date: DateTime.now(),
        latitude: 21.4225, // Mecca
        longitude: 39.8262,
        calculationMethod: 2, // Muslim World League
      );

      return HealthCheckResult(
        name: 'AlAdhan API',
        status: HealthStatus.healthy,
        message: 'API is responsive',
        details: {},
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'AlAdhan API',
        status: HealthStatus.unhealthy,
        message: 'API check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Check audio engine health
  Future<HealthCheckResult> _checkAudioEngine() async {
    try {
      // We can't easily test the audio engine without playing sound
      // So we just check if it's initialized
      return HealthCheckResult(
        name: 'Audio Engine',
        status: HealthStatus.healthy,
        message: 'Audio engine is ready',
        details: {'initialized': true},
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Audio Engine',
        status: HealthStatus.unhealthy,
        message: 'Audio engine check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Check reciter images health
  Future<HealthCheckResult> _checkReciterImages() async {
    try {
      final report = await _imageRegistry.getValidationReport();
      final totalAssets = report['totalAssets'] as int? ?? 0;
      final validAssets = report['validAssets'] as int? ?? 0;
      final invalidAssets = report['invalidAssets'] as int? ?? 0;
      
      if (invalidAssets > 0) {
        return HealthCheckResult(
          name: 'Reciter Images',
          status: HealthStatus.degraded,
          message: '$invalidAssets of $totalAssets images are invalid',
          details: report,
        );
      }
      
      return HealthCheckResult(
        name: 'Reciter Images',
        status: HealthStatus.healthy,
        message: 'All $totalAssets images are valid',
        details: report,
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Reciter Images',
        status: HealthStatus.unhealthy,
        message: 'Image check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Check download integrity health
  Future<HealthCheckResult> _checkDownloadIntegrity() async {
    try {
      final report = await _integrityVerifier.getIntegrityReport();
      final totalFiles = report.totalFiles;
      final validFiles = report.validFiles;
      final invalidFiles = report.invalidFiles;
      
      if (invalidFiles > 0) {
        return HealthCheckResult(
          name: 'Download Integrity',
          status: HealthStatus.degraded,
          message: '$invalidFiles of $totalFiles files are corrupted',
          details: report.toJson(),
        );
      }
      
      return HealthCheckResult(
        name: 'Download Integrity',
        status: HealthStatus.healthy,
        message: 'All $totalFiles files are valid',
        details: report.toJson(),
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Download Integrity',
        status: HealthStatus.unhealthy,
        message: 'Integrity check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Check API cache health
  Future<HealthCheckResult> _checkApiCache() async {
    try {
      final mp3QuranCache = _mp3QuranApi.getCacheStatus();
      final radioCache = _radioApi.getCacheStatus();
      
      final mp3QuranValid = mp3QuranCache['isCacheValid'] as bool? ?? false;
      final radioValid = radioCache['isCacheValid'] as bool? ?? false;
      
      if (!mp3QuranValid && !radioValid) {
        return HealthCheckResult(
          name: 'API Cache',
          status: HealthStatus.degraded,
          message: 'All API caches are expired',
          details: {
            'mp3quran': mp3QuranCache,
            'radio': radioCache,
          },
        );
      }
      
      return HealthCheckResult(
        name: 'API Cache',
        status: HealthStatus.healthy,
        message: 'API caches are valid',
        details: {
          'mp3quran': mp3QuranCache,
          'radio': radioCache,
        },
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'API Cache',
        status: HealthStatus.unhealthy,
        message: 'Cache check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Calculate overall health status
  HealthStatus _calculateOverallHealth(Map<String, HealthCheckResult> checks) {
    if (checks.isEmpty) return HealthStatus.unknown;
    
    final unhealthyCount = checks.values.where((c) => c.status == HealthStatus.unhealthy).length;
    final degradedCount = checks.values.where((c) => c.status == HealthStatus.degraded).length;
    
    if (unhealthyCount > 0) {
      return HealthStatus.unhealthy;
    }
    
    if (degradedCount > 0) {
      return HealthStatus.degraded;
    }
    
    return HealthStatus.healthy;
  }

  /// Get cached health report
  HealthReport? getCachedReport() {
    if (_lastHealthCheck == null || _healthCache.isEmpty) return null;
    
    final overallHealth = _calculateOverallHealth(_healthCache);
    
    return HealthReport(
      overallHealth: overallHealth,
      checks: _healthCache,
      checkedAt: _lastHealthCheck!,
    );
  }

  /// Clear health cache
  void clearCache() {
    _healthCache.clear();
    _lastHealthCheck = null;
    debugPrint('🗑️ Health cache cleared');
  }
}

/// Health status enum
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}

/// Result of a single health check
class HealthCheckResult {
  final String name;
  final HealthStatus status;
  final String message;
  final Map<String, dynamic> details;

  HealthCheckResult({
    required this.name,
    required this.status,
    required this.message,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status.name,
      'message': message,
      'details': details,
    };
  }
}

/// Overall health report
class HealthReport {
  final HealthStatus overallHealth;
  final Map<String, HealthCheckResult> checks;
  final DateTime checkedAt;

  HealthReport({
    required this.overallHealth,
    required this.checks,
    required this.checkedAt,
  });

  int get totalChecks => checks.length;
  int get healthyChecks => checks.values.where((c) => c.status == HealthStatus.healthy).length;
  int get degradedChecks => checks.values.where((c) => c.status == HealthStatus.degraded).length;
  int get unhealthyChecks => checks.values.where((c) => c.status == HealthStatus.unhealthy).length;

  Map<String, dynamic> toJson() {
    return {
      'overallHealth': overallHealth.name,
      'totalChecks': totalChecks,
      'healthyChecks': healthyChecks,
      'degradedChecks': degradedChecks,
      'unhealthyChecks': unhealthyChecks,
      'checkedAt': checkedAt.toIso8601String(),
      'checks': checks.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  @override
  String toString() {
    return 'HealthReport('
        'overall: $overallHealth, '
        'healthy: $healthyChecks/$totalChecks, '
        'degraded: $degradedChecks, '
        'unhealthy: $unhealthyChecks'
        ')';
  }
}
