import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';
import '../models/audio_playback.dart';
import 'unified_audio_engine.dart';

export '../models/canonical_identities.dart' show AudioSourceType;

/// Unified global audio manager - ONE canonical audio engine
/// All screens must use this manager - never create another AudioPlayer
class GlobalAudioManager extends ChangeNotifier {
  GlobalAudioManager._internal();

  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;

  final UnifiedAudioEngine _engine = UnifiedAudioEngine();
  
  AudioSourceType _currentSource = AudioSourceType.quran;
  AudioSourceDescriptor? _currentDescriptor;
  PlaybackState _playbackState = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration? _duration;
  String? _currentUrl;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _errorSub;

  AudioSourceType get currentSource => _currentSource;
  AudioSourceDescriptor? get currentDescriptor => _currentDescriptor;
  PlaybackState get playbackState => _playbackState;
  bool get isPlaying => _playbackState == PlaybackState.playing;
  bool get isPaused => _playbackState == PlaybackState.paused;
  bool get isStopped => _playbackState == PlaybackState.idle;
  bool isPlayingOrBuffering => _playbackState == PlaybackState.playing || _playbackState == PlaybackState.loading;
  Duration get position => _position;
  Duration? get duration => _duration;
  String? get currentUrl => _currentUrl;

  String get currentTitle => _currentDescriptor?.title ?? '';
  String get currentSubtitle => _currentDescriptor?.subtitle ?? '';
  String? get currentArtwork => _currentDescriptor?.metadata?['artwork'] as String?;

  Stream<bool> get isPlayingStream => _engine.isPlayingStream;
  Stream<Duration> get positionStream => _engine.positionStream;
  Stream<Duration?> get durationStream => _engine.durationStream;
  Stream<String> get errorStream => _engine.errorStream;
  Stream<PlaybackState> get playbackStateStream => _engine.playbackStateStream;

  GlobalAudioManager() {
    _initListeners();
  }

  void _initListeners() {
    _posSub = _engine.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durSub = _engine.durationStream.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _stateSub = _engine.playbackStateStream.listen((state) {
      _playbackState = state;
      notifyListeners();
    });

    _errorSub = _engine.errorStream.listen((error) {
      debugPrint('GlobalAudioManager Error: $error');
      notifyListeners();
    });
  }

  Future<void> play(AudioSourceDescriptor source) async {
    debugPrint('🎵 GlobalAudioManager: Playing ${source.type} - ${source.title}');
    
    _currentSource = source.type;
    _currentDescriptor = source;
    _currentUrl = source.effectiveSource;
    _playbackState = PlaybackState.loading;
    notifyListeners();

    try {
      await _engine.play(
        _currentUrl!,
        isLiveStream: source.type == AudioSourceType.radio,
      );
      _playbackState = PlaybackState.playing;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ GlobalAudioManager: Failed to play - $e');
      _playbackState = PlaybackState.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> pause() async {
    await _engine.pause();
    _playbackState = PlaybackState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    await _engine.resume();
    _playbackState = PlaybackState.playing;
    notifyListeners();
  }

  Future<void> stop() async {
    await _engine.stop();
    _playbackState = PlaybackState.idle;
    _currentDescriptor = null;
    _currentUrl = null;
    notifyListeners();
  }

  Future<void> stopAdhan({bool restorePrevious = false}) async {
    await stop();
  }

  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _engine.setVolume(volume);
  }

  Future<void> setSpeed(double speed) async {
    await _engine.setPlaybackRate(speed);
  }

  Future<void> togglePlayPause() async {
    if (_playbackState == PlaybackState.playing) {
      await pause();
    } else if (_currentDescriptor != null) {
      await resume();
    }
  }

  Duration getPosition() => _position;
  Duration? getDuration() => _duration;

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }
}