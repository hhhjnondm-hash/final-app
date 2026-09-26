import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated acoustic equalizer waveform bars for Quran/Radio playback.
class SoundWaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double barWidth;
  final double maxHeight;
  final double minHeight;
  final double spacing;
  final Color activeColor;
  final Color idleColor;

  const SoundWaveVisualizer({
    super.key,
    this.isPlaying = true,
    this.barCount = 7,
    this.barWidth = 2.5,
    this.maxHeight = 18.0,
    this.minHeight = 4.0,
    this.spacing = 2.5,
    this.activeColor = const Color(0xFFFFD56B),
    this.idleColor = const Color(0xFF64748B),
  });

  @override
  State<SoundWaveVisualizer> createState() => _SoundWaveVisualizerState();
}

class _SoundWaveVisualizerState extends State<SoundWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoundWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            double height = widget.minHeight;

            if (widget.isPlaying) {
              // Staggered sinusoidal heights for natural acoustic fluid motion
              final phase = (index / widget.barCount) * 2 * math.pi;
              final t = _controller.value * 2 * math.pi;
              final factor = (math.sin(t + phase) + 1.0) / 2.0; // 0..1
              final factor2 = (math.cos(t * 1.5 + phase * 0.7) + 1.0) / 2.0;
              final combined = (factor * 0.6 + factor2 * 0.4);
              height = widget.minHeight + (widget.maxHeight - widget.minHeight) * combined;
            }

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.barWidth,
              height: height,
              decoration: BoxDecoration(
                color: widget.isPlaying ? widget.activeColor : widget.idleColor,
                borderRadius: BorderRadius.circular(widget.barWidth),
                boxShadow: widget.isPlaying
                    ? [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
