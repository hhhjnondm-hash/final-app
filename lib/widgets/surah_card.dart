import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../utils/design_system.dart';

class SurahCard extends StatefulWidget {
  final SurahMeta surah;
  final bool isFavorite;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPlayAudio;

  const SurahCard({
    super.key,
    required this.surah,
    required this.isFavorite,
    this.progress = 0.0,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onPlayAudio,
  });

  @override
  State<SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<SurahCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignSystem.bgCard.withValues(alpha: _isHovered ? 0.95 : 0.8),
              DesignSystem.bgDarkest.withValues(alpha: 0.95),
            ],
          ),
          border: Border.all(
            color: _isHovered
                ? DesignSystem.gold.withValues(alpha: 0.8)
                : DesignSystem.gold.withValues(alpha: 0.18),
            width: _isHovered ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? DesignSystem.gold.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: _isHovered ? 25 : 15,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(DesignSystem.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Surah Number Badge & Bookmark Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gold Surah Number Badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: DesignSystem.goldGradient,
                          boxShadow: DesignSystem.goldGlow,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.surah.number}',
                            style: const TextStyle(
                              color: DesignSystem.bgDarkest,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // Bookmark Action
                      IconButton(
                        icon: Icon(
                          widget.isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: widget.isFavorite
                              ? DesignSystem.gold
                              : DesignSystem.textMuted,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onFavoriteToggle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Surah Artistic Visual Banner (Islamic Arch + Shimmer Mesh)
                  Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.surah.themeGradients
                            .map((c) => c.withValues(alpha: 0.35))
                            .toList(),
                      ),
                      border: Border.all(
                        color: DesignSystem.gold.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Icon(
                            Icons.nights_stay_rounded,
                            size: 50,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        Icon(
                          widget.surah.themeIcon,
                          color: DesignSystem.goldLight.withValues(alpha: 0.7),
                          size: 28,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Arabic Surah Name
                  Text(
                    'سورة ${widget.surah.nameArabic}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesignSystem.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // English Surah Name & Meaning
                  Text(
                    widget.surah.nameEnglish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Surah Meta (Ayah Count • Meccan / Medinan)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (widget.surah.isMeccan
                                  ? DesignSystem.gold
                                  : DesignSystem.electricBlue)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          border: Border.all(
                            color: (widget.surah.isMeccan
                                    ? DesignSystem.gold
                                    : DesignSystem.electricBlue)
                                .withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.surah.isMeccan ? 'مكية' : 'مدنية',
                          style: TextStyle(
                            color: widget.surah.isMeccan
                                ? DesignSystem.goldLight
                                : DesignSystem.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.surah.ayahCount} آية',
                        style: const TextStyle(
                          color: DesignSystem.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom Action Row: Reading Progress Bar & Audio Play Button
                  Row(
                    children: [
                      // Progress Bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: widget.progress > 0 ? widget.progress : 0.05,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.progress > 0
                                      ? DesignSystem.gold
                                      : DesignSystem.textMuted.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Audio Play Circle
                      InkWell(
                        onTap: widget.onPlayAudio,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignSystem.gold.withValues(alpha: 0.15),
                            border: Border.all(
                              color: DesignSystem.gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: DesignSystem.goldLight,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
