import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// محرك صوتي متقدم مع نظام إعادة المحاولة التلقائي
/// ومعالجة أخطاء شاملة ودعم مصادر متعددة
class AdvancedAudioEngine {
  final AudioPlayer _player = AudioPlayer();
  final Connectivity _connectivity = Connectivity();
  
  // حالة المشغل
  bool _isInitialized = false;
  bool _isRetryInProgress = false;
  int _currentRetryCount = 0;
  static const int _maxRetries = 3;
  
  // قائمة مصادر احتياطية
  final List<String> _backupSources = [];
  int _currentSourceIndex = 0;
  
  // أحداث
  final StreamController<bool> _isPlayingController = StreamController.broadcast();
  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<Duration?> _durationController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  final StreamController<String> _statusController = StreamController.broadcast();
  
  // Getters
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get statusStream => _statusController.stream;
  
  bool get isPlaying => _state == PlayerState.playing;
  Duration get position => _currentPosition;
  Duration? get duration => _currentDuration;
  
  PlayerState _state = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;
  
  AdvancedAudioEngine() {
    _setupPlayerListeners();
  }
  
  /// إعداد مستمعي المشغل
  void _setupPlayerListeners() {
    _player.onPlayerStateChanged.listen((state) {
      _state = state;
      _isPlayingController.add(state == PlayerState.playing);
      _statusController.add(state.name);
      debugPrint('AdvancedAudioEngine: Player state changed to ${state.name}');
    });
    
    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      _positionController.add(pos);
    });
    
    _player.onDurationChanged.listen((dur) {
      if (dur != null && dur.inMilliseconds > 0) {
        _currentDuration = dur;
        _durationController.add(dur);
      }
    });
    
    _player.onPlayerComplete.listen((_) {
      _statusController.add('completed');
      debugPrint('AdvancedAudioEngine: Playback completed');
    });
    
    // audioplayers doesn't have onPlayerError, errors are thrown in play methods
    // We'll handle errors in the try-catch blocks of play methods
  }
  
  /// تهيئة المحرك الصوتي
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = true;
      _statusController.add('initialized');
      debugPrint('AdvancedAudioEngine: Initialized successfully');
      return true;
    } catch (e) {
      _errorController.add('Initialization failed: $e');
      debugPrint('AdvancedAudioEngine: Initialization error - $e');
      return false;
    }
  }
  
  /// فحص الاتصال بالإنترنت
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('AdvancedAudioEngine: Connectivity check failed - $e');
      return true; // افتراض وجود اتصال لتجنب تعطيل التشغيل
    }
  }
  
  /// تشغيل صوت مع مصادر احتياطية
  Future<bool> playWithBackup(
    String primaryUrl, {
    List<String>? backupUrls,
    Duration? startPosition,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _errorController.add('Failed to initialize audio engine');
        return false;
      }
    }
    
    // التحقق من الاتصال
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _errorController.add('No internet connection');
      _statusController.add('no_connection');
      return false;
    }
    
    // إعداد المصادر
    _backupSources.clear();
    _backupSources.add(primaryUrl);
    if (backupUrls != null) {
      _backupSources.addAll(backupUrls);
    }
    _currentSourceIndex = 0;
    
    // محاولة التشغيل مع إعادة المحاولة
    return await _playWithRetry(startPosition);
  }
  
  /// تشغيل مع نظام إعادة المحاولة
  Future<bool> _playWithRetry(Duration? startPosition) async {
    if (_isRetryInProgress) return false;
    _isRetryInProgress = true;
    _currentRetryCount = 0;
    
    try {
      final result = await _attemptPlay(startPosition);
      
      _isRetryInProgress = false;
      return result;
    } catch (e) {
      _isRetryInProgress = false;
      // إذا فشلت جميع المحاولات، جرب المصدر الاحتياطي التالي
      if (_currentSourceIndex < _backupSources.length - 1) {
        _currentSourceIndex++;
        _statusController.add('trying_backup_$_currentSourceIndex');
        debugPrint('AdvancedAudioEngine: Trying backup source $_currentSourceIndex');
        return await _playWithRetry(startPosition);
      } else {
        _errorController.add('All sources failed: $e');
        _statusController.add('all_sources_failed');
        return false;
      }
    }
  }
  
  /// محاولة تشغيل مصدر واحد
  Future<bool> _attemptPlay(Duration? startPosition) async {
    if (_currentSourceIndex >= _backupSources.length) {
      return false;
    }
    
    final url = _backupSources[_currentSourceIndex];
    debugPrint('AdvancedAudioEngine: Attempting to play $url');
    
    try {
      // إيقاف أي تشغيل حالي
      await _player.stop();
      
      // التحقق إذا كان ملف محلي
      if (url.startsWith('assets/')) {
        await _player.play(AssetSource(url));
      } else {
        // التحقق من صحة الرابط
        if (!await _validateUrl(url)) {
          throw Exception('Invalid URL: $url');
        }
        
        // تشغيل الرابط
        await _player.play(UrlSource(url));
      }
      
      if (startPosition != null && startPosition > Duration.zero) {
        await _player.seek(startPosition);
      }
      
      _statusController.add('playing');
      debugPrint('AdvancedAudioEngine: Successfully started playing');
      return true;
    } catch (e) {
      debugPrint('AdvancedAudioEngine: Play attempt failed - $e');
      
      // إعادة المحاولة
      if (_currentRetryCount < _maxRetries) {
        _currentRetryCount++;
        _statusController.add('retrying_$_currentRetryCount');
        debugPrint('AdvancedAudioEngine: Retry attempt $_currentRetryCount');
        await Future.delayed(Duration(seconds: _currentRetryCount));
        return await _attemptPlay(startPosition);
      }
      
      return false;
    }
  }
  
  /// التحقق من صحة الرابط
  Future<bool> _validateUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// معالجة الأخطاء
  void _handleError(String error) {
    debugPrint('AdvancedAudioEngine: Error - $error');
    
    // إذا كان الخطأ يتعلق بالاتصال، حاول مرة أخرى
    if (error.contains('connection') || 
        error.contains('network') || 
        error.contains('socket')) {
      if (!_isRetryInProgress && _currentRetryCount < _maxRetries) {
        _playWithRetry(null);
      }
    }
  }
  
  /// إيقاف مؤقت
  Future<void> pause() async {
    try {
      await _player.pause();
      _statusController.add('paused');
    } catch (e) {
      _errorController.add('Pause failed: $e');
    }
  }
  
  /// إيقاف
  Future<void> stop() async {
    try {
      await _player.stop();
      _statusController.add('stopped');
      _currentRetryCount = 0;
      _isRetryInProgress = false;
    } catch (e) {
      _errorController.add('Stop failed: $e');
    }
  }
  
  /// الانتقال إلى موضع معين
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      _errorController.add('Seek failed: $e');
    }
  }
  
  /// ضبط مستوى الصوت
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _errorController.add('Set volume failed: $e');
    }
  }
  
  /// ضبط السرعة
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setPlaybackRate(speed.clamp(0.5, 2.0));
    } catch (e) {
      _errorController.add('Set speed failed: $e');
    }
  }
  
  /// التكرار
  Future<void> setLoopMode(LoopMode mode) async {
    try {
      if (mode == LoopMode.one) {
        await _player.setReleaseMode(ReleaseMode.loop);
      } else {
        await _player.setReleaseMode(ReleaseMode.release);
      }
    } catch (e) {
      _errorController.add('Set loop mode failed: $e');
    }
  }
  
  /// التخلص من الموارد
  Future<void> dispose() async {
    await _player.dispose();
    await _isPlayingController.close();
    await _positionController.close();
    await _durationController.close();
    await _errorController.close();
    await _statusController.close();
    _isInitialized = false;
  }
}

/// enum for loop mode
enum LoopMode { off, one, all }
