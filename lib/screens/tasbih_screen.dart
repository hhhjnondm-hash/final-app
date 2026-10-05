import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/celebration_achievement_dialog.dart';
import '../widgets/developer_credits_badge.dart';
import '../widgets/visual_effects/floating_particles.dart';
import '../widgets/visual_effects/interactive_motion_card.dart';
import '../widgets/visual_effects/star_glint.dart';

enum TasbihMaterial {
  amberGold,     // كهرمان ملكي وذهب عيار 24
  emerald,       // زمرد إمبراطوري بلوري
  pearl,         // لؤلؤ عاجي متوهج
  sapphireLapis, // ياقوت ولازورد أزرق
  blackOnyx,     // عقيق يماني أسود فاخر
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with TickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  int _totalTasbih = 1420;
  int _todayTasbih = 142;
  int _longestSession = 300;
  int _currentSessionCount = 0;
  int _selectedDhikrIndex = 0;
  bool _isAutoPostPrayerMode = false;
  int _postPrayerPhase = 0; // 0: Subhanallah (33), 1: Alhamdulillah (33), 2: Allahu Akbar (33), 3: Tamam 100 (1)

  // Settings
  bool _enableVibration = true;
  bool _enableSound = false;
  TasbihMaterial _currentMaterial = TasbihMaterial.amberGold;

  // Kinetic Bead Drag & Rotation
  late AnimationController _rotationAnimController;
  late AnimationController _beadPulseController;
  late AnimationController _shockwaveController;
  double _currentRotationAngle = 0.0;
  double _targetRotationAngle = 0.0;

  // Floating Particles on Tap
  final List<_FloatingSpark> _activeSparks = [];

