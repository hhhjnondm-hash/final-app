import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../models/audio_playback.dart';
import '../observability/dev_log.dart';

/// Single canonical playback engine using just_audio (stronger on Android)
/// All screens must go through GlobalAudioManager — never construct another player
class UnifiedAudioEngine {
  UnifiedAudioEngine._internal();
  static final UnifiedAudioEngine instance = UnifiedAudioEngine._internal();
  factory UnifiedAudioEngine() => instance;

  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;
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
    
    // Setup audio session
    _session = await AudioSession.instance;
    await _session.configure(const AudioSessionConfiguration.music());
    
    _player.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          _setState(PlaybackState.idle);
          break;
        case ProcessingState.loading:
          _setState(PlaybackState.loading);
          break;
        case ProcessingState.buffering:
          _setState(PlaybackState.loading);
          break;
        case ProcessingState.ready:
          if (state.playing) {
            _setState(PlaybackState.playing);
          } else {
            _setState(PlaybackState.paused);
          }
          break;
        case ProcessingState.completed:
          _setState(PlaybackState.completed);
          break;
      }
      _isPlayingController.add(state.playing);
    });
    
    _player.positionStream.listen((pos) {
      _position = pos;
      _positionController.add(pos);
    });
    
    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        _durationController.add(dur);
      }
    });
    
    _player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        _setState(PlaybackState.completed);
      }
    });
    
    _listenersReady = true;
    DevLog.audio(message: 'engine initialized', provider: 'just_audio');
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
      
      DevLog.audio(
        message: 'play',
        origin: source.startsWith('http') ? 'remote' : 'local',
        host: _host(source),
        state: 'loading',
      );
      
      if (source.startsWith('http://') || source.startsWith('https://')) {
        final uri = Uri.parse(source);
        await _player.setUrl(source);
        await _player.play();
      } else if (source.startsWith('assets/')) {
        final path = source.substring('assets/'.length);
        await _player.setAsset(path);
        await _player.play();
      } else {
        await _player.setFilePath(source);
        await _player.play();
      }
      
      _setState(PlaybackState.playing);
    } catch (e) {
      _setState(PlaybackState.error);
      _errorController.add('$e');
      DevLog.audio(message: 'play failed', error: '$e', host: _host(source));
      rethrow;
    }
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
    await _player.play();
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
    await _player.setSpeed(rate.clamp(0.5, 2.0));
  }

  Future<void> duck() async {
    await _player.setVolume(0.15);
  }

  Future<void> unduck() async {
    await _player.setVolume(1.0);
  }

  /// Do not dispose the shared engine from feature services
  Future<void> disposeEngine() async {
    await _player.dispose();
    await _session?.dispose();
    await _isPlayingController.close();
    await _positionController.close();
    await _durationController.close();
    await _errorController.close();
    await _playbackStateController.close();
    _listenersReady = false;
  }
}
