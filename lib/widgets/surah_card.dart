import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../utils/design_system.dart';

class SurahCard extends StatefulWidget {
  final SurahMeta surah;
  final bool isFavorite;
  final double progress;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPlayAudio;
  final VoidCallback? onMoreOptions;

  const SurahCard({
    super.key,
    required this.surah,
    required this.isFavorite,
    this.progress = 0.0,
    this.isSelected = false,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onPlayAudio,
    this.onMoreOptions,
  });

  @override
  State<SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<SurahCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final isHighlight = widget.isSelected || _isHovered;

    // Card Colors according to screenshot
    final cardBg = isLight
        ? (isHighlight ? const Color(0xFFFFFFFF) : const Color(0xFFF8FAFC))
        : (isHighlight ? const Color(0xFF131B28) : const Color(0xFF0F1520));

    final borderColor = isLight
        ? (isHighlight ? const Color(0xFFC89B3C) : const Color(0xFFE2E8F0))
        : (isHighlight
            ? const Color(0xFFFFD56B)
            : const Color(0xFFC89B3C).withValues(alpha: 0.2));

    final numberBadgeBg = isLight
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF241C10);

    final numberTextColor = isLight
        ? const Color(0xFF0F172A)
        : const Color(0xFFFFD56B);

    final titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final countColor = isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isHighlight ? 1.6 : 1.0,
          ),
          boxShadow: [
            if (!isLight && isHighlight)
              BoxShadow(
                color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: isLight
                  ? const Color(0xFF0F172A).withValues(alpha: isHighlight ? 0.08 : 0.03)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Bookmark Left & Number Badge Right (or vice versa for RTL)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bookmark Action (Left)
                      InkWell(
                        onTap: widget.onFavoriteToggle,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            widget.isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: widget.isFavorite
                                ? const Color(0xFFFFD56B)
                                : (isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),

                      // Number Badge (Right)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: numberBadgeBg,
                          border: Border.all(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.surah.number}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: numberTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Middle Content: Surah Name Arabic + English + Badges
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'سورة ${widget.surah.nameArabic}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.surah.nameEnglish,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Type pill & Ayah count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: widget.surah.isMeccan
                                  ? const Color(0xFF241C10)
                                  : const Color(0xFF0F2634),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.surah.isMeccan
                                    ? const Color(0xFFC89B3C).withValues(alpha: 0.7)
                                    : const Color(0xFF38BDF8).withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.surah.isMeccan ? 'مكية' : 'مدنية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.surah.isMeccan
                                    ? const Color(0xFFFFD56B)
                                    : const Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.surah.ayahCount} آية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: countColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bottom Action Row: Play Button + Audio Track Line + More Options (...)
                  Row(
                    children: [
                      // Play Audio Button
                      InkWell(
                        onTap: widget.onPlayAudio,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: const Color(0xFFFFD56B).withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                              color: Color(0xFFFFD56B),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Audio / Reading Progress Line
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: widget.progress > 0 ? (widget.progress * 80) : 0,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD56B),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // More options (...)
                      InkWell(
                        onTap: widget.onMoreOptions ?? widget.onTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
