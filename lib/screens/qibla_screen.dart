import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../utils/design_system.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  final PrayerService _prayerService = PrayerService();
  final LocationService _locationService = LocationService();

  // Kaaba Coordinates (Makkah Al-Mukarramah)
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  // Real-time sensor state
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _rawHeading = 0.0;
  double _smoothedHeading = 0.0;
  double? _sensorAccuracy;
  bool _hasCompassSensor = true;
  bool _isSensorLoading = true;
  String? _sensorErrorMessage;

  // Location & Bearing state
  double _userLat = 30.0444; // Default Cairo
  double _userLng = 31.2357;
  String _cityName = 'القاهرة';
  bool _isLoadingLocation = false;
  String? _locationErrorMessage;

  // UI state
  bool _isFullscreen = false;
  bool _hasVibrated = false;

  // Animation controller for smooth rotational transitions
  late AnimationController _animController;
  late Animation<double> _headingAnimation;
  double _lastAnimatedHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _headingAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _initLocation();
    _initCompassSensor();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  /// Initialize real GPS location
  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);

    // Initial fallback from cached prayer service location
    final cached = _prayerService.currentLocation;
    _userLat = cached.latitude;
    _userLng = cached.longitude;
    _cityName = cached.cityName;

    try {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _isLoadingLocation = false;
          _locationErrorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationErrorMessage = _locationService.errorMessage ?? 'تعذر الوصول التلقائي للموقع، تم استخدام الموقع المحفوظ.';
        });
      }
    }
  }

  /// Initialize real device compass sensor via magnetometer + accelerometer
  void _initCompassSensor() {
    try {
      final compassEvents = FlutterCompass.events;
      if (compassEvents == null) {
        setState(() {
          _hasCompassSensor = false;
          _isSensorLoading = false;
          _sensorErrorMessage = 'مستشعر البوصلة (Magnetometer) غير متوفر، يمكنك السحب لتدوير البوصلة يدوياً.';
        });
        return;
      }

      _compassSubscription = compassEvents.listen(
        (CompassEvent event) {
          if (!mounted) return;
          final heading = event.heading;
          if (heading == null) {
            setState(() {
              _isSensorLoading = true;
              _sensorErrorMessage = 'جاري قراءة إشارة مستشعر البوصلة...';
            });
            return;
          }

          // Real device heading detected
          _onNewHeadingReceived(heading, event.accuracy);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _hasCompassSensor = false;
            _isSensorLoading = false;
            _sensorErrorMessage = 'حدث خطأ أثناء قراءة مستشعر البوصلة.';
          });
        },
      );
    } catch (e) {
      setState(() {
        _hasCompassSensor = false;
        _isSensorLoading = false;
        _sensorErrorMessage = 'تعذر تشغيل مستشعر البوصلة.';
      });
    }
  }

  /// Smooth heading filter avoiding 360-0 degree wrap discontinuity
  void _onNewHeadingReceived(double newRawHeading, double? accuracy) {
    // Normalise to 0..360
    final normalized = (newRawHeading % 360.0 + 360.0) % 360.0;
    _rawHeading = normalized;
    _sensorAccuracy = accuracy;
    _isSensorLoading = false;
    _sensorErrorMessage = null;

    // Exponential smoothing / Low-pass filter to reject magnetic noise
    var diff = normalized - _smoothedHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    // Filter factor: 0.4 gives crisp responsiveness while absorbing jitter
    final target = _smoothedHeading + diff * 0.4;
    final finalHeading = (target % 360.0 + 360.0) % 360.0;

    _headingAnimation = Tween<double>(begin: _lastAnimatedHeading, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0.0);
    _lastAnimatedHeading = finalHeading;
    _smoothedHeading = finalHeading;

    if (mounted) setState(() {});
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
        math.cos(userLat * (math.pi / 180.0)) *
            math.cos(kaabaLat * (math.pi / 180.0)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  void _showCalibrationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(DesignSystem.spacingL),
        decoration: BoxDecoration(
          color: const Color(0xFF14121E),
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
            const Icon(Icons.all_inclusive_rounded, color: DesignSystem.goldLight, size: 52),
            const SizedBox(height: 16),
            const Text(
              'معايرة مستشعر البوصلة',
              style: TextStyle(color: DesignSystem.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'حرّك هاتفك في الهواء على شكل رقم (8) لعدة ثوانٍ لمعايرة مستشعر البوصلة وضمان دقة توجيه القبلة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignSystem.textMuted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignSystem.goldLight,
                      side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('تحديث الموقع'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _initLocation();
                    },
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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('تمت المعايرة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyCoordinates(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: '21.4225° N, 39.8262° E'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('تم نسخ إحداثيات الكعبة المشرفة إلى الحافظة', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF14121E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF10B981)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qiblaBearing = _calculateQiblaBearing(_userLat, _userLng);
    final distanceKm = _calculateDistanceToKaaba(_userLat, _userLng);

    // Angular deviation between device heading and calculated Qibla bearing
    final deviation = ((qiblaBearing - _smoothedHeading + 180) % 360 - 180).abs();
    final isAligned = deviation <= 3.5;

    if (isAligned && !_hasVibrated) {
      _hasVibrated = true;
      HapticFeedback.mediumImpact();
    } else if (!isAligned && _hasVibrated) {
      _hasVibrated = false;
    }

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0B14),
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded, color: DesignSystem.goldLight, size: 24),
                      onPressed: () => setState(() => _isFullscreen = false),
                      tooltip: 'الخروج من وضع ملء الشاشة',
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCompassDial(qiblaBearing, isAligned, size: 340),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildDegreeStatusCard(qiblaBearing, isAligned, deviation),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Top App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _buildTopBar(context),
                    ),
                  ),

                  // 2. Banner Header with Ayah & Location Pill
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: _buildHeroBanner(_cityName),
                    ),
                  ),

                  // Sensor / Location Status Warnings if any
                  if (_sensorErrorMessage != null || _locationErrorMessage != null || _isSensorLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _buildStatusNotice(),
                      ),
                    ),

                  // 3. Luxurious Real-time Compass Disc Hero
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: _buildCompassDial(qiblaBearing, isAligned, size: 310),
                      ),
                    ),
                  ),

                  // 4. Degree & Direction Badge Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: _buildDegreeStatusCard(qiblaBearing, isAligned, deviation),
                    ),
                  ),

                  // 5. Two Metric Cards (Distance & Coordinates)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: _buildDistanceCard(distanceKm)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCoordinatesCard(context)),
                        ],
                      ),
                    ),
                  ),

                  // 6. Dua for Facing Qibla Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: _buildDuaCard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: DesignSystem.goldLight, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القبلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  'اتجه نحو الكعبة المشرفة بدقة',
                  style: TextStyle(color: DesignSystem.goldLight, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: DesignSystem.goldLight, size: 20),
                onPressed: () => setState(() => _isFullscreen = true),
                tooltip: 'ملء الشاشة',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: DesignSystem.goldLight, size: 20),
                onPressed: () => _showCalibrationSheet(context),
                tooltip: 'معايرة البوصلة',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroBanner(String cityName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D172A), Color(0xFF13101C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _initLocation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: DesignSystem.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoadingLocation
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: DesignSystem.goldLight),
                            )
                          : const Icon(Icons.location_on_rounded, color: DesignSystem.goldLight, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'موقعك: $cityName',
                        style: const TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                '[البقرة: 144]',
                style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '﴿ فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ وَحَيْثُ مَا كُنتُمْ فَوَلُّوا وُجُوهَكُمْ شَطْرَهُ ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Amiri',
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusNotice() {
    final msg = _sensorErrorMessage ?? _locationErrorMessage ?? (_isSensorLoading ? 'جاري قراءة إشارة المستشعر...' : '');
    if (msg.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1C14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
            ),
          ),
          if (_sensorAccuracy != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'الدقة: ${_sensorAccuracy!.toStringAsFixed(0)}°',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompassDial(double qiblaBearing, bool isAligned, {double size = 310}) {
    return GestureDetector(
      // Allows gesture drag if running on desktop/web without magnetometer
      onHorizontalDragUpdate: (details) {
        if (!_hasCompassSensor || kIsWeb) {
          _onNewHeadingReceived((_rawHeading - details.delta.dx * 0.5) % 360, null);
        }
      },
      child: AnimatedBuilder(
        animation: _headingAnimation,
        builder: (context, child) {
          final currentHeading = (_headingAnimation.value % 360.0 + 360.0) % 360.0;
          final needleRotation = (qiblaBearing - currentHeading) * (math.pi / 180.0);

          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Outer Glow Aura
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: size - 10,
                  height: size - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isAligned
                            ? const Color(0xFF10B981).withValues(alpha: 0.35)
                            : DesignSystem.gold.withValues(alpha: 0.15),
                        blurRadius: isAligned ? 40 : 25,
                        spreadRadius: isAligned ? 4 : 1,
                      ),
                    ],
                  ),
                ),

                // 2. Intricate Golden Islamic Outer Octagonal Ring
                CustomPaint(
                  size: Size(size - 10, size - 10),
                  painter: _IslamicCompassRingPainter(isAligned: isAligned),
                ),

                // 3. Rotating Cardinal Disc (N, E, S, W in Arabic)
                Transform.rotate(
                  angle: -currentHeading * (math.pi / 180.0),
                  child: Container(
                    width: size - 60,
                    height: size - 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF120E1F),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dial Ticks
                        ...List.generate(72, (index) {
                          final isCardinal = index % 18 == 0;
                          final isMinor = index % 6 == 0;
                          return Transform.rotate(
                            angle: (index * 5) * (math.pi / 180.0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: isCardinal ? 2.5 : (isMinor ? 1.5 : 1),
                                height: isCardinal ? 12 : (isMinor ? 8 : 4),
                                color: isCardinal
                                    ? DesignSystem.goldLight
                                    : (isMinor ? Colors.white38 : Colors.white12),
                              ),
                            ),
                          );
                        }),

                        // Cardinal Letters
                        // North (N / شمال)
                        const Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Text('N', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        // East (ق / شرق)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: Text('ق', style: TextStyle(color: DesignSystem.goldLight, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        // South (ج / جنوب)
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text('ج', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        // West (ش / غرب)
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 24),
                            child: Text('ش', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Rotating Golden Needle pointing toward Qibla
                Transform.rotate(
                  angle: needleRotation,
                  child: SizedBox(
                    width: 70,
                    height: size - 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Kaaba Icon at the tip of the needle
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isAligned ? const Color(0xFF10B981) : DesignSystem.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isAligned ? const Color(0xFF10B981) : DesignSystem.gold).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mosque_rounded, color: Color(0xFF0D0B14), size: 16),
                          ),
                        ),

                        // Needle Blade
                        Positioned(
                          top: 30,
                          bottom: 30,
                          child: Container(
                            width: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isAligned
                                    ? [const Color(0xFF10B981), Colors.white24]
                                    : [DesignSystem.goldLight, DesignSystem.gold.withValues(alpha: 0.2)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Center Golden Medallion
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF2C2442), Color(0xFF140F24)],
                    ),
                    border: Border.all(
                      color: isAligned ? const Color(0xFF10B981) : DesignSystem.gold,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isAligned ? const Color(0xFF10B981) : DesignSystem.gold).withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: isAligned ? const Color(0xFF10B981) : DesignSystem.goldLight,
                          size: 22,
                        ),
                        Text(
                          '${currentHeading.toInt()}°',
                          style: TextStyle(
                            color: isAligned ? const Color(0xFF10B981) : DesignSystem.goldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDegreeStatusCard(double qiblaBearing, bool isAligned, double deviation) {
    if (isAligned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2B20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  '${qiblaBearing.toInt()}°',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'أنت الآن في الاتجاه الصحيح للقبلة المشرفة ✓',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${qiblaBearing.toInt()}°',
            style: const TextStyle(color: DesignSystem.goldLight, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text(
            'اتجاه القبلة من موقعك',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'قم بتدوير الهاتف حتى يتطابق المؤشر الذهبي (الانحراف: ${deviation.toInt()}°)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(double distanceKm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignSystem.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mosque_outlined, color: DesignSystem.goldLight, size: 20),
          ),
          const SizedBox(height: 12),
          const Text('المسافة للكعبة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '${distanceKm.toInt()} كم',
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text('تقريباً من موقعك الحالي', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B982).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pin_drop_outlined, color: Color(0xFF38B982), size: 20),
              ),
              InkWell(
                onTap: () => _copyCoordinates(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded, color: DesignSystem.goldLight, size: 12),
                      SizedBox(width: 4),
                      Text('نسخ', style: TextStyle(color: DesignSystem.goldLight, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('إحداثيات الكعبة', style: TextStyle(color: DesignSystem.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(
            '21.42° N, 39.83° E',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text('مكة المكرمة، السعودية', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDuaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1730), Color(0xFF13101C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignSystem.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.brightness_3_rounded, color: DesignSystem.goldLight, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'دعاء التوجه إلى القبلة',
                style: TextStyle(color: DesignSystem.goldLight, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '« اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالإِكْرَامِ »',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Amiri',
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'صحيح مسلم',
              style: TextStyle(color: DesignSystem.textMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslamicCompassRingPainter extends CustomPainter {
  final bool isAligned;
  _IslamicCompassRingPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerPaint = Paint()
      ..color = (isAligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37)).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius - 4, outerPaint);

    final innerPaint = Paint()
      ..color = (isAligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37)).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 16, innerPaint);

    final starPaint = Paint()
      ..color = (isAligned ? const Color(0xFF10B981) : const Color(0xFFE6CA65))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180.0);
      final x = center.dx + (radius - 10) * math.cos(angle);
      final y = center.dy + (radius - 10) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicCompassRingPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
