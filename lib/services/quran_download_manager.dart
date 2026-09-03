import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/audio_models.dart';
import '../models/quran_models.dart';
import 'storage_service.dart';
import 'download_integrity_verifier.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadRecord {
  final String id;
  final String reciterId;
  final int surahId;
  final String reciterName;
  final String surahName;
  final String remoteUrl;
  final String? localPath;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  DownloadRecord({
    required this.id,
    required this.reciterId,
    required this.surahId,
    required this.reciterName,
    required this.surahName,
    required this.remoteUrl,
    this.localPath,
    required this.status,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reciterId': reciterId,
      'surahId': surahId,
      'reciterName': reciterName,
      'surahName': surahName,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'status': status.name,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    return DownloadRecord(
      id: json['id'] as String,
      reciterId: json['reciterId'] as String,
      surahId: json['surahId'] as int,
      reciterName: json['reciterName'] as String,
      surahName: json['surahName'] as String,
      remoteUrl: json['remoteUrl'] as String,
      localPath: json['localPath'] as String?,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  DownloadRecord copyWith({
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    String? localPath,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return DownloadRecord(
      id: id,
      reciterId: reciterId,
      surahId: surahId,
      reciterName: reciterName,
      surahName: surahName,
      remoteUrl: remoteUrl,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QuranDownloadManager {
  static final QuranDownloadManager _instance = QuranDownloadManager._internal();
  factory QuranDownloadManager() => _instance;
  QuranDownloadManager._internal();

  final StorageService _storage = StorageService();
  final DownloadIntegrityVerifier _integrityVerifier = DownloadIntegrityVerifier();
  final Map<String, DownloadRecord> _downloads = {};
  final Map<String, http.Client> _activeClients = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  
  static const String _downloadsKey = 'quran_downloads';
  static const int _maxConcurrentDownloads = 3;
  int _activeDownloadCount = 0;

  List<DownloadRecord> get downloads => _downloads.values.toList();
  bool get hasActiveDownloads => _activeDownloadCount > 0;

  Future<void> initialize() async {
    await _storage.init();
    await _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final downloadsJson = _storage.getJson(_downloadsKey);
    if (downloadsJson != null) {
      final downloadsList = downloadsJson['downloads'] as List<dynamic>;
      for (final downloadJson in downloadsList) {
        final record = DownloadRecord.fromJson(downloadJson as Map<String, dynamic>);
        _downloads[record.id] = record;
        
        // Reset failed downloads to queued on app restart
        if (record.isFailed) {
          _downloads[record.id] = record.copyWith(status: DownloadStatus.queued);
        }
      }
    }
  }

  Future<void> _saveDownloads() async {
    final downloadsList = _downloads.values.map((d) => d.toJson()).toList();
    await _storage.setJson(_downloadsKey, {'downloads': downloadsList});
  }

  String _generateDownloadId(String reciterId, int surahId) {
    return '${reciterId}_$surahId';
  }

  Future<Directory> _getDownloadsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${directory.path}/quran_downloads');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }
    return quranDir;
  }

  Future<String> _getLocalFilePath(String reciterId, int surahId) async {
    final directory = await _getDownloadsDirectory();
    return '${directory.path}/${reciterId}_surah_$surahId.mp3';
  }

  bool isDownloaded(String reciterId, int surahId) {
    final id = _generateDownloadId(reciterId, surahId);
    final record = _downloads[id];
    if (record?.isCompleted != true) return false;
    
    // Additional check: verify file still exists
    final localPath = record?.localPath;
    if (localPath == null) return false;
    
    final file = File(localPath);
    return file.existsSync();
  }

  String? getLocalPath(String reciterId, int surahId) {
    final id = _generateDownloadId(reciterId, surahId);
    return _downloads[id]?.localPath;
  }

  DownloadRecord? getDownloadRecord(String reciterId, int surahId) {
    final id = _generateDownloadId(reciterId, surahId);
    return _downloads[id];
  }

  Future<DownloadRecord?> downloadSurah({
    required ReciterProfile reciter,
    required SurahMeta surah,
    required String audioUrl,
  }) async {
    final id = _generateDownloadId(reciter.id, surah.number);
    
    // Check if already downloaded
    if (_downloads.containsKey(id) && _downloads[id]!.isCompleted) {
      return _downloads[id];
    }

    // Check if file exists on disk
    final localPath = await _getLocalFilePath(reciter.id, surah.number);
    final file = File(localPath);
    if (await file.exists()) {
      final record = DownloadRecord(
        id: id,
        reciterId: reciter.id,
        surahId: surah.number,
        reciterName: reciter.nameArabic,
        surahName: surah.nameArabic,
        remoteUrl: audioUrl,
        localPath: localPath,
        status: DownloadStatus.completed,
        downloadedBytes: await file.length(),
        totalBytes: await file.length(),
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      _downloads[id] = record;
      await _saveDownloads();
      return record;
    }

    // Create new download record
    final record = DownloadRecord(
      id: id,
      reciterId: reciter.id,
      surahId: surah.number,
      reciterName: reciter.nameArabic,
      surahName: surah.nameArabic,
      remoteUrl: audioUrl,
      status: DownloadStatus.queued,
      downloadedBytes: 0,
      totalBytes: 0,
      createdAt: DateTime.now(),
    );
    _downloads[id] = record;
    await _saveDownloads();

    // Start download if under concurrent limit
    if (_activeDownloadCount < _maxConcurrentDownloads) {
      _startDownload(id);
    }

    return record;
  }

  Future<void> _startDownload(String id) async {
    final record = _downloads[id];
    if (record == null || record.isDownloading) return;

    _activeDownloadCount++;
    _downloads[id] = record.copyWith(status: DownloadStatus.downloading);
    await _saveDownloads();

    try {
      final localPath = await _getLocalFilePath(record.reciterId, record.surahId);
      final tempPath = '$localPath.temp';
      
      final client = http.Client();
      _activeClients[id] = client;

      final request = http.Request('GET', Uri.parse(record.remoteUrl));
      
      // Check if file already exists (resume support)
      int resumeFrom = 0;
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        resumeFrom = await tempFile.length();
        request.headers.addAll({'Range': 'bytes=$resumeFrom-'});
      }

      final response = await client.send(request);
      
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final totalBytes = resumeFrom + contentLength;

      _downloads[id] = record.copyWith(
        totalBytes: totalBytes,
        downloadedBytes: resumeFrom,
      );
      await _saveDownloads();

      final sink = tempFile.openWrite(mode: FileMode.append);
      
      final subscription = response.stream.listen(
        (data) {
          sink.add(data);
          _downloads[id] = _downloads[id]!.copyWith(
            downloadedBytes: _downloads[id]!.downloadedBytes + data.length,
          );
          _saveDownloads();
        },
        onDone: () async {
          await sink.close();
          
          // Verify file integrity
          final finalFile = File(localPath);
          if (await tempFile.exists()) {
            await tempFile.rename(localPath);
          }
          
          if (await finalFile.exists() && await finalFile.length() > 0) {
            // Verify file integrity
            final verification = await _integrityVerifier.verifyFile(
              localPath,
              expectedSurahNumber: record.surahId,
            );
            
            if (verification.isValid) {
              _downloads[id] = _downloads[id]!.copyWith(
                status: DownloadStatus.completed,
                localPath: localPath,
                completedAt: DateTime.now(),
                downloadedBytes: verification.size ?? totalBytes,
              );
              debugPrint('✅ Download verified: $localPath (${verification.sizeFormatted})');
            } else {
              // File is corrupted, delete it
              await finalFile.delete();
              _downloads[id] = _downloads[id]!.copyWith(
                status: DownloadStatus.failed,
                errorMessage: 'File integrity check failed: ${verification.error}',
              );
              debugPrint('❌ Download failed integrity check: ${verification.error}');
            }
          } else {
            _downloads[id] = _downloads[id]!.copyWith(
              status: DownloadStatus.failed,
              errorMessage: 'File verification failed',
            );
          }
          
          await _saveDownloads();
          _cleanupDownload(id);
        },
        onError: (error) async {
          await sink.close();
          _downloads[id] = _downloads[id]!.copyWith(
            status: DownloadStatus.failed,
            errorMessage: error.toString(),
          );
          await _saveDownloads();
          _cleanupDownload(id);
        },
        cancelOnError: false,
      );

      _activeSubscriptions[id] = subscription;
    } catch (e) {
      _downloads[id] = _downloads[id]!.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      await _saveDownloads();
      _cleanupDownload(id);
    }
  }

  Future<void> pauseDownload(String reciterId, int surahId) async {
    final id = _generateDownloadId(reciterId, surahId);
    final record = _downloads[id];
    if (record == null || !record.isDownloading) return;

    await _cancelDownload(id);
    _downloads[id] = record.copyWith(status: DownloadStatus.paused);
    await _saveDownloads();
  }

  Future<void> resumeDownload(String reciterId, int surahId) async {
    final id = _generateDownloadId(reciterId, surahId);
    final record = _downloads[id];
    if (record == null || !record.isPaused) return;

    _downloads[id] = record.copyWith(status: DownloadStatus.queued);
    await _saveDownloads();

    if (_activeDownloadCount < _maxConcurrentDownloads) {
      _startDownload(id);
    }
  }

  Future<void> cancelDownload(String reciterId, int surahId) async {
    final id = _generateDownloadId(reciterId, surahId);
    final record = _downloads[id];
    if (record == null) return;

    await _cancelDownload(id);
    
    // Delete temp file
    final localPath = await _getLocalFilePath(reciterId, surahId);
    final tempFile = File('$localPath.temp');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    _downloads.remove(id);
    await _saveDownloads();
  }

  Future<void> _cancelDownload(String id) async {
    await _activeSubscriptions[id]?.cancel();
    _activeSubscriptions.remove(id);
    final client = _activeClients[id];
    if (client != null) {
      client.close();
    }
    _activeClients.remove(id);
    _activeDownloadCount--;
  }

  Future<void> _cleanupDownload(String id) async {
    await _cancelDownload(id);
    
    // Start next queued download
    final queued = _downloads.values
        .where((d) => d.status == DownloadStatus.queued)
        .toList();
    
    if (queued.isNotEmpty && _activeDownloadCount < _maxConcurrentDownloads) {
      _startDownload(queued.first.id);
    }
  }

  Future<void> deleteDownload(String reciterId, int surahId) async {
    final id = _generateDownloadId(reciterId, surahId);
    final record = _downloads[id];
    if (record == null) return;

    // Cancel if downloading
    if (record.isDownloading) {
      await _cancelDownload(id);
    }

    // Delete local file
    if (record.localPath != null) {
      final file = File(record.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _downloads.remove(id);
    await _saveDownloads();
  }

  Future<void> clearAllDownloads() async {
    // Cancel all active downloads
    for (final id in _activeSubscriptions.keys) {
      await _cancelDownload(id);
    }

    // Delete all local files
    for (final record in _downloads.values) {
      if (record.localPath != null) {
        final file = File(record.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    _downloads.clear();
    await _saveDownloads();
  }

  /// Verify all downloaded files for integrity
  Future<DownloadIntegrityReport> verifyAllDownloads() async {
    return await _integrityVerifier.getIntegrityReport();
  }

  /// Clean up corrupted downloads
  Future<int> cleanupCorruptedDownloads() async {
    return await _integrityVerifier.cleanupCorruptedDownloads();
  }

  Future<int> getTotalDownloadSize() async {
    int totalSize = 0;
    for (final record in _downloads.values) {
      if (record.localPath != null) {
        final file = File(record.localPath!);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
    }
    return totalSize;
  }

  Future<int> getCacheSize() async {
    final directory = await _getDownloadsDirectory();
    if (!await directory.exists()) return 0;
    
    int totalSize = 0;
    await for (final entity in directory.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  Stream<DownloadRecord> downloadProgress(String reciterId, int surahId) {
    final id = _generateDownloadId(reciterId, surahId);
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return _downloads[id];
    }).where((record) => record != null).map((record) => record!);
  }

  void dispose() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    for (final client in _activeClients.values) {
      client.close();
    }
    _activeSubscriptions.clear();
    _activeClients.clear();
  }
}
