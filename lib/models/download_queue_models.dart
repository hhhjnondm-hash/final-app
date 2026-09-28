enum SurahDownloadStatus {
  waiting,     // في قائمة الانتظار
  downloading, // جاري التنزيل
  completed,   // مكتمل
  failed,      // فشل التنزيل
  cancelled,   // ملغي
}

class DownloadQueueItem {
  final int surahNumber;
  final String surahName;
  final String reciterId;
  final String reciterName;
  final String audioUrl;
  SurahDownloadStatus status;
  double progress; // 0.0 to 1.0
  int receivedBytes;
  int totalBytes;
  String? errorMessage;

  DownloadQueueItem({
    required this.surahNumber,
    required this.surahName,
    required this.reciterId,
    required this.reciterName,
    required this.audioUrl,
    this.status = SurahDownloadStatus.waiting,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  int get percentage => (progress * 100).clamp(0, 100).toInt();

  String get sizeText {
    if (totalBytes > 0) {
      final recMB = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
      final totMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$recMB / $totMB ميجابايت';
    } else if (receivedBytes > 0) {
      final recMB = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$recMB ميجابايت';
    }
    return '';
  }

  String get statusArabic {
    switch (status) {
      case SurahDownloadStatus.waiting:
        return 'في قائمة الانتظار ⏳';
      case SurahDownloadStatus.downloading:
        return 'جاري التنزيل... ($percentage%)';
      case SurahDownloadStatus.completed:
        return 'تم التنزيل بنجاح ✅';
      case SurahDownloadStatus.failed:
        return 'تعذر التنزيل ❌';
      case SurahDownloadStatus.cancelled:
        return 'تم الإلغاء ⏹️';
    }
  }
}
