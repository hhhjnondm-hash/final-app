import 'package:flutter/material.dart';

/// An animated glowing Islamic lantern with gentle pendulum sway and warm breathing ambient light cone.
class GlowingLantern extends StatefulWidget {
  final double height;
  final double chainHeight;
  final bool isLeft;
  final bool isLight;
  final double maxSwayAngle;
  final Duration swayDuration;

  const GlowingLantern({
    super.key,
    this.height = 130,
    this.chainHeight = 36,
    this.isLeft = true,
    this.isLight = false,
    this.maxSwayAngle = 0.035, // ~2 degrees gentle sway
    this.swayDuration = const Duration(milliseconds: 3200),
  });

  @override
  State<GlowingLantern> createState() => _GlowingLanternState();
}

class _GlowingLanternState extends State<GlowingLantern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swayAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.swayDuration,
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(
      begin: -widget.maxSwayAngle,
      end: widget.maxSwayAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;
    final primaryGold = isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B);
    final deepGold = isLight ? const Color(0xFF996515) : const Color(0xFFC89B3C);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sway = _swayAnimation.value * (widget.isLeft ? 1.0 : -1.0);
        final glowScale = _glowAnimation.value;

        return Transform(
          transform: Matrix4.rotationZ(sway),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hanging Chain with tiny links
              Container(
                width: 2,
                height: widget.chainHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryGold.withValues(alpha: isLight ? 0.3 : 0.6),
                      primaryGold.withValues(alpha: isLight ? 0.8 : 1.0),
                    ],
                  ),
                ),
              ),

              // Lantern Top Ring & Dome
              CustomPaint(
                size: const Size(26, 12),
                painter: _LanternCapPainter(color: deepGold),
              ),

              // Lantern Main Glass & Brass Frame
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ambient warm light cone / bloom radiating outwards
                  Positioned(
                    top: -10,
                    child: Container(
                      width: 90 * glowScale,
                      height: 110 * glowScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.25 : 0.40),
                            const Color(0xFFE5A93C).withValues(alpha: isLight ? 0.12 : 0.20),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Lantern Geometric Brass Housing
                  Container(
                    width: 32,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isLight
                            ? [
                                const Color(0xFFE8D29A),
                                const Color(0xFFC89B3C),
                                const Color(0xFF8B6214),
                              ]
                            : [
                                const Color(0xFFFFE8A3),
                                const Color(0xFFD4A038),
                                const Color(0xFF6B4500),
                              ],
                      ),
                      border: Border.all(
                        color: primaryGold,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.3 : 0.55),
                          blurRadius: 18 * glowScale,
                          spreadRadius: 2 * glowScale,
                        ),
                      ],
                    ),
                    child: Center(
                      // Inner Glowing Core (Flame / Lamp Chamber)
                      child: Container(
                        width: 16,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFFFFBEA) : const Color(0xFFFFF7DB),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE082),
                              blurRadius: 12 * glowScale,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          // Little golden flame
                          child: Container(
                            width: 6,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFFF5722),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Finial / Tassel
              CustomPaint(
                size: const Size(12, 10),
                painter: _LanternFinialPainter(color: deepGold),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanternCapPainter extends CustomPainter {
  final Color color;
  _LanternCapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.4, 0, size.height);
    path.lineTo(size.width, size.height);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.4, size.width * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Mini hanging loop
    final loopPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width * 0.5, -2), 3, loopPaint);
  }

  @override
  bool shouldRepaint(covariant _LanternCapPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LanternFinialPainter extends CustomPainter {
  final Color color;
  _LanternFinialPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.5, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LanternFinialPainter oldDelegate) =>
      oldDelegate.color != color;
}
