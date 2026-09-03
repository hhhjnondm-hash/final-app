import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';
import '../models/radio_models.dart';
import '../services/radio_api_service.dart';

/// Adapter to convert canonical RadioIdentity to RadioStation
/// Bridges between new API layer and existing UI models
class RadioAdapter {
  static final RadioApiService _apiService = RadioApiService();

  /// Convert RadioIdentity to RadioStation
  static RadioStation toRadioStation(RadioIdentity identity) {
    return RadioStation(
      id: identity.radioId,
      name: identity.canonicalName,
      origin: identity.provider,
      description: identity.category ?? 'إذاعة إسلامية',
      streamUrl: identity.streamUrl,
      category: RadioCategory.all, // Default category
      listenersCount: 'مستمعين',
      currentProgram: identity.category ?? 'برامج إيمانية',
      quality: 'جودة عالية',
      photoUrl: identity.imageUrl,
      isLive: true,
    );
  }

  /// Convert list of RadioIdentity to RadioStation
  static List<RadioStation> toRadioStations(List<RadioIdentity> identities) {
    return identities.map((id) => toRadioStation(id)).toList();
  }

  /// Fetch radio stations from API and convert to stations
  static Future<List<RadioStation>> fetchRadioStations({bool forceRefresh = false}) async {
    try {
      final identities = await _apiService.getRadios(forceRefresh: forceRefresh);
      return toRadioStations(identities);
    } catch (e) {
      debugPrint('Error fetching radios from API: $e');
      return [];
    }
  }

  /// Test if a radio stream is accessible
  static Future<bool> testRadioStream(String streamUrl) async {
    return await _apiService.testRadioStream(streamUrl);
  }

  /// Get a specific radio station by ID 
  static RadioStation? getRadioById(String radioId) {
    final identity = _apiService.getRadioById(radioId);
    if (identity != null) {
      return toRadioStation(identity);
    }
    return null;
  }
}
