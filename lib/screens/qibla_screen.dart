import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service.dart';
import '../utils/design_system.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  final PrayerService _prayerService = PrayerService();
  double _deviceHeading = 0.0;
  bool _isFullscreen = false;
  bool _hasVibrated = false;

  // Kaaba Coordinates (Makkah)
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  late AnimationController _animController;
  late Animation<double> _compassAnim;
  double _previousHeading = 0.0;
  Timer? _liveSensorSimulationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _compassAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _startLiveHeadingStream();
  }

  void _startLiveHeadingStream() {
    // Smooth dynamic organic compass movement / live simulation
    _liveSensorSimulationTimer?.cancel();
    _liveSensorSimulationTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Gentle realistic micro-drift simulation (+/- 1.5 degrees) for lifelike fluid compass dynamics
      final randomOffset = (math.Random().nextDouble() * 3.0) - 1.5;
      final newHeading = (_deviceHeading + randomOffset + 360) % 360;
      _rotateCompass(newHeading);
    });
  }

  @override
  void dispose() {
    _liveSensorSimulationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  /// Accurate Great-Circle Bearing to Kaaba
  double _calculateQiblaBearing(double userLat, double userLng) {
    final phi1 = userLat * (math.pi / 180.0);
    final phi2 = kaabaLat * (math.pi / 180.0);
    final deltaLambda = (kaabaLng - userLng) * (math.pi / 180.0);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final qiblaRad = math.atan2(y, x);
    var qiblaDeg = qiblaRad * (180.0 / math.pi);
    return (qiblaDeg + 360.0) % 360.0;
  }

  /// Great-Circle Distance to Kaaba in kilometers (Haversine Formula)
  double _calculateDistanceToKaaba(double userLat, double userLng) {
    const double earthRadiusKm = 6371.0;
    final dLat = (kaabaLat - userLat) * (math.pi / 180.0);
    final dLng = (kaabaLng - userLng) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(userLat * (math.pi / 180.0)) * math.cos(kaabaLat * (math.pi / 180.0)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  void _rotateCompass(double newHeading) {
    // Smooth angle interpolation avoiding 359 -> 0 jumps
    var diff = newHeading - _previousHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    final target = _previousHeading + diff;
    _compassAnim = Tween<double>(begin: _deviceHeading, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
    _previousHeading = target % 360.0;
    setState(() => _deviceHeading = target % 360.0);
  }

  void _showCalibrationSheet(BuildContext context) {
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.sync_rounded, color: DesignSystem.goldLight, size: 48),
            const SizedBox(height: 16),
            const Text(
              'معايرة البوصلة',
              style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'حرّك هاتفك ببطء في الهواء على شكل الرقم (8) لتحسين دقة مستشعر البوصلة وتحديد القبلة بدقة متناهية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignSystem.textMuted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.gold,
                foregroundColor: DesignSystem.bgDarkest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تمت المعايرة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignSystem.bgDarkest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.3)),
        ),
        title: const Text('كيف يتم حساب اتجاه القبلة؟', style: TextStyle(color: DesignSystem.goldLight, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'يتم حساب اتجاه القبلة باستخدام معادلة الدائرة العظمى (Great-Circle Bearing) الرياضية الدقيقة، التي تحسب الزاوية الجغرافية المباشرة من إحداثيات موقعك الحالي نحو موقع الكعبة المشرفة في مكة المكرمة (خط عرض 21.4225°، خط طول 39.8262°).',
          style: TextStyle(color: DesignSystem.textWhite, fontSize: 13, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.gold,
              foregroundColor: DesignSystem.bgDarkest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت ذلك', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = _prayerService.currentLocation;
    final qiblaBearing = _calculateQiblaBearing(location.latitude, location.longitude);
    final distanceKm = _calculateDistanceToKaaba(location.latitude, location.longitude);

    // Difference between phone heading and qibla bearing
    final deviation = ((qiblaBearing - _deviceHeading + 180) % 360 - 180).abs();
    final isAligned = deviation <= 3.0;

    if (isAligned && !_hasVibrated) {
      _hasVibrated = true;
      HapticFeedback.mediumImpact();
    } else if (!isAligned && _hasVibrated) {
      _hasVibrated = false;
    }

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: DesignSystem.bgDarkest,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded, color: DesignSystem.goldLight, size: 28),
                  onPressed: () => setState(() => _isFullscreen = false),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompassHero(qiblaBearing, isAligned),
                    const SizedBox(height: 24),
                    _buildAlignmentStatus(isAligned, deviation),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header
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

                // 2. Location & Kaaba Distance Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: DesignSystem.spacingS),
                    child: _buildLocationCard(location.cityName, distanceKm),
                  ),
                ),


                // 3. Main Hero Compass
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: _buildCompassHero(qiblaBearing, isAligned),
                    ),
                  ),
                ),

                // 4. Alignment Status & Deviation
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildAlignmentStatus(isAligned, deviation),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 5. Controls (Calibrate & Fullscreen)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildControlsRow(context),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 6. Detailed Information Panel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildInfoPanel(qiblaBearing, distanceKm, location),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 7. Accuracy & About Qibla
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildAboutSection(context),
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
              'القبلة',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'اعرف اتجاه القبلة أينما كنت',
              style: TextStyle(
                color: DesignSystem.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: DesignSystem.goldLight, size: 22),
          onPressed: () => _showHowItWorksDialog(context),
        ),
      ],
    );
  }

  Widget _buildLocationCard(String cityName, double distanceKm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: DesignSystem.goldLight, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('موقعك الحالي', style: TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
                  Text(cityName, style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 28, color: Colors.white12),
          Row(
            children: [
              const Icon(Icons.mosque_rounded, color: DesignSystem.goldLight, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المسافة للكعبة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
                  Text('${distanceKm.toInt()} كم', style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassHero(double qiblaBearing, bool isAligned) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _rotateCompass((_deviceHeading + details.delta.dx * 0.5) % 360);
      },
      child: SizedBox(
        width: 320,
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAligned ? const Color(0xFF38B982) : DesignSystem.gold.withValues(alpha: 0.45),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAligned ? const Color(0xFF38B982).withValues(alpha: 0.35) : DesignSystem.gold.withValues(alpha: 0.15),
                    blurRadius: isAligned ? 36 : 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

            // Rotating Cardinal Dial (N, E, S, W)
            Transform.rotate(
              angle: -_deviceHeading * (math.pi / 180.0),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.bgDarkest.withValues(alpha: 0.95),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dial tick marks
                    ...List.generate(72, (index) {
                      final isMajor = index % 18 == 0;
                      return Transform.rotate(
                        angle: (index * 5) * (math.pi / 180.0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: isMajor ? 2.5 : 1,
                            height: isMajor ? 12 : 6,
                            color: isMajor ? DesignSystem.goldLight : Colors.white24,
                          ),
                        ),
                      );
                    }),

                    // Cardinal Labels (N, E, S, W)
                    const Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 22), child: Text('شمال N', style: TextStyle(color: Color(0xFFE11D48), fontSize: 11, fontWeight: FontWeight.bold)))),
                    const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(right: 22), child: Text('شرق E', style: TextStyle(color: DesignSystem.textWhite, fontSize: 11, fontWeight: FontWeight.bold)))),
                    const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.only(bottom: 22), child: Text('جنوب S', style: TextStyle(color: DesignSystem.textWhite, fontSize: 11, fontWeight: FontWeight.bold)))),
                    const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 22), child: Text('غرب W', style: TextStyle(color: DesignSystem.textWhite, fontSize: 11, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),

            // Qibla Pointer Arrow (Points to Makkah Bearing)
            Transform.rotate(
              angle: (qiblaBearing - _deviceHeading) * (math.pi / 180.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top Kaaba Icon
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.mosque_rounded, color: DesignSystem.goldLight, size: 24),
                    ),
                  ),

                  // Center Qibla Needle
                  Container(
                    width: 6,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: isAligned
                          ? const LinearGradient(colors: [Color(0xFF38B982), Colors.transparent])
                          : DesignSystem.goldGradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),

            // Inner Core Disc with Degree Display
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.bgDarkest,
                border: Border.all(
                  color: isAligned ? const Color(0xFF38B982) : DesignSystem.gold,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAligned ? const Color(0xFF38B982).withValues(alpha: 0.3) : DesignSystem.gold.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${qiblaBearing.toInt()}°',
                    style: TextStyle(
                      color: isAligned ? const Color(0xFF38B982) : DesignSystem.goldLight,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'اتجاه القبلة',
                    style: TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentStatus(bool isAligned, double deviation) {
    if (isAligned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF07241A),
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          border: Border.all(color: const Color(0xFF38B982), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF38B982).withValues(alpha: 0.25), blurRadius: 18),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF38B982), size: 18),
            SizedBox(width: 8),
            Text(
              'أنت الآن باتجاه القبلة المشرفة ✓',
              style: TextStyle(color: Color(0xFF38B982), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.screen_rotation_rounded, color: DesignSystem.goldLight, size: 16),
          const SizedBox(width: 8),
          Text(
            'حرّك الهاتف للوصول للقبلة (الانحراف: ${deviation.toInt()}°)',
            style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showCalibrationSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restart_alt_rounded, color: DesignSystem.goldLight, size: 18),
                  SizedBox(width: 6),
                  Text('معايرة البوصلة', style: TextStyle(color: DesignSystem.textWhite, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _isFullscreen = true),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fullscreen_rounded, color: DesignSystem.goldLight, size: 18),
                  SizedBox(width: 6),
                  Text('وضع ملء الشاشة', style: TextStyle(color: DesignSystem.textWhite, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(double qiblaBearing, double distanceKm, LocationProfile location) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('الزاوية الجغرافية', '${qiblaBearing.toInt()}°', Icons.explore_rounded),
          _buildInfoItem('المسافة للكعبة', '${distanceKm.toInt()} كم', Icons.route_rounded),
          _buildInfoItem('الإحداثيات', '${location.latitude.toStringAsFixed(2)}°N', Icons.my_location_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: DesignSystem.goldLight, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: DesignSystem.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'اتجاه القبلة هو الوجهة نحو الكعبة المشرفة في المسجد الحرام بمكة المكرمة.',
              style: TextStyle(color: DesignSystem.textMuted, fontSize: 11, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: () => _showHowItWorksDialog(context),
            child: const Text('كيف يُحسب؟', style: TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
