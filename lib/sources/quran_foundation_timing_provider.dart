import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_source_config.dart';
import '../observability/dev_log.dart';
import '../observability/source_health_monitor.dart';
import 'source_contracts.dart';

/// Quran Foundation timing via backend proxy only.
/// If no proxy URL is configured, exact ayah sync is disabled (honest).
class QuranFoundationTimingProvider implements ReadTimingProvider {
  static final QuranFoundationTimingProvider _instance =
      QuranFoundationTimingProvider._internal();
  factory QuranFoundationTimingProvider() => _instance;
  QuranFoundationTimingProvider._internal();

  @override
  Future<ReadTimingResult> getChapterTimings({
    required int recitationId,
    required int chapterNumber,
  }) async {
    if (!ApiSourceConfig.hasQuranFoundationProxy) {
      return const ReadTimingResult(
        available: false,
        reason: 'quran_foundation_proxy_not_configured',
      );
    }

    final base = ApiSourceConfig.quranFoundationProxyBaseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse(
      '$base/chapter_recitations/$recitationId/$chapterNumber',
    );

    try {
      final response = await SourceHealthMonitor().track(
        provider: 'quran_foundation_proxy',
        endpoint: '/chapter_recitations',
        action: () => http.get(uri).timeout(ApiSourceConfig.defaultTimeout),
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const ReadTimingResult(available: false, reason: 'unauthorized');
      }
      if (response.statusCode == 429) {
        return const ReadTimingResult(available: false, reason: 'rate_limited');
      }
      if (response.statusCode != 200) {
        return ReadTimingResult(available: false, reason: 'http_${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      final audioFile = decoded is Map ? decoded['audio_file'] ?? decoded['audioFile'] : null;
      if (audioFile is! Map) {
        return const ReadTimingResult(available: false, reason: 'malformed');
      }
      final timestamps = audioFile['timestamps'] ?? audioFile['verse_timings'];
      if (timestamps is! List || timestamps.isEmpty) {
        return const ReadTimingResult(available: false, reason: 'no_timestamps');
      }

      final timings = <ChapterTiming>[];
      for (final raw in timestamps) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final ayah = int.tryParse(
              (map['verse_number'] ?? map['verseNumber'] ?? map['ayah'] ?? '').toString(),
            ) ??
            0;
        final from = _ms(map['timestamp_from'] ?? map['timestampFrom']);
        final to = _ms(map['timestamp_to'] ?? map['timestampTo']);
        if (ayah <= 0 || from == null || to == null) continue;
        final segs = <List<int>>[];
        final segments = map['segments'];
        if (segments is List) {
          for (final s in segments) {
            if (s is List && s.length >= 3) {
              segs.add(s.map((e) => int.tryParse('$e') ?? 0).toList());
            }
          }
        }
        timings.add(ChapterTiming(
          ayahNumber: ayah,
          timestampFromMs: from,
          timestampToMs: to,
          segments: segs,
        ));
      }
      if (timings.isEmpty) {
        return const ReadTimingResult(available: false, reason: 'no_valid_timestamps');
      }
      return ReadTimingResult(available: true, timings: timings);
    } catch (e) {
      DevLog.audio(message: 'timing fetch failed', provider: 'quran_foundation', error: '$e');
      return const ReadTimingResult(available: false, reason: 'network_or_parse');
    }
  }

  int? _ms(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
