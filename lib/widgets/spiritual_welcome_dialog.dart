import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class SpiritualZekrItem {
  final String title;
  final String content;
  final String virtue;
  final IconData icon;

  const SpiritualZekrItem({
    required this.title,
    required this.content,
    required this.virtue,
    required this.icon,
  });
}

class SpiritualWelcomeDialog extends StatefulWidget {
  final VoidCallback? onDismissed;

  const SpiritualWelcomeDialog({
    super.key,
    this.onDismissed,
  });

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) => const SpiritualWelcomeDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SpiritualWelcomeDialog> createState() => _SpiritualWelcomeDialogState();
}

class _SpiritualWelcomeDialogState extends State<SpiritualWelcomeDialog>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _timerController;
  late AnimationController _particleController;
  
  late SpiritualZekrItem _selectedZekr;
  Timer? _dismissTimer;
  int _secondsRemaining = 10;
  Timer? _countdownTicker;

  static final List<SpiritualZekrItem> _spiritualTreasures = [
    const SpiritualZekrItem(
      title: 'الصلاة على النبي ﷺ',
      content: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ',
      virtue: 'مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا',
      icon: Icons.favorite_rounded,
    ),
    const SpiritualZekrItem(
      title: 'التسبيح وبداية اليوم',
      content: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      virtue: 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ',
      icon: Icons.wb_sunny_rounded,
    ),
    const SpiritualZekrItem(
      title: 'الاستغفار ومحو الذنوب',
      content: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ',
      virtue: 'مَنْ لَزِمَ الِاسْتِغْفَارَ جَعَلَ اللَّهُ لَهُ مِنْ كُلِّ ضِيقٍ مَخْرَجًا وَمِنْ كُلِّ هَمٍّ فَرَجًا',
      icon: Icons.cloud_done_rounded,
    ),
    const SpiritualZekrItem(
      title: 'كنز من كنوز الجنة',
      content: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      virtue: 'كَنْزٌ مِنْ تَحْتِ عَرْشِ الرَّحْمَنِ تَدْفَعُ سَبْعِينَ بَابًا مِنَ الضُّرِّ',
      icon: Icons.shield_rounded,
    ),
    const SpiritualZekrItem(
      title: 'سيد الاستغفار',
      content: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
      virtue: 'مَنْ قَالَهَا مُوقِنًا بِهَا حِينَ يُمْسِي أَوْ يُصْبِحُ فَمَاتَ دَخَلَ الْجَنَّةَ',
      icon: Icons.star_rounded,
    ),
    const SpiritualZekrItem(
      title: 'التوكل على الحي القيوم',
      content: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      virtue: 'مَنْ قَالَهَا سَبْعَ مَرَّاتٍ كَفَاهُ اللَّهُ مَا أَهَمَّهُ مِنْ أَمْرِ الدُّنْيَا وَالْآخِرَةِ',
      icon: Icons.all_inclusive_rounded,
    ),
    const SpiritualZekrItem(
      title: 'التهليل الأعظم',
      content: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      virtue: 'كَانَتْ لَهُ عِدْلَ عَشْرِ رِقَابٍ وَكُتِبَتْ لَهُ مِائَةُ حَسَنَةٍ وَمُحِيَتْ عَنْهُ مِائَةُ سَيِّئَةٍ',
      icon: Icons.brightness_high_rounded,
    ),
    const SpiritualZekrItem(
      title: 'دعاء تفريج الكرب (ذي النون)',
      content: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      virtue: 'لَمْ يَدْعُ بِهَا مُسْلِمٌ فِي كُرْبَةٍ إِلَّا اسْتَجَابَ اللَّهُ لَهُ',
      icon: Icons.light_mode_rounded,
    ),
    const SpiritualZekrItem(
      title: 'التحصين الشامل',
      content: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      virtue: 'مَنْ قَالَهَا ثَلَاثًا لَمْ يَضُرَّهُ شَيْءٌ حَتَّى يُمْسِيَ أَوْ يُصْبِحَ',
      icon: Icons.verified_user_rounded,
    ),
    const SpiritualZekrItem(
      title: 'شكر النعم ورضا الرب',
      content: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا وَرَسُولًا',
      virtue: 'كَانَ حَقًّا عَلَى اللَّهِ أَنْ يُرْضِيَهُ يَوْمَ الْقِيَامَةِ',
      icon: Icons.emoji_emotions_rounded,
    ),
    const SpiritualZekrItem(
      title: 'غراس الجنة الباقيات الصالحات',
      content: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
      virtue: 'أَحَبُّ الْكَلَامِ إِلَى اللَّهِ وَهُنَّ غِرَاسُ الْجَنَّةِ',
      icon: Icons.eco_rounded,
    ),
    const SpiritualZekrItem(
      title: 'طلب العفو والعافية',
      content: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ كَرِيمٌ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
      virtue: 'مِنْ أَعْظَمِ الْأَدْعِيَةِ جَامِعَةً لِخَيْرَيِ الدُّنْيَا وَالْآخِرَةِ',
      icon: Icons.health_and_safety_rounded,
    ),
    const SpiritualZekrItem(
      title: 'الحفظ والتوكل عند الخروج والبدء',
      content: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      virtue: 'يُقَالُ لَهُ: كُفِيتَ وَوُقِيتَ وَهُدِيتَ، وَتَنَحَّى عَنْهُ الشَّيْطَانُ',
      icon: Icons.navigation_rounded,
    ),
    const SpiritualZekrItem(
      title: 'دعاء انشراح الصدر وتيسير الأمر',
      content: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي يَفْقَهُوا قَوْلِي',
      virtue: 'دُعَاءُ كَلِيمِ اللَّهِ مُوسَى عَلَيْهِ السَّلَامُ لِتَيْسِيرِ الْعَسِيرِ',
      icon: Icons.auto_awesome_rounded,
    ),
    const SpiritualZekrItem(
      title: 'الاستعاذة من الهم والحزن',
      content: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَغَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ',
      virtue: 'دُعَاءٌ كَانَ يُكْثِرُ مِنْهُ النَّبِيُّ ﷺ لِدَفْعِ جَمِيعِ الْغُمُومِ',
      icon: Icons.healing_rounded,
    ),
    const SpiritualZekrItem(
      title: 'الصلاة الإبراهيمية المباركة',
      content: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      virtue: 'أَفْضَلُ صِيَغِ الصَّلَاةِ عَلَى الْحَبِيبِ الْمُصْطَفَى ﷺ',
      icon: Icons.military_tech_rounded,
    ),
    const SpiritualZekrItem(
      title: 'الاستغفار للمؤمنين والمؤمنات',
      content: 'اللَّهُمَّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ وَالْمُسْلِمِينَ وَالْمُسْلِمَاتِ الْأَحْيَاءِ مِنْهُمْ وَالْأَمْوَاتِ',
      virtue: 'كَتَبَ اللَّهُ لَهُ بِكُلِّ مُؤْمِنٍ وَمُؤْمِنَةٍ حَسَنَةً',
      icon: Icons.groups_rounded,
    ),
    const SpiritualZekrItem(
      title: 'الحمد عند تجدد النعم',
      content: 'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ مِلْءَ السَّمَاوَاتِ وَمِلْءَ الْأَرْضِ',
      virtue: 'ابْتَدَرَهَا بِضْعَةٌ وَثَلَاثُونَ مَلَكًا أَيُّهُمْ يَكْتُبُهَا أَوَّلُ',
      icon: Icons.water_drop_rounded,
    ),
    const SpiritualZekrItem(
      title: 'طلب الهداية والثبات',
      content: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ وَطَاعَتِكَ',
      virtue: 'كَانَ أَكْثَرَ دُعَاءِ النَّبِيِّ ﷺ فِي سُجُودِهِ وَخَلَوَاتِهِ',
      icon: Icons.compass_calibration_rounded,
    ),
    const SpiritualZekrItem(
      title: 'دعاء الرزق والبركة',
      content: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
      virtue: 'دُعَاءٌ صَبَاحِيٌّ مَأْثُورٌ عَقِبَ صَلَاةِ الْفَجْرِ',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Randomly select one of the 20+ zekr items each time
    final rand = math.Random();
    _selectedZekr = _spiritualTreasures[rand.nextInt(_spiritualTreasures.length)];

    // 1. Lantern/Halo Glow Animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. Continuous Particle Shimmer Animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 3. 10-Second Countdown Timer Controller for circular progress bar
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _timerController.forward();

    // Countdown seconds counter
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 1) {
            _secondsRemaining--;
          } else {
            _secondsRemaining = 0;
            timer.cancel();
          }
        });
      }
    });

    // Auto dismiss precisely after 10 seconds
    _dismissTimer = Timer(const Duration(seconds: 10), () {
      _closeDialog();
    });
  }

  void _closeDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      widget.onDismissed?.call();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _countdownTicker?.cancel();
    _glowController.dispose();
    _timerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Golden Shimmer Aura
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final scale = 1.0 + (_glowController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 360,
                  height: 480,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.35 * _glowController.value),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: const Color(0xFF0D1D3A).withValues(alpha: 0.8),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Main Spiritual Card Container
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1E36),
                  Color(0xFF081220),
                  Color(0xFF040A14),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.6),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header: Animated Mosque / Star Icon Badge & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close X Button
                    InkWell(
                      onTap: _closeDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                      ),
                    ),

                    // Top Central Spiritual Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFC89B3C).withValues(alpha: 0.25),
                            const Color(0xFF8E6920).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(
                          color: const Color(0xFFC89B3C).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedZekr.icon,
                            color: const Color(0xFFFFD56B),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'نفحات وذكر مبارك',
                            style: TextStyle(
                              color: Color(0xFFFFD56B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Uthmanic',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 10-Second Circular Progress Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: AnimatedBuilder(
                            animation: _timerController,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: 1.0 - _timerController.value,
                                strokeWidth: 2.8,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC89B3C)),
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                              );
                            },
                          ),
                        ),
                        Text(
                          '$_secondsRemaining',
                          style: const TextStyle(
                            color: Color(0xFFFFD56B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Icon Aura Spotlight
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFD56B),
                            Color(0xFFC89B3C),
                            Color(0xFF7A5812),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.45 * _glowController.value),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _selectedZekr.icon,
                        color: const Color(0xFF0B1626),
                        size: 34,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Zekr Category Title
                Text(
                  _selectedZekr.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD56B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // Main Zekr Card (Uthmanic Arabic Calligraphy Box)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFC89B3C).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _selectedZekr.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      height: 1.65,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Virtue / Hadith Explanatory Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081A30).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF4ADE80),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedZekr.virtue,
                          style: const TextStyle(
                            color: Color(0xFFD1FAE5),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Direct Action Buttons (تابع إلى التطبيق)
                Row(
                  children: [
                    // Continue Button
                    Expanded(
                      child: InkWell(
                        onTap: _closeDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD56B),
                                Color(0xFFC89B3C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC89B3C).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ابدأ بالبركة',
                                  style: TextStyle(
                                    color: Color(0xFF091424),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF091424),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}