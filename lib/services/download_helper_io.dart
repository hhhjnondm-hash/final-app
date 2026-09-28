import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<bool> platformDownloadFile(
  String url,
  String fileName, {
  String? reciterName,
  void Function(double progress, int receivedBytes, int totalBytes)? onProgress,
}) async {
  try {
    Directory baseDir;
    if (Platform.isAndroid) {
      // 1. First priority: Public Music directory on Android: /storage/emulated/0/Music/Islamiyat_Quran/
      final publicMusic = Directory('/storage/emulated/0/Music/Islamiyat_Quran');
      if (await publicMusic.exists() || await _createDir(publicMusic)) {
        baseDir = publicMusic;
      } else {
        final ext = await getExternalStorageDirectory();
        baseDir = Directory('${ext?.path ?? (await getApplicationDocumentsDirectory()).path}/Music/Islamiyat_Quran');
      }
    } else if (Platform.isWindows || Platform.isLinux) {
      final downloads = await getDownloadsDirectory();
      baseDir = Directory('${downloads?.path ?? (await getApplicationDocumentsDirectory()).path}/Islamiyat_Quran');
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final sanitizedReciter = (reciterName ?? 'Reciter').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final targetDir = Directory('${baseDir.path}/$sanitizedReciter');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final file = File('${targetDir.path}/$fileName');
    final request = http.Request('GET', Uri.parse(url));
    final streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (onProgress != null && totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress, receivedBytes, totalBytes);
        }
      }
      await sink.flush();
      await sink.close();

      if (onProgress != null) {
        onProgress(1.0, receivedBytes, receivedBytes);
      }
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

Future<bool> _createDir(Directory d) async {
  try {
    await d.create(recursive: true);
    return true;
  } catch (_) {
    return false;
  }
}
