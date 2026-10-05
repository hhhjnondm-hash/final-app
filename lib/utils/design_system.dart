import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Design System for Islamyat (Rafeeq) App
/// Luxury Islamic Digital Product Design System - Dynamic Time-Based & Presets
class DesignSystem {
  // Theme Mode State - bound to ThemeService
  static bool get isLightMode => ThemeService.instance.isLightMode;
  static set isLightMode(bool value) {
    ThemeService.instance.setLightMode(value);
  }

  // ==================== DYNAMIC ADAPTIVE THEME ACCESSORS ====================
  static AppThemePalette get currentPalette => ThemeService.instance.effectivePalette;

  static Color get currentBgMain => currentPalette.bgMain;
  static Color get currentBgSecondary => currentPalette.bgSecondary;
  static Color get currentCardBg => currentPalette.cardBg;
  static Color get currentCardElevated => currentPalette.cardElevated;
  static Color get currentTextPrimary => currentPalette.textPrimary;
  static Color get currentTextSecondary => currentPalette.textSecondary;
  static Color get currentBorder => currentPalette.border;
  static Color get currentGold => currentPalette.goldAccent;
  static Color get currentAccentGlow => currentPalette.accentGlow;
  static LinearGradient get currentHeroGradient => currentPalette.heroGradient;
  static LinearGradient get currentCardGradient => currentPalette.cardGradient;

  // ==================== 1. LUXURY DARK MODE PALETTE CONSTANTS ====================
  static const Color darkBgMain = Color(0xFF08090B);       // Pure Deep Void Black
  static const Color darkBgSecondary = Color(0xFF0E1117);  // Deep Charcoal Slate
  static const Color darkCardBg = Color(0xFF131722);       // Obsidian Card Background
  static const Color darkCardElevated = Color(0xFF1A2130); // Elevated Card
  static const Color darkBorder = Color(0xFF263248);       // Subtle Midnight Blue Border
  static const Color darkGoldBorder = Color(0xFFD4AF57);   // Royal Gold Border
  static const Color darkTextPrimary = Color(0xFFF6F8FA);  // Pure Crisp White
  static const Color darkTextSecondary = Color(0xFF94A3B8);// Silver Slate Subtitles
  static const Color darkTextGold = Color(0xFFE8D29A);     // Luminous Radiant Gold

  // ==================== 2. LIGHT MODE COLOR PALETTE CONSTANTS ====================
  static const Color lightBgMain = Color(0xFFDCEAF4);      // Soft Sky Blue (Day default)
  static const Color lightBgSecondary = Color(0xFFEEF6FA); // Pale Sky Blue
  static const Color lightCardBg = Color(0xFFFFFFFF);      // Pure White Card
  static const Color lightPrimaryNavy = Color(0xFF102A43);  // Deep Navy for branding & active pills
  static const Color lightSecondaryNavy = Color(0xFF183B5B);// Secondary Navy
  static const Color lightTeal = Color(0xFF0F6B78);         // Teal Accent (Hisn Al-Muslim)
  static const Color lightTealBg = Color(0xFFE8F3F3);       // Light Teal BG
  static const Color lightSoftSkyBlue = Color(0xFFDCEAF4);  // Soft Sky Blue (Qibla / Hero)
  static const Color lightPrimaryGold = Color(0xFFC9A24D);  // Primary Metallic Gold (Quran / Accents)
  static const Color lightSoftGold = Color(0xFFE8D29A);     // Soft Gold Glow & Borders
  static const Color lightPrimaryText = Color(0xFF102A43);  // Primary Dark Text (Titles)
  static const Color lightSecondaryText = Color(0xFF2B6F9B);// Secondary Muted Blue Text
  static const Color lightBorder = Color(0xFFBDD8EA);       // Card & Container Subtle Border
  static const Color lightPurple = Color(0xFF6956B8);       // Purple Accent (Quran Radio)
  static const Color lightSoftPurple = Color(0xFFF0ECFA);   // Soft Purple BG
  static const Color lightWarmBeige = Color(0xFFF3E8D0);    // Light Warm Sand

  // ==================== BACKGROUND CONSTANTS (FOR BACKWARD COMPATIBILITY) ====================
  static const Color bgDarkest = Color(0xFF08090B);
  static const Color bgDark = Color(0xFF0E1117);
  static const Color bgElevated = Color(0xFF1A2130);
  static const Color bgSurface = Color(0xFF131722);
  static const Color bgCard = Color(0xFF131722);
  static const Color bgCardHover = Color(0xFF1C2433);

