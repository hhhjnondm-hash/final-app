import 'package:flutter/material.dart';

enum ReciterCategory {
  popular,
  youth,
  schools,
  all,
  murattal,
  mujawwad,
}

class ReciterProfile {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String country;
  final String style;
  final String photoUrl;
  final int surahCount;
  final ReciterCategory category;
  final String serverUrl;

  const ReciterProfile({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.country,
    required this.style,
    required this.photoUrl,
    this.surahCount = 114,
    this.category = ReciterCategory.popular,
    required this.serverUrl,
  });
}

class AudioSurahTrack {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final int versesCount;
  final Duration duration;

  const AudioSurahTrack({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.versesCount,
    required this.duration,
  });
}
