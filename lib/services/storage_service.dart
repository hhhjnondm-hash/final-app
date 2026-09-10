import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_security_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Ensure preferences are initialized
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== SIMPLE DATA STORAGE ====================
  
  Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  String? getString(String key) {
    return prefs.getString(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return prefs.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    return await prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return prefs.getDouble(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return prefs.getBool(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  // ==================== JSON OBJECT STORAGE ====================
  
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== LOCATION STORAGE (SECURE) ====================
  
  static const String _locationKey = 'user_location';
  
  Future<bool> saveLocation({
    required String cityName,
    required String countryName,
    required double latitude,
    required double longitude,
    required double qiblaAngle,
  }) async {
    final locationData = jsonEncode({
      'cityName': cityName,
      'countryName': countryName,
      'latitude': latitude,
      'longitude': longitude,
      'qiblaAngle': qiblaAngle,
    });
    return await AppSecurityService.saveSecureString(_locationKey, locationData);
  }

  Future<Map<String, dynamic>?> getLocation() async {
    try {
      final locationData = await AppSecurityService.getSecureString(_locationKey);
      if (locationData == null) return null;
      return jsonDecode(locationData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Storage: Secure location read error - $e');
      return getJson(_locationKey);
    }
  }

  // ==================== NOTIFICATION SETTINGS STORAGE (SECURE) ====================
  
  static const String _notificationSettingsKey = 'notification_settings';
  
  Future<bool> saveNotificationSettings(Map<String, dynamic> settings) async {
    final settingsData = jsonEncode(settings);
    return await AppSecurityService.saveSecureString(_notificationSettingsKey, settingsData);
  }

  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final settingsData = await AppSecurityService.getSecureString(_notificationSettingsKey);
      if (settingsData == null) return null;
      return jsonDecode(settingsData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Storage: Secure notification settings read error - $e');
      return getJson(_notificationSettingsKey);
    }
  }

  // ==================== USER PREFERENCES STORAGE ====================
  
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _firstLaunchKey = 'first_launch';
  
  Future<bool> setLanguage(String languageCode) async {
    return await setString(_languageKey, languageCode);
  }

  String? getLanguage() {
    return getString(_languageKey);
  }

  Future<bool> setTheme(String themeMode) async {
    return await setString(_themeKey, themeMode);
  }

  String? getTheme() {
    return getString(_themeKey);
  }

  Future<bool> setFirstLaunch(bool isFirstLaunch) async {
    return await setBool(_firstLaunchKey, isFirstLaunch);
  }

  bool? isFirstLaunch() {
    return getBool(_firstLaunchKey);
  }

  // ==================== FAVORITES STORAGE (SECURE) ====================
  
  static const String _favoritesKey = 'user_favorites';
  
  Future<bool> addFavorite(String itemId, String itemType) async {
    final favorites = await getFavorites();
    final newFavorites = [...favorites, {'id': itemId, 'type': itemType}];
    final favoritesData = jsonEncode({'items': newFavorites});
    return await AppSecurityService.saveSecureString(_favoritesKey, favoritesData);
  }

  Future<bool> removeFavorite(String itemId) async {
    final favorites = await getFavorites();
    final newFavorites = favorites.where((item) => item['id'] != itemId).toList();
    final favoritesData = jsonEncode({'items': newFavorites});
    return await AppSecurityService.saveSecureString(_favoritesKey, favoritesData);
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final favoritesData = await AppSecurityService.getSecureString(_favoritesKey);
      if (favoritesData == null) return [];
      final data = jsonDecode(favoritesData) as Map<String, dynamic>;
      return (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Storage: Secure favorites read error - $e');
      final data = getJson(_favoritesKey);
      if (data == null) return [];
      try {
        return (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (e2) {
        return [];
      }
    }
  }

  Future<bool> isFavorite(String itemId) async {
    final favorites = await getFavorites();
    return favorites.any((item) => item['id'] == itemId);
  }

  // ==================== PRAYER SETTINGS STORAGE ====================
  
  static const String _prayerAdjustmentsKey = 'prayer_adjustments';
  
  Future<bool> savePrayerAdjustments(Map<String, int> adjustments) async {
    return await setJson(_prayerAdjustmentsKey, adjustments);
  }

  Map<String, int>? getPrayerAdjustments() {
    final data = getJson(_prayerAdjustmentsKey);
    if (data == null) return null;
    try {
      return data.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return null;
    }
  }

  // ==================== CLEAR DATA ====================
  
  Future<bool> clearKey(String key) async {
    return await prefs.remove(key);
  }

  Future<bool> clearAll() async {
    return await prefs.clear();
  }

  // ==================== AUDIO SETTINGS STORAGE (SECURE) ====================
  
  static const String _audioSettingsKey = 'audio_settings';
  
  Future<bool> saveAudioSettings({
    required double volume,
    required double playbackRate,
    required bool autoPlay,
  }) async {
    final audioData = jsonEncode({
      'volume': volume,
      'playbackRate': playbackRate,
      'autoPlay': autoPlay,
    });
    return await AppSecurityService.saveSecureString(_audioSettingsKey, audioData);
  }

  Future<Map<String, dynamic>?> getAudioSettings() async {
    try {
      final audioData = await AppSecurityService.getSecureString(_audioSettingsKey);
      if (audioData == null) return null;
      return jsonDecode(audioData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Storage: Secure audio settings read error - $e');
      return getJson(_audioSettingsKey);
    }
  }

  // ==================== LAST PLAYED STORAGE ====================
  
  static const String _lastPlayedKey = 'last_played';
  
  Future<bool> saveLastPlayed({
    required String type, // 'quran', 'radio', 'azkar'
    required String itemId,
    required String itemName,
    required int position,
  }) async {
    return await setJson(_lastPlayedKey, {
      'type': type,
      'itemId': itemId,
      'itemName': itemName,
      'position': position,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getLastPlayed() {
    return getJson(_lastPlayedKey);
  }

  // ==================== PRAYER CACHE & AUTO CLEANER STORAGE ====================
  
  static const String _prayerCachePrefix = 'prayer_cache_';
  static const String _lastCacheCleanKey = 'last_cache_clean_timestamp';
  
  Future<bool> savePrayerCache(String dateKey, Map<String, dynamic> prayerData) async {
    return await setJson('$_prayerCachePrefix$dateKey', prayerData);
  }

  Map<String, dynamic>? getPrayerCache(String dateKey) {
    return getJson('$_prayerCachePrefix$dateKey');
  }

  Future<bool> removePrayerCache(String dateKey) async {
    return await clearKey('$_prayerCachePrefix$dateKey');
  }

  Future<bool> clearPrayerCache() async {
    final keys = getPrayerCacheKeys();
    for (final key in keys) {
      await clearKey('$_prayerCachePrefix$key');
    }
    return true;
  }

  List<String> getPrayerCacheKeys() {
    final allKeys = prefs.getKeys();
    return allKeys
        .where((key) => key.startsWith(_prayerCachePrefix))
        .map((key) => key.substring(_prayerCachePrefix.length))
        .toList();
  }

  /// System Cache Cleaner: Automatically purges prayer & temporary cache older than 30 days
  Future<int> autoCleanOldCache() async {
    int deletedCount = 0;
    try {
      final now = DateTime.now();
      final lastCleanStr = getString(_lastCacheCleanKey);
      
      // Run deep clean if never run or last clean was more than 1 day ago
      if (lastCleanStr != null) {
        final lastClean = DateTime.parse(lastCleanStr);
        if (now.difference(lastClean).inHours < 24) {
          return 0; // Already cleaned today
        }
      }

      final thirtyDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      final keys = getPrayerCacheKeys();

      for (final key in keys) {
        try {
          final parts = key.split('-');
          if (parts.length == 3) {
            final cacheDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            // If cache date is older than 30 days or is in the past before today
            if (cacheDate.isBefore(thirtyDaysAgo) || cacheDate.isBefore(DateTime(now.year, now.month, now.day))) {
              await removePrayerCache(key);
              deletedCount++;
            }
          }
        } catch (_) {}
      }

      await setString(_lastCacheCleanKey, now.toIso8601String());
      debugPrint('🧹 Cache Cleaner: Purged $deletedCount expired cache records');
    } catch (e) {
      debugPrint('⚠️ Error in autoCleanOldCache: $e');
    }
    return deletedCount;
  }
}