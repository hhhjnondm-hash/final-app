import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamyat_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
    });

    test('should save and retrieve string', () async {
      const testKey = 'test_key';
      const testValue = 'test_value';

      await storageService.setString(testKey, testValue);
      final retrievedValue = storageService.getString(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should save and retrieve integer', () async {
      const testKey = 'test_int_key';
      const testValue = 42;

      await storageService.setInt(testKey, testValue);
      final retrievedValue = storageService.getInt(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should save and retrieve boolean', () async {
      const testKey = 'test_bool_key';
      const testValue = true;

      await storageService.setBool(testKey, testValue);
      final retrievedValue = storageService.getBool(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should save and retrieve JSON object', () async {
      const testKey = 'test_json_key';
      final testValue = {
        'name': 'Test',
        'age': 25,
        'active': true,
      };

      await storageService.setJson(testKey, testValue);
      final retrievedValue = storageService.getJson(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should save and retrieve location data', () async {
      await storageService.saveLocation(
        cityName: 'القاهرة',
        countryName: 'مصر',
        latitude: 30.0444,
        longitude: 31.2357,
        qiblaAngle: 136.0,
      );

      final location = await storageService.getLocation();

      expect(location, isNotNull);
      expect(location!['cityName'], equals('القاهرة'));
      expect(location['countryName'], equals('مصر'));
      expect(location['latitude'], equals(30.0444));
      expect(location['longitude'], equals(31.2357));
      expect(location['qiblaAngle'], equals(136.0));
    });

    test('should save and retrieve notification settings', () async {
      final testSettings = {
        'enabled': true,
        'fajr': 'athan',
        'dhuhr': 'silent',
      };

      await storageService.saveNotificationSettings(testSettings);
      final retrievedSettings = await storageService.getNotificationSettings();

      expect(retrievedSettings, equals(testSettings));
    });

    test('should save and retrieve language preference', () async {
      const testLanguage = 'ar';

      await storageService.setLanguage(testLanguage);
      final retrievedLanguage = storageService.getLanguage();

      expect(retrievedLanguage, equals(testLanguage));
    });

    test('should save and retrieve theme preference', () async {
      const testTheme = 'dark';

      await storageService.setTheme(testTheme);
      final retrievedTheme = storageService.getTheme();

      expect(retrievedTheme, equals(testTheme));
    });

    test('should manage favorites', () async {
      const testItemId = 'item_1';
      const testItemType = 'surah';

      await storageService.addFavorite(testItemId, testItemType);
      final isFavorite = await storageService.isFavorite(testItemId);

      expect(isFavorite, isTrue);

      await storageService.removeFavorite(testItemId);
      final isNotFavorite = await storageService.isFavorite(testItemId);

      expect(isNotFavorite, isFalse);
    });

    test('should save and retrieve prayer adjustments', () async {
      final testAdjustments = {
        'fajr': 5,
        'dhuhr': -3,
        'asr': 0,
      };

      await storageService.savePrayerAdjustments(testAdjustments);
      final retrievedAdjustments = storageService.getPrayerAdjustments();

      expect(retrievedAdjustments, equals(testAdjustments));
    });

    test('should save and retrieve audio settings', () async {
      await storageService.saveAudioSettings(
        volume: 0.8,
        playbackRate: 1.0,
        autoPlay: true,
      );

      final audioSettings = await storageService.getAudioSettings();

      expect(audioSettings, isNotNull);
      expect(audioSettings!['volume'], equals(0.8));
      expect(audioSettings['playbackRate'], equals(1.0));
      expect(audioSettings['autoPlay'], equals(true));
    });

    test('should clear specific key', () async {
      const testKey = 'test_clear_key';
      const testValue = 'test_value';

      await storageService.setString(testKey, testValue);
      await storageService.clearKey(testKey);
      final retrievedValue = storageService.getString(testKey);

      expect(retrievedValue, isNull);
    });

    test('should clear all data', () async {
      await storageService.setString('key1', 'value1');
      await storageService.setInt('key2', 42);
      await storageService.setBool('key3', true);

      await storageService.clearAll();

      expect(storageService.getString('key1'), isNull);
      expect(storageService.getInt('key2'), isNull);
      expect(storageService.getBool('key3'), isNull);
    });
  });
}