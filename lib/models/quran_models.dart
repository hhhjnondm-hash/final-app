import 'package:flutter/material.dart';

class SurahMeta {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String meaningEnglish;
  final int ayahCount;
  final bool isMeccan;
  final int juzNumber;
  final int pageNumber;
  final List<Color> themeGradients;
  final IconData themeIcon;

  const SurahMeta({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.meaningEnglish,
    required this.ayahCount,
    required this.isMeccan,
    required this.juzNumber,
    required this.pageNumber,
    required this.themeGradients,
    required this.themeIcon,
  });
}

class QuranBookmark {
  final String id;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahSnippet;
  final DateTime createdAt;
  final String? note;

  QuranBookmark({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahSnippet,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'surahName': surahName,
    'ayahNumber': ayahNumber,
    'ayahSnippet': ayahSnippet,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
    id: json['id'] as String,
    surahNumber: json['surahNumber'] as int,
    surahName: json['surahName'] as String,
    ayahNumber: json['ayahNumber'] as int,
    ayahSnippet: json['ayahSnippet'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    note: json['note'] as String?,
  );
}

class ReadingProgress {
  final int lastSurahNumber;
  final String lastSurahName;
  final int lastAyahNumber;
  final int lastJuz;
  final double progressPercentage;
  final DateTime lastReadTime;

  const ReadingProgress({
    this.lastSurahNumber = 2,
    this.lastSurahName = 'البقرة',
    this.lastAyahNumber = 255,
    this.lastJuz = 3,
    this.progressPercentage = 0.08,
    required this.lastReadTime,
  });

  Map<String, dynamic> toJson() => {
    'lastSurahNumber': lastSurahNumber,
    'lastSurahName': lastSurahName,
    'lastAyahNumber': lastAyahNumber,
    'lastJuz': lastJuz,
    'progressPercentage': progressPercentage,
    'lastReadTime': lastReadTime.toIso8601String(),
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) => ReadingProgress(
    lastSurahNumber: json['lastSurahNumber'] as int? ?? 2,
    lastSurahName: json['lastSurahName'] as String? ?? 'البقرة',
    lastAyahNumber: json['lastAyahNumber'] as int? ?? 255,
    lastJuz: json['lastJuz'] as int? ?? 3,
    progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.08,
    lastReadTime: json['lastReadTime'] != null ? DateTime.parse(json['lastReadTime'] as String) : DateTime.now(),
  );
}

class KhatmahPlan {
  final int totalDays;
  final int currentDay;
  final int completedAyahs;
  final DateTime startDate;

  const KhatmahPlan({
    this.totalDays = 30,
    this.currentDay = 7,
    this.completedAyahs = 1450,
    required this.startDate,
  });

  double get progress => (completedAyahs / 6236).clamp(0.0, 1.0);
  int get todayTargetJuz => ((currentDay - 1) % 30) + 1;
}
