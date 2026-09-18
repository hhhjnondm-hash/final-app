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
      barrierColor: Colors.black.withValues(alpha: 0.75),
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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
      _athanService.playAthan(prayer: widget.prayerName);
    }
  }

  void _snoozeReminder() {
    _athanService.stopAthan();
    // Schedule a reminder 15 minutes later
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
          backgroundColor: Color(0xFF334155),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF0D121D),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.18),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar: Sound Bell (pulsing) & Dismiss (X)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sound toggle bell with ripple waves
                        GestureDetector(
                          onTap: _toggleMute,
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF182232),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFC89B3C).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isMuted
                                        ? Icons.notifications_off_rounded
                                        : Icons.notifications_active_rounded,
                                    color: const Color(0xFFE5C066),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isMuted ? 'صامت' : 'صوت الأذان',
                                    style: const TextStyle(
                                      color: Color(0xFFE5C066),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Close X Button (Stops audio & closes)
                        GestureDetector(
                          onTap: _stopAndDismiss,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF182232),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Islamic Mosque Arch Banner Artwork
                    Container(
                      height: 165,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/athan_dialog_bg.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Graceful fallback if image unavailable
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0xFF141C2B), Color(0xFF0A0E17)],
                                    ),
                                  ),
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
                            // Gradient overlay for smooth transition into text
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF0D121D).withValues(alpha: 0.3),
                                    const Color(0xFF0D121D).withValues(alpha: 0.85),
                                  ],
                                  stops: const [0.5, 0.8, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 'حان الآن'
                    const Text(
                      'حان الآن',
                      style: TextStyle(
                        color: Color(0xFFD6C5A2),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 'أَذَان الفَجْر' with decorative side flourishes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '⚜️',
                          style: TextStyle(fontSize: 16, color: Color(0xFFC89B3C)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'أَذَان ${widget.arabicName}',
                          style: const TextStyle(
                            color: Color(0xFFF3E7C4),
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Color(0xFFC89B3C),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '⚜️',
                          style: TextStyle(fontSize: 16, color: Color(0xFFC89B3C)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 'حان وقت الصلاة'
                    const Text(
                      'حان وقت الصلاة',
                      style: TextStyle(
                        color: Color(0xFF9EABB8),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Geometric Arabesque Divider
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Divider(color: Color(0xFF33445C), thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '◈ ❖ ◈',
                            style: TextStyle(
                              color: Color(0xFFC89B3C),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Divider(color: Color(0xFF33445C), thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Ayah Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A26).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFC89B3C).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'قال الله تعالى:',
                            style: TextStyle(
                              color: Color(0xFF8B9BB4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '﴿ وَأَقِمِ الصَّلَاةَ لِذِكْرِي ﴾',
                            style: TextStyle(
                              color: Color(0xFFF3E7C4),
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '[ طه : 14 ]',
                            style: TextStyle(
                              color: Color(0xFFC89B3C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main Golden CTA Button: [ 🧎 هيا إلى الصلاة ]
                    GestureDetector(
                      onTap: _stopAndDismiss,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF2D17C),
                              Color(0xFFC89B3C),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.accessibility_new_rounded,
                              color: Color(0xFF0C1017),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'هيا إلى الصلاة',
                              style: TextStyle(
                                color: Color(0xFF0C1017),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary Action Buttons Row
                    Row(
                      children: [
                        // Mute Today Button
                        Expanded(
                          child: GestureDetector(
                            onTap: _muteToday,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF131A26),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    color: Color(0xFF9EABB8),
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'إيقاف اليوم',
                                    style: TextStyle(
                                      color: Color(0xFFD6DFE8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Snooze Button
                        Expanded(
                          child: GestureDetector(
                            onTap: _snoozeReminder,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF131A26),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF9EABB8),
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'تذكّرني لاحقاً',
                                    style: TextStyle(
                                      color: Color(0xFFD6DFE8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Footer Quote
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Divider(color: Color(0xFF2A364F), thickness: 0.8),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'الصلاة نور لحياتك',
                                style: TextStyle(
                                  color: Color(0xFF6B7A90),
                                  fontSize: 11,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFC89B3C),
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Divider(color: Color(0xFF2A364F), thickness: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
