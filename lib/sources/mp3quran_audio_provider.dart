import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_source_config.dart';
import '../models/canonical_identities.dart';
import '../observability/dev_log.dart';
import '../observability/source_health_monitor.dart';
import '../services/reciter_image_registry.dart';
import '../services/storage_service.dart';
import 'source_contracts.dart';

class Mp3QuranAudioProvider implements QuranAudioProvider {
  static final Mp3QuranAudioProvider _instance = Mp3QuranAudioProvider._internal();
  factory Mp3QuranAudioProvider() => _instance;
  Mp3QuranAudioProvider._internal();

  final StorageService _storage = StorageService();
  static const _cacheKey = 'api_cache_mp3quran_reciters_v3';

  List<ReciterIdentity> _memory = [];
  Map<String, List<MoshafIdentity>> _moshafByReciter = {};
  DateTime? _lastFetch;
  static const _ttl = Duration(hours: 24);

  @override
  Future<List<ReciterIdentity>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _memory.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _ttl) {
      return List.unmodifiable(_memory);
    }

    if (!forceRefresh) {
      final disk = await _loadDiskCache();
      if (disk != null) {
        _memory = disk;
        _lastFetch = DateTime.now();
      }
    }

    try {
      final identities = await SourceHealthMonitor().track(
        provider: 'mp3quran',
        endpoint: '/reciters',
        action: () => _fetchReciters(),
      );
      _memory = identities;
      _lastFetch = DateTime.now();
      await _saveDiskCache(identities);
      DevLog.quran(message: 'reciters fetched', reciterId: '${identities.length}');
      return List.unmodifiable(identities);
    } catch (e) {
      DevLog.quran(message: 'reciters fetch failed', reciterId: e.toString());
      if (_memory.isNotEmpty) return List.unmodifiable(_memory);
      rethrow;
    }
  }

  @override
  Future<List<MoshafIdentity>> getMoshafForReciter(String reciterApiId) async {
    if (_moshafByReciter.containsKey(reciterApiId)) {
      return _moshafByReciter[reciterApiId]!;
    }
    await getReciters();
    return _moshafByReciter[reciterApiId] ?? const [];
  }

  Future<List<ReciterIdentity>> _fetchReciters() async {
    final uri = ApiSourceConfig.mp3QuranReciters.uri({'language': 'ar'});
    final response = await http.get(uri).timeout(ApiSourceConfig.mp3QuranReciters.timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('malformed reciters payload');
    }
    final list = decoded['reciters'];
    if (list is! List) {
      throw Exception('missing reciters array');
    }

    final reciters = <ReciterIdentity>[];
    _moshafByReciter = {};
    final now = DateTime.now();

    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final parsed = _parseReciter(item, now);
      if (parsed == null) continue;
      reciters.add(parsed.$1);
      _moshafByReciter[parsed.$1.apiId ?? parsed.$1.canonicalId] = parsed.$2;
    }
    return reciters;
  }

  (ReciterIdentity, List<MoshafIdentity>)? _parseReciter(
    Map<String, dynamic> json,
    DateTime now,
  ) {
    final apiId = json['id']?.toString();
    if (apiId == null || apiId.isEmpty) return null;
    final nameArabic = (json['name'] ?? '').toString();
    if (nameArabic.isEmpty) return null;

    final moshafRaw = json['moshaf'];
    final moshafs = <MoshafIdentity>[];
    String? serverUrl;
    String rewayah = '';
    int surahCount = 0;

    if (moshafRaw is List) {
      for (final m in moshafRaw) {
        if (m is! Map) continue;
        final map = Map<String, dynamic>.from(m);
        final moshaf = _parseMoshaf(map, apiId, now);
        if (moshaf == null) continue;
        moshafs.add(moshaf);
      }
      if (moshafs.isNotEmpty) {
        serverUrl = moshafs.first.serverUrl;
        rewayah = moshafs.first.rewayah ?? '';
        surahCount = moshafs.first.totalSurahs;
      }
    }

    final slug = _slugFor(serverUrl);
    return (
      ReciterIdentity(
        canonicalId: apiId,
        apiId: apiId,
        localAssetKey: slug ?? apiId,
        nameArabic: nameArabic,
        nameEnglish: (json['name_en'] ?? nameArabic).toString(),
        country: (json['country'] ?? '').toString(),
        rewayah: rewayah,
        serverUrl: serverUrl,
        surahCount: surahCount,
        updatedAt: now,
      ),
      moshafs,
    );
  }

  MoshafIdentity? _parseMoshaf(Map<String, dynamic> json, String reciterId, DateTime now) {
    final moshafId = json['id']?.toString();
    final server = (json['server'] ?? '').toString().trim();
    if (moshafId == null || moshafId.isEmpty || server.isEmpty) return null;

    final surahList = json['surah_list']?.toString() ?? '';
    final available = surahList
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    var normalizedServer = server;
    if (!normalizedServer.endsWith('/')) normalizedServer = '$normalizedServer/';

    return MoshafIdentity(
      moshafId: moshafId,
      reciterCanonicalId: reciterId,
      moshafName: (json['name'] ?? '').toString(),
      serverUrl: normalizedServer,
      moshafType: json['moshaf_type']?.toString() ?? 'murattal',
      availableSurahs: available,
      totalSurahs: available.isNotEmpty
          ? available.length
          : (json['surah_total'] as num?)?.toInt() ?? 0,
      rewayah: json['name']?.toString(),
      updatedAt: now,
    );
  }

  String? _slugFor(String? serverUrl) {
    if (serverUrl == null) return null;
    try {
      final segs = Uri.parse(serverUrl).pathSegments.where((s) => s.isNotEmpty);
      if (segs.isEmpty) return null;
      return ReciterImageRegistry.serverCodeToSlug[segs.first];
    } catch (_) {
      return null;
    }
  }

  Future<List<ReciterIdentity>?> _loadDiskCache() async {
    await _storage.init();
    final data = _storage.getJson(_cacheKey);
    if (data == null) return null;
    final list = data['reciters'];
    if (list is! List) return null;
    return list
        .whereType<Map>()
        .map((m) => ReciterIdentity.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _saveDiskCache(List<ReciterIdentity> reciters) async {
    await _storage.init();
    await _storage.setJson(_cacheKey, {
      'fetchedAt': DateTime.now().toIso8601String(),
      'reciters': reciters.map((r) => r.toMap()).toList(),
    });
  }

  Future<void> clearApiCache() async {
    _memory = [];
    _moshafByReciter = {};
    _lastFetch = null;
    await _storage.init();
    await _storage.clearKey(_cacheKey);
  }
}
