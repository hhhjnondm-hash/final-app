import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';

/// Radio API Service
/// Fetches radio stations from MP3Quran Radio API
class RadioApiService {
  static final RadioApiService _instance = RadioApiService._internal();
  factory RadioApiService() => _instance;
  RadioApiService._internal();

  // API Endpoints
  static const String _baseUrl = 'https://www.mp3quran.net/api/v3';
  static const String _radioEndpoint = '$_baseUrl/radios';

  // Cache
  Map<String, RadioIdentity> _radioCache = {};
  DateTime? _lastFetch;
  static const Duration _cacheValidDuration = Duration(hours: 6);

  /// Fetch all radio stations
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
          debugPrint('✅ Fetched ${radios.length} radio stations');
          return radios;
        }
      }
      
      throw Exception('Failed to fetch radios: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching radios: $e');
      // Return cached data if available
      return _radioCache.values.toList();
    }
  }

  /// Get a specific radio station by ID
  RadioIdentity? getRadioById(String radioId) {
    return _radioCache[radioId];
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
        radioId: 'radio_$radioId',
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

  /// Test if a radio stream is accessible
  Future<bool> testRadioStream(String streamUrl) async {
    try {
      final request = http.Request('HEAD', Uri.parse(streamUrl));
      final response = await http.Client().send(request);
      
      if (response.statusCode >= 200 && response.statusCode < 400) {
        debugPrint('✅ Radio stream accessible: $streamUrl');
        return true;
      }
      
      debugPrint('❌ Radio stream not accessible: $streamUrl (${response.statusCode})');
      return false;
    } catch (e) {
      debugPrint('❌ Error testing radio stream: $e');
      return false;
    }
  }

  /// Clear cache
  void clearCache() {
    _radioCache.clear();
    _lastFetch = null;
    debugPrint('🗑️ Radio API cache cleared');
  }

  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'radiosCached': _radioCache.length,
      'lastFetch': _lastFetch?.toIso8601String(),
      'isCacheValid': _lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheValidDuration,
    };
  }
}
