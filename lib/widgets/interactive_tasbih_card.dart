import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/design_system.dart';

class InteractiveTasbihCard extends StatefulWidget {
  final VoidCallback? onSettingsTap;

  const InteractiveTasbihCard({
    super.key,
    this.onSettingsTap,
  });

  @override
  State<InteractiveTasbihCard> createState() => _InteractiveTasbihCardState();
}

class _InteractiveTasbihCardState extends State<InteractiveTasbihCard>
    with SingleTickerProviderStateMixin {
  int _counter = 33;
  int _selectedDhikrIndex = 0;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  final List<String> _adhkar = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    HapticFeedback.lightImpact();
    setState(() {
      _counter++;
    });
    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
  }

  void _resetCounter() {
    HapticFeedback.mediumImpact();
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final currentDhikr = _adhkar[_selectedDhikrIndex];

    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFFC89B3C).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (!isLight)
            BoxShadow(
              color: const Color(0xFFFFD56B).withValues(alpha: 0.08),
              blurRadius: 14,
            ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: "السبحة الإلكترونية" + Gear Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: isLight ? const Color(0xFF854D0E) : const Color(0xFF8E9BAE),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'السبحة الإلكترونية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isLight ? const Color(0xFF1C1917) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFFFFD56B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLight ? const Color(0xFFE5D4B3) : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      Icons.all_inclusive_rounded,
                      color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                      size: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Central Circular 3D Rosary Beads with Counter
          Expanded(
            child: GestureDetector(
              onTap: _incrementCounter,
              behavior: HitTestBehavior.opaque,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular Rosary Beads Canvas
                      RepaintBoundary(
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: CustomPaint(
                            painter: _RosaryBeadsPainter(
                              isLight: isLight,
                              activeBeadIndex: _counter % 33,
                            ),
                          ),
                        ),
                      ),

                      // Center Count & Dhikr Title
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_counter',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: isLight ? const Color(0xFF1C1917) : const Color(0xFFFFD56B),
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                if (!isLight)
                                  Shadow(
                                    color: const Color(0xFFFFD56B).withValues(alpha: 0.6),
                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentDhikr,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: isLight ? const Color(0xFF78716C) : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Quick Dhikr Selector & Reset Button
          Row(
            children: [
              // Reset Button (↺)
              InkWell(
                onTap: _resetCounter,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFBF4E4) : const Color(0xFF151D2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE5D4B3) : Colors.white12,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3 Quick Dhikr Buttons
              Expanded(
                child: Row(
                  children: List.generate(3, (index) {
                    final isSelected = _selectedDhikrIndex == index;
                    final dhikrName = _adhkar[index];

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDhikrIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: isLight
                                          ? const [Color(0xFFFFDF7D), Color(0xFFE5A83B), Color(0xFFC89B3C)]
                                          : const [Color(0xFFFFE082), Color(0xFFFFD56B), Color(0xFFC89B3C)],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isLight ? const Color(0xFFFBF4E4) : const Color(0xFF131B27)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B))
                                    : (isLight ? const Color(0xFFE5D4B3) : Colors.white10),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B)).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              dhikrName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isSelected
                                    ? (isLight ? const Color(0xFF1C1917) : const Color(0xFF07090E))
                                    : (isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8)),
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RosaryBeadsPainter extends CustomPainter {
  final bool isLight;
  final int activeBeadIndex;

  _RosaryBeadsPainter({
    required this.isLight,
    required this.activeBeadIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 6);
    final radius = size.width * 0.38;
    const int beadCount = 33;

    // Draw connecting cord ring
    final cordPaint = Paint()
      ..color = const Color(0xFFC89B3C).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, cordPaint);

    // Draw 33 spherical 3D golden beads
    for (int i = 0; i < beadCount; i++) {
      final angle = (i / beadCount) * 2 * math.pi - math.pi / 2;
      final beadCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final isCurrent = i == activeBeadIndex;
      final beadRadius = isCurrent ? 6.5 : 5.0;

      // Outer golden bead aura/glow (ultra-fast alpha circle, 0 GPU jank)
      final shadowPaint = Paint()
        ..color = (isCurrent ? const Color(0xFFFFD56B) : const Color(0xFFC89B3C)).withValues(alpha: isCurrent ? 0.35 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(beadCenter, beadRadius + (isCurrent ? 2.5 : 1.2), shadowPaint);

      // Bead gradient sphere
      final beadGradient = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: isCurrent
            ? const [
                Color(0xFFFFFFFF),
                Color(0xFFFFE082),
                Color(0xFFFFD56B),
                Color(0xFFB37D14),
              ]
            : const [
                Color(0xFFFFF0C2),
                Color(0xFFE5B54F),
                Color(0xFFC89B3C),
                Color(0xFF6B4500),
              ],
      ).createShader(Rect.fromCircle(center: beadCenter, radius: beadRadius));

      final beadPaint = Paint()..shader = beadGradient;
      canvas.drawCircle(beadCenter, beadRadius, beadPaint);
    }

    // Draw Golden Tassel at the bottom
    final bottomOffset = Offset(center.dx, center.dy + radius);
    final tasselPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFD56B),
          Color(0xFFC89B3C),
          Color(0xFF805300),
        ],
      ).createShader(Rect.fromLTWH(bottomOffset.dx - 8, bottomOffset.dy, 16, 22));

    final path = Path();
    path.moveTo(bottomOffset.dx - 2, bottomOffset.dy);
    path.lineTo(bottomOffset.dx + 2, bottomOffset.dy);
    path.lineTo(bottomOffset.dx + 7, bottomOffset.dy + 18);
    path.lineTo(bottomOffset.dx - 7, bottomOffset.dy + 18);
    path.close();

    canvas.drawPath(path, tasselPaint);
  }

  @override
  bool shouldRepaint(covariant _RosaryBeadsPainter oldDelegate) =>
      oldDelegate.activeBeadIndex != activeBeadIndex || oldDelegate.isLight != isLight;
}
