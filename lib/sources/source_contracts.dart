import '../models/canonical_identities.dart';

abstract class QuranAudioProvider {
  Future<List<ReciterIdentity>> getReciters({bool forceRefresh = false});
  Future<List<MoshafIdentity>> getMoshafForReciter(String reciterApiId);
}

abstract class RadioProvider {
  Future<List<RadioIdentity>> getRadios({bool forceRefresh = false});
}

abstract class PrayerTimesProvider {
  Future<NormalizedPrayerDay?> getDay({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    int? school,
    String? timezone,
  });

  Future<List<NormalizedPrayerDay>> getCalendarMonth({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    int? school,
    String? timezone,
  });
}

class NormalizedPrayerDay {
  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime sunset;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? imsak;
  final DateTime? midnight;
  final double latitude;
  final double longitude;
  final String timezone;
  final int calculationMethod;
  final String? madhab;
  final DateTime fetchedAt;

  const NormalizedPrayerDay({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    this.imsak,
    this.midnight,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.calculationMethod,
    this.madhab,
    required this.fetchedAt,
  });
}

class ChapterTiming {
  final int ayahNumber;
  final int timestampFromMs;
  final int timestampToMs;
  final List<List<int>> segments;

  const ChapterTiming({
    required this.ayahNumber,
    required this.timestampFromMs,
    required this.timestampToMs,
    this.segments = const [],
  });
}

class ReadTimingResult {
  final bool available;
  final String? reason;
  final List<ChapterTiming> timings;

  const ReadTimingResult({
    required this.available,
    this.reason,
    this.timings = const [],
  });

  int? ayahAt(Duration position) {
    if (!available) return null;
    final ms = position.inMilliseconds;
    for (final t in timings) {
      if (ms >= t.timestampFromMs && ms < t.timestampToMs) {
        return t.ayahNumber;
      }
    }
    return null;
  }
}

abstract class ReadTimingProvider {
  Future<ReadTimingResult> getChapterTimings({
    required int recitationId,
    required int chapterNumber,
  });
}

abstract class AdhanProvider {
  String assetPathFor(String prayerKey);
}
