import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_source_config.dart';
import '../models/audio_playback.dart';
import '../models/canonical_identities.dart';

class AudioHealthChecker {
  static final AudioHealthChecker _instance = AudioHealthChecker._internal();
  factory AudioHealthChecker() => _instance;
  AudioHealthChecker._internal();

  Future<AudioFailure?> validate(AudioSourceDescriptor source) async {
    if (source.localPath != null && source.localPath!.isNotEmpty) {
      return _validateLocal(source.localPath!);
    }
    final url = source.remoteUrl;
    if (url == null || url.isEmpty) {
      return const AudioFailure(
        type: AudioFailureType.invalidUrl,
        message: 'empty source',
        retryable: false,
      );
    }
    return validateRemote(url);
  }

  AudioFailure? _validateLocal(String path) {
    if (kIsWeb) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return AudioFailure(
          type: AudioFailureType.localFileMissing,
          message: path,
          retryable: false,
        );
      }
      if (file.lengthSync() <= 0) {
        return AudioFailure(
          type: AudioFailureType.localFileCorrupted,
          message: 'zero bytes',
          retryable: false,
        );
      }
      return null;
    } catch (e) {
      return AudioFailure(
        type: AudioFailureType.localFileMissing,
        message: '$e',
        retryable: false,
      );
    }
  }

  Future<AudioFailure?> validateRemote(String url) async {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return const AudioFailure(
        type: AudioFailureType.invalidUrl,
        message: 'malformed',
        retryable: false,
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return const AudioFailure(
        type: AudioFailureType.invalidUrl,
        message: 'unsupported scheme',
        retryable: false,
      );
    }

    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', uri);
        request.headers['Range'] = 'bytes=0-1';
        final streamed = await client.send(request).timeout(ApiSourceConfig.healthCheckTimeout);
        final code = streamed.statusCode;
        await streamed.stream.drain<void>();
        return classifyHttp(code);
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      return AudioFailure(
        type: AudioFailureType.networkFailure,
        message: e.message,
        retryable: true,
      );
    } on HttpException catch (e) {
      return AudioFailure(
        type: AudioFailureType.httpFailure,
        message: e.message,
        retryable: true,
      );
    } on TimeoutException {
      return const AudioFailure(
        type: AudioFailureType.timeout,
        message: 'timeout',
        retryable: true,
      );
    } catch (e) {
      // Live radio often rejects Range; still attempt playback.
      return null;
    }
  }

  AudioFailure? classifyHttp(int code) {
    if (code >= 200 && code < 400) return null;
    if (code == 401 || code == 403) {
      return AudioFailure(
        type: AudioFailureType.httpFailure,
        message: 'HTTP $code',
        statusCode: code,
        retryable: false,
      );
    }
    if (code == 404 || code == 410) {
      return AudioFailure(
        type: AudioFailureType.httpFailure,
        message: 'HTTP $code',
        statusCode: code,
        retryable: false,
      );
    }
    if (code >= 500) {
      return AudioFailure(
        type: AudioFailureType.serverFailure,
        message: 'HTTP $code',
        statusCode: code,
        retryable: true,
      );
    }
    return AudioFailure(
      type: AudioFailureType.httpFailure,
      message: 'HTTP $code',
      statusCode: code,
      retryable: code == 408 || code == 429,
    );
  }

  int retryDelayMs(int attempt) {
    const delays = [400, 900, 1800];
    if (attempt <= 0) return delays.first;
    if (attempt >= delays.length) return delays.last;
    return delays[attempt];
  }
}
