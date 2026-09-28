import 'package:flutter/material.dart';
import '../models/download_queue_models.dart';
import '../services/quran_audio_downloader.dart';
import '../utils/design_system.dart';
import 'quran_download_progress_sheet.dart';

class FloatingDownloadTracker extends StatelessWidget {
  const FloatingDownloadTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final downloader = QuranAudioDownloader();

    return AnimatedBuilder(
      animation: downloader,
      builder: (context, _) {
        if (!downloader.isDownloading && downloader.queue.isEmpty) {
          return const SizedBox.shrink();
        }

        final queue = downloader.queue;
        final currentItem = queue.firstWhere(
          (item) => item.status == SurahDownloadStatus.downloading,
          orElse: () => queue.isNotEmpty ? queue.last : DownloadQueueItem(
            surahNumber: 1,
            surahName: '',
            reciterId: '',
            reciterName: '',
            audioUrl: '',
          ),
        );

        final isDownloading = downloader.isDownloading;
        final overallProgress = downloader.overallProgress;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F233D),
                  DesignSystem.bgDarkest,
                ],
              ),
              border: Border.all(
                color: isDownloading ? DesignSystem.gold : const Color(0xFF38B982),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDownloading ? DesignSystem.gold : const Color(0xFF38B982)).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  QuranDownloadProgressSheet.show(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDownloading
                                  ? DesignSystem.gold.withValues(alpha: 0.2)
                                  : const Color(0xFF38B982).withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              isDownloading ? Icons.downloading_rounded : Icons.check_circle_rounded,
                              color: isDownloading ? DesignSystem.goldLight : const Color(0xFF38B982),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isDownloading
                                            ? 'جاري تنزيل: سورة ${currentItem.surahName} (${currentItem.percentage}%)'
                                            : 'تم اكتمال تنزيل السور بنجاح ✅',
                                        style: const TextStyle(
                                          color: DesignSystem.textWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (currentItem.sizeText.isNotEmpty && isDownloading)
                                      Text(
                                        currentItem.sizeText,
                                        style: const TextStyle(color: DesignSystem.goldLight, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isDownloading
                                      ? 'القارئ: ${currentItem.reciterName} • اضغط هنا لعرض السجل المباشر 📜'
                                      : 'متاحة الآن في مشغل الموسيقى بهاتفك',
                                  style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isDownloading)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                              tooltip: 'إلغاء التنزيل',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                downloader.cancelDownload();
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: DesignSystem.textMuted, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                downloader.clearQueue();
                              },
                            ),
                        ],
                      ),
                      if (isDownloading) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: downloader.totalCount > 1 ? overallProgress : currentItem.progress,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.goldLight),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
