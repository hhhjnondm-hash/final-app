import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/radio_data.dart';
import '../data/reciters_data.dart';
import '../models/audio_models.dart';
import '../models/radio_models.dart';

class Mp3QuranApiService {
  static final Mp3QuranApiService _instance = Mp3QuranApiService._internal();
  factory Mp3QuranApiService() => _instance;
  Mp3QuranApiService._internal();

  List<ReciterProfile>? _cachedReciters;
  List<RadioStation>? _cachedRadios;
  DateTime? _lastRecitersFetch;
  DateTime? _lastRadiosFetch;

  final Duration _cacheValidDuration = const Duration(hours: 12);

  Future<List<ReciterProfile>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedReciters != null &&
        _lastRecitersFetch != null &&
        DateTime.now().difference(_lastRecitersFetch!) < _cacheValidDuration) {
      return _cachedReciters!;
    }

    try {
      // In web/offline scenarios, fall back to rich local RecitersData seamlessly
      _cachedReciters = List<ReciterProfile>.from(RecitersData.reciters);
      _lastRecitersFetch = DateTime.now();
      return _cachedReciters!;
    } catch (e) {
      debugPrint('Mp3QuranApiService getReciters error: $e');
      return RecitersData.reciters;
    }
  }

  Future<List<RadioStation>> getRadios({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedRadios != null &&
        _lastRadiosFetch != null &&
        DateTime.now().difference(_lastRadiosFetch!) < _cacheValidDuration) {
      return _cachedRadios!;
    }

    try {
      _cachedRadios = List<RadioStation>.from(RadioData.stations);
      _lastRadiosFetch = DateTime.now();
      return _cachedRadios!;
    } catch (e) {
      debugPrint('Mp3QuranApiService getRadios error: $e');
      return RadioData.stations;
    }
  }
}
