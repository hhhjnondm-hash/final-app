import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/athan_service.dart';
import '../services/global_audio_manager.dart';
import '../screens/notification_settings_screen.dart';

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
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => PrayerAthanDialog(
        prayerName: prayerName,
        arabicName: arabicName,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
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
  double _volume = 0.9;

  @override
  void initState() {
    super.initState();
    _volume = _athanService.settings.volume;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
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

  void _volumeUp() {
    setState(() {
      _volume = (_volume + 0.15).clamp(0.0, 1.0);
      _isMuted = false;
    });
    _athanService.updateSettings(_athanService.settings.copyWith(volume: _volume));
    GlobalAudioManager().setVolume(_volume);
  }

  void _volumeDown() {
    setState(() {
      _volume = (_volume - 0.15).clamp(0.0, 1.0);
    });
    _athanService.updateSettings(_athanService.settings.copyWith(volume: _volume));
    GlobalAudioManager().setVolume(_volume);
  }

  String _getPrayerBgImage(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return 'assets/images/athan/athan_bg_fajr.png';
      case 'dhuhr':
        return 'assets/images/athan/athan_bg_dhuhr.jpg';
      case 'asr':
        return 'assets/images/athan/athan_bg_asr.jpg';
      case 'maghrib':
        return 'assets/images/athan/athan_bg_maghrib.png';
      case 'isha':
      default:
        return 'assets/images/athan/athan_bg_isha.jpg';
    }
  }

  Map<String, String> _getPrayerAyah(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return {
          'text': 'وَأَقِمِ الصَّلَوةَ لِذِكْرِي',
          'surah': '[ طه : 14 ]',
          'hasBookIcon': 'true',
        };
      case 'dhuhr':
      case 'asr':
        return {
          'text': 'حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَى',
          'surah': '[ البقرة : 238 ]',
          'hasBookIcon': 'false',
        };
      case 'maghrib':
        return {
          'text': 'وَأَقِمِ الصَّلَوةَ لِذِكْرِي',
          'surah': '[ طه : 14 ]',
          'hasBookIcon': 'false',
        };
      case 'isha':
      default:
        return {
          'text': 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا',
          'surah': '[ النساء : 103 ]',
          'hasBookIcon': 'false',
        };
    }
  }

  String _getArabicDate() {
    final now = DateTime.now();
    const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName\n${now.day} $monthName ${now.year}';
  }

  String _getFormattedPrayerTime() {
    final pTime = _athanService.prayerTimes[widget.prayerName] ??
        _athanService.lastPrayerTime ??
        DateTime.now();
    final h = pTime.hour.toString().padLeft(2, '0');
    final m = pTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getSubtitle() {
    if (widget.prayerName.toLowerCase() == 'fajr') {
      return 'الصلاة خير من النوم';
    }
    return 'حي على الصلاة';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isFajr = widget.prayerName.toLowerCase() == 'fajr';
    final ayahInfo = _getPrayerAyah(widget.prayerName);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF07090E),
        body: Stack(
          children: [
            // Background Arch Scenery
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.44,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _getPrayerBgImage(widget.prayerName),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/home_hero_mosque.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      );
                    },
                  ),
                  // Dark bottom gradient overlay to merge into deep black background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          const Color(0xFF07090E).withValues(alpha: 0.85),
                          const Color(0xFF07090E),
                        ],
                        stops: const [0.0, 0.35, 0.80, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Layout
            SafeArea(
              child: Column(
                children: [
                  // 1. Top Bar: Close (X) & Settings (Gear)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Close (X)
                        _buildTopCircularButton(
                          icon: Icons.close_rounded,
                          onTap: _stopAndDismiss,
                        ),
                        // Right: Settings (Gear)
                        _buildTopCircularButton(
                          icon: Icons.settings_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 2. Mosque Icon & Golden Header Title Over Arch
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 1,
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.6),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.mosque_rounded,
                          color: Color(0xFFE8D29A),
                          size: 16,
                        ),
                      ),
                      const Text(
                        'حان الآن وقت',
                        style: TextStyle(
                          color: Color(0xFFE8D29A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '♦',
                          style: TextStyle(color: Color(0xFFC89B3C), fontSize: 10),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 1,
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.6),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Big Glowing Calligraphy Title: أَذَانُ المَغْرِب / أَذَانُ الفَجْر
                  Text(
                    'أَذَانُ ${widget.arabicName}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFFFF4D4),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Color(0xFFC89B3C),
                          blurRadius: 28,
                          offset: Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle: ♦ الصلاة خير من النوم ♦ / ♦ حي على الصلاة ♦
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('♦', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 11)),
                      const SizedBox(width: 8),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isFajr ? const Color(0xFFF0DAAA) : const Color(0xFFD6C5A2),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('♦', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 11)),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // 3. Middle Capsule Bar: Location & Time | Center Mosque Visualizer | Date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildInfoCapsule(),
                  ),

                  const SizedBox(height: 14),

                  // 4. Quranic Verse Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAyahCard(ayahInfo),
                  ),

                  const Spacer(flex: 3),

                  // 5. Large Central Glowing Stop Controller & Waveform Bars
                  _buildCenterStopSection(),

                  const Spacer(flex: 3),

                  // 6. Bottom Row Controls: خفض الصوت | كتم الأذان | رفع الصوت
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: _buildBottomControlsRow(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Left / Right Circular Golden Outlined Buttons
  Widget _buildTopCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131924).withValues(alpha: 0.85),
          border: Border.all(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFFF2D1),
          size: 19,
        ),
      ),
    );
  }

  /// Middle Capsule Bar (Location & Time | Center Mosque Visualizer | Day & Date)
  Widget _buildInfoCapsule() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1520).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC89B3C).withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Location & Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFE8D29A),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'القاهرة',
                    style: TextStyle(
                      color: Color(0xFFFFF4D4),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getFormattedPrayerTime(),
                    style: const TextStyle(
                      color: Color(0xFFB4C2D1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center: Glowing Golden Mosque Silhouette Circle + Equalizer Wings
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniWaveform(isLeft: true),
              const SizedBox(width: 6),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFF3D99E),
                      Color(0xFFC89B3C),
                      Color(0xFF8A6517),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC89B3C).withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFF161003),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildMiniWaveform(isLeft: false),
            ],
          ),

          // Right: Day & Date
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getArabicDate().split('\n').first,
                    style: const TextStyle(
                      color: Color(0xFFFFF4D4),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getArabicDate().split('\n').last,
                    style: const TextStyle(
                      color: Color(0xFFB4C2D1),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFFE8D29A),
                  size: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Quranic Ayah Card with Ornamental Corner Brackets
  Widget _buildAyahCard(Map<String, String> ayahInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1520).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.38),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: قال الله تعالى:
          const Text(
            'قال الله تعالى:',
            style: TextStyle(
              color: Color(0xFFD6C5A2),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Quranic Verse Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '❖',
                style: TextStyle(color: Color(0xFFC89B3C), fontSize: 13),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  ayahInfo['text'] ?? 'وَأَقِمِ الصَّلَوةَ لِذِكْرِي',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFFFFF8E5),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '❖',
                style: TextStyle(color: Color(0xFFC89B3C), fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Surah Reference: [ طه : 14 ]
          Text(
            ayahInfo['surah'] ?? '[ طه : 14 ]',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Large Central Glowing Stop Controller & Waveform Bars
  Widget _buildCenterStopSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Equalizer Soundwave Bars
            _buildEqualizerBars(isLeft: true),

            const SizedBox(width: 18),

            // Pulsing Concentric Glowing Stop Button
            ScaleTransition(
              scale: _pulseAnimation,
              child: GestureDetector(
                onTap: _stopAndDismiss,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF221706),
                        Color(0xFF130E05),
                        Color(0xFF090D14),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFE8D29A),
                      width: 2.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.9),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D4),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC89B3C).withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 18),

            // Right Equalizer Soundwave Bars
            _buildEqualizerBars(isLeft: false),
          ],
        ),

        const SizedBox(height: 12),

        // Text below button: إيقاف الأذان / جاري تشغيل الأذان...
        GestureDetector(
          onTap: _stopAndDismiss,
          child: const Text(
            'إيقاف الأذان',
            style: TextStyle(
              color: Color(0xFFE8D29A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Animated Vertical Equalizer Bars around the Stop Button
  Widget _buildEqualizerBars({required bool isLeft}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        const heights = [10.0, 16.0, 24.0, 32.0, 20.0, 14.0];
        final list = isLeft ? heights.reversed.toList() : heights;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(list.length, (i) {
            final wave = (math.sin(t * math.pi * 2 + (i * 0.9)) + 1.0) / 2.0;
            final h = (list[i] * (0.35 + wave * 0.65)).clamp(6.0, 34.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.2),
              width: 3.2,
              height: h,
              decoration: BoxDecoration(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.4 + wave * 0.55),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  /// Mini Acoustic Waveform for Middle Capsule
  Widget _buildMiniWaveform({required bool isLeft}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        const heights = [8.0, 14.0, 20.0, 12.0];
        final list = isLeft ? heights.reversed.toList() : heights;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(list.length, (i) {
            final wave = (math.sin(t * math.pi * 2 + (i * 0.8)) + 1.0) / 2.0;
            final h = (list[i] * (0.4 + wave * 0.6)).clamp(5.0, 22.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2.2,
              height: h,
              decoration: BoxDecoration(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.5 + wave * 0.5),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  /// Bottom Row of 3 Capsule Buttons: [ خفض الصوت ] - [ كتم الأذان ] - [ رفع الصوت ]
  Widget _buildBottomControlsRow() {
    return Row(
      children: [
        // 1. خفض الصوت (Volume Down)
        Expanded(
          child: _buildControlPillButton(
            icon: Icons.volume_down_rounded,
            label: 'خفض الصوت',
            onTap: _volumeDown,
          ),
        ),

        const SizedBox(width: 10),

        // 2. كتم الأذان (Mute Adhan)
        Expanded(
          child: _buildControlPillButton(
            icon: _isMuted ? Icons.volume_off_rounded : Icons.notifications_off_rounded,
            label: _isMuted ? 'إلغاء الكتم' : 'كتم الأذان',
            onTap: _toggleMute,
            isActive: _isMuted,
          ),
        ),

        const SizedBox(width: 10),

        // 3. رفع الصوت (Volume Up)
        Expanded(
          child: _buildControlPillButton(
            icon: Icons.volume_up_rounded,
            label: 'رفع الصوت',
            onTap: _volumeUp,
          ),
        ),
      ],
    );
  }

  /// Single Capsule Control Button
  Widget _buildControlPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF8A6517).withValues(alpha: 0.35)
            : const Color(0xFF111722).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? const Color(0xFFF3D99E)
              : const Color(0xFFC89B3C).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFFFF2D1) : const Color(0xFFE8D29A),
                size: 19,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isActive ? const Color(0xFFFFF2D1) : const Color(0xFFF6F8FA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