  final List<Map<String, dynamic>> _adhkar = [
    {
      'name': 'سبحان الله',
      'icon': Icons.mosque_outlined,
      'virtue': 'تغرس لك شجرة في الجنة وتملأ الميزان بالبركة',
    },
    {
      'name': 'الحمد لله',
      'icon': Icons.volunteer_activism_outlined,
      'virtue': 'أفضل الدعاء وتملأ ما بين السماء والأرض',
    },
    {
      'name': 'لا إله إلا الله',
      'icon': Icons.spa_outlined,
      'virtue': 'خير ما قال النبيون وأثقل ما في الميزان',
    },
    {
      'name': 'الله أكبر',
      'icon': Icons.nightlight_round,
      'virtue': 'أحب الكلام إلى الله وترفع الدرجات في الجنات',
    },
    {
      'name': 'لا حول ولا قوة إلا بالله',
      'icon': Icons.stars_rounded,
      'virtue': 'كنز عظيم من تحت عرش الرحمن المنان',
    },
    {
      'name': 'أستغفر الله وأتوب إليه',
      'icon': Icons.all_inclusive_rounded,
      'virtue': 'تفتح الأرزاق وتكفر السيئات وتشرح الصدور',
    },
    {
      'name': 'اللهم صلِّ وسلم على نبينا محمد',
      'icon': Icons.favorite_border_rounded,
      'virtue': 'يصلي الله عليك بها عشراً وتغفر لك الذنوب',
    },
    {
      'name': 'سبحان الله وبحمده سبحان الله العظيم',
      'icon': Icons.auto_awesome_rounded,
      'virtue': 'كلمتان خفيفتان على اللسان ثقيلتان في الميزان',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rotationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _beadPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _rotationAnimController.dispose();
    _beadPulseController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  void _triggerHaptic({bool isGoal = false, bool isSeparator = false}) {
    if (!_enableVibration) return;
    if (isGoal) {
      HapticFeedback.heavyImpact();
    } else if (isSeparator) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _incrementCounter() {
    final nextCount = _counter + 1;
    final isSeparator = (nextCount % 11 == 0);
    _triggerHaptic(isSeparator: isSeparator);

    if (_enableSound) {
      SystemSound.play(SystemSoundType.click);
    }

    _beadPulseController.forward(from: 0.0);
    _shockwaveController.forward(from: 0.0);

    // Add floating golden spark
    final random = math.Random();
    _activeSparks.add(_FloatingSpark(
      id: DateTime.now().microsecondsSinceEpoch,
      dx: (random.nextDouble() - 0.5) * 60,
      text: '+1',
    ));
    if (_activeSparks.length > 6) {
      _activeSparks.removeAt(0);
    }

    // Step rotation by 1 bead (2pi / 33)
    final stepAngle = (2 * math.pi) / 33.0;
    _targetRotationAngle += stepAngle;

    setState(() {
      _counter = nextCount;
      _totalTasbih++;
      _todayTasbih++;
      _currentSessionCount++;
      if (_currentSessionCount > _longestSession) {
        _longestSession = _currentSessionCount;
      }
    });

    // Check Auto Post-Prayer Cycle
    if (_isAutoPostPrayerMode) {
      _handlePostPrayerProgression();
      return;
    }

    // Normal Goal check
    if (_target > 0 && _counter >= _target) {
      _triggerHaptic(isGoal: true);
      _showGoalCompletedDialog();
      setState(() {
        _counter = 0;
      });
    }
  }

  void _handlePostPrayerProgression() {
    if (_postPrayerPhase == 0 && _counter >= 33) {
      // 33 Subhanallah completed -> Switch to Alhamdulillah
      _triggerHaptic(isGoal: true);
      setState(() {
        _counter = 0;
        _postPrayerPhase = 1;
        _selectedDhikrIndex = 1; // الحمد لله
      });
    } else if (_postPrayerPhase == 1 && _counter >= 33) {
      // 33 Alhamdulillah completed -> Switch to Allahu Akbar
      _triggerHaptic(isGoal: true);
      setState(() {
        _counter = 0;
        _postPrayerPhase = 2;
        _selectedDhikrIndex = 3; // الله أكبر
      });
    } else if (_postPrayerPhase == 2 && _counter >= 33) {
      // 33 Allahu Akbar completed -> Switch to Tamam 100
      _triggerHaptic(isGoal: true);
      setState(() {
        _counter = 0;
        _postPrayerPhase = 3;
        _target = 1;
      });
    } else if (_postPrayerPhase == 3 && _counter >= 1) {
      // 100 Completed!
      _triggerHaptic(isGoal: true);
      CelebrationAchievementDialog.show(
        context,
        title: 'هنيئاً لك! أتممت تسبيح أدبار الصلوات 🌟',
        subtitle: '«غُفِرَتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ»',
        achievementText: 'أتممت 33 تسبيحة + 33 تحميدة + 33 تكبيرة + تمام المائة بفضل الله ورحمته.',
        icon: Icons.stars_rounded,
        onContinue: () {
          setState(() {
            _counter = 0;
            _postPrayerPhase = 0;
            _selectedDhikrIndex = 0;
            _target = 33;
            _isAutoPostPrayerMode = false;
          });
        },
      );
      setState(() {
        _counter = 0;
      });
    }
  }

  void _undoCounter() {
    if (_counter > 0) {
      _triggerHaptic();
      final stepAngle = (2 * math.pi) / 33.0;
      _targetRotationAngle -= stepAngle;
      setState(() {
        _counter--;
        _totalTasbih--;
        if (_todayTasbih > 0) _todayTasbih--;
        if (_currentSessionCount > 0) _currentSessionCount--;
      });
    }
  }

  void _resetCounter() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1724),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFD56B), width: 1.2),
        ),
        title: const Text(
          'تأكيد تصفير العداد',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد إعادة تصفير عداد الذكر الحالي والبدء من جديد؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD56B),
              foregroundColor: const Color(0xFF0B1019),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _counter = 0;
                _currentSessionCount = 0;
                if (_isAutoPostPrayerMode) {
                  _postPrayerPhase = 0;
                  _selectedDhikrIndex = 0;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('تصفير الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGoalCompletedDialog() {
    CelebrationAchievementDialog.show(
      context,
      title: 'تَقَبَّلَ اللَّهُ طَاعَتَك وَذِكْرَك ✨',
      subtitle: '﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾',
      achievementText: 'أتممت هدفك المبارك ($_target تسبيحة) من ${_adhkar[_selectedDhikrIndex]['name']}، جعلها الله نوراً لك في الدنيا والآخرة.',
      icon: Icons.check_circle_rounded,
      onContinue: () {
        setState(() {
          _counter = 0;
        });
      },
    );
  }

  void _showAddCustomDhikr() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D131E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFD56B), width: 1.2),
        ),
        title: const Text(
          'إضافة تسبيحة أو ذكر مخصص',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب نص الذكر أو الدعاء...',
            hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFF151C28),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334155))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFFD56B))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD56B),
              foregroundColor: const Color(0xFF0D131E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _adhkar.insert(0, {
                    'name': controller.text.trim(),
                    'icon': Icons.auto_awesome_rounded,
                    'virtue': 'ذكر ودعاء مأثور يقرّبك إلى الله',
                  });
                  _selectedDhikrIndex = 0;
                  _counter = 0;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ الذكر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0C131E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.35), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'تخصيص السبحة والمجسمات ثلاثية الأبعاد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gemstone 3D Materials Selector
              const Text(
                '💎 خامة وأحجار السبحة 3D',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildMaterialOption('كهرمان ملكي عيار 24', TasbihMaterial.amberGold, const Color(0xFFFFD56B), setSheetState),
                    const SizedBox(width: 8),
                    _buildMaterialOption('زمرد إمبراطوري', TasbihMaterial.emerald, const Color(0xFF10B981), setSheetState),
                    const SizedBox(width: 8),
                    _buildMaterialOption('لؤلؤ عاجي مشع', TasbihMaterial.pearl, const Color(0xFFF1F5F9), setSheetState),
                    const SizedBox(width: 8),
                    _buildMaterialOption('ياقوت أزرق سماوي', TasbihMaterial.sapphireLapis, const Color(0xFF38BDF8), setSheetState),
                    const SizedBox(width: 8),
                    _buildMaterialOption('عقيق يماني أسود', TasbihMaterial.blackOnyx, const Color(0xFF64748B), setSheetState),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Auto Post-Prayer Mode Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E293B), const Color(0xFF111827)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAutoPostPrayerMode ? const Color(0xFFFFD56B) : const Color(0xFF334155),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFFFD56B),
                  activeTrackColor: const Color(0xFFC89B3C),
                  inactiveThumbColor: const Color(0xFF64748B),
                  inactiveTrackColor: const Color(0xFF1E293B),
                  title: const Text(
                    '🕌 وضع تسبيح دبر الصلوات التلقائي',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    '33 سبحان الله ➔ 33 الحمد لله ➔ 33 الله أكبر ➔ تمام المائة',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  value: _isAutoPostPrayerMode,
                  onChanged: (val) {
                    setSheetState(() => _isAutoPostPrayerMode = val);
                    setState(() {
                      _isAutoPostPrayerMode = val;
                      if (val) {
                        _postPrayerPhase = 0;
                        _selectedDhikrIndex = 0;
                        _target = 33;
                        _counter = 0;
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Vibration switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFFFFD56B),
                activeTrackColor: const Color(0xFFC89B3C),
                inactiveThumbColor: const Color(0xFF64748B),
                inactiveTrackColor: const Color(0xFF1E293B),
                title: const Text(
                  '📳 التفاعل اللمسي والاهتزاز الفيزيائي (Haptic)',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
                ),
                value: _enableVibration,
                onChanged: (val) {
                  setSheetState(() => _enableVibration = val);
                  setState(() => _enableVibration = val);
                },
              ),

              // Sound switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFFFFD56B),
                activeTrackColor: const Color(0xFFC89B3C),
                inactiveThumbColor: const Color(0xFF64748B),
                inactiveTrackColor: const Color(0xFF1E293B),
                title: const Text(
                  '🔊 صوت نقر الخرزات الواقعي',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
                ),
                value: _enableSound,
                onChanged: (val) {
                  setSheetState(() => _enableSound = val);
                  setState(() => _enableSound = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialOption(String title, TasbihMaterial mat, Color accent, StateSetter setSheetState) {
    final isSelected = _currentMaterial == mat;
    return InkWell(
      onTap: () {
        setSheetState(() => _currentMaterial = mat);
        setState(() => _currentMaterial = mat);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141D2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _primaryMaterialColor {
    switch (_currentMaterial) {
      case TasbihMaterial.emerald:
        return const Color(0xFF10B981);
      case TasbihMaterial.pearl:
        return const Color(0xFFE2E8F0);
      case TasbihMaterial.sapphireLapis:
        return const Color(0xFF38BDF8);
      case TasbihMaterial.blackOnyx:
        return const Color(0xFF1E293B);
      case TasbihMaterial.amberGold:
        return const Color(0xFFFFD56B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDhikr = _isAutoPostPrayerMode
        ? (_postPrayerPhase == 0
            ? 'سُبْحَانَ اللَّه (1/3)'
            : _postPrayerPhase == 1
                ? 'الْحَمْدُ لِلَّه (2/3)'
                : _postPrayerPhase == 2
                    ? 'اللَّهُ أَكْبَر (3/3)'
                    : 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ')
        : (_adhkar[_selectedDhikrIndex]['name'] as String);

    final activeVirtue = _adhkar[_selectedDhikrIndex]['virtue'] as String? ?? 'ذكر الله حصن المسلم وطمأنينة القلب';
    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 0.0;
    final percentInt = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Cinematic Lantern Mosque Artwork
          Image.asset(
            'assets/quran_viewer_left_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/home_hero_mosque.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF070B11)),
            ),
          ),

          // Layer 2: Dark Atmospheric Scrim with Royal Radial Glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF0D1726).withValues(alpha: 0.82),
                  const Color(0xFF070B11).withValues(alpha: 0.94),
                  const Color(0xFF030508).withValues(alpha: 0.98),
                ],
              ),
            ),
          ),

          // Layer 3: Floating Golden Dust Particles
          const Positioned.fill(
            child: RepaintBoundary(
              child: FloatingParticles(
                numberOfParticles: 18,
                particleColor: Color(0xFFFFD56B),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // 1. Top Header: [Settings Gear] | [السبحة الإلكترونية] | [Material Badge]
                  _buildHeader(),

                  const SizedBox(height: 12),

                  // 2. Horizontal Dhikr Selector Carousel
                  if (!_isAutoPostPrayerMode) _buildDhikrHorizontalSelector(),

                  // 2.5 Active Dhikr Virtue Callout Ribbon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E2838).withValues(alpha: 0.8),
                            const Color(0xFF121B2A).withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD56B).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD56B), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeVirtue,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Color(0xFFFFE58F),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. Central Photorealistic 3D Circular Misbaha Dial
                  _buildCentral3DMisbaha(activeDhikr),

                  const SizedBox(height: 18),

                  // 4. Action Controls: [إعادة (Reset)] | [ + اضغط للتسبيح (Grand 3D)] | [تراجع (Undo)]
                  _buildActionButtonsRow(),

                  const SizedBox(height: 22),

                  // 5. Daily Goal Card: [الهدف اليومي للتسبيح] + [33 | 100 | 500 | 1000] + Glowing Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InteractiveMotionCard(
                      borderRadius: 22,
                      child: _buildDailyGoalCard(progress, percentInt),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 6. Statistics Card: [إحصائيات التسبيح]
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InteractiveMotionCard(
                      borderRadius: 22,
                      child: _buildStatisticsCard(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 7. Customization Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InteractiveMotionCard(
                      onTap: _showCustomizationSheet,
                      borderRadius: 22,
                      child: _buildCustomizationBanner(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 8. Bottom Islamic Ornament
                  _buildFooterOrnament(),

                  const SizedBox(height: 16),

                  // 9. Developer Rights Badge
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: DeveloperCreditsBadge(),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Settings Button
          _buildCircleIconButton(
            icon: Icons.tune_rounded,
            onTap: _showCustomizationSheet,
          ),

          // Center: Title & Subtitle with Gold Ornament
          Column(
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarGlint(size: 14, color: Color(0xFFFFD56B)),
                  SizedBox(width: 6),
                  Text(
                    'السبحة الإلكترونية ثلاثية الأبعاد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0xFFFFD56B), blurRadius: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: 6),
                  StarGlint(size: 14, color: Color(0xFFFFD56B)),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'اذكر الله واطمئن قلبك • تفاعل فيزيائي وخرز ثلاثي الأبعاد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD56B),
                ),
              ),
            ],
          ),

          // Right: Reset to Default Button
          _buildCircleIconButton(
            icon: Icons.refresh_rounded,
            onTap: _resetCounter,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131B26).withValues(alpha: 0.9),
          border: Border.all(
            color: const Color(0xFFFFD56B).withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFFFD56B),
          ),
        ),
      ),
    );
  }

  /// Horizontal Dhikr Selector Carousel
  Widget _buildDhikrHorizontalSelector() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _adhkar.length + 1,
        itemBuilder: (context, index) {
          if (index == _adhkar.length) {
            // Add Dhikr Button
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: _showAddCustomDhikr,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1722).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFFD56B), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'إضافة ذكر',
                        style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final dhikr = _adhkar[index];
          final isSelected = _selectedDhikrIndex == index;
          final IconData iconData = dhikr['icon'] as IconData;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                _triggerHaptic();
                setState(() {
                  _selectedDhikrIndex = index;
                  _counter = 0;
                  _currentSessionCount = 0;
                });
              },
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFE58F), Color(0xFFE5B54F), Color(0xFFB8860B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF0F1722).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFF2B2) : const Color(0xFF334155).withValues(alpha: 0.7),
                    width: isSelected ? 1.6 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFC89B3C).withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dhikr['name'] as String,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF070B11) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      iconData,
                      size: 15,
                      color: isSelected ? const Color(0xFF070B11) : const Color(0xFFFFD56B),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Photorealistic 3D Volumetric Misbaha with CustomPainter & Kinetic Physics
  Widget _buildCentral3DMisbaha(String activeDhikr) {
    return GestureDetector(
      onTap: _incrementCounter,
      onVerticalDragEnd: (_) => _incrementCounter(),
      child: Center(
        child: SizedBox(
          width: 330,
          height: 330,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Central Ambient Lighting Aura behind Rosary
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryMaterialColor.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 2. Volumetric 3D Spherical Beads Ring Painter (60 FPS RepaintBoundary)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rotationAnimController,
                  builder: (context, _) {
                    // Smooth continuous angle interpolation
                    _currentRotationAngle += (_targetRotationAngle - _currentRotationAngle) * 0.25;
                    return CustomPaint(
                      size: const Size(330, 330),
                      painter: _Photorealistic3DMisbahaPainter(
                        rotationAngle: _currentRotationAngle,
                        activeCount: _counter,
                        material: _currentMaterial,
                        pulseScale: 1.0 + (_beadPulseController.value * 0.08),
                      ),
                    );
                  },
                ),
              ),

              // 3. Central 3D Extruded Islamic Dial
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(0.0, -0.2),
                    radius: 0.9,
                    colors: [
                      Color(0xFF1B283A),
                      Color(0xFF0F1824),
                      Color(0xFF070C13),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD56B).withValues(alpha: 0.65),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 24,
                      spreadRadius: 3,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD56B).withValues(alpha: 0.2),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Concentric Golden Filigree Ring
                    Container(
                      width: 172,
                      height: 172,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD56B).withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                    ),

                    // Tap Shockwave Expanding Ripple
                    AnimatedBuilder(
                      animation: _shockwaveController,
                      builder: (context, _) {
                        final val = _shockwaveController.value;
                        if (val == 0.0 || val == 1.0) return const SizedBox.shrink();
                        return Container(
                          width: 180 * val,
                          height: 180 * val,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFD56B).withValues(alpha: (1.0 - val) * 0.7),
                              width: 2.5 * (1.0 - val),
                            ),
                          ),
                        );
                      },
                    ),

                    // Dial Center Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Selected Dhikr Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            activeDhikr,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD56B),
                              shadows: [
                                Shadow(
                                  color: Color(0xFFC89B3C),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Luminous Large Digital Count
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 140),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text(
                            '$_counter',
                            key: ValueKey<int>(_counter),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.05,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFFD56B),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Goal indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFD56B).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _isAutoPostPrayerMode ? 'المرحلة ${_postPrayerPhase + 1} من 4' : 'الهدف: $_target',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD56B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Floating +1 Sparks
                    ..._activeSparks.map((spark) {
                      return Positioned(
                        top: 25,
                        left: 95 + spark.dx,
                        child: Text(
                          spark.text,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFFFFD56B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.amber, blurRadius: 8)],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action Controls: [إعادة (Reset)] | [ + اضغط للتسبيح (Giant 3D Gold)] | [تراجع (Undo)]
  Widget _buildActionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Button: إعادة (Reset)
        Column(
          children: [
            InkWell(
              onTap: _resetCounter,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2838), Color(0xFF0F1722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF334155), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.replay_rounded,
                    size: 24,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'تصفير',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),

        const SizedBox(width: 32),

        // Center Button: Giant Tactile 3D Gold + Button
        Column(
          children: [
            InkWell(
              onTap: _incrementCounter,
              borderRadius: BorderRadius.circular(44),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.25, -0.35),
                    radius: 0.8,
                    colors: [
                      Color(0xFFFFF9E6),
                      Color(0xFFFFD56B),
                      Color(0xFFC89B3C),
                      Color(0xFF8C5C0F),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFFDF2),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD56B).withValues(alpha: 0.55),
                      blurRadius: 30,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(
                      color: Color(0xFF000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 42,
                    color: Color(0xFF130E04),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'المس للتسبيح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD56B),
              ),
            ),
          ],
        ),

        const SizedBox(width: 32),

        // Right Button: تراجع (Undo)
        Column(
          children: [
            InkWell(
              onTap: _undoCounter,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2838), Color(0xFF0F1722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF334155), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.undo_rounded,
                    size: 24,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'تراجع -1',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Daily Goal Card
  Widget _buildDailyGoalCard(double progress, int percentInt) {
    final targets = [33, 100, 500, 1000];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Target Selection Pills
              Row(
                children: targets.reversed.map((t) {
                  final isSelected = _target == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        _triggerHaptic();
                        setState(() {
                          _target = t;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFF182232),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF334155),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Text(
                          '$t',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF0B1019) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Title with Target Icon
              const Row(
                children: [
                  Text(
                    'الهدف اليومي للتسبيح',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.track_changes_rounded,
                    size: 18,
                    color: Color(0xFFFFD56B),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Linear Progress Bar with glowing indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD56B)),
            ),
          ),

          const SizedBox(height: 8),

          // Progress status text: [0 / 33] and [0%]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_counter / $_target تسبيحة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD56B),
                ),
              ),
              Text(
                '$percentInt% مكتمل',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Statistics Card: [إحصائيات التسبيح] (1420 إجمالي | 142 اليوم | 300 أطول جلسة)
  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'إحصائيات التسبيح اليومية والتراكمية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.insights_rounded,
                size: 18,
                color: Color(0xFFFFD56B),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3 Columns Stats Row
          Row(
            children: [
              // Col 3: أطول جلسة
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFFFD56B), size: 22),
                    const SizedBox(height: 4),
                    Text(
                      '$_longestSession',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'أطول جلسة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 42, color: const Color(0xFF334155)),

              // Col 2: تسبيحات اليوم
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFFFFD56B), size: 22),
                    const SizedBox(height: 4),
                    Text(
                      '$_todayTasbih',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'تسبيحات اليوم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 42, color: const Color(0xFF334155)),

              // Col 1: إجمالي التسبيحات
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.all_inclusive_rounded, color: Color(0xFFFFD56B), size: 22),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalTasbih',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'إجمالي التسبيحات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Customization Banner
  Widget _buildCustomizationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD56B).withValues(alpha: 0.35), width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFFFFD56B)),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'تخصيص نمط وخامات السبحة 3D',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'كهرمان • زمرد • لؤلؤ • ياقوت • اهتزاز هابتك فيزيائي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          Icon(
            Icons.palette_outlined,
            size: 22,
            color: Color(0xFFFFD56B),
          ),
        ],
      ),
    );
  }

  /// Footer Ornament: ❖ واذكر ربك كثيراً ❖
  Widget _buildFooterOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.5)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '❖ فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي ❖',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD56B),
            ),
          ),
        ),
        Container(width: 36, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.5)),
      ],
    );
  }
}

