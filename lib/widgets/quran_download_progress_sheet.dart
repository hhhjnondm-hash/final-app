import 'package:flutter/material.dart';
import '../models/download_queue_models.dart';
import '../services/quran_audio_downloader.dart';
import '../utils/design_system.dart';

class QuranDownloadProgressSheet extends StatelessWidget {
  const QuranDownloadProgressSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuranDownloadProgressSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloader = QuranAudioDownloader();

    return AnimatedBuilder(
      animation: downloader,
      builder: (context, _) {
        final queue = downloader.queue;
        final overallProgress = downloader.overallProgress;
        final completedCount = downloader.completedCount;
        final totalCount = downloader.totalCount;
        final isDownloading = downloader.isDownloading;

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: DesignSystem.bgDarkest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: DesignSystem.gold.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDownloading
                            ? DesignSystem.gold.withValues(alpha: 0.2)
                            : const Color(0xFF38B982).withValues(alpha: 0.2),
                        border: Border.all(
                          color: isDownloading ? DesignSystem.gold : const Color(0xFF38B982),
                        ),
                      ),
                      child: Icon(
                        isDownloading ? Icons.cloud_download_rounded : Icons.check_circle_rounded,
                        color: isDownloading ? DesignSystem.goldLight : const Color(0xFF38B982),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            downloader.activeTitle.isNotEmpty ? downloader.activeTitle : 'قائمة التنزيلات وسجل السور',
                            style: const TextStyle(
                              color: DesignSystem.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDownloading
                                ? 'جاري تنزيل السور وحفظها في مجلد الموسيقى...'
                                : (completedCount > 0
                                    ? 'تم الانتهاء من تنزيل $completedCount سورة بنجاح'
                                    : 'لا توجد تنزيلات نشطة حالياً'),
                            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (isDownloading)
                      TextButton.icon(
                        onPressed: () {
                          downloader.cancelDownload();
                        },
                        icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFEF4444), size: 18),
                        label: const Text(
                          'إلغاء',
                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: DesignSystem.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Overall Progress Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DesignSystem.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DesignSystem.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_outlined, color: DesignSystem.goldLight, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'التقدم الكلي:',
                                style: TextStyle(color: DesignSystem.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '$completedCount من $totalCount سورة (${(overallProgress * 100).toInt()}%)',
                            style: const TextStyle(
                              color: DesignSystem.goldLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDownloading ? DesignSystem.goldLight : const Color(0xFF38B982),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // List Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سجل وحالة تنزيل السور:',
                        style: TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إجمالي: ${queue.length} سورة',
                        style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Scrollable Live Queue List
                Expanded(
                  child: queue.isEmpty
                      ? const Center(
                          child: Text(
                            'لم تبدأ أي عملية تنزيل بعد',
                            style: TextStyle(color: DesignSystem.textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          itemCount: queue.length,
                          itemBuilder: (context, index) {
                            final item = queue[index];
                            return _buildQueueItemTile(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueItemTile(DownloadQueueItem item) {
    Color borderColor;
    Color iconColor;
    IconData icon;
    Widget trailing;

    switch (item.status) {
      case SurahDownloadStatus.completed:
        borderColor = const Color(0xFF38B982).withValues(alpha: 0.4);
        iconColor = const Color(0xFF38B982);
        icon = Icons.check_circle_rounded;
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF38B982).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF38B982).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Color(0xFF38B982), size: 14),
              const SizedBox(width: 4),
              Text(
                item.sizeText.isNotEmpty ? item.sizeText : 'تم الحفظ ✅',
                style: const TextStyle(color: Color(0xFF38B982), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
        break;

      case SurahDownloadStatus.downloading:
        borderColor = DesignSystem.gold;
        iconColor = DesignSystem.goldLight;
        icon = Icons.downloading_rounded;
        trailing = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.percentage}%',
              style: const TextStyle(
                color: DesignSystem.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.sizeText.isNotEmpty)
              Text(
                item.sizeText,
                style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
              ),
          ],
        );
        break;

      case SurahDownloadStatus.failed:
        borderColor = const Color(0xFFEF4444).withValues(alpha: 0.4);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.error_outline_rounded;
        trailing = const Text(
          'فشل ❌',
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
        );
        break;

      case SurahDownloadStatus.cancelled:
        borderColor = Colors.white12;
        iconColor = DesignSystem.textMuted;
        icon = Icons.cancel_outlined;
        trailing = const Text(
          'ملغي ⏹️',
          style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
        );
        break;

      case SurahDownloadStatus.waiting:
        borderColor = Colors.white.withValues(alpha: 0.08);
        iconColor = DesignSystem.textMuted;
        icon = Icons.hourglass_empty_rounded;
        trailing = const Text(
          'في الانتظار ⏳',
          style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.status == SurahDownloadStatus.downloading
            ? DesignSystem.gold.withValues(alpha: 0.08)
            : DesignSystem.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: item.status == SurahDownloadStatus.downloading ? 1.5 : 1.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Surah Number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),

              // Surah info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سورة ${item.surahName}',
                      style: TextStyle(
                        color: item.status == SurahDownloadStatus.downloading
                            ? DesignSystem.goldLight
                            : DesignSystem.textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'القارئ: ${item.reciterName}',
                      style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // Status & progress
              trailing,
            ],
          ),

          // Mini progress bar for downloading item
          if (item.status == SurahDownloadStatus.downloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.goldLight),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
