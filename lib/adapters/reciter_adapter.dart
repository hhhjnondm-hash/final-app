import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';
import '../models/audio_models.dart';
import '../services/reciter_image_registry.dart';
import '../services/mp3quran_api_service_v2.dart';

/// Adapter to convert canonical ReciterIdentity to ReciterProfile
/// Bridges between new API layer and existing UI models
class ReciterAdapter {
  static final ReciterImageRegistry _imageRegistry = ReciterImageRegistry();
  static final Mp3QuranApiServiceV2 _apiService = Mp3QuranApiServiceV2();

  /// Convert ReciterIdentity to ReciterProfile
  static ReciterProfile toReciterProfile(ReciterIdentity identity) {
    // Determine category based on surah count and popularity
    final category = _determineCategory(identity);
    
    // Get the image path from registry
    final imagePath = _imageRegistry.lookupPath(identity.localAssetKey) ?? 
                      _imageRegistry.lookupPath(identity.canonicalId) ?? 
                      _imageRegistry.lookupPath(identity.apiId ?? '') ??
                      'assets/reciters/shaikh-Mishari-Al-afasi.webP';
    
    return ReciterProfile(
      id: identity.canonicalId,
      nameArabic: identity.nameArabic,
      nameEnglish: identity.nameEnglish,
      country: identity.country,
      style: identity.rewayah,
      photoUrl: imagePath,
      surahCount: identity.surahCount,
      category: category,
      serverUrl: identity.serverUrl ?? '',
    );
  }

  /// Convert list of ReciterIdentity to ReciterProfile
  static List<ReciterProfile> toReciterProfiles(List<ReciterIdentity> identities) {
    return identities.map((id) => toReciterProfile(id)).toList();
  }

  /// Determine reciter category based on heuristics
  static ReciterCategory _determineCategory(ReciterIdentity identity) {
    // Popular reciters with full Quran
    if (identity.surahCount == 114) {
      final popularIds = ['mp3quran_2', 'mp3quran_3', 'mp3quran_4', 'mp3quran_5'];
      if (popularIds.contains(identity.canonicalId)) {
        return ReciterCategory.popular;
      }
      return ReciterCategory.murattal;
    }
    
    // Newer reciters
    return ReciterCategory.youth;
  }

  /// Fetch reciters from API and convert to profiles
  static Future<List<ReciterProfile>> fetchReciterProfiles({bool forceRefresh = false}) async {
    try {
      final identities = await _apiService.getReciters(forceRefresh: forceRefresh);
      return toReciterProfiles(identities);
    } catch (e) {
      // Fallback to local data if API fails
      debugPrint('Error fetching reciters from API: $e');
      return [];
    }
  }

  /// Fetch moshaf details for a reciter
  static Future<List<MoshafIdentity>> fetchMoshafForReciter(String reciterId) async {
    return await _apiService.getMoshafForReciter(reciterId);
  }

  /// Get audio URL for a surah
  static String getSurahAudioUrl(MoshafIdentity moshaf, int surahNumber) {
    return _apiService.getSurahAudioUrl(moshaf, surahNumber);
  }
}
