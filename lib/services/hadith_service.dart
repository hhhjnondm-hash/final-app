import 'package:flutter/material.dart';
import '../data/hadith_data.dart';
import '../models/hadith_models.dart';

class HadithService extends ChangeNotifier {
  static final HadithService _instance = HadithService._internal();
  factory HadithService() => _instance;
  HadithService._internal();

  final Set<String> _favoriteHadithIds = {'h_1', 'h_2', 'h_8'};
  int _readStreakDays = 16;
  int _todayReadCount = 12;

  Set<String> get favoriteHadithIds => _favoriteHadithIds;
  int get readStreakDays => _readStreakDays;
  int get todayReadCount => _todayReadCount;

  HadithItem get dailyHadith => HadithData.ahadith.first;

  bool isFavorite(String id) => _favoriteHadithIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteHadithIds.contains(id)) {
      _favoriteHadithIds.remove(id);
    } else {
      _favoriteHadithIds.add(id);
    }
    notifyListeners();
  }

  void markHadithRead() {
    _todayReadCount++;
    notifyListeners();
  }
}
