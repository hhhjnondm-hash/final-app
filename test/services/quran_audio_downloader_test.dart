import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamyat_app/data/reciters_data.dart';
import 'package:islamyat_app/data/quran_metadata.dart';
import 'package:islamyat_app/models/audio_models.dart';
import 'package:islamyat_app/models/quran_models.dart';
import 'package:islamyat_app/services/quran_audio_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranAudioDownloader All Reciters & Surahs Tests', () {
    late QuranAudioDownloader downloader;
    late List<ReciterProfile> allReciters;
    late List<SurahMeta> allSurahs;

    setUp(() {
      downloader = QuranAudioDownloader();
      allReciters = RecitersData.reciters;
      allSurahs = QuranMetadataProvider.getAllSurahs();
    });

    test('should have a rich collection of reciters configured', () {
      expect(allReciters.length, greaterThanOrEqualTo(50));
    });

    test('should have 114 Surahs defined', () {
      expect(allSurahs.length, equals(114));
    });

    test('should generate valid audio URLs for all 52 reciters across all 114 Surahs', () {
      for (final reciter in allReciters) {
        expect(reciter.serverUrl.isNotEmpty, isTrue, reason: 'Reciter ${reciter.nameArabic} has empty serverUrl');

        for (int surahNum = 1; surahNum <= 114; surahNum++) {
          final url = downloader.buildAudioUrl(reciter, surahNum);
          final surahPadded = surahNum.toString().padLeft(3, '0');

          expect(url.startsWith('http'), isTrue);
          expect(url.endsWith('/$surahPadded.mp3'), isTrue,
              reason: 'Generated URL $url is invalid for reciter ${reciter.nameArabic} and surah $surahNum');
        }
      }
    });

    test('should test specific popular reciters (Mishary, Abdulbasit, Minshawi, Maher, Sudais)', () {
      final afasy = allReciters.firstWhere((r) => r.id == 'afasy');
      final maher = allReciters.firstWhere((r) => r.id == 'maher');
      final sudais = allReciters.firstWhere((r) => r.id == 'sudais');
      final minshawi = allReciters.firstWhere((r) => r.id == 'minshawi_murattal');

      expect(downloader.buildAudioUrl(afasy, 1), equals('https://server8.mp3quran.net/afs/001.mp3'));
      expect(downloader.buildAudioUrl(maher, 18), equals('https://server12.mp3quran.net/maher/018.mp3'));
      expect(downloader.buildAudioUrl(sudais, 114), equals('https://server11.mp3quran.net/sds/114.mp3'));
      expect(downloader.buildAudioUrl(minshawi, 2), equals('https://server10.mp3quran.net/minsh/002.mp3'));
    });
  });
}
