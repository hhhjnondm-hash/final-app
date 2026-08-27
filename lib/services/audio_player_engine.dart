import 'dart:async';
import 'audio_player_real.dart';

class UniversalAudioPlayer {
  static final UniversalAudioPlayer _instance = UniversalAudioPlayer._internal();
  factory UniversalAudioPlayer() => _instance;
  UniversalAudioPlayer._internal();

  final PlatformAudioEngine _engine = PlatformAudioEngine();

  Stream<Duration> get onPositionChanged => _engine.onPositionChanged;
  Stream<Duration> get onDurationChanged => _engine.onDurationChanged;
  Stream<bool> get onPlayerComplete => _engine.onPlayerComplete;
  Stream<String> get onError => _engine.onError;

  Future<void> playUrl(String url) async {
    await _engine.playUrl(url);
  }

  Future<void> pause() async {
    await _engine.pause();
  }

  Future<void> resume() async {
    await _engine.resume();
  }

  Future<void> stop() async {
    await _engine.stop();
  }

  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _engine.setVolume(volume);
  }

  Future<void> setPlaybackRate(double rate) async {
    await _engine.setPlaybackRate(rate);
  }

  // Additional methods for better control
  Future<Duration?> getDuration() async {
    return await _engine.getDuration();
  }

  Future<Duration?> getCurrentPosition() async {
    return await _engine.getCurrentPosition();
  }

  Future<String> getPlayerState() async {
    return await _engine.getPlayerState();
  }

  Future<void> release() async {
    await _engine.release();
  }
}
