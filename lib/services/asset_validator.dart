import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Asset validation system
/// Validates that local assets exist and are accessible
class AssetValidator {
  static final AssetValidator _instance = AssetValidator._internal();
  factory AssetValidator() => _instance;
  AssetValidator._internal();

  // Validation cache
  final Map<String, bool> _validationCache = {};
  final Map<String, FileValidationResult> _detailedCache = {};
  DateTime? _lastValidation;
  static const Duration _cacheValidDuration = Duration(hours: 1);

  /// Validate a single asset
  Future<bool> validateAsset(String assetPath) async {
    // Check cache first
    if (_validationCache.containsKey(assetPath)) {
      final cachedAt = _lastValidation;
      if (cachedAt != null && DateTime.now().difference(cachedAt) < _cacheValidDuration) {
        return _validationCache[assetPath]!;
      }
    }

    try {
      // Try to load the asset to verify it exists
      final byteData = await rootBundle.load(assetPath);
      final isValid = byteData.lengthInBytes > 0;
      
      _validationCache[assetPath] = isValid;
      _lastValidation = DateTime.now();
      
      if (!isValid) {
        debugPrint('⚠️ Asset validation failed: $assetPath (0 bytes)');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('❌ Asset validation error for $assetPath: $e');
      _validationCache[assetPath] = false;
      _lastValidation = DateTime.now();
      return false;
    }
  }

  /// Validate asset with detailed information
  Future<FileValidationResult> validateAssetDetailed(String assetPath) async {
    // Check cache first
    if (_detailedCache.containsKey(assetPath)) {
      final cachedAt = _lastValidation;
      if (cachedAt != null && DateTime.now().difference(cachedAt) < _cacheValidDuration) {
        return _detailedCache[assetPath]!;
      }
    }

    try {
      final byteData = await rootBundle.load(assetPath);
      final size = byteData.lengthInBytes;
      final isValid = size > 0;
      
      final result = FileValidationResult(
        path: assetPath,
        isValid: isValid,
        size: size,
        lastValidated: DateTime.now(),
        error: isValid ? null : 'File is empty (0 bytes)',
      );
      
      _detailedCache[assetPath] = result;
      _validationCache[assetPath] = isValid;
      _lastValidation = DateTime.now();
      
      return result;
    } catch (e) {
      final result = FileValidationResult(
        path: assetPath,
        isValid: false,
        size: 0,
        lastValidated: DateTime.now(),
        error: e.toString(),
      );
      
      _detailedCache[assetPath] = result;
      _validationCache[assetPath] = false;
      _lastValidation = DateTime.now();
      
      return result;
    }
  }

  /// Validate multiple assets
  Future<Map<String, bool>> validateAssets(List<String> assetPaths) async {
    final results = <String, bool>{};
    
    for (final assetPath in assetPaths) {
      results[assetPath] = await validateAsset(assetPath);
    }
    
    return results;
  }

  /// Validate all reciter images
  Future<AssetValidationReport> validateReciterImages(List<String> reciterIds) async {
    final results = <String, FileValidationResult>{};
    int validCount = 0;
    int invalidCount = 0;
    final List<String> invalidPaths = [];

    for (final reciterId in reciterIds) {
      // Assume images are in assets/reciters/
      final imagePath = 'assets/reciters/${reciterId}.webP';
      final result = await validateAssetDetailed(imagePath);
      
      results[reciterId] = result;
      
      if (result.isValid) {
        validCount++;
      } else {
        invalidCount++;
        invalidPaths.add(imagePath);
      }
    }

    return AssetValidationReport(
      totalAssets: reciterIds.length,
      validAssets: validCount,
      invalidAssets: invalidCount,
      invalidPaths: invalidPaths,
      results: results,
      validatedAt: DateTime.now(),
    );
  }

  /// Validate local downloaded files
  Future<FileValidationResult> validateLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return FileValidationResult(
          path: filePath,
          isValid: false,
          size: 0,
          lastValidated: DateTime.now(),
          error: 'File does not exist',
        );
      }

      final size = await file.length();
      final isValid = size > 0;

