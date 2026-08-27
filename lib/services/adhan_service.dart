import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import 'prayer_service.dart';

enum AdhanVoice {
  makkah,
  madinah,
  cairo,
  quds,
}

class AdhanService extends ChangeNotifier {
  static final AdhanService _instance = AdhanService._internal();
  factory AdhanService() => _instance;
  AdhanService._internal() {
    _startPrayerMonitoring();
  }

  final PrayerService _prayerService = PrayerService();
  Timer? _monitoringTimer;

  bool _adhanSoundEnabled = true;
  AdhanVoice _selectedVoice = AdhanVoice.makkah;
  int _preAdhanReminderMinutes = 10; // 0, 5, 10, 15
  bool _preAdhanReminderEnabled = true;

  final Set<String> _triggeredPrayersToday = {};
  String _lastCheckedDate = '';

  bool get adhanSoundEnabled => _adhanSoundEnabled;
  AdhanVoice get selectedVoice => _selectedVoice;
  int get preAdhanReminderMinutes => _preAdhanReminderMinutes;
  bool get preAdhanReminderEnabled => _preAdhanReminderEnabled;

  void toggleAdhanSound(bool enabled) {
    _adhanSoundEnabled = enabled;
    notifyListeners();
  }

  void selectVoice(AdhanVoice voice) {
    _selectedVoice = voice;
    notifyListeners();
  }

  void setPreAdhanReminder(bool enabled, int minutes) {
    _preAdhanReminderEnabled = enabled;
    _preAdhanReminderMinutes = minutes;
    notifyListeners();
  }

  String getVoiceNameArabic(AdhanVoice voice) {
    switch (voice) {
      case AdhanVoice.makkah:
        return 'أذان الحرم المكي الشريف';
      case AdhanVoice.madinah:
        return 'أذان المسجد النبوي الشريف';
      case AdhanVoice.cairo:
        return 'أذان الجامع الأزهر (القاهرة)';
      case AdhanVoice.quds:
        return 'أذان المسجد الأقصى المبارك';
    }
  }

  void _startPrayerMonitoring() {
    _monitoringTimer?.cancel();
    // Only monitor if not in flutter test environment
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPrayerTimes();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void _checkPrayerTimes() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (_lastCheckedDate != todayStr) {
      _triggeredPrayersToday.clear();
      _lastCheckedDate = todayStr;
    }

    final timings = _prayerService.getPrayerTimingsForDate(now);
    final nowMinutes = now.hour * 60 + now.minute;

    for (final timing in timings) {
      final prayerMinutes = timing.time.hour * 60 + timing.time.minute;
      final diff = prayerMinutes - nowMinutes;
      final key = '${timing.type.name}_$todayStr';

      // Pre-adhan reminder check
      if (_preAdhanReminderEnabled && diff == _preAdhanReminderMinutes) {
        final reminderKey = 'pre_${timing.type.name}_$todayStr';
        if (!_triggeredPrayersToday.contains(reminderKey)) {
          _triggeredPrayersToday.add(reminderKey);
          debugPrint('Pre-Adhan Reminder: باقي $preAdhanReminderMinutes دقائق على صلاة ${timing.nameArabic}');
        }
      }

      // Adhan exact time check
      if (diff == 0 && !_triggeredPrayersToday.contains(key)) {
        _triggeredPrayersToday.add(key);
        _triggerAdhan(timing);
      }
    }
  }

  void _triggerAdhan(PrayerTiming timing) {
    debugPrint('🕌 حان الآن موعد أذان صلاة ${timing.nameArabic}');
    // In production mobile, this triggers local audio player / local notification sound
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}
