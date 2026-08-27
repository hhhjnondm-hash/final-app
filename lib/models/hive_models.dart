import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class FavoriteItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'surah', 'ayah', 'dhikr', 'hadith', 'radio'

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.type,
    required this.name,
    this.imageUrl,
    required this.createdAt,
  });

  FavoriteItem copyWith({
    String? id,
    String? type,
    String? name,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@HiveType(typeId: 1)
class HistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'quran', 'radio', 'azkar'

  @HiveField(2)
  final String itemId;

  @HiveField(3)
  final String itemName;

  @HiveField(4)
  final int position; // Last played position in seconds

  @HiveField(5)
  final DateTime lastPlayed;

  HistoryItem({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.position,
    required this.lastPlayed,
  });

  HistoryItem copyWith({
    String? id,
    String? type,
    String? itemId,
    String? itemName,
    int? position,
    DateTime? lastPlayed,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      position: position ?? this.position,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}

@HiveType(typeId: 2)
class UserProgress extends HiveObject {
  @HiveField(0)
  final String userId; // Device ID or anonymous ID

  @HiveField(1)
  int totalAzkarCount;

  @HiveField(2)
  int totalQuranRead;

  @HiveField(3)
  int totalHadithRead;

  @HiveField(4)
  int totalPrayerReminders;

  @HiveField(5)
  DateTime lastActiveDate;

  @HiveField(6)
  int streakDays; // Consecutive days of usage

  UserProgress({
    required this.userId,
    this.totalAzkarCount = 0,
    this.totalQuranRead = 0,
    this.totalHadithRead = 0,
    this.totalPrayerReminders = 0,
    required this.lastActiveDate,
    this.streakDays = 1,
  });

  UserProgress copyWith({
    String? userId,
    int? totalAzkarCount,
    int? totalQuranRead,
    int? totalHadithRead,
    int? totalPrayerReminders,
    DateTime? lastActiveDate,
    int? streakDays,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      totalAzkarCount: totalAzkarCount ?? this.totalAzkarCount,
      totalQuranRead: totalQuranRead ?? this.totalQuranRead,
      totalHadithRead: totalHadithRead ?? this.totalHadithRead,
      totalPrayerReminders: totalPrayerReminders ?? this.totalPrayerReminders,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

@HiveType(typeId: 3)
class CustomDhikr extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String arabicText;

  @HiveField(2)
  final String? translation;

  @HiveField(3)
  final int targetCount;

  @HiveField(4)
  int currentCount;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final DateTime createdAt;

  CustomDhikr({
    required this.id,
    required this.arabicText,
    this.translation,
    required this.targetCount,
    this.currentCount = 0,
    required this.category,
    required this.createdAt,
  });

  CustomDhikr copyWith({
    String? id,
    String? arabicText,
    String? translation,
    int? targetCount,
    int? currentCount,
    String? category,
    DateTime? createdAt,
  }) {
    return CustomDhikr(
      id: id ?? this.id,
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress => targetCount > 0 ? currentCount / targetCount : 0;
  bool get isCompleted => currentCount >= targetCount;
}