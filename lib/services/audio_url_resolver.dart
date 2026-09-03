import '../models/audio_models.dart';
import '../models/canonical_identities.dart';
import '../observability/dev_log.dart';

class AudioUrlResolver {
  static final AudioUrlResolver _instance = AudioUrlResolver._internal();
  factory AudioUrlResolver() => _instance;
  AudioUrlResolver._internal();

  /// Build a Quran audio URL from official MP3Quran moshaf server metadata.
  String? resolveFromMoshaf(MoshafIdentity moshaf, int surahNumber) {
    if (!moshaf.hasSurah(surahNumber)) {
      DevLog.quran(
        message: 'surah not in moshaf',
        reciterId: moshaf.reciterCanonicalId,
        moshafId: moshaf.moshafId,
        surahId: surahNumber,
        available: false,
      );
      return null;
    }
    return _joinServer(moshaf.serverUrl, surahNumber);
  }

  String? resolveFromReciter(ReciterProfile reciter, int surahNumber) {
    if (!_isSurahAvailable(reciter, surahNumber)) {
      DevLog.quran(
        message: 'surah not available',
        reciterId: reciter.id,
        moshafId: reciter.moshafId,
        surahId: surahNumber,
        available: false,
      );
      return null;
    }
    if (reciter.serverUrl.trim().isEmpty) return null;
    return _joinServer(reciter.serverUrl, surahNumber);
  }

  bool _isSurahAvailable(ReciterProfile reciter, int surahNumber) {
    final list = reciter.availableSurahs;
    if (list != null && list.isNotEmpty) {
      return list.contains(surahNumber);
    }
    if (reciter.surahCount == 114 && surahNumber >= 1 && surahNumber <= 114) {
      return true;
    }
    return false;
  }

  String _joinServer(String server, int surahNumber) {
    var base = server.trim();
    if (!base.endsWith('/')) base = '$base/';
    final padded = surahNumber.toString().padLeft(3, '0');
    return '$base$padded.mp3';
  }

  String? hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return null;
    }
  }
}
