enum PlaybackState {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

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

class AudioFailure {
  final AudioFailureType type;
  final String message;
  final int? statusCode;
  final bool retryable;

  const AudioFailure({
    required this.type,
    required this.message,
    this.statusCode,
    required this.retryable,
  });

  @override
  String toString() => 'AudioFailure($type, $message, status=$statusCode)';
}
