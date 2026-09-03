import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Stub notification service for quick compilation
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> showPrayerNotification({
    required String prayerName,
    required TimeOfDay prayerTime,
    required PrayerType prayerType,
  }) async {
    debugPrint('Would show notification for $prayerName');
  }

  Future<void> cancel(int id) async {
    debugPrint('Would cancel notification $id');
  }

  Future<void> cancelAll() async {
    debugPrint('Would cancel all notifications');
  }
}

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}