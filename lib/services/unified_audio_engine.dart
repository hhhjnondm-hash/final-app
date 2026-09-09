import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:audio_session/audio_session.dart';
import '../models/audio_playback.dart';
import '../observability/dev_log.dart';

class UnifiedAudioEngine {
  UnifiedAudioEngine._internal();
  static final UnifiedAudioEngine instance = UnifiedAudioEngine._internal();
  factory UnifiedAudioEngine() => instance;

  // Web engine: audioplayers (HTML5 Audio, supports mp3, m3u8, streaming without CORS issues)
  ap.AudioPlayer? _webPlayer;

  // Native engine: just_audio
  ja.AudioPlayer? _nativePlayer;

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

    if (kIsWeb) {
      _webPlayer = ap.AudioPlayer();
      _webPlayer!.setReleaseMode(ap.ReleaseMode.stop);

      _webPlayer!.onPlayerStateChanged.listen((state) {
        switch (state) {
          case ap.PlayerState.playing:
            _setState(PlaybackState.playing);
            _isPlayingController.add(true);
            break;
          case ap.PlayerState.paused:
            _setState(PlaybackState.paused);
            _isPlayingController.add(false);
            break;
          case ap.PlayerState.stopped:
            _setState(PlaybackState.idle);
            _isPlayingController.add(false);
            break;
          case ap.PlayerState.completed:
            _setState(PlaybackState.completed);
            _isPlayingController.add(false);
            break;
          case ap.PlayerState.disposed:
            _setState(PlaybackState.idle);
            _isPlayingController.add(false);
            break;
        }
      });

      _webPlayer!.onPositionChanged.listen((pos) {
        _position = pos;
        _positionController.add(pos);
      });

      _webPlayer!.onDurationChanged.listen((dur) {
        _duration = dur;
        _durationController.add(dur);
      });

      _webPlayer!.onLog.listen((msg) {
        debugPrint('[AudioPlayerWeb] Log: $msg');
      });
    } else {
      _nativePlayer = ja.AudioPlayer();
      _session = await AudioSession.instance;
      if (_session != null) {
        await _session!.configure(const AudioSessionConfiguration.music());
      }

      _nativePlayer!.playerStateStream.listen((state) {
        switch (state.processingState) {
          case ja.ProcessingState.idle:
            _setState(PlaybackState.idle);
            break;
          case ja.ProcessingState.loading:
          case ja.ProcessingState.buffering:
            _setState(PlaybackState.loading);
            break;
          case ja.ProcessingState.ready:
            if (state.playing) {
              _setState(PlaybackState.playing);
            } else {
              _setState(PlaybackState.paused);
            }
            break;
          case ja.ProcessingState.completed:
            _setState(PlaybackState.completed);
            break;
        }
        _isPlayingController.add(state.playing);
      });

      _nativePlayer!.positionStream.listen((pos) {
        _position = pos;
        _positionController.add(pos);
      });

      _nativePlayer!.durationStream.listen((dur) {
        if (dur != null) {
          _duration = dur;
          _durationController.add(dur);
        }
      });
    }

    _listenersReady = true;
    DevLog.audio(message: 'engine initialized', provider: kIsWeb ? 'audioplayers' : 'just_audio');
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
      DevLog.audio(
        message: 'play',
        origin: source.startsWith('http') ? 'remote' : 'local',
        host: _host(source),
        state: 'loading',
      );

      if (kIsWeb) {
        await _webPlayer!.stop();
        if (source.startsWith('http://') || source.startsWith('https://')) {
          await _webPlayer!.play(ap.UrlSource(source));
        } else if (source.startsWith('assets/')) {
          final assetPath = source.substring('assets/'.length);
          await _webPlayer!.play(ap.AssetSource(assetPath));
        } else {
          await _webPlayer!.play(ap.DeviceFileSource(source));
        }
      } else {
        await _nativePlayer!.stop();
        if (source.startsWith('http://') || source.startsWith('https://')) {
          await _nativePlayer!.setUrl(source);
          await _nativePlayer!.play();
        } else if (source.startsWith('assets/')) {
          final path = source.substring('assets/'.length);
          await _nativePlayer!.setAsset(path);
          await _nativePlayer!.play();
        } else {
          await _nativePlayer!.setFilePath(source);
          await _nativePlayer!.play();
        }
      }

      _setState(PlaybackState.playing);
    } catch (e) {
      debugPrint('UnifiedAudioEngine error: $e');
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
    if (kIsWeb) {
      await _webPlayer?.pause();
    } else {
      await _nativePlayer?.pause();
    }
  }

  Future<void> resume() async {
    if (kIsWeb) {
      await _webPlayer?.resume();
    } else {
      await _nativePlayer?.play();
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      await _webPlayer?.stop();
    } else {
      await _nativePlayer?.stop();
    }
    _currentSource = null;
    _setState(PlaybackState.idle);
  }

  Future<void> seek(Duration position) async {
    if (kIsWeb) {
      await _webPlayer?.seek(position);
    } else {
      await _nativePlayer?.seek(position);
    }
  }

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    if (kIsWeb) {
      await _webPlayer?.setVolume(v);
    } else {
      await _nativePlayer?.setVolume(v);
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    final r = rate.clamp(0.5, 2.0);
    if (kIsWeb) {
      await _webPlayer?.setPlaybackRate(r);
    } else {
      await _nativePlayer?.setSpeed(r);
    }
  }

  Future<void> duck() async {
    await setVolume(0.15);
  }

  Future<void> unduck() async {
    await setVolume(1.0);
  }

  Future<void> disposeEngine() async {
    if (kIsWeb) {
      await _webPlayer?.dispose();
    } else {
      await _nativePlayer?.dispose();
    }
    await _isPlayingController.close();
    await _positionController.close();
    await _durationController.close();
    await _errorController.close();
    await _playbackStateController.close();
    _listenersReady = false;
  }
}
