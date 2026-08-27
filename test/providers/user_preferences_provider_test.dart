import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamyat_app/providers/user_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserPreferencesProvider Tests', () {
    late UserPreferencesProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = UserPreferencesProvider();
      await provider.initialize();
    });

    test('should have default language as Arabic', () {
      expect(provider.language, equals('ar'));
    });

    test('should have default theme as dark', () {
      expect(provider.themeMode, equals('dark'));
    });

    test('should have default first launch as true', () {
      expect(provider.isFirstLaunch, isTrue);
    });

    test('should have default font size as 1.0', () {
      expect(provider.fontSize, equals(1.0));
    });

    test('should have default auto play audio as true', () {
      expect(provider.autoPlayAudio, isTrue);
    });

    test('should have default show translations as true', () {
      expect(provider.showTranslations, isTrue);
    });

    test('should have default audio volume as 1.0', () {
      expect(provider.audioVolume, equals(1.0));
    });

    test('should have default audio playback rate as 1.0', () {
      expect(provider.audioPlaybackRate, equals(1.0));
    });

    test('should set language', () async {
      await provider.setLanguage('en');
      expect(provider.language, equals('en'));
    });

    test('should set theme', () async {
      await provider.setTheme('light');
      expect(provider.themeMode, equals('light'));
    });

    test('should set first launch', () async {
      await provider.setFirstLaunch(false);
      expect(provider.isFirstLaunch, isFalse);
    });

    test('should set font size', () {
      provider.setFontSize(1.5);
      expect(provider.fontSize, equals(1.5));
    });

    test('should set auto play audio', () async {
      await provider.setAutoPlayAudio(false);
      expect(provider.autoPlayAudio, isFalse);
    });

    test('should set show translations', () {
      provider.setShowTranslations(false);
      expect(provider.showTranslations, isFalse);
    });

    test('should set audio volume', () async {
      await provider.setAudioVolume(0.5);
      expect(provider.audioVolume, equals(0.5));
    });

    test('should clamp audio volume between 0 and 1', () async {
      await provider.setAudioVolume(1.5);
      expect(provider.audioVolume, equals(1.0));

      await provider.setAudioVolume(-0.5);
      expect(provider.audioVolume, equals(0.0));
    });

    test('should set audio playback rate', () async {
      await provider.setAudioPlaybackRate(1.5);
      expect(provider.audioPlaybackRate, equals(1.5));
    });

    test('should clamp audio playback rate between 0.5 and 2.0', () async {
      await provider.setAudioPlaybackRate(3.0);
      expect(provider.audioPlaybackRate, equals(2.0));

      await provider.setAudioPlaybackRate(0.2);
      expect(provider.audioPlaybackRate, equals(0.5));
    });

    test('should reset to defaults', () async {
      // Change some values
      await provider.setLanguage('en');
      await provider.setTheme('light');
      provider.setFontSize(1.5);
      await provider.setAutoPlayAudio(false);
      provider.setShowTranslations(false);
      await provider.setAudioVolume(0.5);
      await provider.setAudioPlaybackRate(1.5);

      // Reset
      await provider.resetToDefaults();

      // Check defaults
      expect(provider.language, equals('ar'));
      expect(provider.themeMode, equals('dark'));
      expect(provider.fontSize, equals(1.0));
      expect(provider.autoPlayAudio, isTrue);
      expect(provider.showTranslations, isTrue);
      expect(provider.audioVolume, equals(1.0));
      expect(provider.audioPlaybackRate, equals(1.0));
    });

    test('should notify listeners when language changes', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setLanguage('en');
      expect(notified, isTrue);
    });

    test('should notify listeners when theme changes', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setTheme('light');
      expect(notified, isTrue);
    });

    test('should notify listeners when audio settings change', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setAudioVolume(0.5);
      expect(notified, isTrue);
    });
  });
}