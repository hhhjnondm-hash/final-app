import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/app_initializer.dart';
import '../utils/design_system.dart';
import 'home_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ambientController;
  late AnimationController _revealController;
  late AnimationController _glowController;
  late AnimationController _progressController;

  late Animation<double> _bgFadeAnimation;
  late Animation<double> _bgScaleAnimation;
  late Animation<double> _glowPulseAnimation;
  late Animation<double> _starsShimmerAnimation;

  double _initProgress = 0.0;
  String _statusText = 'جاري التحميل ...';
  bool _isNavigating = false;

  final List<Offset> _starOffsets = List.generate(
    28,
    (index) => Offset(
      math.Random(index * 7).nextDouble(),
      math.Random(index * 13).nextDouble() * 0.55,
    ),
  );

  final List<double> _starSizes = List.generate(
    28,
    (index) => 1.0 + math.Random(index * 5).nextDouble() * 2.2,
  );

  @override
  void initState() {
    super.initState();

    // 1. Ambient Particle & Star Animation Loop
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _starsShimmerAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );

    // 2. Cinematic Logo & Artwork Reveal (Dark -> Fade & Slow Scale)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bgFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );

    _bgScaleAnimation = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );

    // 3. Lantern & Crescent Glow Pulse Loop
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowPulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    // 4. Progress Loading Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Start reveal animation
    _revealController.forward();

    // Trigger parallel system initialization
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final startTime = DateTime.now();

    await AppInitializer().initialize(
      onProgress: (prog, status) {
        if (mounted) {
          setState(() {
            _initProgress = prog;
            _statusText = status;
          });
        }
      },
    );

    // Ensure minimum cinematic exposure of 2.2 seconds for spiritual luxury feel (skip if in test)
    final isTest = WidgetsBinding.instance is! WidgetsFlutterBinding;
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = isTest ? 0 : math.max(0, 2200 - elapsed);
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted && !_isNavigating) {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    setState(() {
      _isNavigating = true;
    });

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          final scale = Tween<double>(begin: 0.97, end: 1.0).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ambientController.stop();
    _ambientController.dispose();
    _revealController.stop();
    _revealController.dispose();
    _glowController.stop();
    _glowController.dispose();
    _progressController.stop();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF020713),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient Background Layer with Deep Islamic Midnight Gradients
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.35),
                  radius: 1.2,
                  colors: [
                    Color(0xFF0B1936),
                    Color(0xFF040A18),
                    Color(0xFF01040D),
                  ],
                ),
              ),
            ),

            // 2. Official Splash Hero Artwork with Smooth Cinematic Fade & Slow Scale
            AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) {
                return Opacity(
                  opacity: _bgFadeAnimation.value,
                  child: Transform.scale(
                    scale: _bgScaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Image.asset(
                    'assets/out logo app/startapp.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),

            // 3. Floating Sparkling Stars Layer
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return Stack(
                  children: _starOffsets.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final offset = entry.value;
                    final starSize = _starSizes[idx];
                    final phase = (math.sin(_ambientController.value * math.pi * 2 + idx) + 1) / 2;

                    return Positioned(
                      left: offset.dx * size.width,
                      top: offset.dy * size.height,
                      child: Opacity(
                        opacity: (0.2 + 0.8 * phase).clamp(0.0, 1.0),
                        child: Container(
                          width: starSize,
                          height: starSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: idx % 3 == 0 ? const Color(0xFFF3C95B) : const Color(0xFFFFFFFF),
                            boxShadow: [
                              BoxShadow(
                                color: (idx % 3 == 0 ? DesignSystem.gold : const Color(0xFF60A5FA))
                                    .withValues(alpha: 0.6 * phase),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // 4. Subtle Lanterns & Crescent Ambient Glow Layer
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Positioned(
                  top: size.height * 0.18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 220 * _glowPulseAnimation.value,
                      height: 220 * _glowPulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            DesignSystem.gold.withValues(alpha: 0.15),
                            const Color(0xFF315BEA).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 5. Bottom Loading Indicator & Status Label
            Positioned(
              left: 24,
              right: 24,
              bottom: size.height * 0.065,
              child: AnimatedBuilder(
                animation: _revealController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _bgFadeAnimation.value,
                    child: child,
                  );
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Luxury Islamic Golden Linear Progress Indicator
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            border: Border.all(
                              color: DesignSystem.gold.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                            child: LinearProgressIndicator(
                              value: _initProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(DesignSystem.gold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle status text with subtle fade
                        Text(
                          _statusText,
                          style: TextStyle(
                            color: DesignSystem.goldLight.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
