import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class IslamicBackground extends StatefulWidget {
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
  State<IslamicBackground> createState() => _IslamicBackgroundState();
}

class _IslamicBackgroundState extends State<IslamicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Mesh Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              color: DesignSystem.bgDarkest,
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.6),
                radius: 1.3,
                colors: [
                  Color(0xFF0F1E38), // Deep Midnight Blue Glow
                  Color(0xFF07101E),
                  DesignSystem.bgDarkest,
                ],
              ),
            ),
          ),
        ),

        // Secondary Radial Glow (Cosmic Violet / Gold)
        Positioned(
          top: -120,
          right: -80,
          width: 340,
          height: 340,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DesignSystem.violet.withOpacity(0.12),
                  DesignSystem.electricBlue.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Subtle Gold Ambient Glow at the bottom
        Positioned(
          bottom: -150,
          left: -80,
          width: 380,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DesignSystem.gold.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Animated Sacred Geometry / Subtle Particles
        if (widget.showParticles)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SacredParticlesPainter(
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),

        // Foreground Content
        widget.child,
      ],
    );
  }
}

class _SacredParticlesPainter extends CustomPainter {
  final double progress;

  _SacredParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    const particleCount = 28;
    for (int i = 0; i < particleCount; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.5;
      final radius = 1.0 + random.nextDouble() * 1.8;

      final animatedY = (baseY - (progress * speed * 60)) % size.height;
      final opacity = (math.sin((progress * 2 * math.pi) + i) * 0.3 + 0.5)
          .clamp(0.1, 0.65);

      final isGold = i % 3 == 0;
      paint.color = isGold
          ? DesignSystem.goldLight.withOpacity(opacity * 0.7)
          : DesignSystem.cyanGlow.withOpacity(opacity * 0.5);

      canvas.drawCircle(Offset(baseX, animatedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SacredParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
