import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_source_config.dart';
import '../models/canonical_identities.dart';
import '../observability/dev_log.dart';
import '../observability/source_health_monitor.dart';
import '../services/storage_service.dart';
import 'source_contracts.dart';

class Mp3QuranRadioProvider implements RadioProvider {
  static final Mp3QuranRadioProvider _instance = Mp3QuranRadioProvider._internal();
  factory Mp3QuranRadioProvider() => _instance;
  Mp3QuranRadioProvider._internal();

  final StorageService _storage = StorageService();
  static const _cacheKey = 'api_cache_mp3quran_radios_v3';
  List<RadioIdentity> _memory = [];
  DateTime? _lastFetch;
  static const _ttl = Duration(hours: 6);

  @override
  Future<List<RadioIdentity>> getRadios({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _memory.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _ttl) {
      return List.unmodifiable(_memory);
    }

    if (!forceRefresh) {
      final disk = await _loadDisk();
      if (disk != null) {
        _memory = disk;
      }
    }

    try {
      final radios = await SourceHealthMonitor().track(
        provider: 'mp3quran',
        endpoint: '/radios',
        action: () => _fetchPrimary(),
      );
      _memory = radios;
      _lastFetch = DateTime.now();
      await _saveDisk(radios);
      return List.unmodifiable(radios);
    } catch (e) {
      DevLog.audio(message: 'radio api primary failed', provider: 'mp3quran', error: '$e');
      try {
        final radios = await SourceHealthMonitor().track(
          provider: 'mp3quran',
          endpoint: '/radio_ar.json',
          action: () => _fetchFallbackJson(),
        );
        _memory = radios;
        _lastFetch = DateTime.now();
        await _saveDisk(radios);
        return List.unmodifiable(radios);
      } catch (e2) {
        if (_memory.isNotEmpty) return List.unmodifiable(_memory);
        rethrow;
      }
    }
  }

  Future<List<RadioIdentity>> _fetchPrimary() async {
    final uri = ApiSourceConfig.mp3QuranRadios.uri({'language': 'ar'});
    final response =
        await http.get(uri).timeout(ApiSourceConfig.mp3QuranRadios.timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return _parsePayload(json.decode(response.body));
  }

  Future<List<RadioIdentity>> _fetchFallbackJson() async {
    final uri = ApiSourceConfig.mp3QuranRadioJsonFallback.uri();
    final response = await http
        .get(uri)
        .timeout(ApiSourceConfig.mp3QuranRadioJsonFallback.timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return _parsePayload(json.decode(response.body));
  }

  List<RadioIdentity> _parsePayload(dynamic decoded) {
    List list;
    if (decoded is Map && decoded['radios'] is List) {
      list = decoded['radios'] as List;
    } else if (decoded is List) {
      list = decoded;
    } else {
      throw Exception('malformed radios payload');
    }

    final now = DateTime.now();
    final radios = <RadioIdentity>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final id = item['id']?.toString();
      final name = (item['name'] ?? '').toString();
      final url = (item['url'] ?? item['radio_url'] ?? '').toString().trim();
      if (id == null || name.isEmpty || url.isEmpty) continue;
      if (!(url.startsWith('http://') || url.startsWith('https://'))) continue;

      radios.add(RadioIdentity(
        radioId: id,
        canonicalName: name,
        streamUrl: url,
        provider: 'mp3quran',
        language: item['language']?.toString(),
        category: item['recent_date']?.toString() ?? 'quran',
        imageUrl: item['image']?.toString(),
        updatedAt: now,
      ));
    }
    if (radios.isEmpty) {
      throw Exception('no valid radio streams');
    }
    return radios;
  }

  Future<List<RadioIdentity>?> _loadDisk() async {
    await _storage.init();
    final data = _storage.getJson(_cacheKey);
    if (data == null) return null;
    final list = data['radios'];
    if (list is! List) return null;
    return list
        .whereType<Map>()
        .map((m) => RadioIdentity.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _saveDisk(List<RadioIdentity> radios) async {
    await _storage.init();
    await _storage.setJson(_cacheKey, {
      'fetchedAt': DateTime.now().toIso8601String(),
      'radios': radios.map((r) => r.toMap()).toList(),
    });
  }

  Future<void> clearApiCache() async {
    _memory = [];
    _lastFetch = null;
    await _storage.init();
    await _storage.clearKey(_cacheKey);
  }
}
