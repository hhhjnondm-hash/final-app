import 'package:flutter/material.dart';

/// Animated 4-point golden star lens flare / sparkle glint for card corners and headers.
class StarGlint extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final bool rotate;

  const StarGlint({
    super.key,
    this.size = 20,
    this.color = const Color(0xFFFFD56B),
    this.duration = const Duration(milliseconds: 2400),
    this.rotate = true,
  });

  @override
  State<StarGlint> createState() => _StarGlintState();
}

class _StarGlintState extends State<StarGlint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.65, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final glow = _glowAnimation.value;
          final rotation = widget.rotate ? _controller.value * 0.15 : 0.0;

          return Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _StarGlintPainter(
                    color: widget.color,
                    glowOpacity: glow,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StarGlintPainter extends CustomPainter {
  final Color color;
  final double glowOpacity;

  _StarGlintPainter({
    required this.color,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Soft radial bloom
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.6 * glowOpacity),
          color.withValues(alpha: 0.15 * glowOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glowPaint);

    // 2. Primary 4-point Diamond Star Ray Path
    final starPaint = Paint()
      ..color = color.withValues(alpha: (0.7 + 0.3 * glowOpacity).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    final rMax = radius * 0.95;
    final rMin = radius * 0.18;

    path.moveTo(center.dx, center.dy - rMax); // Top
    path.quadraticBezierTo(center.dx, center.dy, center.dx + rMax, center.dy); // Right
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + rMax); // Bottom
    path.quadraticBezierTo(center.dx, center.dy, center.dx - rMax, center.dy); // Left
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - rMax);
    path.close();

    canvas.drawPath(path, starPaint);

    // 3. Subtle 45-degree diagonal cross rays
    final diagPaint = Paint()
      ..color = color.withValues(alpha: 0.45 * glowOpacity)
      ..style = PaintingStyle.fill;

    final diagPath = Path();
    final dMax = radius * 0.5;

    diagPath.moveTo(center.dx + dMax * 0.707, center.dy - dMax * 0.707);
    diagPath.quadraticBezierTo(center.dx, center.dy, center.dx + dMax * 0.707, center.dy + dMax * 0.707);
    diagPath.quadraticBezierTo(center.dx, center.dy, center.dx - dMax * 0.707, center.dy + dMax * 0.707);
    diagPath.quadraticBezierTo(center.dx, center.dy, center.dx - dMax * 0.707, center.dy - dMax * 0.707);
    diagPath.quadraticBezierTo(center.dx, center.dy, center.dx + dMax * 0.707, center.dy - dMax * 0.707);
    diagPath.close();

    canvas.drawPath(diagPath, diagPaint);

    // 4. Brilliant bright core dot
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: glowOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rMin, corePaint);
  }

  @override
  bool shouldRepaint(covariant _StarGlintPainter oldDelegate) =>
      oldDelegate.glowOpacity != glowOpacity || oldDelegate.color != color;
}
