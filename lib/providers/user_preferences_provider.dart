import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class UserPreferencesProvider extends ChangeNotifier {
  static final UserPreferencesProvider _instance = UserPreferencesProvider._internal();
  factory UserPreferencesProvider() => _instance;
  UserPreferencesProvider._internal() {
    // Don't call async init in constructor
  }

  final StorageService _storage = StorageService();

  // Language
  String _language = 'ar';
  String get language => _language;

  // Theme
  String _themeMode = 'dark';
  String get themeMode => _themeMode;

  // First Launch
  bool _isFirstLaunch = true;
  bool get isFirstLaunch => _isFirstLaunch;

  // Font Size
  double _fontSize = 1.0;
  double get fontSize => _fontSize;

  // Auto Play Audio
  bool _autoPlayAudio = true;
  bool get autoPlayAudio => _autoPlayAudio;

  // Show Translations
  bool _showTranslations = true;
  bool get showTranslations => _showTranslations;

  // Audio Volume
  double _audioVolume = 1.0;
  double get audioVolume => _audioVolume;

  // Audio Playback Rate
  double _audioPlaybackRate = 1.0;
  double get audioPlaybackRate => _audioPlaybackRate;

  Future<void> _init() async {
    await _storage.init();
    _loadPreferences();
  }

  Future<void> initialize() async {
    await _init();
  }

  void _loadPreferences() {
    // Load language
    final savedLanguage = _storage.getLanguage();
    if (savedLanguage != null) {
      _language = savedLanguage;
    }

    // Load theme
    final savedTheme = _storage.getTheme();
    if (savedTheme != null) {
      _themeMode = savedTheme;
    }

    // Load first launch
    final firstLaunch = _storage.isFirstLaunch();
    if (firstLaunch != null) {
      _isFirstLaunch = firstLaunch;
    }

    // Load audio settings
    final audioSettings = _storage.getAudioSettings();
    if (audioSettings != null) {
      _audioVolume = audioSettings['volume'] as double? ?? 1.0;
      _audioPlaybackRate = audioSettings['playbackRate'] as double? ?? 1.0;
      _autoPlayAudio = audioSettings['autoPlay'] as bool? ?? true;
    }
  }

  // Language
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    await _storage.setLanguage(languageCode);
    notifyListeners();
  }

  // Theme
  Future<void> setTheme(String themeMode) async {
    _themeMode = themeMode;
    await _storage.setTheme(themeMode);
    notifyListeners();
  }

  // First Launch
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    _isFirstLaunch = isFirstLaunch;
    await _storage.setFirstLaunch(isFirstLaunch);
    notifyListeners();
  }

  // Font Size
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  // Auto Play Audio
  Future<void> setAutoPlayAudio(bool value) async {
    _autoPlayAudio = value;
    await _saveAudioSettings();
    notifyListeners();
  }

  // Show Translations
  void setShowTranslations(bool value) {
    _showTranslations = value;
    notifyListeners();
  }

  // Audio Volume
  Future<void> setAudioVolume(double volume) async {
    _audioVolume = volume.clamp(0.0, 1.0);
    await _saveAudioSettings();
    notifyListeners();
  }

  // Audio Playback Rate
  Future<void> setAudioPlaybackRate(double rate) async {
    _audioPlaybackRate = rate.clamp(0.5, 2.0);
    await _saveAudioSettings();
    notifyListeners();
  }

  Future<void> _saveAudioSettings() async {
    await _storage.saveAudioSettings(
      volume: _audioVolume,
      playbackRate: _audioPlaybackRate,
      autoPlay: _autoPlayAudio,
    );
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _language = 'ar';
    _themeMode = 'dark';
    _fontSize = 1.0;
    _autoPlayAudio = true;
    _showTranslations = true;
    _audioVolume = 1.0;
    _audioPlaybackRate = 1.0;

    await _storage.setLanguage('ar');
    await _storage.setTheme('dark');
    await _saveAudioSettings();
    
    notifyListeners();
  }
}