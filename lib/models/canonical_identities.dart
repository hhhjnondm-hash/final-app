/// Canonical identity models for Quran, Radio, and Prayer entities
/// Provides stable identifiers that don't change across API refreshes or data updates

/// Canonical identity for a Quran reciter
class ReciterIdentity {
  final String canonicalId; // Stable ID used across the app
  final String? apiId; // ID from MP3Quran API
  final String localAssetKey; // Key for local image asset
  final String nameArabic;
  final String nameEnglish;
  final String country;
  final String rewayah;
  final String? serverUrl;
  final int surahCount;
  final DateTime updatedAt;

  const ReciterIdentity({
    required this.canonicalId,
    this.apiId,
    required this.localAssetKey,
    required this.nameArabic,
    required this.nameEnglish,
    required this.country,
    required this.rewayah,
    this.serverUrl,
    required this.surahCount,
    required this.updatedAt,
  });

  factory ReciterIdentity.fromMap(Map<String, dynamic> map) {
    return ReciterIdentity(
      canonicalId: map['canonicalId'] as String,
      apiId: map['apiId'] as String?,
      localAssetKey: map['localAssetKey'] as String,
      nameArabic: map['nameArabic'] as String,
      nameEnglish: map['nameEnglish'] as String,
      country: map['country'] as String,
      rewayah: map['rewayah'] as String,
      serverUrl: map['serverUrl'] as String?,
      surahCount: map['surahCount'] as int,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canonicalId': canonicalId,
      'apiId': apiId,
      'localAssetKey': localAssetKey,
      'nameArabic': nameArabic,
      'nameEnglish': nameEnglish,
      'country': country,
      'rewayah': rewayah,
      'serverUrl': serverUrl,
      'surahCount': surahCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ReciterIdentity copyWith({
    String? apiId,
    String? serverUrl,
    DateTime? updatedAt,
  }) {
    return ReciterIdentity(
      canonicalId: canonicalId,
      apiId: apiId ?? this.apiId,
      localAssetKey: localAssetKey,
      nameArabic: nameArabic,
      nameEnglish: nameEnglish,
      country: country,
      rewayah: rewayah,
      serverUrl: serverUrl ?? this.serverUrl,
      surahCount: surahCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Canonical identity for a Moshaf (Quran recording)
class MoshafIdentity {
  final String moshafId; // Stable ID for this moshaf
  final String reciterCanonicalId; // Reference to reciter
  final String moshafName;
  final String serverUrl;
  final String moshafType; // 'murattal', 'muallim', etc.
  final List<int> availableSurahs; // List of available surah numbers
  final int totalSurahs;
  final String? rewayah;
  final DateTime updatedAt;

  const MoshafIdentity({
    required this.moshafId,
    required this.reciterCanonicalId,
    required this.moshafName,
    required this.serverUrl,
    required this.moshafType,
    required this.availableSurahs,
    required this.totalSurahs,
    this.rewayah,
    required this.updatedAt,
  });

  factory MoshafIdentity.fromMap(Map<String, dynamic> map) {
    return MoshafIdentity(
      moshafId: map['moshafId'] as String,
      reciterCanonicalId: map['reciterCanonicalId'] as String,
      moshafName: map['moshafName'] as String,
      serverUrl: map['serverUrl'] as String,
      moshafType: map['moshafType'] as String,
      availableSurahs: List<int>.from(map['availableSurahs'] as List),
      totalSurahs: map['totalSurahs'] as int,
      rewayah: map['rewayah'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moshafId': moshafId,
      'reciterCanonicalId': reciterCanonicalId,
      'moshafName': moshafName,
      'serverUrl': serverUrl,
      'moshafType': moshafType,
      'availableSurahs': availableSurahs,
      'totalSurahs': totalSurahs,
      'rewayah': rewayah,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool hasSurah(int surahNumber) => availableSurahs.contains(surahNumber);
}

/// Canonical identity for a Radio station
class RadioIdentity {
  final String radioId; // Stable ID for this radio
  final String canonicalName;
  final String streamUrl;
  final String provider; // 'mp3quran', etc.
  final String? language;
  final String? category;
  final String? imageUrl;
  final DateTime updatedAt;

  const RadioIdentity({
    required this.radioId,
    required this.canonicalName,
    required this.streamUrl,
    required this.provider,
    this.language,
    this.category,
    this.imageUrl,
    required this.updatedAt,
  });

  factory RadioIdentity.fromMap(Map<String, dynamic> map) {
    return RadioIdentity(
      radioId: map['radioId'] as String,
      canonicalName: map['canonicalName'] as String,
      streamUrl: map['streamUrl'] as String,
      provider: map['provider'] as String,
      language: map['language'] as String?,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'radioId': radioId,
      'canonicalName': canonicalName,
      'streamUrl': streamUrl,
      'provider': provider,
      'language': language,
      'category': category,
      'imageUrl': imageUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Canonical identity for a prayer day
class PrayerDayIdentity {
  final String dateKey; // YYYY-MM-DD format
  final double latitude;
  final double longitude;
  final String timezone;
  final int calculationMethod;
  final String? madhab;
  final DateTime fetchedAt;
  final DateTime expiresAt;
  final String source; // 'aladhan_api', etc.

  const PrayerDayIdentity({
    required this.dateKey,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.calculationMethod,
    this.madhab,
    required this.fetchedAt,
    required this.expiresAt,
    required this.source,
  });

  factory PrayerDayIdentity.fromMap(Map<String, dynamic> map) {
    return PrayerDayIdentity(
      dateKey: map['dateKey'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timezone: map['timezone'] as String,
      calculationMethod: map['calculationMethod'] as int,
      madhab: map['madhab'] as String?,
      fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      source: map['source'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'fetchedAt': fetchedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'source': source,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isFresh => DateTime.now().isBefore(expiresAt);
  DateTime get date => DateTime.parse(dateKey);
}

/// Audio source descriptor for unified audio management
class AudioSourceDescriptor {
  final String id;
  final AudioSourceType type;
  final String title;
  final String subtitle;
  final String provider;
  final String? remoteUrl;
  final String? localPath;
  final String? mimeType;
  final Map<String, String>? headers;
  final Duration? duration;
  final Map<String, dynamic>? metadata;

  const AudioSourceDescriptor({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.provider,
    this.remoteUrl,
    this.localPath,
    this.mimeType,
    this.headers,
    this.duration,
    this.metadata,
  });

  bool get isLocal => localPath != null;
  bool get isRemote => remoteUrl != null;
  String get effectiveSource => localPath ?? remoteUrl ?? '';

  AudioSourceDescriptor copyWith({
    String? localPath,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    return AudioSourceDescriptor(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      provider: provider,
      remoteUrl: remoteUrl,
      localPath: localPath ?? this.localPath,
      mimeType: mimeType,
      headers: headers,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum AudioSourceType {
  quran,
  read,
  radio,
  adhan,
  none,
}
