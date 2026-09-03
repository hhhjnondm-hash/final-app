import 'package:flutter/foundation.dart';

/// Structured development logs. Never log secrets, tokens, or private user data.
class DevLog {
  DevLog._();

  static void audio({
    required String message,
    String? provider,
    String? sourceType,
    String? origin,
    String? host,
    String? state,
    String? error,
  }) {
    _print('[AUDIO]', {
      'msg': message,
      'provider': provider,
      'type': sourceType,
      'origin': origin,
      'host': host,
      'state': state,
      'error': error,
    });
  }

  static void quran({
    required String message,
    String? reciterId,
    String? moshafId,
    int? surahId,
    bool? available,
  }) {
    _print('[QURAN]', {
      'msg': message,
      'reciterId': reciterId,
      'moshafId': moshafId,
      'surahId': surahId,
      'available': available,
    });
  }

  static void image({
    required String message,
    String? reciterId,
    String? assetPath,
    String? fallbackReason,
  }) {
    _print('[IMAGE]', {
      'msg': message,
      'reciterId': reciterId,
      'path': assetPath,
      'fallback': fallbackReason,
    });
  }

  static void prayer({
    required String message,
    String? date,
    String? location,
    String? cache,
    String? refresh,
    int? offset,
  }) {
    _print('[PRAYER]', {
      'msg': message,
      'date': date,
      'location': location,
      'cache': cache,
      'refresh': refresh,
      'offset': offset,
    });
  }

  static void download({
    required String message,
    int? surah,
    String? status,
    String? error,
    int? progress,
  }) {
    _print('[DOWNLOAD]', {
      'msg': message,
      'surah': surah,
      'status': status,
      'progress': progress,
      'error': error,
    });
  }

  static void _print(String tag, Map<String, Object?> fields) {
    if (!kDebugMode) return;
    final parts = fields.entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    debugPrint('$tag $parts');
  }
}
