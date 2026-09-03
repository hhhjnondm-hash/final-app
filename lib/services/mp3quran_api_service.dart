import 'dart:convert';
import 'package:http/http.dart' as http;

/// MP3Quran API Service for getting real audio URLs
/// Official API: https://www.mp3quran.net/api
class Mp3QuranApiService {
  static const String _baseUrl = 'https://www.mp3quran.net/api/v3';
  
  /// Get all reciters with their moshaf data
  Future<List<ReciterInfo>> getReciters() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reciters'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recitersJson = data['reciters'] as List;
        return recitersJson.map((json) => ReciterInfo.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch reciters: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching reciters: $e');
    }
  }
  
  /// Get radio stations
  Future<List<RadioStationInfo>> getRadios() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/radios'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final radiosJson = data['radios'] as List;
        return radiosJson.map((json) => RadioStationInfo.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch radios: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching radios: $e');
    }
  }
  
  /// Build audio URL for a specific surah
  /// Returns: server + surahNumber (padded to 3 digits) + .mp3
  /// Example: https://server12.mp3quran.net/maher/001.mp3
  String buildAudioUrl(String server, int surahNumber) {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final cleanServer = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
    return '$cleanServer/$surahPadded.mp3';
  }
}

/// Reciter info from MP3Quran API
class ReciterInfo {
  final int id;
  final String name;
  final String letter;
  final String date;
  final List<MoshafInfo> moshaf;
  
  ReciterInfo({
    required this.id,
    required this.name,
    required this.letter,
    required this.date,
    required this.moshaf,
  });
  
  factory ReciterInfo.fromJson(Map<String, dynamic> json) {
    final moshafList = (json['moshaf'] as List)
        .map((m) => MoshafInfo.fromJson(m))
        .toList();
    
    return ReciterInfo(
      id: json['id'],
      name: json['name'],
      letter: json['letter'],
      date: json['date'],
      moshaf: moshafList,
    );
  }
  
  /// Get the primary moshaf (Hafs Murattal usually)
  MoshafInfo? getPrimaryMoshaf() {
    // Prefer moshaf_type 11 (Hafs Murattal)
    final hafsMurattal = moshaf.firstWhere(
      (m) => m.moshafType == 11,
      orElse: () => moshaf.first,
    );
    return hafsMurattal;
  }
}

/// Moshaf (Quran copy) info
class MoshafInfo {
  final int id;
  final String name;
  final int rewayaId;
  final String server;
  final int surahTotal;
  final int moshafType;
  final String surahList;
  
  MoshafInfo({
    required this.id,
    required this.name,
    required this.rewayaId,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });
  
  factory MoshafInfo.fromJson(Map<String, dynamic> json) {
    return MoshafInfo(
      id: json['id'],
      name: json['name'],
      rewayaId: json['rewaya_id'],
      server: json['server'],
      surahTotal: json['surah_total'],
      moshafType: json['moshaf_type'],
      surahList: json['surah_list'],
    );
  }
  
  /// Get list of available surah numbers
  List<int> getAvailableSurahs() {
    return surahList.split(',').map(int.parse).toList();
  }
  
  /// Check if a surah is available
  bool isSurahAvailable(int surahNumber) {
    return getAvailableSurahs().contains(surahNumber);
  }
}

/// Radio station info
class RadioStationInfo {
  final int id;
  final String name;
  final String url;
  final String? image;
  
  RadioStationInfo({
    required this.id,
    required this.name,
    required this.url,
    this.image,
  });
  
  factory RadioStationInfo.fromJson(Map<String, dynamic> json) {
    return RadioStationInfo(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      image: json['image'],
    );
  }
}
