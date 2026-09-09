import 'package:flutter/material.dart';

enum AzkarCategoryType {
  morning,
  evening,
  afterPrayer,
  sleep,
  wakingUp,
  general,
  propheticHadiths,
  mosque,
}

class DhikrItem {
  final String id;
  final AzkarCategoryType category;
  final String title;
  final String text;
  final int targetRepetitions;
  final String repetitionText;
  final String? fadl;
  final String? source;
  final String? meaning;

  const DhikrItem({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
    required this.targetRepetitions,
    this.repetitionText = 'مرة واحدة',
    this.fadl,
    this.source,
    this.meaning,
  });
}

class AzkarCategoryMeta {
  final AzkarCategoryType type;
  final String titleArabic;
  final String titleEnglish;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;

  const AzkarCategoryMeta({
    required this.type,
    required this.titleArabic,
    required this.titleEnglish,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
  });
}

class DhikrWirdProgress {
  final int completedToday;
  final int totalToday;
  final String lastReadDhikrId;
  final AzkarCategoryType lastCategory;
  final int streakDays;

  const DhikrWirdProgress({
    this.completedToday = 14,
    this.totalToday = 21,
    this.lastReadDhikrId = 'morning_7',
    this.lastCategory = AzkarCategoryType.morning,
    this.streakDays = 7,
  });

  double get percentage => (totalToday > 0 ? completedToday / totalToday : 0.0).clamp(0.0, 1.0);
}
