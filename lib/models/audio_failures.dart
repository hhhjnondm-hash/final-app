enum AudioFailureType {
  networkFailure,
  httpFailure,
  invalidUrl,
  unsupportedFormat,
  serverFailure,
  timeout,
  localFileMissing,
  localFileCorrupted,
  unknown,
}

class AudioPlaybackException implements Exception {
  AudioPlaybackException(this.type, this.message, {this.statusCode});

  final AudioFailureType type;
  final String message;
  final int? statusCode;

  bool get isRetryable {
    switch (type) {
      case AudioFailureType.networkFailure:
      case AudioFailureType.timeout:
      case AudioFailureType.serverFailure:
        return true;
      case AudioFailureType.httpFailure:
        final code = statusCode ?? 0;
        return code >= 500 && code < 600;
      case AudioFailureType.invalidUrl:
      case AudioFailureType.unsupportedFormat:
      case AudioFailureType.localFileMissing:
      case AudioFailureType.localFileCorrupted:
      case AudioFailureType.unknown:
        return false;
    }
  }

  @override
  String toString() => 'AudioPlaybackException($type, $message)';
}

enum PlaybackLifecycle {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}
