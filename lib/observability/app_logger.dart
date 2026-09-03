import 'package:flutter/foundation.dart';

/// Structured development logs. Never log secrets, tokens, or private user data.
class AppLogger {
  AppLogger._();

  static void audio(String message, {Map<String, Object?> extra = const {}}) {
    _log('AUDIO', message, extra);
  }

  static void quran(String message, {Map<String, Object?> extra = const {}}) {
    _log('QURAN', message, extra);
  }

  static void image(String message, {Map<String, Object?> extra = const {}}) {
    _log('IMAGE', message, extra);
  }

  static void prayer(String message, {Map<String, Object?> extra = const {}}) {
    _log('PRAYER', message, extra);
  }

  static void download(String message, {Map<String, Object?> extra = const {}}) {
    _log('DOWNLOAD', message, extra);
  }

  static void source(String message, {Map<String, Object?> extra = const {}}) {
    _log('SOURCE', message, extra);
  }

  static void _log(String channel, String message, Map<String, Object?> extra) {
    if (!kDebugMode) return;
    final parts = extra.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    debugPrint(parts.isEmpty ? '[$channel] $message' : '[$channel] $message $parts');
  }
}