  static const Color darkBgDarkest = Color(0xFF08090B);
  static const Color darkBgDark = Color(0xFF0E1117);
  static const Color darkBgElevated = Color(0xFF1A2130);
  static const Color darkBgSurface = Color(0xFF131722);
  static const Color darkBgCard = Color(0xFF131722);
  static const Color darkBgCardHover = Color(0xFF1C2433);

  // ==================== SACRED ROYAL GOLD PALETTE ====================
  static const Color gold = Color(0xFFD4AF57);
  static const Color goldLight = Color(0xFFE8D29A);
  static const Color goldDark = Color(0xFF996515);
  static const Color goldAmber = Color(0xFFE6B84A);
  static const Color goldMuted = Color(0x33D4AF57);
  static const Color goldRadiant = Color(0xFFFFD56B);

  // ==================== CELESTIAL BLUE & CYAN ====================
  static const Color electricBlue = Color(0xFF102A43);
  static const Color royalBlue = Color(0xFF183B5B);
  static const Color blueLight = Color(0xFFDCEAF4);
  static const Color cyanAccent = Color(0xFF0F6B78);
  static const Color cyanGlow = Color(0xFF22D3EE);

  // ==================== COSMIC PURPLE & VIOLET ====================
  static const Color violet = Color(0xFF6956B8);
  static const Color purple = Color(0xFF6956B8);
  static const Color purpleLight = Color(0xFFF0ECFA);

  // ==================== TEXT HIERARCHY ====================
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF6F8FA);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF475569);

  // ==================== STATUS COLORS ====================
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0F6B78);

  // ==================== LUXURY GRADIENTS ====================
  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF141A26),
      Color(0xFF0C1018),
      Color(0xFF08090B),
    ],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF151C2B),
      Color(0xFF0E131E),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightPrimaryNavy, lightTeal],
  );

  static const LinearGradient lightHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDCEAF4),
      Color(0xFFEEF6FA),
    ],
  );

  // ==================== SHADOW SYSTEM ====================
  static List<BoxShadow> get softCardShadow => currentPalette.cardShadow;

  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: gold.withValues(alpha: 0.35),
          blurRadius: 22,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  // ==================== SPACING ====================
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacing2XL = 48;
  static const double spacing3XL = 64;

  // ==================== BORDER RADIUS ====================
  static const double radiusXS = 6;
  static const double radiusSmall = 10;
  static const double radiusMedium = 16;
  static const double radiusLarge = 22;
  static const double radiusXLarge = 28;
  static const double radiusPill = 999;

  // ==================== THEME DATA ====================
  static ThemeData get darkTheme {
    final palette = currentPalette.isDark ? currentPalette : AppThemePalette.darkNight;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.bgMain,
      primaryColor: palette.goldAccent,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.dark(
        primary: palette.goldAccent,
        secondary: goldLight,
        surface: palette.cardBg,
        error: error,
      ),
    );
  }

  static ThemeData get lightTheme {
    final palette = !currentPalette.isDark ? currentPalette : AppThemePalette.lightSkyBlue;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: palette.bgMain,
      primaryColor: palette.primaryNavy,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.light(
        primary: palette.primaryNavy,
        secondary: palette.goldAccent,
        surface: palette.cardBg,
        error: error,
      ),
    );
  }

  // ==================== DECORATIONS ====================
  static BoxDecoration radialGlowBackground([BuildContext? context]) {
    final p = currentPalette;
    if (p.isDark) {
      return BoxDecoration(
        color: p.bgMain,
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.6),
          radius: 1.2,
          colors: [
            p.cardElevated,
            p.bgSecondary,
            p.bgMain,
          ],
        ),
      );
    } else {
      return BoxDecoration(
        color: p.bgMain,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgMain, p.bgSecondary],
        ),
      );
    }
  }

  static BoxDecoration glassCard([BuildContext? context]) {
    final p = currentPalette;
    return BoxDecoration(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: p.border.withValues(alpha: p.isDark ? 0.6 : 0.8),
        width: 1,
      ),
      boxShadow: p.cardShadow,
    );
  }
}
