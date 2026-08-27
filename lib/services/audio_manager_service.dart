import 'package:flutter/material.dart';
import 'audio_quran_service.dart';
import 'radio_service.dart';

enum ActiveAudioSource {
  none,
  quran,
  radio,
}

class AudioManagerService extends ChangeNotifier {
  static final AudioManagerService _instance = AudioManagerService._internal();
  factory AudioManagerService() => _instance;
  AudioManagerService._internal() {
    _audioQuranService.addListener(_onQuranServiceChanged);
    _radioService.addListener(_onRadioServiceChanged);
  }

  final AudioQuranService _audioQuranService = AudioQuranService();
  final RadioService _radioService = RadioService();

  ActiveAudioSource _activeSource = ActiveAudioSource.none;

  ActiveAudioSource get activeSource => _activeSource;
  bool get hasActiveAudio => _activeSource != ActiveAudioSource.none;
  bool get isPlaying =>
      (_activeSource == ActiveAudioSource.quran && _audioQuranService.isPlaying) ||
      (_activeSource == ActiveAudioSource.radio && _radioService.isPlaying);

  String get currentTitle {
    if (_activeSource == ActiveAudioSource.quran) {
      return 'سورة ${_audioQuranService.currentSurah.nameArabic}';
    } else if (_activeSource == ActiveAudioSource.radio) {
      return _radioService.currentStation.name;
    }
    return '';
  }

  String get currentSubtitle {
    if (_activeSource == ActiveAudioSource.quran) {
      return _audioQuranService.currentReciter.nameArabic;
    } else if (_activeSource == ActiveAudioSource.radio) {
      return _radioService.currentStation.currentProgram;
    }
    return '';
  }

  String? get currentArtwork {
    if (_activeSource == ActiveAudioSource.quran) {
      return _audioQuranService.currentReciter.photoUrl;
    } else if (_activeSource == ActiveAudioSource.radio) {
      return _radioService.currentStation.photoUrl;
    }
    return null;
  }

  void _onQuranServiceChanged() {
    if (_audioQuranService.isPlaying && _activeSource != ActiveAudioSource.quran) {
      if (_radioService.isPlaying) {
        _radioService.stop();
      }
      _activeSource = ActiveAudioSource.quran;
      notifyListeners();
    } else if (!_audioQuranService.isPlaying && _activeSource == ActiveAudioSource.quran) {
      notifyListeners();
    }
  }

  void _onRadioServiceChanged() {
    if (_radioService.isPlaying && _activeSource != ActiveAudioSource.radio) {
      if (_audioQuranService.isPlaying) {
        _audioQuranService.pause();
      }
      _activeSource = ActiveAudioSource.radio;
      notifyListeners();
    } else if (!_radioService.isPlaying && _activeSource == ActiveAudioSource.radio) {
      notifyListeners();
    }
  }

  void togglePlayPause() {
    if (_activeSource == ActiveAudioSource.quran) {
      _audioQuranService.togglePlayPause();
    } else if (_activeSource == ActiveAudioSource.radio) {
      _radioService.togglePlayPause();
    }
  }

  void stop() {
    if (_activeSource == ActiveAudioSource.quran) {
      _audioQuranService.pause();
    } else if (_activeSource == ActiveAudioSource.radio) {
      _radioService.stop();
    }
    _activeSource = ActiveAudioSource.none;
    notifyListeners();
  }
}
