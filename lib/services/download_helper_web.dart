// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

Future<bool> platformDownloadFile(
  String url,
  String fileName, {
  String? reciterName,
  void Function(double progress, int receivedBytes, int totalBytes)? onProgress,
}) async {
  try {
    // 1. Fetch file bytes as Stream to report real-time chunk progress
    final request = http.Request('GET', Uri.parse(url));
    final streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      final chunks = <List<int>>[];

      await for (final chunk in streamedResponse.stream) {
        chunks.add(chunk);
        receivedBytes += chunk.length;
        if (onProgress != null && totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress, receivedBytes, totalBytes);
        }
      }

      final blob = html.Blob(chunks, 'audio/mpeg');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: blobUrl)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();

      if (onProgress != null) {
        onProgress(1.0, receivedBytes, receivedBytes);
      }

      Future.delayed(const Duration(seconds: 15), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
      return true;
    }
  } catch (_) {}

  // Fallback: direct anchor click
  try {
    if (onProgress != null) {
      onProgress(0.5, 0, 0);
    }
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..target = '_blank'
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    if (onProgress != null) {
      onProgress(1.0, 1, 1);
    }
    return true;
  } catch (_) {
    return false;
  }
}
