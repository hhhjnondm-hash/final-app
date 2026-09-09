import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'utils/design_system.dart';
import 'widgets/islamic_background.dart';
import 'widgets/premium_bottom_nav.dart';
import 'widgets/unified_mini_player.dart';
import 'widgets/spiritual_welcome_dialog.dart';
import 'screens/home_screen.dart';
import 'screens/iqra_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/radio_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/hadith_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_initializer.dart';
import 'l10n/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await AppInitializer.initializeServices();
  
  // Initialize localization
  await AppLocalization.initialize();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    EasyLocalization(
      supportedLocales: AppLocalization.supportedLocales,
      fallbackLocale: AppLocalization.fallbackLocale,
      path: 'assets/l10n',
      startLocale: const Locale('ar', 'SA'),
      child: const IslamyatApp(),
    ),
  );
}

class IslamyatApp extends StatelessWidget {
  const IslamyatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rafeeq',
      debugShowCheckedModeBanner: false,
      theme: DesignSystem.darkTheme,
      darkTheme: DesignSystem.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: EasyLocalization.of(context)!.delegates,
      supportedLocales: EasyLocalization.of(context)!.supportedLocales,
      locale: EasyLocalization.of(context)!.locale,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Default to HomeScreen

  @override
  void initState() {
    super.initState();
    // Trigger Spiritual Welcome Dialog right after first frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          SpiritualWelcomeDialog.show(context);
        }
      });
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),          // 0. الرئيسية
    const IqraScreen(),          // 1. اقرأ
    const AudioScreen(),         // 2. المصاحف الصوتية
    const RadioScreen(),         // 3. الراديو
    const PrayerTimesScreen(),   // 4. مواقيت الصلاة
    const QuranScreen(),         // 5. القرآن الكريم
    const AzkarScreen(),         // 6. الأذكار
    const HadithScreen(),        // 7. الأحاديث النبوية
    const ProfileScreen(),       // 8. حسابي
  ];

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: IslamicBackground(
        child: Stack(
          children: [
            // Active Screen Content
            Positioned.fill(
              bottom: 75, // Leave room for floating nav
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),

            // Floating Frosted Glass Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UnifiedMiniPlayer(),
                    PremiumBottomNav(
                      currentIndex: _currentIndex,
                      onTap: _onTabChange,
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
}
