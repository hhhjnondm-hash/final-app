import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/design_system.dart';
import 'visual_effects/shimmer_sweep.dart';
import 'visual_effects/star_glint.dart';

/// Luxury Islamic & Tech Developer Credits Badge for Eng. Ahmed Zaki
class DeveloperCreditsBadge extends StatefulWidget {
  final bool compact;
  final EdgeInsetsGeometry? margin;

  const DeveloperCreditsBadge({
    super.key,
    this.compact = false,
    this.margin,
  });

  static const String telegramUrl = 'https://t.me/o_w_i';
  static const String developerName = 'Eng Ahmed Zaki';

  static Future<void> openTelegram() async {
    final uri = Uri.parse(telegramUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      // Fallback
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  State<DeveloperCreditsBadge> createState() => _DeveloperCreditsBadgeState();
}

class _DeveloperCreditsBadgeState extends State<DeveloperCreditsBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHovered ? 1.03 : _scaleAnimation.value,
              child: child,
            );
          },
          child: ShimmerSweep(
            duration: const Duration(milliseconds: 3500),
            pauseDuration: const Duration(milliseconds: 2500),
            shimmerColor: const Color(0xFFFFD56B),
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await DeveloperCreditsBadge.openTelegram();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : 18,
                  vertical: widget.compact ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLight
                        ? [
                            const Color(0xFFFFFFFF),
                            const Color(0xFFF6F8FC),
                            const Color(0xFFEDF2F9),
                          ]
                        : [
                            const Color(0xFF141C2B),
                            const Color(0xFF0C1320),
                            const Color(0xFF070B12),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isHovered
                        ? const Color(0xFFFFD56B)
                        : const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.45 : 0.55),
                    width: _isHovered ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD56B).withValues(alpha: _isHovered ? 0.35 : 0.15),
                      blurRadius: _isHovered ? 18 : 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0088CC).withValues(alpha: _isHovered ? 0.25 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Telegram Glowing Icon Button
                    Container(
                      width: widget.compact ? 32 : 38,
                      height: widget.compact ? 32 : 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2AABEE),
                            Color(0xFF229ED9),
                            Color(0xFF0088CC),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2AABEE).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: widget.compact ? 16 : 19,
                        ),
                      ),
                    ),

                    SizedBox(width: widget.compact ? 10 : 14),

                    // Copyright & Dev Texts
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'حقوق الطبع والنشر محفوظة © ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: widget.compact ? 11 : 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isLight
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              Text(
                                DeveloperCreditsBadge.developerName,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: widget.compact ? 11.5 : 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFD56B),
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFFFD56B).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const StarGlint(size: 11),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'تواصل مع المطور عبر تلجرام • ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: widget.compact ? 9.5 : 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isLight
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const Text(
                                '@o_w_i',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2AABEE),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: widget.compact ? 8 : 12),

                    // Arrow / External Link Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD56B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: Color(0xFFFFD56B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
