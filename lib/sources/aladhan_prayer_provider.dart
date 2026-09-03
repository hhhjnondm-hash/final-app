import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_source_config.dart';
import '../observability/dev_log.dart';
import '../observability/source_health_monitor.dart';
import 'source_contracts.dart';

class AlAdhanPrayerProvider implements PrayerTimesProvider {
  static final AlAdhanPrayerProvider _instance = AlAdhanPrayerProvider._internal();
  factory AlAdhanPrayerProvider() => _instance;
  AlAdhanPrayerProvider._internal();

  @override
  Future<NormalizedPrayerDay?> getDay({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    int? school,
    String? timezone,
  }) async {
    final datePath =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final uri = Uri.parse('${ApiSourceConfig.aladhanTimings.baseUrl}/timings/$datePath')
        .replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': calculationMethod.toString(),
      if (school != null) 'school': school.toString(),
      if (timezone != null && timezone.isNotEmpty) 'timezonestring': timezone,
    });

    try {
      final response = await SourceHealthMonitor().track(
        provider: 'aladhan',
        endpoint: '/timings',
        action: () => http.get(uri).timeout(ApiSourceConfig.aladhanTimings.timeout),
      );
      if (response.statusCode != 200) {
        DevLog.prayer(message: 'aladhan http ${response.statusCode}', date: datePath);
        return null;
      }
      return _parseDay(json.decode(response.body), date, latitude, longitude, calculationMethod);
    } catch (e) {
      DevLog.prayer(message: 'aladhan error', date: datePath, refresh: '$e');
      return null;
    }
  }

  @override
  Future<List<NormalizedPrayerDay>> getCalendarMonth({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    int? school,
    String? timezone,
  }) async {
    final uri = Uri.parse(
      '${ApiSourceConfig.aladhanCalendar.baseUrl}/calendar/$year/$month',
    ).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': calculationMethod.toString(),
      if (school != null) 'school': school.toString(),
      if (timezone != null && timezone.isNotEmpty) 'timezonestring': timezone,
    });

    try {
      final response = await SourceHealthMonitor().track(
        provider: 'aladhan',
        endpoint: '/calendar',
        action: () => http.get(uri).timeout(ApiSourceConfig.aladhanCalendar.timeout),
      );
      if (response.statusCode != 200) return const [];
      final decoded = json.decode(response.body);
      if (decoded is! Map) return const [];
      final data = decoded['data'];
      if (data is! List) return const [];
      final days = <NormalizedPrayerDay>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final wrapped = {'code': 200, 'data': raw};
        final gregorian = raw['date']?['gregorian'];
        DateTime date;
        try {
          date = DateTime.parse(gregorian['date'].toString().split('-').reversed.join('-'));
        } catch (_) {
          final d = int.tryParse(gregorian?['day']?.toString() ?? '') ?? 1;
          date = DateTime(year, month, d);
        }
        final parsed = _parseDay(wrapped, date, latitude, longitude, calculationMethod);
        if (parsed != null) days.add(parsed);
      }
      return days;
    } catch (e) {
      DevLog.prayer(message: 'calendar error', refresh: '$e');
      return const [];
    }
  }

  NormalizedPrayerDay? _parseDay(
    dynamic decoded,
    DateTime date,
    double latitude,
    double longitude,
    int calculationMethod,
  ) {
    if (decoded is! Map) return null;
    final data = decoded['data'];
    if (data is! Map) return null;
    final timings = data['timings'];
    if (timings is! Map) return null;
    final meta = data['meta'] is Map ? Map<String, dynamic>.from(data['meta'] as Map) : <String, dynamic>{};

    DateTime? parseClock(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().split(' ').first;
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    final fajr = parseClock(timings['Fajr']);
    final sunrise = parseClock(timings['Sunrise']);
    final dhuhr = parseClock(timings['Dhuhr']);
    final asr = parseClock(timings['Asr']);
    final maghrib = parseClock(timings['Maghrib']);
    final isha = parseClock(timings['Isha']);
    final sunset = parseClock(timings['Sunset']) ?? maghrib;
    if (fajr == null || sunrise == null || dhuhr == null || asr == null || maghrib == null || isha == null) {
      return null;
    }

    return NormalizedPrayerDay(
      date: DateTime(date.year, date.month, date.day),
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      sunset: sunset ?? maghrib,
      maghrib: maghrib,
      isha: isha,
      imsak: parseClock(timings['Imsak']),
      midnight: parseClock(timings['Midnight']),
      latitude: latitude,
      longitude: longitude,
      timezone: meta['timezone']?.toString() ?? 'UTC',
      calculationMethod: calculationMethod,
      madhab: meta['school']?.toString() ?? meta['madhab']?.toString(),
      fetchedAt: DateTime.now(),
    );
  }
}
