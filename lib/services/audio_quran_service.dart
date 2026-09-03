import 'dart:async';
import 'package:flutter/material.dart';
import '../data/quran_metadata.dart';
import '../data/reciters_data.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import '../models/canonical_identities.dart';
import 'global_audio_manager.dart';
import 'quran_download_manager.dart';

class AudioQuranService extends ChangeNotifier {
  static final AudioQuranService _instance = AudioQuranService._internal();
  factory AudioQuranService() => _instance;
  AudioQuranService._internal() {
    _initAudioListeners();
    _downloadManager.initialize();
  }

  final GlobalAudioManager _audioManager = GlobalAudioManager();
  final QuranDownloadManager _downloadManager = QuranDownloadManager();

  ReciterProfile _currentReciter = RecitersData.reciters.first;
  SurahMeta _currentSurah = QuranMetadataProvider.getAllSurahs().first;
  double _playbackSpeed = 1.0;
  final Set<String> _favoriteReciterIds = {'hassan_saleh', 'afasy', 'maher', 'dosari'};

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _errorSub;

  ReciterProfile get currentReciter => _currentReciter;
  SurahMeta get currentSurah => _currentSurah;
  bool get isPlaying => _audioManager.isPlaying;
  Duration get currentPosition => _audioManager.position;
  Duration get totalDuration => _audioManager.duration ?? Duration.zero;
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
    _posSub = _audioManager.positionStream.listen((pos) {
      notifyListeners();
    });

    _durSub = _audioManager.durationStream.listen((dur) {
      notifyListeners();
    });

    _stateSub = _audioManager.playbackStateStream.listen((state) {
      notifyListeners();
    });

    _errorSub = _audioManager.errorStream.listen((error) {
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
    if (_audioManager.isPlaying) {
      await _playCurrentSurah();
    }
  }

  Future<void> selectSurah(SurahMeta surah) async {
    _currentSurah = surah;
    await _playCurrentSurah();
  }

  Future<void> _playCurrentSurah() async {
    debugPrint('AudioQuranService: Playing surah ${_currentSurah.number} with reciter ${_currentReciter.nameArabic}');
    
    // Check if downloaded first
    final localPath = _downloadManager.getLocalPath(_currentReciter.id, _currentSurah.number);
    final audioUrl = localPath ?? _buildAudioUrl(_currentReciter, _currentSurah.number);
    
    final descriptor = AudioSourceDescriptor(
      type: AudioSourceType.quran,
      url: audioUrl,
      title: _currentSurah.nameArabic,
      subtitle: _currentReciter.nameArabic,
      metadata: {
        'reciterId': _currentReciter.id,
        'surahNumber': _currentSurah.number,
        'isLocal': localPath != null,
      },
    );

    await _audioManager.play(descriptor);
  }

  Future<void> pause() async {
    await _audioManager.pause();
  }

  Future<void> togglePlayPause() async {
    await _audioManager.togglePlayPause();
  }

  Future<void> seekTo(Duration position) async {
    await _audioManager.seek(position);
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
    await _audioManager.setSpeed(speed);
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
    // Use real MP3Quran server URL from reciter data
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final baseUrl = reciter.serverUrl;
    
    if (baseUrl == null || baseUrl.isEmpty) {
      // Fallback to a working server if reciter URL is missing
      debugPrint('Warning: Reciter ${reciter.id} has no server URL, using fallback');
      return 'https://server12.mp3quran.net/afs/$surahStr.mp3';
    }
    
    // Clean and build URL
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBaseUrl/$surahStr.mp3';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _errorSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