class _FloatingSpark {
  final int id;
  final double dx;
  final String text;

  _FloatingSpark({required this.id, required this.dx, required this.text});
}

/// Photorealistic 3D Spherical Beads Ring CustomPainter
class _Photorealistic3DMisbahaPainter extends CustomPainter {
  final double rotationAngle;
  final int activeCount;
  final TasbihMaterial material;
  final double pulseScale;

  _Photorealistic3DMisbahaPainter({
    required this.rotationAngle,
    required this.activeCount,
    required this.material,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int totalBeads = 33;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 22;

    // 1. Draw Braided Silk Thread passing through beads
    final threadPaint = Paint()
      ..color = const Color(0xFFC89B3C).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, radius, threadPaint);

    // 2. Draw 33 Volumetric 3D Spherical Beads
    for (int i = 0; i < totalBeads; i++) {
      final beadAngle = rotationAngle + (i * (2 * math.pi / totalBeads)) - (math.pi / 2);
      final beadCenter = Offset(
        center.dx + radius * math.cos(beadAngle),
        center.dy + radius * math.sin(beadAngle),
      );

      final isImamah = (i == 0);
      final isSeparator = (i == 11 || i == 22);
      final isCurrentActive = (i == (activeCount % totalBeads));

      final beadRadius = isImamah
          ? 13.5 * pulseScale
          : isSeparator
              ? 11.5
              : isCurrentActive
                  ? 12.0 * pulseScale
                  : 9.8;

      // A. Ambient Ground Shadow under each 3D Sphere
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(beadCenter.translate(0, 3), beadRadius * 0.95, shadowPaint);

      // B. 3D Volumetric Sphere RadialGradient Lighting
      final lightOffset = beadCenter.translate(-beadRadius * 0.35, -beadRadius * 0.35);
      final sphereGradient = _getMaterialSphereGradient(material, isSeparator, isImamah, isCurrentActive);

      final spherePaint = Paint()
        ..shader = sphereGradient.createShader(
          Rect.fromCircle(center: lightOffset, radius: beadRadius * 1.35),
        );
      canvas.drawCircle(beadCenter, beadRadius, spherePaint);

      // C. Brilliant Specular Reflection Dot (Top-Left Glint)
      final glintOffset = beadCenter.translate(-beadRadius * 0.38, -beadRadius * 0.38);
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: isCurrentActive ? 0.95 : 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
      canvas.drawCircle(glintOffset, beadRadius * 0.22, glintPaint);

      // D. Rim Outline
      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = (isSeparator || isImamah)
            ? const Color(0xFFFFF7D6).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.3);
      canvas.drawCircle(beadCenter, beadRadius, rimPaint);

      // E. Golden Filigree on Separators & Imamah
      if (isSeparator) {
        final starPaint = Paint()
          ..color = const Color(0xFFFFF9E6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(beadCenter, beadRadius * 0.3, starPaint);
      }
    }

    // 3. Draw 3D Master Imamah / Minaret & Silk Tassel at the Top Center
    final imamahTopAngle = rotationAngle - (math.pi / 2);
    final imamahCenter = Offset(
      center.dx + (radius + 2) * math.cos(imamahTopAngle),
      center.dy + (radius + 2) * math.sin(imamahTopAngle),
    );

    _draw3DImamahTassel(canvas, imamahCenter, imamahTopAngle);
  }

