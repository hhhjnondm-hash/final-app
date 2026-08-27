import 'dart:async';
import 'package:flutter/material.dart';
import '../data/radio_data.dart';
import '../models/radio_models.dart';
import 'audio_player_engine.dart';

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

  final UniversalAudioPlayer _audioPlayer = UniversalAudioPlayer();

  RadioStation _currentStation = RadioData.stations.first;
  RadioPlaybackState _playbackState = RadioPlaybackState.stopped;
  double _volume = 0.85;
  String _selectedQuality = 'جودة عالية (128 kbps)';
  final Set<String> _favoriteStationIds = {'cairo_quran', 'makkah_quran', 'hassan_saleh_radio'};

  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Timer? _sleepCountdownTimer;

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
    _audioPlayer.onError.listen((err) {
      debugPrint('Radio Stream Error: $err');
      _playbackState = RadioPlaybackState.error;
      notifyListeners();
    });
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
      await _audioPlayer.playUrl(_currentStation.streamUrl);
      
      // Wait a moment to see if it starts successfully
      await Future.delayed(const Duration(seconds: 2));
      
      final state = await _audioPlayer.getPlayerState();
      debugPrint('Radio player state: $state');
      
      if (state.contains('playing') || state.contains('ready')) {
        _playbackState = RadioPlaybackState.playing;
        debugPrint('Radio started successfully');
      } else {
        _playbackState = RadioPlaybackState.error;
        debugPrint('Radio failed to start, state: $state');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error streaming radio station: $e');
      _playbackState = RadioPlaybackState.error;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    _playbackState = RadioPlaybackState.paused;
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    _playbackState = RadioPlaybackState.stopped;
    await _audioPlayer.stop();
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
    await _audioPlayer.setVolume(val);
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
    super.dispose();
  }
}
