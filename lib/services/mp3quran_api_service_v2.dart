import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';
import '../models/audio_models.dart';

/// Official MP3Quran API Service
/// Fetches real data from mp3quran.net API
class Mp3QuranApiServiceV2 {
  static final Mp3QuranApiServiceV2 _instance = Mp3QuranApiServiceV2._internal();
  factory Mp3QuranApiServiceV2() => _instance;
  Mp3QuranApiServiceV2._internal();

  // API Endpoints
  static const String _baseUrl = 'https://www.mp3quran.net/api/v3';
  static const String _recitersEndpoint = '$_baseUrl/reciters';
  static const String _moshafEndpoint = '$_baseUrl/moshaf';
  static const String _radioEndpoint = '$_baseUrl/radios';

  // Cache
  Map<String, ReciterIdentity> _reciterCache = {};
  Map<String, MoshafIdentity> _moshafCache = {};
  Map<String, RadioIdentity> _radioCache = {};
  DateTime? _lastFetch;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  /// Fetch all reciters from MP3Quran API
  Future<List<ReciterIdentity>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _reciterCache.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return _reciterCache.values.toList();
    }

    try {
      final response = await http.get(Uri.parse(_recitersEndpoint));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['reciters'] != null) {
          final reciters = <ReciterIdentity>[];
          
          for (var item in data['reciters']) {
            final reciter = _parseReciter(item);
            if (reciter != null) {
              reciters.add(reciter);
              _reciterCache[reciter.canonicalId] = reciter;
            }
          }
          
          _lastFetch = DateTime.now();
          debugPrint('✅ Fetched ${reciters.length} reciters from MP3Quran API');
          return reciters;
        }
      }
      
      throw Exception('Failed to fetch reciters: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching reciters: $e');
      return _reciterCache.values.toList();
    }
  }

  /// Fetch moshaf (Quran recording) details for a reciter
  Future<List<MoshafIdentity>> getMoshafForReciter(String reciterId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _moshafCache.isNotEmpty) {
      return _moshafCache.values
          .where((m) => m.reciterCanonicalId == reciterId)
          .toList();
    }

    try {
      final response = await http.get(Uri.parse('$_moshafEndpoint/$reciterId'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['moshaf'] != null) {
          final moshafs = <MoshafIdentity>[];
          
          for (var item in data['moshaf']) {
            final moshaf = _parseMoshaf(item, reciterId);
            if (moshaf != null) {
              moshafs.add(moshaf);
              _moshafCache[moshaf.moshafId] = moshaf;
            }
          }
          
          debugPrint('✅ Fetched ${moshafs.length} moshafs for reciter $reciterId');
          return moshafs;
        }
      }
      
      throw Exception('Failed to fetch moshaf: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching moshaf: $e');
      return _moshafCache.values
          .where((m) => m.reciterCanonicalId == reciterId)
          .toList();
    }
  }

  /// Fetch all radio stations from MP3Quran API
  Future<List<RadioIdentity>> getRadios({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _radioCache.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return _radioCache.values.toList();
    }

    try {
      final response = await http.get(Uri.parse(_radioEndpoint));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['radios'] != null) {
          final radios = <RadioIdentity>[];
          
          for (var item in data['radios']) {
            final radio = _parseRadio(item);
            if (radio != null) {
              radios.add(radio);
              _radioCache[radio.radioId] = radio;
            }
          }
          
          _lastFetch = DateTime.now();
          debugPrint('✅ Fetched ${radios.length} radios from MP3Quran API');
          return radios;
        }
      }
      
      throw Exception('Failed to fetch radios: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching radios: $e');
      return _radioCache.values.toList();
    }
  }

  /// Get audio URL for a specific surah from a moshaf
  String getSurahAudioUrl(MoshafIdentity moshaf, int surahNumber) {
    // MP3Quran URL pattern: {serverUrl}/{surahNumber:03d}.mp3
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    return '${moshaf.serverUrl}$paddedSurah.mp3';
  }

  /// Parse reciter from API response
  ReciterIdentity? _parseReciter(Map<String, dynamic> json) {
    try {
      final apiId = json['id']?.toString();
      if (apiId == null || apiId.isEmpty) return null;
      
      final nameArabic = json['name'] ?? '';
      final nameEnglish = json['name_en'] ?? nameArabic;
      final country = json['country'] ?? '';
      final rewayah = json['rewaya'] ?? '';
      final count = json['moshaf'] ?? 0;
      
      // Create canonical ID from API ID
      final canonicalId = 'mp3quran_$apiId';
      
      // Use a default asset key for unknown IDs
      final assetKey = _mapApiIdToAssetKey(apiId);

      return ReciterIdentity(
        canonicalId: canonicalId,
        apiId: apiId,
        localAssetKey: assetKey ?? 'afasy',
        nameArabic: nameArabic,
        nameEnglish: nameEnglish,
        country: country,
        rewayah: rewayah,
        surahCount: count,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error parsing reciter: $e');
      return null;
    }
  }

  /// Parse moshaf from API response
  MoshafIdentity? _parseMoshaf(Map<String, dynamic> json, String reciterCanonicalId) {
    try {
      final moshafId = json['id']?.toString() ?? '';
      final moshafName = json['name'] ?? '';
      final serverUrl = json['server'] ?? '';
      final moshafType = json['moshaf_type'] ?? 'murattal';
      final surahList = json['surah_list'] ?? '';
      final rewayah = json['rewaya'];
      
      // Parse surah list (comma-separated numbers)
      final availableSurahs = surahList
          .toString()
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      
      return MoshafIdentity(
        moshafId: moshafId,
        reciterCanonicalId: reciterCanonicalId,
        moshafName: moshafName,
        serverUrl: serverUrl,
        moshafType: moshafType,
        availableSurahs: availableSurahs,
        totalSurahs: availableSurahs.length,
        rewayah: rewayah,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error parsing moshaf: $e');
      return null;
    }
  }

  /// Parse radio from API response
  RadioIdentity? _parseRadio(Map<String, dynamic> json) {
    try {
      final radioId = json['id']?.toString() ?? '';
      final name = json['name'] ?? '';
      final url = json['url'] ?? '';
      final image = json['image'];
      final language = json['language'];
      final category = json['category'];
      
      return RadioIdentity(
        radioId: 'mp3quran_radio_$radioId',
        canonicalName: name,
        streamUrl: url,
        provider: 'mp3quran',
        language: language,
        category: category,
        imageUrl: image,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error parsing radio: $e');
      return null;
    }
  }

  /// Map API ID to local asset key
  String? _mapApiIdToAssetKey(String apiId) {
    // This mapping needs to be maintained for known reciters
    // For new reciters, we'll use a default
    final knownMappings = {
      '2': 'afasy',
      '3': 'abdulbaset_murattal',
      '4': 'minshawi_murattal',
      '5': 'hussary_murattal',
      '6': 'maher',
      '7': 'dosari',
      '8': 'ajmy',
      '9': 'ghamdi',
      '10': 'shuraim',
      '11': 'banna',
      '12': 'tablawi',
      '13': 'fares_abbad',
      '14': 'khaled_jileel',
      '15': 'abu_bakr_shatri',
      '16': 'abdullah_juhany',
      '17': 'salah_bukhatir',
      '18': 'muhammad_jibreel',
      '19': 'muhammad_ayyoub',
      '20': 'khaled_qahtani',
      '21': 'nabil_rifai',
      '22': 'hatem_farid',
      '23': 'bandar_baleela',
      '24': 'adel_kalbani',
      '25': 'abdulrahman_majid',
      '26': 'abdulrahman_shahat',
      '27': 'abdulilah_aoun',
      '28': 'abdulaziz_zahran',
      '29': 'abdullah_kamel',
      '30': 'adel_rayyan',
      '31': 'ahmed_nafis',
      '32': 'alfatih_zubair',
      '33': 'bisha_qadir',
      '34': 'hisham_haraz',
      '35': 'ibrahim_jarmi',
      '36': 'juman_osaimi',
      '37': 'mahmoud_rifai',
      '38': 'mansour_salmi',
      '39': 'mohammad_kareem',
      '40': 'noreen_siddiq',
      '41': 'raad_kurdi',
      '42': 'yasser_salama',
      '43': 'naser_katamy',
      '44': 'sudais',
      '45': 'abdul_rahman_aws',
    };

    return knownMappings[apiId];
  }

  /// Clear cache
  void clearCache() {
    _reciterCache.clear();
    _moshafCache.clear();
    _radioCache.clear();
    _lastFetch = null;
    debugPrint('🗑️ MP3Quran API cache cleared');
  }

  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'recitersCached': _reciterCache.length,
      'moshafsCached': _moshafCache.length,
      'radiosCached': _radioCache.length,
      'lastFetch': _lastFetch?.toIso8601String(),
      'isCacheValid': _lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheValidDuration,
    };
  }
}
