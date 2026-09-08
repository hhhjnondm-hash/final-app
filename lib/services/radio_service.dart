import 'dart:async';
import 'package:flutter/material.dart';
import '../data/radio_data.dart';
import '../models/radio_models.dart';
import '../models/canonical_identities.dart';
import '../models/audio_playback.dart';
import 'global_audio_manager.dart';

enum RadioPlaybackState {
  stopped,
  buffering,
  playing,
  paused,
  error,
}

class RadioService extends ChangeNotifier {
  static final RadioService _instance = RadioService._internal();
  factory RadioService() => _instance;
  RadioService._internal() {
    _initAudioListeners();
  }

  final GlobalAudioManager _audioManager = GlobalAudioManager();

  RadioStation _currentStation = RadioData.stations.first;
  RadioPlaybackState _playbackState = RadioPlaybackState.stopped;
  double _volume = 0.85;
  String _selectedQuality = 'جودة عالية (128 kbps)';
  final Set<String> _favoriteStationIds = {'cairo_quran', 'makkah_quran', 'hassan_saleh_radio'};

  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Timer? _sleepCountdownTimer;

  StreamSubscription? _stateSub;
  StreamSubscription? _errorSub;

  RadioStation get currentStation => _currentStation;
  RadioPlaybackState get playbackState => _playbackState;
  bool get isPlaying => _playbackState == RadioPlaybackState.playing;
  bool get isBuffering => _playbackState == RadioPlaybackState.buffering;
  double get volume => _volume;
  String get selectedQuality => _selectedQuality;
  Set<String> get favoriteStationIds => _favoriteStationIds;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  bool isFavorite(String id) => _favoriteStationIds.contains(id);

  void _initAudioListeners() {
    _stateSub = _audioManager.playbackStateStream.listen((state) {
      _updatePlaybackStateFromGlobal(state);
    });

    _errorSub = _audioManager.errorStream.listen((err) {
      debugPrint('Radio Stream Error: $err');
      _playbackState = RadioPlaybackState.error;
      notifyListeners();
    });
  }

  void _updatePlaybackStateFromGlobal(PlaybackState globalState) {
    switch (globalState) {
      case PlaybackState.playing:
        _playbackState = RadioPlaybackState.playing;
        break;
      case PlaybackState.paused:
        _playbackState = RadioPlaybackState.paused;
        break;
      case PlaybackState.loading:
        _playbackState = RadioPlaybackState.buffering;
        break;
      case PlaybackState.error:
        _playbackState = RadioPlaybackState.error;
        break;
      default:
        _playbackState = RadioPlaybackState.stopped;
    }
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (_favoriteStationIds.contains(id)) {
      _favoriteStationIds.remove(id);
    } else {
      _favoriteStationIds.add(id);
    }
    notifyListeners();
  }

  Future<void> selectStation(RadioStation station) async {
    if (_currentStation.id == station.id && _playbackState == RadioPlaybackState.playing) {
      return;
    }
    _currentStation = station;
    await play();
  }

  Future<void> play() async {
    _playbackState = RadioPlaybackState.buffering;
    notifyListeners();

    try {
      debugPrint('Attempting to play radio: ${_currentStation.streamUrl}');
      
      final descriptor = AudioSourceDescriptor(
        id: _currentStation.id,
        type: AudioSourceType.radio,
        title: _currentStation.name,
        subtitle: _currentStation.language,
        provider: 'RadioService',
        remoteUrl: _currentStation.streamUrl,
        metadata: {
          'stationId': _currentStation.id,
          'quality': _selectedQuality,
        },
      );

      await _audioManager.play(descriptor);

      // Wait a moment to see if it starts successfully
      await Future.delayed(const Duration(seconds: 2));

      if (_audioManager.isPlaying) {
        _playbackState = RadioPlaybackState.playing;
        debugPrint('Radio started successfully');
      } else {
        _playbackState = RadioPlaybackState.error;
        debugPrint('Radio failed to start');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error streaming radio station: $e');
      _playbackState = RadioPlaybackState.error;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioManager.pause();
  }

  Future<void> resume() async {
    if (_playbackState == RadioPlaybackState.paused) {
      await play();
    }
  }

  Future<void> stop() async {
    await _audioManager.stop();
    _playbackState = RadioPlaybackState.stopped;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_playbackState == RadioPlaybackState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> nextStation() async {
    final stations = RadioData.stations;
    final currentIndex = stations.indexWhere((s) => s.id == _currentStation.id);
    final nextIndex = (currentIndex + 1) % stations.length;
    await selectStation(stations[nextIndex]);
  }

  Future<void> previousStation() async {
    final stations = RadioData.stations;
    final currentIndex = stations.indexWhere((s) => s.id == _currentStation.id);
    final prevIndex = (currentIndex - 1 + stations.length) % stations.length;
    await selectStation(stations[prevIndex]);
  }

  Future<void> setVolume(double val) async {
    _volume = val;
    await _audioManager.setVolume(val);
    notifyListeners();
  }

  void setQuality(String quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    _cancelSleepTimer();
    _sleepTimerRemaining = duration;
    notifyListeners();

    _sleepTimer = Timer(duration, () {
      stop();
      _cancelSleepTimer();
    });

    _sleepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemaining != null && _sleepTimerRemaining!.inSeconds > 0) {
        _sleepTimerRemaining = Duration(seconds: _sleepTimerRemaining!.inSeconds - 1);
        notifyListeners();
      } else {
        _cancelSleepTimer();
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepCountdownTimer?.cancel();
    _sleepTimer = null;
    _sleepCountdownTimer = null;
    _sleepTimerRemaining = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSleepTimer();
    _stateSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }
}
