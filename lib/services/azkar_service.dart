import 'package:flutter/material.dart';
import '../data/all_azkar_data.dart';
import '../models/azkar_models.dart';

class AzkarService extends ChangeNotifier {
  static final AzkarService _instance = AzkarService._internal();
  factory AzkarService() => _instance;
  AzkarService._internal();

  final Set<String> _favoriteIds = {'m_1', 'm_6', 'ap_3'};
  final Map<String, int> _repetitionCounts = {};
  final Set<String> _completedIds = {'m_1', 'm_2', 'm_3', 'm_4', 'm_5'};

  AzkarCategoryType _selectedCategory = AzkarCategoryType.morning;
  int _streakDays = 7;
  int _completedToday = 14;
  int _totalToday = 21;

  Set<String> get favoriteIds => _favoriteIds;
  AzkarCategoryType get selectedCategory => _selectedCategory;
  int get streakDays => _streakDays;
  int get completedToday => _completedToday;
  int get totalToday => _totalToday;

  bool isFavorite(String id) => _favoriteIds.contains(id);
  bool isCompleted(String id) => _completedIds.contains(id);

  int getRepetition(String id) => _repetitionCounts[id] ?? 0;

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  void incrementRepetition(DhikrItem dhikr) {
    final current = _repetitionCounts[dhikr.id] ?? 0;
    if (current < dhikr.targetRepetitions) {
      _repetitionCounts[dhikr.id] = current + 1;
      if (_repetitionCounts[dhikr.id] == dhikr.targetRepetitions) {
        _completedIds.add(dhikr.id);
        _completedToday++;
      }
      notifyListeners();
    }
  }

  void decrementRepetition(DhikrItem dhikr) {
    final current = _repetitionCounts[dhikr.id] ?? 0;
    if (current > 0) {
      if (current == dhikr.targetRepetitions) {
        _completedIds.remove(dhikr.id);
        _completedToday = (_completedToday - 1).clamp(0, _totalToday);
      }
      _repetitionCounts[dhikr.id] = current - 1;
      notifyListeners();
    }
  }

  void resetDhikr(String id) {
    _repetitionCounts.remove(id);
    _completedIds.remove(id);
    notifyListeners();
  }

  List<DhikrItem> getFavorites() {
    return AllAzkarData.getAllAzkar().where((d) => _favoriteIds.contains(d.id)).toList();
  }
}
