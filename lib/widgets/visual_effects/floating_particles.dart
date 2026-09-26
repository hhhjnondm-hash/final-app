import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Atmospheric floating golden spiritual dust particles
class FloatingParticles extends StatefulWidget {
  final int numberOfParticles;
  final Color particleColor;
  final Widget child;

  const FloatingParticles({
    super.key,
    this.numberOfParticles = 18,
    this.particleColor = const Color(0xFFFFD56B),
    required this.child,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ParticleModel> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.numberOfParticles; i++) {
      _particles.add(
        _ParticleModel(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2.5 + 1.2,
          speed: _random.nextDouble() * 0.08 + 0.03,
          theta: _random.nextDouble() * 2 * math.pi,
          alpha: _random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _controller.value,
                  baseColor: widget.particleColor,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ParticleModel {
  double x;
  double y;
  final double size;
  final double speed;
  final double theta;
  final double alpha;

  _ParticleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.theta,
    required this.alpha,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_ParticleModel> particles;
  final double progress;
  final Color baseColor;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y - progress * p.speed) % 1.0;
      final currentX = (p.x + math.sin(progress * 2 * math.pi + p.theta) * 0.03) % 1.0;

      final posX = currentX * size.width;
      final posY = currentY * size.height;

      final paint = Paint()
        ..color = baseColor.withValues(alpha: p.alpha * (0.6 + 0.4 * math.sin(progress * 2 * math.pi + p.theta)))
        ..style = PaintingStyle.fill;

      // Draw glowing particle
      canvas.drawCircle(Offset(posX, posY), p.size, paint);

      // Glow halo around particle
      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: p.alpha * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(posX, posY), p.size * 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
