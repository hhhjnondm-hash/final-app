import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/design_system.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  int _totalTasbih = 1420;
  int _selectedDhikrIndex = 0;
  String _tasbihStyle = 'gold'; // gold, emerald, royal, minimal
  bool _enableVibration = true;

  late AnimationController _rotationController;
  double _currentAngle = 0.0;

  final List<String> _adhkar = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ صَلِّ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    if (_enableVibration) HapticFeedback.lightImpact();

    setState(() {
      _counter++;
      _totalTasbih++;
      _currentAngle += (2 * math.pi / 33);

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
        _currentAngle -= (2 * math.pi / 33);
      });
    }
  }

  void _resetCounter() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignSystem.bgDarkest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.4)),
        ),
        title: const Text('تأكيد إعادة التعيين', style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('هل تريد تصفير عداد الذكر الحالي؟', style: TextStyle(color: DesignSystem.textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: DesignSystem.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
            ),
            onPressed: () {
              setState(() => _counter = 0);
              Navigator.pop(ctx);
            },
            child: const Text('إعادة تعيين'),
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
        padding: const EdgeInsets.all(DesignSystem.spacingL),
        decoration: BoxDecoration(
          color: DesignSystem.bgDarkest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: DesignSystem.goldGradient,
                boxShadow: DesignSystem.goldGlow,
              ),
              child: const Icon(Icons.check_circle_rounded, color: DesignSystem.bgDarkest, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'أحسنت! تقبل الله طاعتك ✨',
              style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'أتممت وردك ($_target تسبيحة) من ${_adhkar[_selectedDhikrIndex]}',
              style: const TextStyle(color: DesignSystem.goldLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('تم', style: TextStyle(color: DesignSystem.textWhite)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.gold,
                      foregroundColor: DesignSystem.bgDarkest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('جلسة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: DesignSystem.bgDarkest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.4)),
        ),
        title: const Text('إضافة تسبيحة جديدة', style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: DesignSystem.textWhite),
          decoration: InputDecoration(
            hintText: 'اكتب الذكر أو الدعاء...',
            hintStyle: const TextStyle(color: DesignSystem.textMuted),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DesignSystem.gold)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: DesignSystem.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.gold,
              foregroundColor: DesignSystem.bgDarkest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _adhkar.insert(0, controller.text.trim());
                  _selectedDhikrIndex = 0;
                  _counter = 0;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getPrimaryAccent() {
    switch (_tasbihStyle) {
      case 'emerald':
        return const Color(0xFF38B982);
      case 'royal':
        return const Color(0xFF315BEA);
      case 'minimal':
        return Colors.white70;
      default:
        return DesignSystem.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDhikr = _adhkar[_selectedDhikrIndex];
    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 0.0;
    final accentColor = _getPrimaryAccent();

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spacingL,
                      DesignSystem.spacingM,
                      DesignSystem.spacingL,
                      DesignSystem.spacingS,
                    ),
                    child: _buildHeader(context),
                  ),
                ),

                // 2. Dhikr Selection Carousel Pills
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacingS),
                    child: _buildDhikrCarousel(),
                  ),
                ),

                // 3. Main Realistic Tasbih Bead Visual
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 16),
                    child: _buildMainTasbihVisual(activeDhikr, progress, accentColor),
                  ),
                ),

                // 4. Primary Giant Tap Target & Controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildActionControls(accentColor),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 5. Goal & Daily Target Progress Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildGoalCard(accentColor),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 6. Statistics Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildStatisticsSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 7. Customization & Styles
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildCustomizationSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.goldLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const Column(
          children: [
            Text(
              'السبحة الإلكترونية',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'اذكر الله واطمئن قلبك',
              style: TextStyle(
                color: DesignSystem.goldLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: DesignSystem.textMuted, size: 22),
          onPressed: _resetCounter,
        ),
      ],
    );
  }

  Widget _buildDhikrCarousel() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
        itemCount: _adhkar.length + 1,
        itemBuilder: (context, index) {
          if (index == _adhkar.length) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: _showAddCustomDhikr,
                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: DesignSystem.goldLight, size: 16),
                      SizedBox(width: 4),
                      Text('إضافة تسبيحة', style: TextStyle(color: DesignSystem.goldLight, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          }

          final isSelected = _selectedDhikrIndex == index;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDhikrIndex = index;
                  _counter = 0;
                });
              },
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? DesignSystem.goldGradient : null,
                  color: isSelected ? null : DesignSystem.bgCard.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  border: Border.all(
                    color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: isSelected ? DesignSystem.goldGlow : null,
                ),
                child: Center(
                  child: Text(
                    _adhkar[index],
                    style: TextStyle(
                      color: isSelected ? DesignSystem.bgDarkest : DesignSystem.textWhite,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainTasbihVisual(String activeDhikr, double progress, Color accentColor) {
    const int beadCount = 33;
    const double radius = 120.0;

    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Rotating Islamic Prayer Beads Ring
            Transform.rotate(
              angle: _currentAngle,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(beadCount, (index) {
                  final angle = (2 * math.pi / beadCount) * index;
                  final x = radius * math.cos(angle);
                  final y = radius * math.sin(angle);
                  final isMasterBead = index == 0;

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Container(
                      width: isMasterBead ? 18 : 13,
                      height: isMasterBead ? 18 : 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isMasterBead
                              ? [DesignSystem.goldLight, DesignSystem.gold, const Color(0xFF8B6508)]
                              : [
                                  const Color(0xFF1E3A5F),
                                  const Color(0xFF0F1E33),
                                  Colors.black,
                                ],
                        ),
                        border: Border.all(
                          color: isMasterBead ? DesignSystem.goldLight : accentColor.withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMasterBead ? DesignSystem.gold.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Inner Glass Dial
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.bgCard.withValues(alpha: 0.9),
                border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activeDhikr,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        color: DesignSystem.goldLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Text(
                        '$_counter',
                        key: ValueKey<int>(_counter),
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'الهدف: $_target',
                      style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControls(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Undo Button
        InkWell(
          onTap: _undoCounter,
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignSystem.bgCard.withValues(alpha: 0.8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.undo_rounded, color: DesignSystem.textMuted, size: 22),
          ),
        ),

        const SizedBox(width: 24),

        // Giant Primary Tap Target Button
        InkWell(
          onTap: _incrementCounter,
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: DesignSystem.bgDarkest,
              size: 48,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Reset Button
        InkWell(
          onTap: _resetCounter,
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignSystem.bgCard.withValues(alpha: 0.8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.restart_alt_rounded, color: DesignSystem.textMuted, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الهدف اليومي للتسبيح', style: TextStyle(color: DesignSystem.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                children: [33, 100, 500, 1000].map((t) {
                  final isSelected = _target == t;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => setState(() => _target = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$t',
                          style: TextStyle(
                            color: isSelected ? DesignSystem.bgDarkest : DesignSystem.textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_counter / _target).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إحصائيات التسبيح', style: TextStyle(color: DesignSystem.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('إجمالي التسبيحات', '$_totalTasbih', Icons.all_inclusive_rounded),
              _buildStatItem('تسبيحات اليوم', '142', Icons.today_rounded),
              _buildStatItem('أطول جلسة', '300', Icons.timer_outlined),
              _buildStatItem('أيام الذكر', '14 يوم', Icons.calendar_month_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: DesignSystem.goldLight, size: 16),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: DesignSystem.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildCustomizationSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تخصيص نمط السبحة', style: TextStyle(color: DesignSystem.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStyleTile('ذهبي ملكي', 'gold', DesignSystem.gold),
              const SizedBox(width: 8),
              _buildStyleTile('زمردي', 'emerald', const Color(0xFF38B982)),
              const SizedBox(width: 8),
              _buildStyleTile('نيلي فاخر', 'royal', const Color(0xFF315BEA)),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('الاهتزاز والتفاعل اللمسي (Haptic)', style: TextStyle(color: DesignSystem.textWhite, fontSize: 12)),
            value: _enableVibration,
            activeColor: DesignSystem.gold,
            onChanged: (val) => setState(() => _enableVibration = val),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTile(String title, String key, Color color) {
    final isSelected = _tasbihStyle == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tasbihStyle = key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? color : DesignSystem.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

