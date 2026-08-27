import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';

class HiveDatabaseService {
  static final HiveDatabaseService _instance = HiveDatabaseService._internal();
  factory HiveDatabaseService() => _instance;
  HiveDatabaseService._internal();

  static const String _favoritesBox = 'favorites';
  static const String _historyBox = 'history';
  static const String _progressBox = 'progress';
  static const String _customDhikrBox = 'custom_dhikr';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(FavoriteItemAdapter());
    Hive.registerAdapter(HistoryItemAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    Hive.registerAdapter(CustomDhikrAdapter());

    // Open boxes
    await Hive.openBox<FavoriteItem>(_favoritesBox);
    await Hive.openBox<HistoryItem>(_historyBox);
    await Hive.openBox<UserProgress>(_progressBox);
    await Hive.openBox<CustomDhikr>(_customDhikrBox);

    _isInitialized = true;
  }

  // ==================== FAVORITES ====================

  Box<FavoriteItem> get _favoritesBoxInstance => Hive.box<FavoriteItem>(_favoritesBox);

  Future<void> addFavorite(FavoriteItem item) async {
    await _favoritesBoxInstance.put(item.id, item);
  }

  Future<void> removeFavorite(String id) async {
    await _favoritesBoxInstance.delete(id);
  }

  List<FavoriteItem> getFavorites() {
    return _favoritesBoxInstance.values.toList();
  }

  bool isFavorite(String id) {
    return _favoritesBoxInstance.containsKey(id);
  }

  List<FavoriteItem> getFavoritesByType(String type) {
    return _favoritesBoxInstance.values
        .where((item) => item.type == type)
        .toList();
  }

  Future<void> clearFavorites() async {
    await _favoritesBoxInstance.clear();
  }

  // ==================== HISTORY ====================

  Box<HistoryItem> get _historyBoxInstance => Hive.box<HistoryItem>(_historyBox);

  Future<void> addHistoryItem(HistoryItem item) async {
    await _historyBoxInstance.put(item.id, item);
    
    // Keep only last 50 items
    if (_historyBoxInstance.length > 50) {
      final oldest = _historyBoxInstance.values
          .toList()
          ..sort((a, b) => a.lastPlayed.compareTo(b.lastPlayed));
      await _historyBoxInstance.delete(oldest.first.id);
    }
  }

  List<HistoryItem> getHistory() {
    final items = _historyBoxInstance.values.toList();
    items.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    return items;
  }

  List<HistoryItem> getHistoryByType(String type) {
    final items = _historyBoxInstance.values
        .where((item) => item.type == type)
        .toList();
    items.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    return items;
  }

  HistoryItem? getLastPlayedItem() {
    final items = getHistory();
    return items.isNotEmpty ? items.first : null;
  }

  Future<void> clearHistory() async {
    await _historyBoxInstance.clear();
  }

  // ==================== USER PROGRESS ====================

  Box<UserProgress> get _progressBoxInstance => Hive.box<UserProgress>(_progressBox);

  Future<void> updateProgress(String userId, {
    int? azkarCount,
    int? quranRead,
    int? hadithRead,
    int? prayerReminders,
  }) async {
    UserProgress? progress = _progressBoxInstance.get(userId);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (progress == null) {
      progress = UserProgress(
        userId: userId,
        totalAzkarCount: azkarCount ?? 0,
        totalQuranRead: quranRead ?? 0,
        totalHadithRead: hadithRead ?? 0,
        totalPrayerReminders: prayerReminders ?? 0,
        lastActiveDate: today,
        streakDays: 1,
      );
    } else {
      // Update streak days
      final lastActive = DateTime(
        progress.lastActiveDate.year,
        progress.lastActiveDate.month,
        progress.lastActiveDate.day,
      );
      
      final daysDifference = today.difference(lastActive).inDays;
      
      if (daysDifference == 1) {
        // Consecutive day
        progress = progress.copyWith(
          streakDays: progress.streakDays + 1,
          lastActiveDate: today,
        );
      } else if (daysDifference > 1) {
        // Streak broken
        progress = progress.copyWith(
          streakDays: 1,
          lastActiveDate: today,
        );
      } else {
        // Same day, just update date
        progress = progress.copyWith(lastActiveDate: today);
      }

      // Update counts
      progress = progress.copyWith(
        totalAzkarCount: azkarCount ?? progress.totalAzkarCount,
        totalQuranRead: quranRead ?? progress.totalQuranRead,
        totalHadithRead: hadithRead ?? progress.totalHadithRead,
        totalPrayerReminders: prayerReminders ?? progress.totalPrayerReminders,
      );
    }

    await _progressBoxInstance.put(userId, progress);
  }

  UserProgress? getProgress(String userId) {
    return _progressBoxInstance.get(userId);
  }

  Future<void> resetProgress(String userId) async {
    final progress = _progressBoxInstance.get(userId);
    if (progress != null) {
      await _progressBoxInstance.put(userId, progress.copyWith(
        totalAzkarCount: 0,
        totalQuranRead: 0,
        totalHadithRead: 0,
        totalPrayerReminders: 0,
        streakDays: 1,
      ));
    }
  }

  // ==================== CUSTOM DHIKR ====================

  Box<CustomDhikr> get _customDhikrBoxInstance => Hive.box<CustomDhikr>(_customDhikrBox);

  Future<void> addCustomDhikr(CustomDhikr dhikr) async {
    await _customDhikrBoxInstance.put(dhikr.id, dhikr);
  }

  Future<void> updateCustomDhikrCount(String id, int count) async {
    final dhikr = _customDhikrBoxInstance.get(id);
    if (dhikr != null) {
      await _customDhikrBoxInstance.put(id, dhikr.copyWith(currentCount: count));
    }
  }

  List<CustomDhikr> getCustomAdhkar() {
    return _customDhikrBoxInstance.values.toList();
  }

  List<CustomDhikr> getCustomAdhkarByCategory(String category) {
    return _customDhikrBoxInstance.values
        .where((dhikr) => dhikr.category == category)
        .toList();
  }

  CustomDhikr? getCustomDhikr(String id) {
    return _customDhikrBoxInstance.get(id);
  }

  Future<void> deleteCustomDhikr(String id) async {
    await _customDhikrBoxInstance.delete(id);
  }

  Future<void> clearCustomAdhkar() async {
    await _customDhikrBoxInstance.clear();
  }

  // ==================== GENERAL ====================

  Future<void> clearAllData() async {
    await _favoritesBoxInstance.clear();
    await _historyBoxInstance.clear();
    await _progressBoxInstance.clear();
    await _customDhikrBoxInstance.clear();
  }

  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}