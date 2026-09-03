import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';
import '../models/audio_playback.dart';

export '../models/canonical_identities.dart' show AudioSourceType;

/// Simplified global audio manager for compilation
class GlobalAudioManager extends ChangeNotifier {
  GlobalAudioManager._internal();

  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;

  AudioSourceType _currentSource = AudioSourceType.quran;
  AudioSourceDescriptor? _currentDescriptor;
  bool _isPlaying = false;

  AudioSourceType get currentSource => _currentSource;
  bool get isPlaying => _isPlaying;
  PlaybackState get playbackState => _isPlaying ? PlaybackState.playing : PlaybackState.idle;
  AudioSourceDescriptor? get currentDescriptor => _currentDescriptor;

  Stream<bool> get isPlayingStream => Stream.value(_isPlaying);
  Stream<Duration> get positionStream => Stream.value(Duration.zero);
  Stream<Duration?> get durationStream => Stream.value(null);
  Stream<String> get errorStream => Stream.empty();
  Stream<PlaybackState> get playbackStateStream => Stream.value(playbackState);

  Duration get position => Duration.zero;
  Duration? get duration => null;

  String get currentTitle => _currentDescriptor?.title ?? '';
  String get currentSubtitle => _currentDescriptor?.subtitle ?? '';
  String? get currentArtwork => _currentDescriptor?.metadata?['artwork'] as String?;

  Future<void> play(AudioSourceDescriptor source) async {
    _currentSource = source.type;
    _currentDescriptor = source;
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stopAdhan({bool restorePrevious = false}) async {
    _isPlaying = false;
    _currentDescriptor = null;
    notifyListeners();
  }

  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentDescriptor = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    // Stub implementation
  }

  Future<void> setVolume(double volume) async {
    // Stub implementation
  }

  Future<void> setSpeed(double speed) async {
    // Stub implementation
  }

  Duration getPosition() => Duration.zero;
  Duration? getDuration() => null;

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else if (_currentDescriptor != null) {
      await resume();
    }
  }
}