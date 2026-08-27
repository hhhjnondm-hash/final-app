import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class PlatformAudioEngine {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completeController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onPlayerComplete => _completeController.stream;
  Stream<String> get onError => _errorController.stream;

  bool _isInitialized = false;

  PlatformAudioEngine() {
    _initListeners();
  }

  void _initListeners() {
    _audioPlayer.onPositionChanged.listen((position) {
      if (position != null) {
        _positionController.add(position);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (duration != null) {
        _durationController.add(duration);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _completeController.add(true);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state.name == 'error') {
        _errorController.add('Player error occurred');
      }
    });
  }

  Future<void> playUrl(String url) async {
    try {
      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.resume();
    } catch (e) {
      _errorController.add('Error playing URL: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _errorController.add('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      _errorController.add('Error resuming: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      _errorController.add('Error stopping: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _errorController.add('Error seeking: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      _errorController.add('Error setting volume: $e');
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    try {
      await _audioPlayer.setPlaybackRate(rate);
    } catch (e) {
      _errorController.add('Error setting playback rate: $e');
    }
  }

  Future<void> release() async {
    await _audioPlayer.release();
    await _positionController.close();
    await _durationController.close();
    await _completeController.close();
    await _errorController.close();
  }

  // Additional useful methods
  Future<Duration?> getDuration() async {
    return await _audioPlayer.getDuration();
  }

  Future<Duration?> getCurrentPosition() async {
    return await _audioPlayer.getCurrentPosition();
  }

  Future<String> getPlayerState() async {
    return _audioPlayer.state.toString();
  }
}