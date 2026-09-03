import 'dart:async';
import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import 'robust_quran_audio_service.dart';
import 'quran_download_manager.dart';

class AudioQuranService extends ChangeNotifier {
  static final AudioQuranService _instance = AudioQuranService._internal();
  factory AudioQuranService() => _instance;
  AudioQuranService._internal() {
    _initAudioListeners();
    _downloadManager.initialize();
  }

  final RobustQuranAudioService _audioService = RobustQuranAudioService();
  final QuranDownloadManager _downloadManager = QuranDownloadManager();

  ReciterProfile _currentReciter = RecitersData.reciters.first;
  SurahMeta _currentSurah = QuranMetadataProvider.getAllSurahs().first;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(minutes: 5, seconds: 0);
  double _playbackSpeed = 1.0;
  final Set<String> _favoriteReciterIds = {'hassan_saleh', 'afasy', 'maher', 'dosari'};

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _statusSub;

  ReciterProfile get currentReciter => _currentReciter;
  SurahMeta get currentSurah => _currentSurah;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  Set<String> get favoriteReciterIds => _favoriteReciterIds;
  QuranDownloadManager get downloadManager => _downloadManager;

  bool isFavorite(String id) => _favoriteReciterIds.contains(id);
  bool isDownloaded(String reciterId, int surahId) => _downloadManager.isDownloaded(reciterId, surahId);

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _initAudioListeners() {
    _posSub = _audioService.positionStream.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    _durSub = _audioService.durationStream.listen((dur) {
      if (dur != null && dur.inSeconds > 0) {
        _totalDuration = dur;
        notifyListeners();
      }
    });

    _statusSub = _audioService.statusStream.listen((status) {
      if (status == 'playing') {
        _isPlaying = true;
      } else if (status == 'paused' || status == 'stopped' || status == 'completed') {
        _isPlaying = false;
      }
      notifyListeners();
    });

    _errorSub = _audioService.errorStream.listen((error) {
      debugPrint('AudioQuranService Error: $error');
    });
  }

  void toggleFavorite(String id) {
    if (_favoriteReciterIds.contains(id)) {
      _favoriteReciterIds.remove(id);
    } else {
      _favoriteReciterIds.add(id);
    }
    notifyListeners();
  }

  Future<void> selectReciter(ReciterProfile reciter) async {
    _currentReciter = reciter;
    notifyListeners();
    if (_isPlaying) {
      await _playCurrentSurah();
    }
  }

  Future<void> selectSurah(SurahMeta surah) async {
    _currentSurah = surah;
    _currentPosition = Duration.zero;
    await _playCurrentSurah();
  }

  Future<void> _playCurrentSurah() async {
    debugPrint('AudioQuranService: Playing surah ${_currentSurah.number} with reciter ${_currentReciter.nameArabic}');
    
    // Check if downloaded first
    final localPath = _downloadManager.getLocalPath(_currentReciter.id, _currentSurah.number);
    if (localPath != null) {
      debugPrint('AudioQuranService: Playing from local file: $localPath');
      final success = await _audioService.playLocalFile(localPath);
      
      if (!success) {
        debugPrint('AudioQuranService: Failed to play local file, falling back to stream');
        await _audioService.playSurah(_currentReciter, _currentSurah.number);
      }
    } else {
      // Stream from remote
      final success = await _audioService.playSurah(_currentReciter, _currentSurah.number);
      
      if (!success) {
        debugPrint('AudioQuranService: Failed to play surah');
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await _playCurrentSurah();
    }
  }

  Future<void> seekTo(Duration position) async {
    _currentPosition = position;
    await _audioService.seek(position);
    notifyListeners();
  }

  Future<void> nextSurah() async {
    final allSurahs = QuranMetadataProvider.getAllSurahs();
    final nextNumber = (_currentSurah.number % 114) + 1;
    final next = allSurahs.firstWhere((s) => s.number == nextNumber, orElse: () => allSurahs.first);
    await selectSurah(next);
  }

  Future<void> previousSurah() async {
    final allSurahs = QuranMetadataProvider.getAllSurahs();
    final prevNumber = _currentSurah.number == 1 ? 114 : _currentSurah.number - 1;
    final prev = allSurahs.firstWhere((s) => s.number == prevNumber, orElse: () => allSurahs.first);
    await selectSurah(prev);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioService.setSpeed(speed);
    notifyListeners();
  }

  Future<DownloadRecord?> downloadCurrentSurah() async {
    final audioUrl = _buildAudioUrl(_currentReciter, _currentSurah.number);
    return await _downloadManager.downloadSurah(
      reciter: _currentReciter,
      surah: _currentSurah,
      audioUrl: audioUrl,
    );
  }

  String _buildAudioUrl(ReciterProfile reciter, int surahNumber) {
    // This should be centralized in an AudioUrlResolver
    // For now, use the existing pattern from RecitersData
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return '${reciter.serverUrl}$surahStr.mp3';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _errorSub?.cancel();
    _statusSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