      return FileValidationResult(
        path: filePath,
        isValid: isValid,
        size: size,
        lastValidated: DateTime.now(),
        error: isValid ? null : 'File is empty (0 bytes)',
      );
    } catch (e) {
      return FileValidationResult(
        path: filePath,
        isValid: false,
        size: 0,
        lastValidated: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Get app directory for local files
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get downloads directory
  Future<Directory> getDownloadsDirectory() async {
    final appDir = await getAppDirectory();
    final downloadsDir = Directory(path.join(appDir.path, 'downloads'));
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsDir;
  }

  /// Validate all downloaded audio files
  Future<AssetValidationReport> validateDownloadedFiles() async {
    final downloadsDir = await getDownloadsDirectory();
    final results = <String, FileValidationResult>{};
    int validCount = 0;
    int invalidCount = 0;
    final List<String> invalidPaths = [];

    try {
      final files = downloadsDir.listSync(recursive: true).whereType<File>();
      
      for (final file in files) {
        final result = await validateLocalFile(file.path);
        results[file.path] = result;
        
        if (result.isValid) {
          validCount++;
        } else {
          invalidCount++;
          invalidPaths.add(file.path);
        }
      }
    } catch (e) {
      debugPrint('❌ Error validating downloaded files: $e');
    }

    return AssetValidationReport(
      totalAssets: results.length,
      validAssets: validCount,
      invalidAssets: invalidCount,
      invalidPaths: invalidPaths,
      results: results,
      validatedAt: DateTime.now(),
    );
  }

  /// Clean up invalid cached files
  Future<int> cleanupInvalidFiles(List<String> paths) async {
    int cleanedCount = 0;

    for (final filePath in paths) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          cleanedCount++;
          debugPrint('🗑️ Cleaned up invalid file: $filePath');
        }
      } catch (e) {
        debugPrint('❌ Error cleaning up file $filePath: $e');
      }
    }

    return cleanedCount;
  }

  /// Clear validation cache
  void clearCache() {
    _validationCache.clear();
    _detailedCache.clear();
    _lastValidation = null;
    debugPrint('🗑️ Asset validation cache cleared');
  }

  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'cachedAssets': _validationCache.length,
      'detailedResults': _detailedCache.length,
      'lastValidation': _lastValidation?.toIso8601String(),
      'isCacheValid': _lastValidation != null &&
          DateTime.now().difference(_lastValidation!) < _cacheValidDuration,
    };
  }
}

/// Result of file validation
class FileValidationResult {
  final String path;
  final bool isValid;
  final int size;
  final DateTime lastValidated;
  final String? error;

  FileValidationResult({
    required this.path,
    required this.isValid,
    required this.size,
    required this.lastValidated,
    this.error,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'isValid': isValid,
      'size': size,
      'sizeFormatted': sizeFormatted,
      'lastValidated': lastValidated.toIso8601String(),
      'error': error,
    };
  }
}

/// Report of asset validation
class AssetValidationReport {
  final int totalAssets;
  final int validAssets;
  final int invalidAssets;
  final List<String> invalidPaths;
  final Map<String, FileValidationResult> results;
  final DateTime validatedAt;

  AssetValidationReport({
    required this.totalAssets,
    required this.validAssets,
    required this.invalidAssets,
    required this.invalidPaths,
    required this.results,
    required this.validatedAt,
  });

  double get validPercentage => totalAssets > 0 ? (validAssets / totalAssets) * 100 : 0;
  double get invalidPercentage => totalAssets > 0 ? (invalidAssets / totalAssets) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'totalAssets': totalAssets,
      'validAssets': validAssets,
      'invalidAssets': invalidAssets,
      'validPercentage': validPercentage,
      'invalidPercentage': invalidPercentage,
      'invalidPaths': invalidPaths,
      'validatedAt': validatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AssetValidationReport('
        'total: $totalAssets, '
        'valid: $validAssets (${validPercentage.toStringAsFixed(1)}%), '
        'invalid: $invalidAssets (${invalidPercentage.toStringAsFixed(1)}%)'
        ')';
  }
}
