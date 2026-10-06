import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../utils/design_system.dart';
import '../widgets/visual_effects/floating_particles.dart';
import '../widgets/visual_effects/shimmer_sweep.dart';
import '../widgets/visual_effects/star_glint.dart';
import '../widgets/visual_effects/pulsing_halo.dart';
import '../widgets/visual_effects/interactive_motion_card.dart';
import '../widgets/developer_credits_badge.dart';
import '../widgets/islamic_background.dart';

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

    final isLight = DesignSystem.isLightMode;

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: isLight ? const Color(0xFFFBF8F2) : const Color(0xFF0D0B14),
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
                      color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1E1B2E),
                      shape: BoxShape.circle,
                      border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : Colors.white12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.fullscreen_exit_rounded,
                        color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                        size: 24,
                      ),
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
      backgroundColor: Colors.transparent,
      body: IslamicBackground(
        child: SafeArea(
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
                          child: _buildCompassDial(
                            qiblaBearing,
                            isAligned,
                            size: math.min(310.0, MediaQuery.of(context).size.width - 40),
                          ),
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _buildDuaCard(),
                      ),
                    ),

                    // 7. Developer Credits Badge
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
                        child: Center(
                          child: DeveloperCreditsBadge(),
                        ),
                      ),
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

  Widget _buildTopBar(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1E1B2E),
                shape: BoxShape.circle,
                border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black26,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القبلة',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1C1917) : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  'اتجه نحو الكعبة المشرفة بدقة',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1E1B2E),
                shape: BoxShape.circle,
                border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black26,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_rounded,
                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                  size: 20,
                ),
                onPressed: () => setState(() => _isFullscreen = true),
                tooltip: 'ملء الشاشة',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF1E1B2E),
                shape: BoxShape.circle,
                border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black26,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                  size: 20,
                ),
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
    final isLight = DesignSystem.isLightMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFDF8), Color(0xFFFAF5EB)]
              : const [Color(0xFF1D172A), Color(0xFF13101C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Kaaba Artwork Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? const Color(0xFFC89B3C) : DesignSystem.goldLight.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD56B).withValues(alpha: isLight ? 0.2 : 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                'assets/images/3d/kaaba_qibla_3d.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.explore_rounded,
                  color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFFFD56B).withValues(alpha: 0.25)
                              : DesignSystem.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLight ? const Color(0xFFC89B3C).withValues(alpha: 0.5) : DesignSystem.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isLoadingLocation
                                ? SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                    ),
                                  )
                                : Icon(
                                    Icons.location_on_rounded,
                                    color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                    size: 12,
                                  ),
                            const SizedBox(width: 4),
                            Text(
                              'موقعك: $cityName',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '[البقرة: 144]',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '﴿ فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ ﴾',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1C1917) : Colors.white,
                    fontSize: 13,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                // 1. Ambient & Specular Glow Aura
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: size - 8,
                  height: size - 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isAligned
                            ? const Color(0xFF10B981).withValues(alpha: 0.45)
                            : const Color(0xFFD4AF57).withValues(alpha: 0.22),
                        blurRadius: isAligned ? 36 : 24,
                        spreadRadius: isAligned ? 4 : 1,
                      ),
                      if (isAligned)
                        const BoxShadow(
                          color: Color(0xFFFFD56B),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),

                // 2. Photorealistic Volumetric 3D Compass Housing & Dial
                CustomPaint(
                  size: Size(size, size),
                  painter: _Photorealistic3DQiblaPainter(
                    currentHeading: currentHeading,
                    needleRotation: needleRotation,
                    isAligned: isAligned,
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
    final isLight = DesignSystem.isLightMode;

    if (isAligned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]
                : const [Color(0xFF0D3325), Color(0xFF072017), Color(0xFF03120D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF10B981), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.2 : 0.3),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF10B981), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${qiblaBearing.toInt()}°',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'أنت في اتجاه القبلة المشرفة ✓',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF064E3B) : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'استقبل الكعبة المشرفة وابدأ صلاتك بخشوع',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFDF8), Color(0xFFFAF5EB)]
              : const [Color(0xFF151C2A), Color(0xFF0F1420), Color(0xFF0A0D15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.35),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: isLight
                  ? const LinearGradient(colors: [Color(0xFFFFDF7D), Color(0xFFE5A83B)])
                  : null,
              color: isLight ? null : const Color(0xFFFFD56B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLight ? const Color(0xFFB8860B) : const Color(0xFFFFD56B).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '${qiblaBearing.toInt()}°',
              style: TextStyle(
                color: isLight ? const Color(0xFF1A1002) : const Color(0xFFFFE58F),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اتجاه القبلة من موقعك',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1C1917) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'دوّر الهاتف حتى تتطابق الإبرة الذهبية مع الكعبة (الانحراف: ${deviation.toInt()}°)',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(double distanceKm) {
    final isLight = DesignSystem.isLightMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF141926),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFD56B).withValues(alpha: 0.25) : const Color(0xFFFFD56B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.mosque_outlined,
              color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'المسافة للكعبة',
            style: TextStyle(
              color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${distanceKm.toInt()} كم',
            style: TextStyle(
              color: isLight ? const Color(0xFF1C1917) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard(BuildContext context) {
    final isLight = DesignSystem.isLightMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF141926),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B982).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pin_drop_outlined, color: Color(0xFF38B982), size: 18),
              ),
              InkWell(
                onTap: () => _copyCoordinates(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFFD56B).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'نسخ',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'إحداثيات الكعبة',
            style: TextStyle(
              color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '21.42° N, 39.83° E',
            style: TextStyle(
              color: isLight ? const Color(0xFF1C1917) : Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaCard() {
    final isLight = DesignSystem.isLightMode;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFDF8), Color(0xFFFAF5EB)]
              : const [Color(0xFF161F2E), Color(0xFF0F1520)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFFFFD56B).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0xFF8C7355).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFFFD56B).withValues(alpha: 0.25)
                      : const Color(0xFFFFD56B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.brightness_3_rounded,
                  color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'دعاء التوجه إلى القبلة',
                style: TextStyle(
                  color: isLight ? const Color(0xFF854D0E) : const Color(0xFFFFD56B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '« اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالإِكْرَامِ »',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLight ? const Color(0xFF1C1917) : Colors.white,
              fontSize: 13.5,
              fontFamily: 'Amiri',
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'صحيح مسلم',
              style: TextStyle(
                color: isLight ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==================== PHOTOREALISTIC 3D LUXURY QIBLA COMPASS PAINTER ====================
class _Photorealistic3DQiblaPainter extends CustomPainter {
  final double currentHeading;
  final double needleRotation;
  final bool isAligned;

  _Photorealistic3DQiblaPainter({
    required this.currentHeading,
    required this.needleRotation,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // 1. Drop Ambient Ground Shadow for 3D Float
    final groundShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center.translate(0, 8), outerRadius - 10, groundShadowPaint);

    // 2. Heavy 3D Stepped Metallic Gold & Brass Outer Bezel
    // Layer 2A: Deep Brass Base Ring
    final brassBasePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 1.1,
        colors: [
          Color(0xFFE5B54F),
          Color(0xFF996515),
          Color(0xFF4A320A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius - 4, brassBasePaint);

    // Layer 2B: Stepped Inner Bevel Ring (Recessed groove)
    final bevelPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.3, 0.3),
        radius: 1.0,
        colors: [
          Color(0xFF1E1405),
          Color(0xFF4A320A),
          Color(0xFF996515),
          Color(0xFFFFE58F),
        ],
        stops: [0.82, 0.88, 0.94, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius - 12, bevelPaint);

    // 12 Screws/Rivets around the outer gold bezel
    final screwPaint = Paint()..color = const Color(0xFF2B1D06);
    final screwHighlight = Paint()..color = const Color(0xFFFFF2B2);
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (math.pi / 180.0);
      final r = outerRadius - 8;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.2, screwPaint);
      canvas.drawCircle(Offset(x - 0.6, y - 0.6), 1.0, screwHighlight);
    }

    // 3. Rotating Dial Face (Obsidian & Deep Midnight Indigo)
    final dialRadius = outerRadius - 20;

    canvas.save();
    // Rotate canvas by -currentHeading so dial turns relative to true North
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-currentHeading * (math.pi / 180.0));

    // Dial Background: Deep Obsidian with subtle radial lighting
    final dialBgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 1.0,
        colors: [
          Color(0xFF192538),
          Color(0xFF101724),
          Color(0xFF070B12),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: dialRadius));
    canvas.drawCircle(Offset.zero, dialRadius, dialBgPaint);

    // Subtle Islamic 8-Point Geometric Star Watermark in center
    _drawIslamicArabesqueLattice(canvas, dialRadius * 0.65);

    // 360-Degree Engraved Ticks & Degree Markings
    _drawDegreeTicks(canvas, dialRadius);

    // 4 Cardinal Points (N, E, S, W / ش, ق, ج, غ)
    _drawCardinalLetters(canvas, dialRadius);

    canvas.restore(); // Restore back to screen coordinates

    // 4. 3D Faceted Needle with Specular Light & 3D Kaaba
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(needleRotation);

    _draw3DPrismaticNeedle(canvas, dialRadius, isAligned);

    canvas.restore();

    // 5. Center Golden Hub & Axis Medallion
    final hubRadius = 26.0;
    // Hub Shadow
    canvas.drawCircle(center.translate(0, 3), hubRadius, Paint()..color = Colors.black.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Hub 3D Gold Cap
    final hubPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: isAligned
            ? const [Color(0xFF6EE7B7), Color(0xFF10B981), Color(0xFF064E3B)]
            : const [Color(0xFFFFF2B2), Color(0xFFE5B54F), Color(0xFF8B5A10)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    // Center Jewel / Needle Pivot
    final jewelPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: isAligned
            ? const [Color(0xFFFFFFFF), Color(0xFF34D399), Color(0xFF065F46)]
            : const [Color(0xFFFFD56B), Color(0xFFD4AF57), Color(0xFF1E1303)],
      ).createShader(Rect.fromCircle(center: center, radius: 11));
    canvas.drawCircle(center, 11, jewelPaint);

    // Heading text in center hub
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${currentHeading.toInt()}°',
        style: TextStyle(
          color: isAligned ? const Color(0xFF022C22) : const Color(0xFF1A1102),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center.translate(-textPainter.width / 2, -textPainter.height / 2));

    // 6. Crystal Mineral Watch Glass Reflection Crescent (Top Left)
    final glassPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: dialRadius - 2),
        -math.pi * 0.9,
        math.pi * 0.8,
      );
    final glassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x35FFFFFF),
          Color(0x08FFFFFF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: dialRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawPath(glassPath, glassPaint);
  }

  void _drawIslamicArabesqueLattice(Canvas canvas, double radius) {
    final latticePaint = Paint()
      ..color = const Color(0xFFFFD56B).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180.0);
      final r = radius;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      canvas.drawLine(Offset.zero, Offset(x, y), latticePaint);
    }
    canvas.drawCircle(Offset.zero, radius * 0.7, latticePaint);
    canvas.drawCircle(Offset.zero, radius * 0.4, latticePaint);
  }

  void _drawDegreeTicks(Canvas canvas, double radius) {
    final majorTickPaint = Paint()
      ..color = const Color(0xFFFFD56B).withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    final microTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.6;

    for (int i = 0; i < 360; i += 2) {
      final angle = i * (math.pi / 180.0);
      final isMajor = i % 30 == 0;
      final isMedium = i % 10 == 0;

      final tickLength = isMajor ? 10.0 : (isMedium ? 6.0 : 3.5);
      final startR = radius - 4;
      final endR = startR - tickLength;

      final x1 = startR * math.sin(angle);
      final y1 = -startR * math.cos(angle);
      final x2 = endR * math.sin(angle);
      final y2 = -endR * math.cos(angle);

      if (isMajor) {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), majorTickPaint);
      } else if (isMedium) {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), minorTickPaint);
      } else {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), microTickPaint);
      }
    }
  }

  void _drawCardinalLetters(Canvas canvas, double radius) {
    final textRadius = radius - 24;

    // North (N / ش - شمال)
    _drawText(
      canvas,
      'ش',
      Offset(0, -textRadius),
      const Color(0xFFEF4444),
      fontSize: 14,
      isBold: true,
    );
    // East (E / ق - شرق)
    _drawText(
      canvas,
      'ق',
      Offset(textRadius, 0),
      const Color(0xFFFFD56B),
      fontSize: 13,
      isBold: true,
    );
    // South (S / ج - جنوب)
    _drawText(
      canvas,
      'ج',
      Offset(0, textRadius),
      const Color(0xFFA5B4C7),
      fontSize: 13,
      isBold: true,
    );
    // West (W / غ - غرب)
    _drawText(
      canvas,
      'غ',
      Offset(-textRadius, 0),
      const Color(0xFFFFD56B),
      fontSize: 13,
      isBold: true,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, {double fontSize = 12, bool isBold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          fontFamily: 'Cairo',
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position.translate(-tp.width / 2, -tp.height / 2));
  }

  void _draw3DPrismaticNeedle(Canvas canvas, double radius, bool isAligned) {
    final needleLength = radius - 32;
    final halfWidth = 7.0;
    final tailLength = radius * 0.42;

    // 1. Needle Drop Shadow
    final shadowPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(halfWidth, 0)
      ..lineTo(0, tailLength)
      ..lineTo(-halfWidth, 0)
      ..close();
    canvas.drawPath(
      shadowPath.shift(const Offset(2, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Top-Left Needle Facet (High Lighted Surface)
    final leftFacetPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(0, 0)
      ..lineTo(-halfWidth, 0)
      ..close();
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isAligned
            ? [const Color(0xFFFFFFFF), const Color(0xFF34D399), const Color(0xFF10B981)]
            : [const Color(0xFFFFF9E0), const Color(0xFFFFD56B), const Color(0xFFE5B54F)],
      ).createShader(Rect.fromLTWH(-halfWidth, -needleLength, halfWidth, needleLength));
    canvas.drawPath(leftFacetPath, leftPaint);

    // 3. Top-Right Needle Facet (Deep Shadow Surface)
    final rightFacetPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(halfWidth, 0)
      ..lineTo(0, 0)
      ..close();
    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isAligned
            ? [const Color(0xFF10B981), const Color(0xFF065F46), const Color(0xFF022C22)]
            : [const Color(0xFFC89B3C), const Color(0xFF8B5A10), const Color(0xFF4A320A)],
      ).createShader(Rect.fromLTWH(0, -needleLength, halfWidth, needleLength));
    canvas.drawPath(rightFacetPath, rightPaint);

    // 4. Tail Needle Facets (Obsidian & Silver Chrome)
    final tailLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(-halfWidth * 0.75, 0)
      ..lineTo(0, tailLength)
      ..close();
    canvas.drawPath(tailLeft, Paint()..color = const Color(0xFF64748B));

    final tailRight = Path()
      ..moveTo(0, 0)
      ..lineTo(halfWidth * 0.75, 0)
      ..lineTo(0, tailLength)
      ..close();
    canvas.drawPath(tailRight, Paint()..color = const Color(0xFF1E293B));

    // 5. 3D Holy Kaaba Cube at Needle Tip
    _draw3DKaabaTip(canvas, Offset(0, -needleLength - 6), isAligned);
  }

  void _draw3DKaabaTip(Canvas canvas, Offset position, bool isAligned) {
    final kaabaSize = 22.0;

    canvas.save();
    canvas.translate(position.dx, position.dy);

    // Kaaba Aura Glow
    final glowPaint = Paint()
      ..color = (isAligned ? const Color(0xFF34D399) : const Color(0xFFFFD56B)).withValues(alpha: isAligned ? 0.85 : 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, kaabaSize * 0.8, glowPaint);

    // Kaaba 3D Isometric Cube
    // Top Roof Face
    final roofPath = Path()
      ..moveTo(0, -kaabaSize * 0.5)
      ..lineTo(kaabaSize * 0.5, -kaabaSize * 0.25)
      ..lineTo(0, 0)
      ..lineTo(-kaabaSize * 0.5, -kaabaSize * 0.25)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF1E1E1E));

    // Left Front Face (Deep Velvet Black)
    final leftFace = Path()
      ..moveTo(-kaabaSize * 0.5, -kaabaSize * 0.25)
      ..lineTo(0, 0)
      ..lineTo(0, kaabaSize * 0.6)
      ..lineTo(-kaabaSize * 0.5, kaabaSize * 0.35)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFF0A0A0A));

    // Right Front Face (Slightly lighter black)
    final rightFace = Path()
      ..moveTo(0, 0)
      ..lineTo(kaabaSize * 0.5, -kaabaSize * 0.25)
      ..lineTo(kaabaSize * 0.5, kaabaSize * 0.35)
      ..lineTo(0, kaabaSize * 0.6)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFF141414));

    // Golden Embroidered Kiswah Belt (حزام الكعبة الذهبي)
    final beltPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-10, 2), const Offset(0, 7), beltPaint);
    canvas.drawLine(const Offset(0, 7), const Offset(10, 2), beltPaint);

    // Golden Kaaba Door (باب الكعبة المشرفة)
    final doorRect = Rect.fromLTWH(2, 6, 4.5, 6.5);
    canvas.drawRect(doorRect, Paint()..color = const Color(0xFFFFE58F));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Photorealistic3DQiblaPainter oldDelegate) {
    return oldDelegate.currentHeading != currentHeading ||
        oldDelegate.needleRotation != needleRotation ||
        oldDelegate.isAligned != isAligned;
  }
}

