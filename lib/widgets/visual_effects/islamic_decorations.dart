import 'package:flutter/material.dart';

/// Custom decorative painter that draws an authentic dual golden Islamic pointed arch border.
class IslamicArchBorderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final double innerPadding;

  IslamicArchBorderPainter({
    this.primaryColor = const Color(0xFFFFD56B),
    this.secondaryColor = const Color(0xFFC89B3C),
    this.strokeWidth = 1.2,
    this.innerPadding = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final innerPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8;

    // Draw Outer Rounded Rect
    final outerRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(outerRRect, outerPaint);

    // Draw Inner Inset Rounded Rect
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        innerPadding,
        innerPadding,
        size.width - innerPadding * 2,
        size.height - innerPadding * 2,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(innerRRect, innerPaint);

    // Subtle golden corner accents
    _drawCornerGlint(canvas, Offset(8, 8), primaryColor);
    _drawCornerGlint(canvas, Offset(size.width - 8, 8), primaryColor);
    _drawCornerGlint(canvas, Offset(8, size.height - 8), primaryColor);
    _drawCornerGlint(canvas, Offset(size.width - 8, size.height - 8), primaryColor);
  }

  void _drawCornerGlint(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 1.8, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicArchBorderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;
}
