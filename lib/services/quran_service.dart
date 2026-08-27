import 'package:flutter/services.dart';
import 'dart:convert';

class QuranService {
  static Map<int, List<Map<String, dynamic>>>? _quranData;
  static Map<int, Map<String, dynamic>>? _surahInfo;

  static Future<void> loadQuranData() async {
    if (_quranData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/quran-simple.txt');
      final List<String> lines = response.split('\n');

      _quranData = {};
      _surahInfo = {};

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.split('|');
        if (parts.length >= 3) {
          final surahNumber = int.tryParse(parts[0]) ?? 1;
          final ayahNumber = int.tryParse(parts[1]) ?? 1;
          final ayahText = parts[2];

          if (!_quranData!.containsKey(surahNumber)) {
            _quranData![surahNumber] = [];
          }

          _quranData![surahNumber]!.add({
            'ayahNumber': ayahNumber,
            'text': ayahText,
          });

          // Update surah info
          if (!_surahInfo!.containsKey(surahNumber)) {
            _surahInfo![surahNumber] = {
              'ayahCount': 0,
            };
          }
          _surahInfo![surahNumber]!['ayahCount'] = _quranData![surahNumber]!.length;
        }
      }
    } catch (e) {
      print('Error loading Quran data: $e');
    }
  }

  static List<Map<String, dynamic>>? getSurahAyahs(int surahNumber) {
    return _quranData?[surahNumber];
  }

  static int? getSurahAyahCount(int surahNumber) {
    return _surahInfo?[surahNumber]?['ayahCount'];
  }

  static Map<String, dynamic>? getSurahInfo(int surahNumber) {
    return _surahInfo?[surahNumber];
  }

  static String? getAyahText(int surahNumber, int ayahNumber) {
    final ayahs = _quranData?[surahNumber];
    if (ayahs == null) return null;

    for (final ayah in ayahs) {
      if (ayah['ayahNumber'] == ayahNumber) {
        return ayah['text'];
      }
    }
    return null;
  }
}
