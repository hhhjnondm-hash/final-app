import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/quran_metadata.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import '../models/download_queue_models.dart';
import 'download_helper.dart';
import 'quran_download_manager.dart';

class QuranAudioDownloader extends ChangeNotifier {
  static final QuranAudioDownloader _instance = QuranAudioDownloader._internal();
  factory QuranAudioDownloader() => _instance;
  QuranAudioDownloader._internal();

  final QuranDownloadManager _downloadManager = QuranDownloadManager();

  final List<DownloadQueueItem> _queue = [];
  bool _isDownloading = false;
  String _activeTitle = '';
  int _currentIndex = 0;
  bool _cancelRequested = false;

  List<DownloadQueueItem> get queue => List.unmodifiable(_queue);
  bool get isDownloading => _isDownloading;
  String get activeTitle => _activeTitle;
  int get currentIndex => _currentIndex;
  int get completedCount => _queue.where((item) => item.status == SurahDownloadStatus.completed).length;
  int get totalCount => _queue.length;

  double get overallProgress {
    if (_queue.isEmpty) return 0.0;
    double sum = 0.0;
    for (final item in _queue) {
      if (item.status == SurahDownloadStatus.completed) {
        sum += 1.0;
      } else if (item.status == SurahDownloadStatus.downloading) {
        sum += item.progress;
      }
    }
    return (sum / _queue.length).clamp(0.0, 1.0);
  }

  /// Build standard MP3 URL for a reciter and Surah
  String buildAudioUrl(ReciterProfile reciter, int surahNumber) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final baseUrl = reciter.serverUrl;
    if (baseUrl.isEmpty) {
      return 'https://server8.mp3quran.net/afs/$surahStr.mp3';
    }
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBaseUrl/$surahStr.mp3';
  }

  /// Start downloading a single Surah and manage its live log item
  Future<bool> downloadSingleSurah({
    required ReciterProfile reciter,
    required SurahMeta surah,
    Function(double progress)? onProgress,
  }) async {
    _cancelRequested = false;
    _isDownloading = true;
    _activeTitle = 'تنزيل سورة ${surah.nameArabic} - ${reciter.nameArabic}';

    final audioUrl = buildAudioUrl(reciter, surah.number);
    final fileName = '${surah.number.toString().padLeft(3, '0')}_سورة_${surah.nameArabic}_${reciter.nameArabic}.mp3';

    // Add or update item in queue
    final queueItem = DownloadQueueItem(
      surahNumber: surah.number,
      surahName: surah.nameArabic,
      reciterId: reciter.id,
      reciterName: reciter.nameArabic,
      audioUrl: audioUrl,
      status: SurahDownloadStatus.downloading,
    );

    // If starting fresh queue
    _queue.clear();
    _queue.add(queueItem);
    _currentIndex = 0;
    notifyListeners();

    try {
      final success = await platformDownloadFile(
        audioUrl,
        fileName,
        reciterName: reciter.nameArabic,
        onProgress: (progress, received, total) {
          queueItem.progress = progress;
          queueItem.receivedBytes = received;
          queueItem.totalBytes = total;
          if (onProgress != null) onProgress(progress);
          notifyListeners();
        },
      );

      if (success) {
        queueItem.status = SurahDownloadStatus.completed;
        queueItem.progress = 1.0;
        await _downloadManager.downloadSurah(
          reciter: reciter,
          surah: surah,
          audioUrl: audioUrl,
        );
      } else {
        queueItem.status = SurahDownloadStatus.failed;
      }

      _isDownloading = false;
      notifyListeners();
      return success;
    } catch (e) {
      queueItem.status = SurahDownloadStatus.failed;
      queueItem.errorMessage = e.toString();
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// Start downloading Full Quran (114 Surahs) with complete interactive queue
  Future<void> downloadFullQuran({
    required ReciterProfile reciter,
    Function(int current, int total, String surahName, double currentSurahProgress)? onProgress,
    Function(int successfulCount, int failedCount)? onCompleted,
  }) async {
    if (_isDownloading) return;

    _cancelRequested = false;
    _isDownloading = true;
    _activeTitle = 'تنزيل المصحف كاملًا - ${reciter.nameArabic}';
    _queue.clear();

    final allSurahs = QuranMetadataProvider.getAllSurahs();

    // Populate all 114 Surahs in queue with initial waiting status
    for (final surah in allSurahs) {
      final isAlreadyDownloaded = _downloadManager.isDownloaded(reciter.id, surah.number);
      _queue.add(
        DownloadQueueItem(
          surahNumber: surah.number,
          surahName: surah.nameArabic,
          reciterId: reciter.id,
          reciterName: reciter.nameArabic,
          audioUrl: buildAudioUrl(reciter, surah.number),
          status: isAlreadyDownloaded ? SurahDownloadStatus.completed : SurahDownloadStatus.waiting,
          progress: isAlreadyDownloaded ? 1.0 : 0.0,
        ),
      );
    }

    notifyListeners();

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < _queue.length; i++) {
      if (_cancelRequested) {
        // Mark remaining waiting items as cancelled
        for (int j = i; j < _queue.length; j++) {
          if (_queue[j].status == SurahDownloadStatus.waiting) {
            _queue[j].status = SurahDownloadStatus.cancelled;
          }
        }
        break;
      }

      final item = _queue[i];
      _currentIndex = i;

      // Skip already completed surahs
      if (item.status == SurahDownloadStatus.completed) {
        successCount++;
        continue;
      }

      item.status = SurahDownloadStatus.downloading;
      notifyListeners();

      final surah = allSurahs.firstWhere((s) => s.number == item.surahNumber);
      final fileName = '${surah.number.toString().padLeft(3, '0')}_سورة_${surah.nameArabic}_${reciter.nameArabic}.mp3';

      if (onProgress != null) {
        onProgress(i + 1, allSurahs.length, surah.nameArabic, 0.0);
      }

      final success = await platformDownloadFile(
        item.audioUrl,
        fileName,
        reciterName: reciter.nameArabic,
        onProgress: (prog, received, total) {
          item.progress = prog;
          item.receivedBytes = received;
          item.totalBytes = total;
          if (onProgress != null) {
            onProgress(i + 1, allSurahs.length, surah.nameArabic, prog);
          }
          notifyListeners();
        },
      );

      if (success) {
        item.status = SurahDownloadStatus.completed;
        item.progress = 1.0;
        successCount++;
        await _downloadManager.downloadSurah(
          reciter: reciter,
          surah: surah,
          audioUrl: item.audioUrl,
        );
      } else {
        item.status = SurahDownloadStatus.failed;
        failCount++;
      }

      notifyListeners();
    }

    _isDownloading = false;
    notifyListeners();

    if (onCompleted != null) {
      onCompleted(successCount, failCount);
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
    _isDownloading = false;
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _isDownloading = false;
    notifyListeners();
  }
}
