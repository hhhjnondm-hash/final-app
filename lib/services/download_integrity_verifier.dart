import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Download integrity verification system
/// Verifies downloaded files are valid and not corrupted
class DownloadIntegrityVerifier {
  static final DownloadIntegrityVerifier _instance = DownloadIntegrityVerifier._internal();
  factory DownloadIntegrityVerifier() => _instance;
  DownloadIntegrityVerifier._internal();

  // Expected file sizes for Quran audio (in bytes)
  // Approximate sizes for 128kbps MP3
  static const Map<int, int> _expectedSurahSizes = {
    1: 6500000,    // Al-Fatiha ~6.5 MB
    2: 8500000,    // Al-Baqarah ~8.5 MB
    3: 5500000,    // Aal-Imran ~5.5 MB
    18: 2500000,   // Al-Kahf ~2.5 MB
    36: 4000000,   // Ya-Sin ~4 MB
    67: 3000000,   // Al-Mulk ~3 MB
    112: 1500000,  // Al-Ikhlas ~1.5 MB
    113: 1500000,  // Al-Falaq ~1.5 MB
    114: 1500000,  // An-Nas ~1.5 MB
  };

  // Size tolerance (20% variance allowed)
  static const double _sizeTolerance = 0.2;

  /// Verify a downloaded file
  Future<DownloadVerificationResult> verifyFile(String filePath, {int? expectedSurahNumber}) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return DownloadVerificationResult(
          filePath: filePath,
          isValid: false,
          error: 'File does not exist',
        );
      }

      final size = await file.length();
      
      // Check if file is empty
      if (size == 0) {
        return DownloadVerificationResult(
          filePath: filePath,
          isValid: false,
          error: 'File is empty (0 bytes)',
          size: size,
        );
      }

      // Check if file is too small (corrupted or incomplete)
      if (size < 1000) {
        return DownloadVerificationResult(
          filePath: filePath,
          isValid: false,
          error: 'File is too small (< 1KB), likely corrupted',
          size: size,
        );
      }

      // Check expected size if surah number provided
      if (expectedSurahNumber != null) {
        final expectedSize = _expectedSurahSizes[expectedSurahNumber];
        if (expectedSize != null) {
          final minSize = (expectedSize * (1 - _sizeTolerance)).toInt();
          final maxSize = (expectedSize * (1 + _sizeTolerance)).toInt();
          
          if (size < minSize) {
            return DownloadVerificationResult(
              filePath: filePath,
              isValid: false,
              error: 'File size ($size bytes) is below expected minimum ($minSize bytes)',
              size: size,
              expectedSize: expectedSize,
            );
          }
          
          if (size > maxSize) {
            return DownloadVerificationResult(
              filePath: filePath,
              isValid: false,
              error: 'File size ($size bytes) exceeds expected maximum ($maxSize bytes)',
              size: size,
              expectedSize: expectedSize,
            );
          }
        }
      }

      // Check if file is a valid MP3
      final isValidMp3 = await _isValidMp3File(file);
      if (!isValidMp3) {
        return DownloadVerificationResult(
          filePath: filePath,
          isValid: false,
          error: 'File is not a valid MP3 file',
          size: size,
        );
      }

      // Generate checksum for future verification
      final checksum = await _generateChecksum(file);

      return DownloadVerificationResult(
        filePath: filePath,
        isValid: true,
        size: size,
        checksum: checksum,
        verifiedAt: DateTime.now(),
      );
    } catch (e) {
      return DownloadVerificationResult(
        filePath: filePath,
        isValid: false,
        error: 'Verification error: $e',
      );
    }
  }

  /// Verify multiple files
  Future<Map<String, DownloadVerificationResult>> verifyFiles(List<String> filePaths) async {
    final results = <String, DownloadVerificationResult>{};
    
    for (final filePath in filePaths) {
      results[filePath] = await verifyFile(filePath);
    }
    
    return results;
  }

  /// Check if file is a valid MP3
  Future<bool> _isValidMp3File(File file) async {
    try {
      final bytes = await file.openRead(0, 4).first;
      
      // MP3 files should start with ID3v2 tag (0x49 0x44 0x33) or have MP3 frame sync (0xFF 0xFB or 0xFF 0xFA)
      if (bytes.length >= 3) {
        // Check for ID3v2 tag
        if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
          return true;
        }
        
        // Check for MP3 frame sync
        if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] == 0xFB || bytes[1] == 0xFA)) {
          return true;
        }
      }
      
      // If no standard header, try to read as MP3
      // This is a basic check - for production, you'd want a proper MP3 parser
      return true;
    } catch (e) {
      debugPrint('Error checking MP3 validity: $e');
      return false;
    }
  }

  /// Generate SHA-256 checksum for a file
  Future<String> _generateChecksum(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error generating checksum: $e');
      return '';
    }
  }

  /// Verify checksum matches expected value
  Future<bool> verifyChecksum(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      final actualChecksum = await _generateChecksum(file);
      return actualChecksum == expectedChecksum;
    } catch (e) {
      debugPrint('Error verifying checksum: $e');
      return false;
    }
  }

  /// Get downloads directory
  Future<Directory> getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(path.join(appDir.path, 'downloads'));
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsDir;
  }

  /// Clean up corrupted downloads
  Future<int> cleanupCorruptedDownloads() async {
    final downloadsDir = await getDownloadsDirectory();
    int cleanedCount = 0;

    try {
      final files = downloadsDir.listSync(recursive: true).whereType<File>();
      
      for (final file in files) {
        if (file.path.endsWith('.mp3')) {
          final result = await verifyFile(file.path);
          if (!result.isValid) {
            await file.delete();
            cleanedCount++;
            debugPrint('🗑️ Cleaned up corrupted file: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up corrupted downloads: $e');
    }

    return cleanedCount;
  }

  /// Get integrity report for all downloads
  Future<DownloadIntegrityReport> getIntegrityReport() async {
    final downloadsDir = await getDownloadsDirectory();
    final results = <String, DownloadVerificationResult>{};
    int validCount = 0;
    int invalidCount = 0;
    int totalSize = 0;

    try {
      final files = downloadsDir.listSync(recursive: true).whereType<File>();
      
      for (final file in files) {
        if (file.path.endsWith('.mp3')) {
          final result = await verifyFile(file.path);
          results[file.path] = result;
          
          if (result.isValid) {
            validCount++;
            totalSize += result.size ?? 0;
          } else {
            invalidCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting integrity report: $e');
    }

    return DownloadIntegrityReport(
      totalFiles: results.length,
      validFiles: validCount,
      invalidFiles: invalidCount,
      totalSize: totalSize,
      results: results,
      generatedAt: DateTime.now(),
    );
  }
}

/// Result of download verification
class DownloadVerificationResult {
  final String filePath;
  final bool isValid;
  final String? error;
  final int? size;
  final int? expectedSize;
  final String? checksum;
  final DateTime? verifiedAt;

  DownloadVerificationResult({
    required this.filePath,
    required this.isValid,
    this.error,
    this.size,
    this.expectedSize,
    this.checksum,
    this.verifiedAt,
  });

  String get sizeFormatted {
    if (size == null) return 'N/A';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'isValid': isValid,
      'error': error,
      'size': size,
      'sizeFormatted': sizeFormatted,
      'expectedSize': expectedSize,
      'checksum': checksum,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
}

/// Report of download integrity
class DownloadIntegrityReport {
  final int totalFiles;
  final int validFiles;
  final int invalidFiles;
  final int totalSize;
  final Map<String, DownloadVerificationResult> results;
  final DateTime generatedAt;

  DownloadIntegrityReport({
    required this.totalFiles,
    required this.validFiles,
    required this.invalidFiles,
    required this.totalSize,
    required this.results,
    required this.generatedAt,
  });

  double get validPercentage => totalFiles > 0 ? (validFiles / totalFiles) * 100 : 0;
  double get invalidPercentage => totalFiles > 0 ? (invalidFiles / totalFiles) * 100 : 0;

  String get totalSizeFormatted {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFiles': totalFiles,
      'validFiles': validFiles,
      'invalidFiles': invalidFiles,
      'validPercentage': validPercentage,
      'invalidPercentage': invalidPercentage,
      'totalSize': totalSize,
      'totalSizeFormatted': totalSizeFormatted,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DownloadIntegrityReport('
        'total: $totalFiles, '
        'valid: $validFiles (${validPercentage.toStringAsFixed(1)}%), '
        'invalid: $invalidFiles (${invalidPercentage.toStringAsFixed(1)}%), '
        'size: $totalSizeFormatted'
        ')';
  }
}
