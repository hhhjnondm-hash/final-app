import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../services/theme_service.dart';
import 'visual_effects/glowing_lantern.dart';

class IslamicBackground extends StatelessWidget {
  final Widget child;
  final bool showParticles;
  final bool showSacredGeometry;

  const IslamicBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showSacredGeometry = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DesignSystem.currentPalette;
    final isLight = !palette.isDark;

    return Stack(
      children: [
        // 1. Dynamic Background: Bound to current active palette (Deep Sapphire, Emerald, Night, Sky Blue, Warm Sand, Soft Rose)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: palette.bgMain,
              gradient: isLight
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.bgMain,
                        palette.bgSecondary,
                        palette.bgMain.withValues(alpha: 0.95),
                      ],
                    )
                  : RadialGradient(
                      center: const Alignment(0.0, -0.3),
                      radius: 1.3,
                      colors: [
                        palette.cardElevated,
                        palette.bgSecondary,
                        palette.bgMain,
                      ],
                    ),
            ),
          ),
        ),

        // 2. Subtle Botanical Leaves & Islamic Sacred Geometry in Canvas matching active theme
        if (showSacredGeometry)
          Positioned.fill(
            child: CustomPaint(
              painter: isLight
                  ? _DaytimeCourtyardPainter(accentColor: palette.accentGlow)
                  : _NightCourtyardPainter(goldColor: palette.goldAccent),
            ),
          ),

        // 3. Left Hanging Golden Lantern with Radiant Gold Glow & Pendulum Sway
        Positioned(
          top: 0,
          left: 36,
          child: GlowingLantern(
            height: 140,
            chainHeight: 38,
            isLeft: true,
            isLight: isLight,
          ),
        ),

        // 4. Right Hanging Golden Lantern with Radiant Gold Glow & Pendulum Sway
        Positioned(
          top: 0,
          right: 36,
          child: GlowingLantern(
            height: 140,
            chainHeight: 38,
            isLeft: false,
            isLight: isLight,
          ),
        ),

        // 5. Left Architectural Arch Silhouette & Text: "كل خطوة تقربك من الله"
        Positioned(
          top: 320,
          left: 18,
          child: _buildSideInspiration(
            text: 'كل\nخطوة\nتقربك\nمن الله',
            palette: palette,
          ),
        ),

        // 6. Right Architectural Arch Silhouette & Text: "طريقك إلى الطمأنينة"
        Positioned(
          top: 320,
          right: 18,
          child: _buildSideInspiration(
            text: 'طريقك\nإلى\nالطمأنينة',
            palette: palette,
          ),
        ),

        // Content
        child,
      ],
    );
  }

  Widget _buildSideInspiration({required String text, required AppThemePalette palette}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 24,
                height: 1.5,
                color: palette.goldAccent.withValues(alpha: palette.isDark ? 0.6 : 0.4),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NightCourtyardPainter extends CustomPainter {
  final Color goldColor;
  _NightCourtyardPainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final glowPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // Islamic 8-point geometric star lattices
    _drawStar(canvas, const Offset(60, 100), 45, patternPaint);
    _drawStar(canvas, Offset(size.width - 60, 100), 45, patternPaint);
    _drawStar(canvas, Offset(60, size.height - 120), 55, patternPaint);
    _drawStar(canvas, Offset(size.width - 60, size.height - 120), 55, patternPaint);

    // Subtle ambient glow points
    canvas.drawCircle(Offset(size.width * 0.5, 80), 120, glowPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = (i % 2 == 0) ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NightCourtyardPainter oldDelegate) =>
      oldDelegate.goldColor != goldColor;
}

class _DaytimeCourtyardPainter extends CustomPainter {
  final Color accentColor;
  _DaytimeCourtyardPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final leafPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    // Outer subtle Islamic geometry (8-point star lattices in corners)
    _drawStar(canvas, const Offset(60, 100), 40, patternPaint);
    _drawStar(canvas, Offset(size.width - 60, 100), 40, patternPaint);
    _drawStar(canvas, Offset(60, size.height - 120), 50, patternPaint);
    _drawStar(canvas, Offset(size.width - 60, size.height - 120), 50, patternPaint);

    // Subtle botanical leaves in bottom corners
    _drawBotanicalLeaf(canvas, Offset(30, size.height - 40), 60, leafPaint);
    _drawBotanicalLeaf(canvas, Offset(size.width - 30, size.height - 40), -60, leafPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = (i % 2 == 0) ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawBotanicalLeaf(Canvas canvas, Offset origin, double size, Paint paint) {
    final path = Path();
    path.moveTo(origin.dx, origin.dy);
    path.quadraticBezierTo(origin.dx + size, origin.dy - size * 1.5, origin.dx + size * 1.8, origin.dy - size * 0.5);
    path.quadraticBezierTo(origin.dx + size * 0.8, origin.dy + size * 0.5, origin.dx, origin.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DaytimeCourtyardPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
