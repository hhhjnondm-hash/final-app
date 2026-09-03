import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/audio_playback.dart';
import '../observability/dev_log.dart';

/// Single canonical playback engine for Quran, Read, Radio, and Adhan.
/// All screens must go through GlobalAudioManager — never construct another player.
class UnifiedAudioEngine {
  UnifiedAudioEngine._internal();
  static final UnifiedAudioEngine instance = UnifiedAudioEngine._internal();
  factory UnifiedAudioEngine() => instance;

  final AudioPlayer _player = AudioPlayer();
  bool _listenersReady = false;
  String? _currentSource;
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration? _duration;

  final StreamController<bool> _isPlayingController = StreamController.broadcast();
  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<Duration?> _durationController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  final StreamController<PlaybackState> _playbackStateController = StreamController.broadcast();

  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;

  bool get isPlaying => _state == PlaybackState.playing;
  bool get isPaused => _state == PlaybackState.paused;
  bool get isStopped => _state == PlaybackState.idle;
  bool get isCompleted => _state == PlaybackState.completed;
  PlaybackState get playbackState => _state;
  Duration? get duration => _duration;
  Duration get position => _position;
  String? get currentSource => _currentSource;

  Future<void> initialize() async {
    if (_listenersReady) return;
    _player.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _setState(PlaybackState.playing);
          break;
        case PlayerState.paused:
          _setState(PlaybackState.paused);
          break;
        case PlayerState.completed:
          _setState(PlaybackState.completed);
          break;
        case PlayerState.stopped:
          _setState(PlaybackState.idle);
          break;
        case PlayerState.disposed:
          _setState(PlaybackState.idle);
          break;
      }
      _isPlayingController.add(state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      _positionController.add(pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (dur.inMilliseconds > 0) {
        _duration = dur;
        _durationController.add(dur);
      }
    });
    _player.onPlayerComplete.listen((_) {
      _setState(PlaybackState.completed);
      _isPlayingController.add(false);
    });
    _listenersReady = true;
    DevLog.audio(message: 'engine initialized', provider: 'audioplayers');
  }

  void _setState(PlaybackState next) {
    _state = next;
    _playbackStateController.add(next);
  }

  Future<void> play(
    String source, {
    Map<String, String>? headers,
    bool isLiveStream = false,
  }) async {
    await initialize();
    _setState(PlaybackState.loading);
    _currentSource = source;
    try {
      await _player.stop();
      if (isLiveStream) {
        await _player.setReleaseMode(ReleaseMode.stop);
      }

      final src = _toSource(source);
      DevLog.audio(
        message: 'play',
        origin: source.startsWith('http') ? 'remote' : 'local',
        host: _host(source),
        state: 'loading',
      );
      await _player.play(src);
    } catch (e) {
      _setState(PlaybackState.error);
      _errorController.add('$e');
      DevLog.audio(message: 'play failed', error: '$e', host: _host(source));
      rethrow;
    }
  }

  Source _toSource(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return UrlSource(source);
    }
    var path = source;
    if (path.startsWith('assets/')) {
      path = path.substring('assets/'.length);
      return AssetSource(path);
    }
    if (!path.contains('/') && !path.contains('\\') || path.startsWith('audio/')) {
      return AssetSource(path);
    }
    return DeviceFileSource(source);
  }

  String? _host(String source) {
    try {
      if (source.startsWith('http')) return Uri.parse(source).host;
    } catch (_) {}
    return null;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSource = null;
    _setState(PlaybackState.idle);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setPlaybackRate(double rate) async {
    await _player.setPlaybackRate(rate.clamp(0.5, 2.0));
  }

  Future<void> duck() async {
    await _player.setVolume(0.15);
  }

  Future<void> unduck() async {
    await _player.setVolume(1.0);
  }

  /// Do not dispose the shared engine from feature services.
  Future<void> disposeEngine() async {
    await _player.dispose();
    await _isPlayingController.close();
    await _positionController.close();
    await _durationController.close();
    await _errorController.close();
    await _playbackStateController.close();
    _listenersReady = false;
  }
}
