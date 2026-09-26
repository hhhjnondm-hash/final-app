import 'package:flutter/material.dart';

/// Shimmer light sweep effect that periodically glints across a widget or background.
class ShimmerSweep extends StatefulWidget {
  final Widget? child;
  final Duration duration;
  final Duration pauseDuration;
  final Color shimmerColor;
  final double angle;

  const ShimmerSweep({
    super.key,
    this.child,
    this.duration = const Duration(milliseconds: 2200),
    this.pauseDuration = const Duration(milliseconds: 3000),
    this.shimmerColor = const Color(0xFFFFD56B),
    this.angle = -0.45, // subtle diagonal
  });

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _startShimmerCycle();
  }

  void _startShimmerCycle() async {
    while (mounted) {
      await _controller.forward(from: 0.0);
      if (!mounted) break;
      await Future.delayed(widget.pauseDuration);
      if (!mounted) break;
    }
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
          final progress = _controller.value;

          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  widget.shimmerColor.withValues(alpha: 0.06),
                  widget.shimmerColor.withValues(alpha: 0.32),
                  widget.shimmerColor.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                transform: _SlidingGradientTransform(slidePercent: progress),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final translation = (bounds.width + bounds.height) * (slidePercent * 2.0 - 0.5);
    return Matrix4.translationValues(translation, 0, 0);
  }
}

/// A subtle diagonal ambient light beam / streak painter for section backgrounds.
class DiagonalLightBeamPainter extends CustomPainter {
  final Color beamColor;
  final double opacity;

  DiagonalLightBeamPainter({
    this.beamColor = const Color(0xFFFFD56B),
    this.opacity = 0.08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          beamColor.withValues(alpha: opacity * 0.4),
          beamColor.withValues(alpha: opacity),
          beamColor.withValues(alpha: opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Offset.zero & size);

    final path = Path();
    path.moveTo(-size.width * 0.2, size.height);
    path.lineTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.8, 0);
    path.lineTo(size.width * 0.2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DiagonalLightBeamPainter oldDelegate) =>
      oldDelegate.beamColor != beamColor || oldDelegate.opacity != opacity;
}
