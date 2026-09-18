import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/athan_service.dart';
import '../services/notification_service.dart';
import '../utils/design_system.dart';

class PrayerAthanDialog extends StatefulWidget {
  final String prayerName;
  final String arabicName;

  const PrayerAthanDialog({
    super.key,
    required this.prayerName,
    required this.arabicName,
  });

  static Future<void> show(
    BuildContext context, {
    required String prayerName,
    required String arabicName,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) => PrayerAthanDialog(
        prayerName: prayerName,
        arabicName: arabicName,
      ),
    );
  }

  @override
  State<PrayerAthanDialog> createState() => _PrayerAthanDialogState();
}

class _PrayerAthanDialogState extends State<PrayerAthanDialog>
    with SingleTickerProviderStateMixin {
  final AthanService _athanService = AthanService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _stopAndDismiss() {
    _athanService.stopAthan();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _athanService.stopAthan();
    } else {
      _athanService.playAthan(prayer: widget.prayerName, showDialog: false);
    }
  }

  void _snoozeReminder() {
    _athanService.stopAthan();
    NotificationService().scheduleMissedPrayerReminder(
      id: 999,
      prayerName: widget.prayerName,
      arabicName: widget.arabicName,
      prayerTime: DateTime.now(),
      delayMinutes: 15,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'سيتم تذكيرك بصلاة ${widget.arabicName} بعد 15 دقيقة إن شاء الله',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: DesignSystem.gold,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _muteToday() {
    _athanService.stopAthan();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إيقاف صوت الإشعارات لبقية صلوات اليوم',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          decoration: BoxDecoration(
            color: const Color(0xFF090D14),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.38),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.16),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Colors.black,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Bar: Sound Bell (animated pulsing soundwaves) & Close Button (X)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sound Bell Button (( 🔔 ))
                      _buildSoundBellButton(),

                      // Close X Button
                      _buildCloseButton(),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 2. Islamic Arch Window with Clean Mosque Sunset Scenery
                  _buildIslamicArchScenery(),

                  const SizedBox(height: 12),

                  // 3. 'حان الآن'
                  const Text(
                    'حان الآن',
                    style: TextStyle(
                      color: Color(0xFFD6C5A2),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 4. '❖ أذان الفجر ❖' with glowing gold calligraphy
                  _buildPrayerTitle(),

                  const SizedBox(height: 4),

                  // 5. 'حان وقت الصلاة'
                  const Text(
                    'حان وقت الصلاة',
                    style: TextStyle(
                      color: Color(0xFF909EAE),
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. Delicate Geometric Diamond Divider: ──── ◈ ────
                  _buildGeometricDivider(),

                  const SizedBox(height: 14),

                  // 7. Framed Ayah Card
                  _buildAyahCard(),

                  const SizedBox(height: 16),

                  // 8. Main Action Button: [ 🧎 هيا إلى الصلاة ]
                  _buildMainActionButton(),

                  const SizedBox(height: 10),

                  // 9. Secondary Capsule Buttons: [ تذكّرني لاحقاً ] & [ إيقاف الإشعار لـ اليوم ]
                  _buildSecondaryActionButtons(),

                  const SizedBox(height: 14),

                  // 10. Footer with Heart: ────── 💛 الصلاة نور لحياتك ──────
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Left Sound Bell Button with animated golden acoustic waves: (( 🔔 ))
  Widget _buildSoundBellButton() {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left acoustic waves
            CustomPaint(
              size: const Size(12, 28),
              painter: _AcousticWavePainter(isLeft: true, isMuted: _isMuted),
            ),
            const SizedBox(width: 4),
            // Central glowing circular bell
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF131924),
                  border: Border.all(
                    color: _isMuted
                        ? Colors.white24
                        : const Color(0xFFE5C066).withValues(alpha: 0.7),
                    width: 1.4,
                  ),
                  boxShadow: [
                    if (!_isMuted)
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Icon(
                  _isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_rounded,
                  color: _isMuted ? Colors.white54 : const Color(0xFFF3E7C4),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Right acoustic waves
            CustomPaint(
              size: const Size(12, 28),
              painter: _AcousticWavePainter(isLeft: false, isMuted: _isMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Right Circular Close Button (X)
  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: _stopAndDismiss,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131924),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white70,
          size: 19,
        ),
      ),
    );
  }

  /// Islamic Arch Window with Clean Mosque Artwork & Custom Border
  Widget _buildIslamicArchScenery() {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle arabesque glow on the sides
          Positioned(
            top: 20,
            left: 10,
            child: Icon(
              Icons.stars_rounded,
              color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
              size: 24,
            ),
          ),
          Positioned(
            top: 20,
            right: 10,
            child: Icon(
              Icons.stars_rounded,
              color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
              size: 24,
            ),
          ),

          // The Clipped Arch Scenery
          SizedBox(
            width: 270,
            height: 180,
            child: ClipPath(
              clipper: IslamicArchClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Clean mosque image
                  Image.asset(
                    'assets/images/athan_mosque_clean.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, -0.3),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF131924),
                        child: const Center(
                          child: Icon(
                            Icons.mosque_rounded,
                            size: 70,
                            color: Color(0xFFC89B3C),
                          ),
                        ),
                      );
                    },
                  ),

                  // Dark bottom gradient overlay to blend into the card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF090D14).withValues(alpha: 0.4),
                          const Color(0xFF090D14).withValues(alpha: 0.95),
                        ],
                        stops: const [0.55, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // The Golden Ornamental Arch Border Painter
          SizedBox(
            width: 270,
            height: 180,
            child: CustomPaint(
              painter: IslamicArchBorderPainter(),
            ),
          ),
        ],
      ),
    );
  }

  /// Big Glowing Golden Title: ❖ أَذَان الفَجْر ❖
  Widget _buildPrayerTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '❖',
          style: TextStyle(
            color: Color(0xFFC89B3C),
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'أَذَان ${widget.arabicName}',
          style: const TextStyle(
            color: Color(0xFFF9EED4),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: Color(0xFFD49E3D),
                blurRadius: 18,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '❖',
          style: TextStyle(
            color: Color(0xFFC89B3C),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Delicate Geometric Diamond Divider: ──── ◈ ────
  Widget _buildGeometricDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 0.8,
          color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '◈',
            style: TextStyle(
              color: Color(0xFFC89B3C),
              fontSize: 11,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 0.8,
          color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
        ),
      ],
    );
  }

  /// Framed Quranic Ayah Card
  Widget _buildAyahCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.28),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'قال الله تعالى:',
            style: TextStyle(
              color: Color(0xFFC5B494),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '«',
                style: TextStyle(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'وَأَقِمِ الصَّلَاةَ لِذِكْرِي',
                style: TextStyle(
                  color: Color(0xFFF9EED4),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '»',
                style: TextStyle(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '[ طه : 14 ]',
            style: TextStyle(
              color: Color(0xFF7E8B9B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Main Action Button: [ 🧎 هيا إلى الصلاة ]
  Widget _buildMainActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3C775),
              Color(0xFFD49E3D),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD49E3D).withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: _stopAndDismiss,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFF1E1404),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'هيا إلى الصلاة',
                  style: TextStyle(
                    color: Color(0xFF1E1404),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Secondary Capsule Buttons: [ تذكّرني لاحقاً ] & [ إيقاف الإشعار لـ اليوم ]
  Widget _buildSecondaryActionButtons() {
    return Row(
      children: [
        // Right: تذكّرني لاحقاً
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF121824),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: _snoozeReminder,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFFB0BCC9),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'تذكّرني لاحقاً',
                      style: TextStyle(
                        color: Color(0xFFD3DDE7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Left: إيقاف الإشعار لـ اليوم
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF121824),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: _muteToday,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: Color(0xFFB0BCC9),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'إيقاف إشعار اليوم',
                      style: TextStyle(
                        color: Color(0xFFD3DDE7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Footer with Heart: ────── 💛 الصلاة نور لحياتك ──────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Text(
                '💛',
                style: TextStyle(fontSize: 11),
              ),
              SizedBox(width: 6),
              Text(
                'الصلاة نور لحياتك',
                style: TextStyle(
                  color: Color(0xFF728090),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

/// Custom Clipper for pointed Islamic Moroccan/Moorish Trefoil Arch
class IslamicArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Start at bottom left
    path.moveTo(0, h);
    // Vertical left wall
    path.lineTo(0, h * 0.50);

    // Left lower outward lobe
    path.cubicTo(
      0, h * 0.35,
      w * 0.09, h * 0.27,
      w * 0.17, h * 0.27,
    );

    // Left inward cusp
    path.cubicTo(
      w * 0.23, h * 0.27,
      w * 0.23, h * 0.19,
      w * 0.26, h * 0.15,
    );

    // Left soaring pointed arc to top center peak
    path.cubicTo(
      w * 0.31, h * 0.04,
      w * 0.41, 0,
      w * 0.50, 0,
    );

    // Right soaring pointed arc from top center peak
    path.cubicTo(
      w * 0.59, 0,
      w * 0.69, h * 0.04,
      w * 0.74, h * 0.15,
    );

    // Right inward cusp
    path.cubicTo(
      w * 0.77, h * 0.19,
      w * 0.77, h * 0.27,
      w * 0.83, h * 0.27,
    );

    // Right lower outward lobe
    path.cubicTo(
      w * 0.91, h * 0.27,
      w, h * 0.35,
      w, h * 0.50,
    );

    // Vertical right wall
    path.lineTo(w, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter to draw the fine golden ornamental trim along the Islamic Arch
class IslamicArchBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h * 0.50);
    path.cubicTo(0, h * 0.35, w * 0.09, h * 0.27, w * 0.17, h * 0.27);
    path.cubicTo(w * 0.23, h * 0.27, w * 0.23, h * 0.19, w * 0.26, h * 0.15);
    path.cubicTo(w * 0.31, h * 0.04, w * 0.41, 0, w * 0.50, 0);
    path.cubicTo(w * 0.59, 0, w * 0.69, h * 0.04, w * 0.74, h * 0.15);
    path.cubicTo(w * 0.77, h * 0.19, w * 0.77, h * 0.27, w * 0.83, h * 0.27);
    path.cubicTo(w * 0.91, h * 0.27, w, h * 0.35, w, h * 0.50);

    // 1. Soft gold outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFC89B3C).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // 2. Primary golden stroke line
    final strokePaint = Paint()
      ..color = const Color(0xFFE5C066)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, strokePaint);

    // 3. Top peak finial / crest small ornament
    final finialPaint = Paint()
      ..color = const Color(0xFFF6E7C4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, 0), 2.5, finialPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom Painter for acoustic soundwaves: ((  ))
class _AcousticWavePainter extends CustomPainter {
  final bool isLeft;
  final bool isMuted;

  _AcousticWavePainter({required this.isLeft, required this.isMuted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isMuted
          ? Colors.white24
          : const Color(0xFFE5C066).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    final cx = isLeft ? size.width : 0.0;
    final cy = size.height / 2;

    // First wave arc
    final rect1 = Rect.fromCircle(center: Offset(cx, cy), radius: 8);
    final startAngle1 = isLeft ? math.pi * 0.65 : -math.pi * 0.35;
    canvas.drawArc(rect1, startAngle1, math.pi * 0.7, false, paint);

    // Second outer wave arc
    final rect2 = Rect.fromCircle(center: Offset(cx, cy), radius: 14);
    final startAngle2 = isLeft ? math.pi * 0.70 : -math.pi * 0.30;
    canvas.drawArc(rect2, startAngle2, math.pi * 0.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant _AcousticWavePainter oldDelegate) =>
      oldDelegate.isMuted != isMuted;
}
