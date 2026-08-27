import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // ==================== LOCATION STORAGE ====================
  
  static const String _locationKey = 'user_location';
  
  Future<bool> saveLocation({
    required String cityName,
    required String countryName,
    required double latitude,
    required double longitude,
    required double qiblaAngle,
  }) async {
    return await setJson(_locationKey, {
      'cityName': cityName,
      'countryName': countryName,
      'latitude': latitude,
      'longitude': longitude,
      'qiblaAngle': qiblaAngle,
    });
  }

  Map<String, dynamic>? getLocation() {
    return getJson(_locationKey);
  }

  // ==================== NOTIFICATION SETTINGS STORAGE ====================
  
  static const String _notificationSettingsKey = 'notification_settings';
  
  Future<bool> saveNotificationSettings(Map<String, dynamic> settings) async {
    return await setJson(_notificationSettingsKey, settings);
  }

  Map<String, dynamic>? getNotificationSettings() {
    return getJson(_notificationSettingsKey);
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

  // ==================== FAVORITES STORAGE ====================
  
  static const String _favoritesKey = 'user_favorites';
  
  Future<bool> addFavorite(String itemId, String itemType) async {
    final favorites = getFavorites();
    final newFavorites = [...favorites, {'id': itemId, 'type': itemType}];
    return await setJson(_favoritesKey, {'items': newFavorites});
  }

  Future<bool> removeFavorite(String itemId) async {
    final favorites = getFavorites();
    final newFavorites = favorites.where((item) => item['id'] != itemId).toList();
    return await setJson(_favoritesKey, {'items': newFavorites});
  }

  List<Map<String, dynamic>> getFavorites() {
    final data = getJson(_favoritesKey);
    if (data == null) return [];
    try {
      return (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  bool isFavorite(String itemId) {
    final favorites = getFavorites();
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

  // ==================== AUDIO SETTINGS STORAGE ====================
  
  static const String _audioSettingsKey = 'audio_settings';
  
  Future<bool> saveAudioSettings({
    required double volume,
    required double playbackRate,
    required bool autoPlay,
  }) async {
    return await setJson(_audioSettingsKey, {
      'volume': volume,
      'playbackRate': playbackRate,
      'autoPlay': autoPlay,
    });
  }

  Map<String, dynamic>? getAudioSettings() {
    return getJson(_audioSettingsKey);
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
}