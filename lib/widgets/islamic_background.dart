import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/design_system.dart';

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
    final isLight = DesignSystem.isLightMode;

    return Stack(
      children: [
        // 1. Dynamic Background: Royal Obsidian Black & Gold (Dark) or Soft Warm Ivory (Light)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF8F6F0) : const Color(0xFF07090E),
              gradient: isLight
                  ? const RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFFFFF), // Radiant daylight center
                        Color(0xFFF8F6F0), // Warm ivory
                        Color(0xFFF2EFE9), // Soft outer edge
                      ],
                    )
                  : const RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.3,
                      colors: [
                        Color(0xFF141E30), // Luminous midnight navy-gold
                        Color(0xFF0A0E17), // Deep obsidian
                        Color(0xFF07090E), // Pure void black
                      ],
                    ),
            ),
          ),
        ),

        // 2. Subtle Botanical Leaves & Islamic Sacred Geometry in Canvas
        Positioned.fill(
          child: CustomPaint(
            painter: isLight ? _DaytimeCourtyardPainter() : _NightCourtyardPainter(),
          ),
        ),

        // 3. Left Hanging Golden Lantern with Radiant Gold Glow
        Positioned(
          top: 0,
          left: 36,
          child: _buildLantern(height: 140, isLeft: true, isLight: isLight),
        ),

        // 4. Right Hanging Golden Lantern with Radiant Gold Glow
        Positioned(
          top: 0,
          right: 36,
          child: _buildLantern(height: 140, isLeft: false, isLight: isLight),
        ),

        // 5. Left Architectural Arch Silhouette & Text: "كل خطوة تقربك من الله"
        Positioned(
          top: 320,
          left: 18,
          child: _buildSideInspiration(
            text: 'كل\nخطوة\nتقربك\nمن الله',
            isLight: isLight,
          ),
        ),

        // 6. Right Architectural Arch Silhouette & Text: "طريقك إلى الطمأنينة"
        Positioned(
          top: 320,
          right: 18,
          child: _buildSideInspiration(
            text: 'طريقك\nإلى\nالطمأنينة',
            isLight: isLight,
          ),
        ),

        // Content
        child,
      ],
    );
  }

  Widget _buildLantern({required double height, required bool isLeft, bool isLight = true}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chain
        Container(
          width: 1.5,
          height: 35,
          color: const Color(0xFFC89B3C).withValues(alpha: isLight ? 0.45 : 0.75),
        ),
        // Lantern Body
        Container(
          width: 32,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? const [
                      Color(0xFFE8D29A),
                      Color(0xFFC89B3C),
                      Color(0xFF996515),
                    ]
                  : const [
                      Color(0xFFFFE082),
                      Color(0xFFC89B3C),
                      Color(0xFF805300),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? const Color(0xFFC89B3C).withValues(alpha: 0.22)
                    : const Color(0xFFC89B3C).withValues(alpha: 0.45),
                blurRadius: isLight ? 20 : 28,
                spreadRadius: isLight ? 2 : 4,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 28,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFFFFBEA) : const Color(0xFFFFF4D0),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isLight ? const Color(0xFFFFE8A3) : const Color(0xFFFFD56B),
                    blurRadius: isLight ? 10 : 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideInspiration({required String text, bool isLight = true}) {
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
                  color: isLight ? const Color(0xFF667085) : const Color(0xFF8C9BAE),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 24,
                height: 1.5,
                color: const Color(0xFFC89B3C).withValues(alpha: isLight ? 0.4 : 0.6),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NightCourtyardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = const Color(0xFFC89B3C).withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final glowPaint = Paint()
      ..color = const Color(0xFFC89B3C).withValues(alpha: 0.02)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DaytimeCourtyardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = const Color(0xFF102A43).withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final leafPaint = Paint()
      ..color = const Color(0xFF0F6B78).withValues(alpha: 0.035)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
