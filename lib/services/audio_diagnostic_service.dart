import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AudioDiagnosticService {
  static final AudioDiagnosticService _instance = AudioDiagnosticService._internal();
  factory AudioDiagnosticService() => _instance;
  AudioDiagnosticService._internal();

  final AudioPlayer _testPlayer = AudioPlayer();

  Future<Map<String, dynamic>> diagnoseAudioSystem() async {
    final results = <String, dynamic>{};

    // 1. Check Internet Connection
    results['internet_connection'] = await _checkInternetConnection();

    // 2. Test Audio Player Initialization
    results['audio_player_init'] = await _testAudioPlayerInit();

    // 3. Test Known Working URL
    results['known_url_test'] = await _testKnownUrl();

    // 4. Test Quran API URL
    results['quran_api_test'] = await _testQuranApiUrl();

    // 5. Test Radio Stream URL
    results['radio_stream_test'] = await _testRadioStreamUrl();

    return results;
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking internet: $e');
      return false;
    }
  }

  Future<bool> _testAudioPlayerInit() async {
    try {
      await _testPlayer.stop();
      return true;
    } catch (e) {
      debugPrint('Audio player init failed: $e');
      return false;
    }
  }

  Future<bool> _testKnownUrl() async {
    try {
      // Test with a known working MP3 file
      final testUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      await _testPlayer.setUrl(testUrl);
      await _testPlayer.play();
      await Future.delayed(const Duration(seconds: 2));
      
      final state = _testPlayer.playerState;
      await _testPlayer.stop();
      
      return state.playing;
    } catch (e) {
      debugPrint('Known URL test failed: $e');
      return false;
    }
  }

  Future<bool> _testQuranApiUrl() async {
    try {
      // Test with a Quran API URL
      final testUrl = 'https://server8.mp3quran.net/afs/001.mp3';
      await _testPlayer.setUrl(testUrl);
      await _testPlayer.play();
      await Future.delayed(const Duration(seconds: 3));
      
      final state = _testPlayer.playerState;
      await _testPlayer.stop();
      
      return state.playing;
    } catch (e) {
      debugPrint('Quran API URL test failed: $e');
      return false;
    }
  }

  Future<bool> _testRadioStreamUrl() async {
    try {
      // Test with a radio stream URL
      final testUrl = 'https://stream.radiojar.com/8s5u5tpdtwzuv';
      await _testPlayer.setUrl(testUrl);
      await _testPlayer.play();
      await Future.delayed(const Duration(seconds: 3));
      
      final state = _testPlayer.playerState;
      await _testPlayer.stop();
      
      return state.playing;
    } catch (e) {
      debugPrint('Radio stream URL test failed: $e');
      return false;
    }
  }

  Future<void> release() async {
    await _testPlayer.dispose();
  }

  static String getDiagnosticMessage(Map<String, dynamic> results) {
    final messages = <String>[];
    
    if (results['internet_connection'] == false) {
      messages.add('❌ لا يوجد اتصال بالإنترنت');
    } else {
      messages.add('✅ الاتصال بالإنترنت يعمل');
    }
    
    if (results['audio_player_init'] == false) {
      messages.add('❌ مشكلة في تهيئة مشغل الصوت');
    } else {
      messages.add('✅ مشغل الصوت يعمل');
    }
    
    if (results['known_url_test'] == false) {
      messages.add('❌ مشكلة في تشغيل الملفات الصوتية المعروفة');
    } else {
      messages.add('✅ تشغيل الملفات الصوتية يعمل');
    }
    
    if (results['quran_api_test'] == false) {
      messages.add('❌ مشكلة في روابط API القرآن');
    } else {
      messages.add('✅ روابط API القرآن تعمل');
    }
    
    if (results['radio_stream_test'] == false) {
      messages.add('❌ مشكلة في روابط الإذاعة');
    } else {
      messages.add('✅ روابط الإذاعة تعمل');
    }
    
    return messages.join('\n');
  }
}