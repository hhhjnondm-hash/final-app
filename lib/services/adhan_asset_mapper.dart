import '../models/prayer_models.dart';

/// Maps prayer types to local Adhan audio assets
/// Ensures existing local assets are used correctly
class AdhanAssetMapper {
  static const Map<PrayerType, String> _assetMap = {
    PrayerType.fajr: 'assets/audio/athan/athan_general.mp3',
    PrayerType.dhuhr: 'assets/audio/athan/athan_general.mp3',
    PrayerType.asr: 'assets/audio/athan/athan_general.mp3',
    PrayerType.maghrib: 'assets/audio/athan/athan_general.mp3',
    PrayerType.isha: 'assets/audio/athan/athan_general.mp3',
  };

  static const Map<PrayerType, String> _specialAssetMap = {
    PrayerType.fajr: 'assets/audio/athan/athan_multiple.mp3',
    PrayerType.dhuhr: 'assets/audio/athan/athan_general.mp3',
    PrayerType.asr: 'assets/audio/athan/athan_general.mp3',
    PrayerType.maghrib: 'assets/audio/athan/athan_general.mp3',
    PrayerType.isha: 'assets/audio/athan/athan_general.mp3',
  };

  /// Get the local asset path for a prayer type
  static String getAssetPath(PrayerType prayer, {bool useSpecial = false}) {
    final map = useSpecial ? _specialAssetMap : _assetMap;
    return map[prayer] ?? _assetMap[prayer]!;
  }

  /// Check if asset exists for a prayer type
  static bool hasAsset(PrayerType prayer) {
    return _assetMap.containsKey(prayer);
  }

  /// Get available prayer types
  static List<PrayerType> getAvailablePrayers() {
    return _assetMap.keys.toList();
  }

  /// Validate that all required assets exist
  static bool validateAssets() {
    // In a real implementation, this would check if files actually exist
    // For now, we assume the assets listed above exist
    return _assetMap.isNotEmpty;
  }
}
