import 'package:flutter_test/flutter_test.dart';
import 'package:islamyat_app/models/hive_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoriteItem Tests', () {
    test('should create FavoriteItem with required fields', () {
      final item = FavoriteItem(
        id: 'test_id',
        type: 'surah',
        name: 'الفاتحة',
        createdAt: DateTime.now(),
      );

      expect(item.id, equals('test_id'));
      expect(item.type, equals('surah'));
      expect(item.name, equals('الفاتحة'));
      expect(item.imageUrl, isNull);
    });

    test('should create FavoriteItem with all fields', () {
      final now = DateTime.now();
      final item = FavoriteItem(
        id: 'test_id',
        type: 'surah',
        name: 'الفاتحة',
        imageUrl: 'https://example.com/image.jpg',
        createdAt: now,
      );

      expect(item.imageUrl, equals('https://example.com/image.jpg'));
      expect(item.createdAt, equals(now));
    });

    test('should copy FavoriteItem with new values', () {
      final item = FavoriteItem(
        id: 'test_id',
        type: 'surah',
        name: 'الفاتحة',
        createdAt: DateTime.now(),
      );

      final copiedItem = item.copyWith(name: 'البقرة');

      expect(copiedItem.id, equals(item.id));
      expect(copiedItem.type, equals(item.type));
      expect(copiedItem.name, equals('البقرة'));
      expect(copiedItem.createdAt, equals(item.createdAt));
    });
  });

  group('HistoryItem Tests', () {
    test('should create HistoryItem with required fields', () {
      final now = DateTime.now();
      final item = HistoryItem(
        id: 'test_id',
        type: 'quran',
        itemId: 'surah_1',
        itemName: 'الفاتحة',
        position: 120,
        lastPlayed: now,
      );

      expect(item.id, equals('test_id'));
      expect(item.type, equals('quran'));
      expect(item.itemId, equals('surah_1'));
      expect(item.itemName, equals('الفاتحة'));
      expect(item.position, equals(120));
      expect(item.lastPlayed, equals(now));
    });

    test('should copy HistoryItem with new values', () {
      final now = DateTime.now();
      final item = HistoryItem(
        id: 'test_id',
        type: 'quran',
        itemId: 'surah_1',
        itemName: 'الفاتحة',
        position: 120,
        lastPlayed: now,
      );

      final copiedItem = item.copyWith(position: 240);

      expect(copiedItem.id, equals(item.id));
      expect(copiedItem.type, equals(item.type));
      expect(copiedItem.itemId, equals(item.itemId));
      expect(copiedItem.position, equals(240));
      expect(copiedItem.lastPlayed, equals(item.lastPlayed));
    });
  });

  group('UserProgress Tests', () {
    test('should create UserProgress with default values', () {
      final now = DateTime.now();
      final progress = UserProgress(
        userId: 'user_123',
        lastActiveDate: now,
      );

      expect(progress.userId, equals('user_123'));
      expect(progress.totalAzkarCount, equals(0));
      expect(progress.totalQuranRead, equals(0));
      expect(progress.totalHadithRead, equals(0));
      expect(progress.totalPrayerReminders, equals(0));
      expect(progress.streakDays, equals(1));
    });

    test('should create UserProgress with custom values', () {
      final now = DateTime.now();
      final progress = UserProgress(
        userId: 'user_123',
        totalAzkarCount: 50,
        totalQuranRead: 10,
        totalHadithRead: 25,
        totalPrayerReminders: 30,
        lastActiveDate: now,
        streakDays: 5,
      );

      expect(progress.totalAzkarCount, equals(50));
      expect(progress.totalQuranRead, equals(10));
      expect(progress.totalHadithRead, equals(25));
      expect(progress.totalPrayerReminders, equals(30));
      expect(progress.streakDays, equals(5));
    });

    test('should copy UserProgress with new values', () {
      final now = DateTime.now();
      final progress = UserProgress(
        userId: 'user_123',
        lastActiveDate: now,
      );

      final copiedProgress = progress.copyWith(
        totalAzkarCount: 100,
        streakDays: 10,
      );

      expect(copiedProgress.userId, equals(progress.userId));
      expect(copiedProgress.totalAzkarCount, equals(100));
      expect(copiedProgress.streakDays, equals(10));
      expect(copiedProgress.lastActiveDate, equals(progress.lastActiveDate));
    });
  });

  group('CustomDhikr Tests', () {
    test('should create CustomDhikr with required fields', () {
      final now = DateTime.now();
      final dhikr = CustomDhikr(
        id: 'dhikr_1',
        arabicText: 'سبحان الله',
        targetCount: 33,
        category: 'morning',
        createdAt: now,
      );

      expect(dhikr.id, equals('dhikr_1'));
      expect(dhikr.arabicText, equals('سبحان الله'));
      expect(dhikr.targetCount, equals(33));
      expect(dhikr.currentCount, equals(0));
      expect(dhikr.category, equals('morning'));
    });

    test('should create CustomDhikr with all fields', () {
      final now = DateTime.now();
      final dhikr = CustomDhikr(
        id: 'dhikr_1',
        arabicText: 'سبحان الله',
        translation: 'Glory be to Allah',
        targetCount: 33,
        currentCount: 10,
        category: 'morning',
        createdAt: now,
      );

      expect(dhikr.translation, equals('Glory be to Allah'));
      expect(dhikr.currentCount, equals(10));
    });

    test('should calculate progress correctly', () {
      final dhikr = CustomDhikr(
        id: 'dhikr_1',
        arabicText: 'سبحان الله',
        targetCount: 100,
        currentCount: 50,
        category: 'morning',
        createdAt: DateTime.now(),
      );

      expect(dhikr.progress, equals(0.5));
    });

    test('should check if dhikr is completed', () {
      final completedDhikr = CustomDhikr(
        id: 'dhikr_1',
        arabicText: 'سبحان الله',
        targetCount: 33,
        currentCount: 33,
        category: 'morning',
        createdAt: DateTime.now(),
      );

      final incompleteDhikr = CustomDhikr(
        id: 'dhikr_2',
        arabicText: 'الحمد لله',
        targetCount: 33,
        currentCount: 10,
        category: 'morning',
        createdAt: DateTime.now(),
      );

      expect(completedDhikr.isCompleted, isTrue);
      expect(incompleteDhikr.isCompleted, isFalse);
    });

    test('should copy CustomDhikr with new values', () {
      final now = DateTime.now();
      final dhikr = CustomDhikr(
        id: 'dhikr_1',
        arabicText: 'سبحان الله',
        targetCount: 33,
        category: 'morning',
        createdAt: now,
      );

      final copiedDhikr = dhikr.copyWith(currentCount: 20);

      expect(copiedDhikr.id, equals(dhikr.id));
      expect(copiedDhikr.arabicText, equals(dhikr.arabicText));
      expect(copiedDhikr.currentCount, equals(20));
      expect(copiedDhikr.targetCount, equals(dhikr.targetCount));
    });

    test('should handle zero target count', () {
      final dhikr = CustomDhikr(
        id: 'dhikr_1',
        arabicText: 'سبحان الله',
        targetCount: 0,
        currentCount: 10,
        category: 'morning',
        createdAt: DateTime.now(),
      );

      expect(dhikr.progress, equals(0.0));
    });
  });
}