  RadialGradient _getMaterialSphereGradient(TasbihMaterial mat, bool isSeparator, bool isImamah, bool isActive) {
    if (isSeparator || isImamah) {
      // 24K Pure Gold Filigree Separator
      return const RadialGradient(
        colors: [
          Color(0xFFFFFDE8),
          Color(0xFFFFD56B),
          Color(0xFFC89B3C),
          Color(0xFF6B4408),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      );
    }

    switch (mat) {
      case TasbihMaterial.emerald:
        return RadialGradient(
          colors: [
            isActive ? const Color(0xFFA7F3D0) : const Color(0xFF6EE7B7),
            const Color(0xFF10B981),
            const Color(0xFF047857),
            const Color(0xFF022C22),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        );

      case TasbihMaterial.pearl:
        return RadialGradient(
          colors: [
            const Color(0xFFFFFFFF),
            const Color(0xFFF1F5F9),
            isActive ? const Color(0xFFFFECC8) : const Color(0xFFCBD5E1),
            const Color(0xFF475569),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        );

      case TasbihMaterial.sapphireLapis:
        return RadialGradient(
          colors: [
            isActive ? const Color(0xFFBAE6FD) : const Color(0xFF7DD3FC),
            const Color(0xFF0284C7),
            const Color(0xFF075985),
            const Color(0xFF082F49),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        );

      case TasbihMaterial.blackOnyx:
        return RadialGradient(
          colors: [
            isActive ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8),
            const Color(0xFF334155),
            const Color(0xFF0F172A),
            const Color(0xFF020617),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case TasbihMaterial.amberGold:
        return RadialGradient(
          colors: [
            isActive ? const Color(0xFFFFF9E6) : const Color(0xFFFFE58F),
            const Color(0xFFFFB800),
            const Color(0xFFD97706),
            const Color(0xFF451A03),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        );
    }
  }

  void _draw3DImamahTassel(Canvas canvas, Offset topCenter, double angle) {
    // 3D Metallic Spire extending outwards
    final tasselTip = Offset(
      topCenter.dx + 16 * math.cos(angle),
      topCenter.dy + 16 * math.sin(angle),
    );

    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF8D6), Color(0xFFFFD56B), Color(0xFF996515)],
      ).createShader(Rect.fromPoints(topCenter, tasselTip))
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(topCenter, tasselTip, goldPaint);

    // Silk Tassel Fringe
    final tasselEnd = Offset(
      tasselTip.dx + 12 * math.cos(angle),
      tasselTip.dy + 12 * math.sin(angle),
    );
    final tasselPaint = Paint()
      ..color = const Color(0xFFFFD56B).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tasselTip, tasselEnd, tasselPaint);
  }

  @override
  bool shouldRepaint(covariant _Photorealistic3DMisbahaPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.activeCount != activeCount ||
        oldDelegate.material != material ||
        oldDelegate.pulseScale != pulseScale;
  }
}
