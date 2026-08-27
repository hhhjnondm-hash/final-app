import 'dart:async';
import 'package:web/web.dart' as web;

class PlatformAudioEngine {
  web.HTMLAudioElement? _audio;
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completeController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  StreamSubscription? _timeUpdateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _errorSub;

  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onPlayerComplete => _completeController.stream;
  Stream<String> get onError => _errorController.stream;

  Future<void> playUrl(String url) async {
    try {
      if (_audio == null) {
        _audio = web.HTMLAudioElement();
        _audio!.autoplay = true;
        
        _audio!.ontimeupdate = (web.Event e) {
          if (_audio != null) {
            _positionController.add(Duration(milliseconds: (_audio!.currentTime * 1000).toInt()));
          }
        };

        _audio!.ondurationchange = (web.Event e) {
          if (_audio != null && !_audio!.duration.isNaN && !_audio!.duration.isInfinite) {
            _durationController.add(Duration(milliseconds: (_audio!.duration * 1000).toInt()));
          }
        };

        _audio!.onended = (web.Event e) {
          _completeController.add(true);
        };

        _audio!.onerror = (web.Event e) {
          _errorController.add('Audio playback error');
        };
      }

      _audio!.src = url;
      _audio!.load();
      await _audio!.play();
    } catch (e) {
      _errorController.add(e.toString());
    }
  }

  Future<void> pause() async {
    _audio?.pause();
  }

  Future<void> resume() async {
    _audio?.play();
  }

  Future<void> stop() async {
    _audio?.pause();
    if (_audio != null) {
      _audio!.src = '';
    }
  }

  Future<void> seek(Duration position) async {
    if (_audio != null) {
      _audio!.currentTime = position.inMilliseconds / 1000.0;
    }
  }

  Future<void> setVolume(double volume) async {
    if (_audio != null) {
      _audio!.volume = volume.clamp(0.0, 1.0);
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    if (_audio != null) {
      _audio!.playbackRate = rate;
    }
  }
}
