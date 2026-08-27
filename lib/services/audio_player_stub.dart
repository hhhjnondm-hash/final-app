import 'dart:async';

class PlatformAudioEngine {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completeController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onPlayerComplete => _completeController.stream;
  Stream<String> get onError => _errorController.stream;

  Future<void> playUrl(String url) async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Future<void> setVolume(double volume) async {}
  Future<void> setPlaybackRate(double rate) async {}
}
