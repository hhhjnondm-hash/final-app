import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/quran_models.dart';

class QuranStorageService extends ChangeNotifier {
  static final QuranStorageService _instance = QuranStorageService._internal();
  factory QuranStorageService() => _instance;
  QuranStorageService._internal();

  ReadingProgress _readingProgress = ReadingProgress(
    lastSurahNumber: 2,
    lastSurahName: 'البقرة',
    lastAyahNumber: 255,
    lastJuz: 3,
    progressPercentage: 0.12,
    lastReadTime: DateTime.now(),
  );

  final List<QuranBookmark> _bookmarks = [
    QuranBookmark(
      id: 'bm_1',
      surahNumber: 2,
      surahName: 'البقرة',
      ayahNumber: 255,
      ayahSnippet: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      note: 'آية الكرسي - حفظ وعظمة',
    ),
    QuranBookmark(
      id: 'bm_2',
      surahNumber: 18,
      surahName: 'الكهف',
      ayahNumber: 1,
      ayahSnippet: 'الْحَمْدُ لِلَّهِ الَّذِي أَنزَلَ عَلَىٰ عَبْدِهِ الْكِتَابَ وَلَمْ يَجْعَل لَّهُ عِوَجًا',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      note: 'ورد يوم الجمعة',
    ),
    QuranBookmark(
      id: 'bm_3',
      surahNumber: 67,
      surahName: 'الملك',
      ayahNumber: 1,
      ayahSnippet: 'تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      note: 'المنجية من عذاب القبر',
    ),
  ];

  KhatmahPlan _khatmahPlan = KhatmahPlan(
    totalDays: 30,
    currentDay: 8,
    completedAyahs: 1680,
    startDate: DateTime.now().subtract(const Duration(days: 8)),
  );

  final Set<int> _favoriteSurahs = {1, 2, 18, 36, 55, 56, 67, 112, 113, 114};

  // Reading settings
  double _fontSize = 26.0;
  String _fontFamily = 'Amiri';
  String _readingTheme = 'dark'; // dark, oled, sepia
  bool _showAyahNumbers = true;
  bool _showTafseer = false;
  bool _showTranslation = false;

  // Selected Reciter
  String _selectedReciter = 'مشاري العفاسي';

  // Getters
  ReadingProgress get readingProgress => _readingProgress;
  List<QuranBookmark> get bookmarks => List.unmodifiable(_bookmarks);
  KhatmahPlan get khatmahPlan => _khatmahPlan;
  Set<int> get favoriteSurahs => Set.unmodifiable(_favoriteSurahs);

  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  String get readingTheme => _readingTheme;
  bool get showAyahNumbers => _showAyahNumbers;
  bool get showTafseer => _showTafseer;
  bool get showTranslation => _showTranslation;
  String get selectedReciter => _selectedReciter;

  // Actions
  void updateReadingProgress({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required int juz,
    required double progress,
  }) {
    updateProgress(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
      juz: juz,
      progress: progress,
    );
  }

  void updateProgress({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required int juz,
    required double progress,
  }) {
    _readingProgress = ReadingProgress(
      lastSurahNumber: surahNumber,
      lastSurahName: surahName,
      lastAyahNumber: ayahNumber,
      lastJuz: juz,
      progressPercentage: progress,
      lastReadTime: DateTime.now(),
    );
    notifyListeners();
  }

  void setReciter(String reciter) {
    _selectedReciter = reciter;
    notifyListeners();
  }

  void toggleFavorite(int surahNumber) {
    if (_favoriteSurahs.contains(surahNumber)) {
      _favoriteSurahs.remove(surahNumber);
    } else {
      _favoriteSurahs.add(surahNumber);
    }
    notifyListeners();
  }

  bool isFavorite(int surahNumber) => _favoriteSurahs.contains(surahNumber);

  void addBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required String ayahSnippet,
    String? note,
  }) {
    final existingIndex = _bookmarks.indexWhere(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );

    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
    } else {
      _bookmarks.insert(
        0,
        QuranBookmark(
          id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
          surahNumber: surahNumber,
          surahName: surahName,
          ayahNumber: ayahNumber,
          ayahSnippet: ayahSnippet,
          createdAt: DateTime.now(),
          note: note,
        ),
      );
    }
    notifyListeners();
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _bookmarks.any((b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber);
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(18.0, 42.0);
    notifyListeners();
  }

  void setReadingTheme(String theme) {
    _readingTheme = theme;
    notifyListeners();
  }

  void setSelectedReciter(String reciter) {
    _selectedReciter = reciter;
    notifyListeners();
  }

  void toggleAyahNumbers() {
    _showAyahNumbers = !_showAyahNumbers;
    notifyListeners();
  }

  void toggleTafseer() {
    _showTafseer = !_showTafseer;
    notifyListeners();
  }
}
