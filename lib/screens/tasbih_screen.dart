import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  int _totalTasbih = 1420;
  int _todayTasbih = 142;
  int _longestSession = 300;
  int _currentSessionCount = 0;
  int _selectedDhikrIndex = 0;

  // Settings
  bool _enableVibration = true;
  bool _enableSound = false;
  String _tasbihTheme = 'gold'; // gold, emerald, royal, obsidian

  late AnimationController _beadAnimController;

  final List<Map<String, dynamic>> _adhkar = [
    {
      'name': 'سبحان الله',
      'icon': Icons.mosque_outlined,
    },
    {
      'name': 'الحمد لله',
      'icon': Icons.volunteer_activism_outlined,
    },
    {
      'name': 'لا إله إلا الله',
      'icon': Icons.spa_outlined,
    },
    {
      'name': 'الله أكبر',
      'icon': Icons.nightlight_round,
    },
    {
      'name': 'لا حول ولا قوة إلا بالله',
      'icon': Icons.stars_rounded,
    },
    {
      'name': 'أستغفر الله',
      'icon': Icons.all_inclusive_rounded,
    },
    {
      'name': 'اللهم صل على محمد',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'name': 'سبحان الله وبحمده',
      'icon': Icons.auto_awesome_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _beadAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _beadAnimController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    if (_enableVibration) HapticFeedback.lightImpact();
    if (_enableSound) SystemSound.play(SystemSoundType.click);

    setState(() {
      _counter++;
      _totalTasbih++;
      _todayTasbih++;
      _currentSessionCount++;
      if (_currentSessionCount > _longestSession) {
        _longestSession = _currentSessionCount;
      }

      if (_counter >= _target) {
        if (_enableVibration) HapticFeedback.heavyImpact();
        _showGoalCompletedDialog();
        _counter = 0;
      }
    });
  }

  void _undoCounter() {
    if (_counter > 0) {
      if (_enableVibration) HapticFeedback.selectionClick();
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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
        ),
        title: const Text(
          'تأكيد إعادة التعيين',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد تصفير عداد الذكر الحالي؟',
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
              backgroundColor: const Color(0xFFC89B3C),
              foregroundColor: const Color(0xFF0B1019),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _counter = 0;
                _currentSessionCount = 0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('تصفير', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGoalCompletedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D131E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD56B).withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0D131E), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'أحسنت! تقبل الله طاعتك ✨',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'أتممت وردك ($_target تسبيحة) من ${_adhkar[_selectedDhikrIndex]['name']}',
              style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF334155)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('تم', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC89B3C),
                      foregroundColor: const Color(0xFF0D131E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('جلسة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomDhikr() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D131E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFC89B3C).withValues(alpha: 0.4)),
        ),
        title: const Text(
          'إضافة تسبيحة جديدة',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب الذكر أو الدعاء...',
            hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFF151C28),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD56B))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC89B3C),
              foregroundColor: const Color(0xFF0D131E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _adhkar.insert(0, {
                    'name': controller.text.trim(),
                    'icon': Icons.auto_awesome_rounded,
                  });
                  _selectedDhikrIndex = 0;
                  _counter = 0;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0D131E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'تخصيص السبحة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Theme Selector
              const Text(
                'لون ونمط الخرز',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildThemeOption('ذهبي ملكي', 'gold', const Color(0xFFFFD56B), setSheetState),
                  const SizedBox(width: 8),
                  _buildThemeOption('زمردي', 'emerald', const Color(0xFF10B981), setSheetState),
                  const SizedBox(width: 8),
                  _buildThemeOption('نيلي ملكي', 'royal', const Color(0xFF3B82F6), setSheetState),
                ],
              ),

              const SizedBox(height: 16),

              // Vibration switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFFFFD56B),
                activeTrackColor: const Color(0xFFC89B3C),
                inactiveThumbColor: const Color(0xFF64748B),
                inactiveTrackColor: const Color(0xFF1E293B),
                title: const Text(
                  'الاهتزاز والتفاعل اللمسي (Haptic)',
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
                  'صوت النقر مع كل تسبيحة',
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

  Widget _buildThemeOption(String title, String key, Color color, StateSetter setSheetState) {
    final isSelected = _tasbihTheme == key;
    return Expanded(
      child: InkWell(
        onTap: () {
          setSheetState(() => _tasbihTheme = key);
          setState(() => _tasbihTheme = key);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF151C28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF334155),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isSelected ? color : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _accentColor {
    switch (_tasbihTheme) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'royal':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFFFD56B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDhikr = _adhkar[_selectedDhikrIndex]['name'] as String;
    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 0.0;
    final percentInt = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Cinematic Lantern Mosque Artwork matching exact aesthetic
          Image.asset(
            'assets/quran_viewer_left_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/home_hero_mosque.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF070B11)),
            ),
          ),

          // Dark overlay gradient with royal glow
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF04070D).withValues(alpha: 0.90),
                  const Color(0xFF070B11).withValues(alpha: 0.80),
                  const Color(0xFF030508).withValues(alpha: 0.96),
                ],
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

                  // 1. Top Header: [Settings Gear] | [السبحة الإلكترونية] | [Chart Stats]
                  _buildHeader(),

                  const SizedBox(height: 14),

                  // 2. Horizontal Dhikr Selector Tabs: [سبحان الله (gold)] [الحمد لله] [لا إله إلا الله] ...
                  _buildDhikrHorizontalSelector(),

                  const SizedBox(height: 18),

                  // 3. Central Circular Beads Dial with glowing active bead and digital counter
                  _buildCentralBeadDial(activeDhikr),

                  const SizedBox(height: 18),

                  // 4. Action Controls: [إعادة (Reset)] | [+ اضغط للتسبيح] | [تراجع (Undo)]
                  _buildActionButtonsRow(),

                  const SizedBox(height: 24),

                  // 5. Daily Goal Card: [الهدف اليومي للتسبيح] + [33 | 100 | 500 | 1000] + Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDailyGoalCard(progress, percentInt),
                  ),

                  const SizedBox(height: 14),

                  // 6. Statistics Card: [إحصائيات التسبيح] (1420 إجمالي | 142 اليوم | 300 أطول جلسة)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStatisticsCard(),
                  ),

                  const SizedBox(height: 14),

                  // 7. Customization Banner: [تخصيص التسبيح] (صوت التسبيح • اهتزاز • نوع العداد)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCustomizationBanner(),
                  ),

                  const SizedBox(height: 20),

                  // 8. Bottom Islamic Ornament: ❖ واذكر ربك كثيراً ❖
                  _buildFooterOrnament(),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header: [Settings Icon] | [Title + Subtitle] | [Stats Icon]
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Settings Gear Button
          _buildCircleIconButton(
            icon: Icons.settings_outlined,
            onTap: _showCustomizationSheet,
          ),

          // Center: Title & Subtitle
          Column(
            children: [
              const Text(
                'السبحة الإلكترونية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'اذكر الله واطمئن قلبك',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFFD56B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 24, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.5)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('❖', style: TextStyle(color: Color(0xFFC89B3C), fontSize: 10)),
                  ),
                  Container(width: 24, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),

          // Right: Statistics Leaderboard Icon
          _buildCircleIconButton(
            icon: Icons.bar_chart_rounded,
            onTap: () {
              // Scroll to stats or trigger feedback
              HapticFeedback.lightImpact();
            },
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131B26).withValues(alpha: 0.8),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.6),
            width: 1,
          ),
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

  /// Horizontal Dhikr Pills Carousel matching screenshot
  Widget _buildDhikrHorizontalSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Right to left scrolling in Arabic
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
                    color: const Color(0xFF0F1722).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: Color(0xFFFFD56B), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'إضافة',
                        style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFD56B), fontSize: 12),
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
                setState(() {
                  _selectedDhikrIndex = index;
                  _counter = 0;
                  _currentSessionCount = 0;
                });
              },
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF0F1722).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF334155).withValues(alpha: 0.6),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD56B).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF070B11) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      iconData,
                      size: 16,
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

  /// Central Circular Dial with 33 Realistic Glowing Beads
  Widget _buildCentralBeadDial(String activeDhikr) {
    const int beadCount = 33;
    const double radius = 132.0;
    final int activeIndex = _counter % beadCount;

    return GestureDetector(
      onTap: _incrementCounter,
      child: Container(
        width: 310,
        height: 310,
        color: Colors.transparent, // Capture taps across the whole circle
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular track of 33 beads with smooth animated rotation
            AnimatedRotation(
              turns: _counter / 33.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(beadCount, (index) {
                  final angle = (2 * math.pi / beadCount) * index - (math.pi / 2);
                  final x = radius * math.cos(angle);
                  final y = radius * math.sin(angle);
                  final isCurrent = index == 0; // Active top bead
                  final isPassed = index < activeIndex;

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isCurrent ? 18 : 13,
                      height: isCurrent ? 18 : 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCurrent
                            ? const RadialGradient(
                                center: Alignment(-0.3, -0.3),
                                colors: [
                                  Color(0xFFFFF7DB),
                                  Color(0xFFFFD56B),
                                  Color(0xFFC89B3C),
                                ],
                              )
                            : isPassed
                                ? RadialGradient(
                                    center: const Alignment(-0.3, -0.3),
                                    colors: [
                                      _accentColor.withValues(alpha: 0.8),
                                      const Color(0xFF1E293B),
                                      Colors.black,
                                    ],
                                  )
                                : const RadialGradient(
                                    center: Alignment(-0.3, -0.3),
                                    colors: [
                                      Color(0xFF334155),
                                      Color(0xFF131B26),
                                      Color(0xFF070B11),
                                    ],
                                  ),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFFFFF7DB)
                              : isPassed
                                  ? _accentColor.withValues(alpha: 0.7)
                                  : const Color(0xFF475569).withValues(alpha: 0.7),
                          width: isCurrent ? 2.0 : 1.0,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD56B).withValues(alpha: 0.8),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Inner Central Glass Dial matching the screenshot
            Container(
              width: 195,
              height: 195,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    const Color(0xFF101926).withValues(alpha: 0.95),
                    const Color(0xFF070B11).withValues(alpha: 0.98),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.5),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD56B).withValues(alpha: 0.12),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Selected Dhikr Name: سبحان الله
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      activeDhikr,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD56B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Digital Count: 0
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_counter',
                      key: ValueKey<int>(_counter),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),

                  // Goal: الهدف: 33
                  Text(
                    'الهدف: $_target',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action Controls: [إعادة] (Reset) | [ + اضغط للتسبيح] (Giant Gold) | [تراجع] (Undo)
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
                  color: const Color(0xFF131B26).withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
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
              'إعادة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),

        const SizedBox(width: 32),

        // Center Button: Giant Glowing Golden + Button
        Column(
          children: [
            InkWell(
              onTap: _incrementCounter,
              borderRadius: BorderRadius.circular(42),
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.3),
                    colors: [
                      Color(0xFFFFF3D1),
                      Color(0xFFFFD56B),
                      Color(0xFFC89B3C),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD56B).withValues(alpha: 0.5),
                      blurRadius: 26,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 46,
                    color: Color(0xFF0B1019),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط للتسبيح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
                  color: const Color(0xFF131B26).withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.reply_rounded,
                    size: 24,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'تراجع',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Daily Goal Card: [الهدف اليومي للتسبيح] + [33 | 100 | 500 | 1000] + Progress bar
  Widget _buildDailyGoalCard(double progress, int percentInt) {
    final targets = [33, 100, 500, 1000];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Target Pills: [1000] [500] [100] [33 (selected gold)]
              Row(
                children: targets.reversed.map((t) {
                  final isSelected = _target == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _target = t;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF182232),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD56B) : const Color(0xFF334155),
                          ),
                        ),
                        child: Text(
                          '$t',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
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
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
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
                '$_counter / $_target',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                '$percentInt%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
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
        color: const Color(0xFF0F1722).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: إحصائيات التسبيح
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'إحصائيات التسبيح',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.bar_chart_rounded,
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
                    const Icon(Icons.timer_outlined, color: Color(0xFFFFD56B), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '$_longestSession',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

              Container(width: 1, height: 40, color: const Color(0xFF334155).withValues(alpha: 0.6)),

              // Col 2: تسبيحات اليوم
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFFFFD56B), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '$_todayTasbih',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

              Container(width: 1, height: 40, color: const Color(0xFF334155).withValues(alpha: 0.6)),

              // Col 1: إجمالي التسبيحات
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.all_inclusive_rounded, color: Color(0xFFFFD56B), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalTasbih',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  /// Customization Banner matching bottom card
  Widget _buildCustomizationBanner() {
    return InkWell(
      onTap: _showCustomizationSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1722).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7)),
        ),
        child: const Row(
          children: [
            Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF94A3B8)),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تخصيص التسبيح',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'صوت التسبيح • اهتزاز • نوع العداد',
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
              Icons.settings_outlined,
              size: 20,
              color: Color(0xFFFFD56B),
            ),
          ],
        ),
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
            '❖ واذكر ربك كثيراً ❖',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: Color(0xFFC89B3C),
            ),
          ),
        ),
        Container(width: 36, height: 1, color: const Color(0xFFC89B3C).withValues(alpha: 0.5)),
      ],
    );
  }
}
