import 'package:flutter/material.dart';

enum HadithCategory {
  all,
  books,
  fiqh,
  manners,
  dua,
  asceticism,
  faith,
}

class HadithItem {
  final String id;
  final int number;
  final String text;
  final String narrator;
  final String book;
  final String chapter;
  final String grade;
  final String explanation;
  final HadithCategory category;
  final String topic;

  const HadithItem({
    required this.id,
    required this.number,
    required this.text,
    required this.narrator,
    required this.book,
    required this.chapter,
    this.grade = 'صحيح',
    this.explanation = '',
    this.category = HadithCategory.manners,
    this.topic = 'عام',
  });
}

class HadithBook {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String author;
  final int hadithCount;
  final IconData icon;

  const HadithBook({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.author,
    required this.hadithCount,
    this.icon = Icons.menu_book_rounded,
  });
}
