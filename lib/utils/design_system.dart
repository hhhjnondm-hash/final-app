import 'package:flutter/material.dart';

/// Design System for Islamyat (Rafeeq) App
/// Luxury Islamic Digital Product Design System - Dark & Light Mode
class DesignSystem {
  // Theme Mode State - true: Light Mode (نهاري), false: Dark Mode (ليلي ملكي أسود وذهبي)
  static bool isLightMode = false; // Default to Luxury Dark Mode (أسود وذهبي) or togglable

  // ==================== 1. LUXURY DARK MODE PALETTE (DEEP BLACK & ROYAL GOLD) ====================
  static const Color darkBgMain = Color(0xFF07090E);       // Pure Deep Void Black
  static const Color darkBgSecondary = Color(0xFF0C1017);  // Deep Charcoal Slate
  static const Color darkCardBg = Color(0xFF111722);       // Obsidian Card Background
  static const Color darkCardElevated = Color(0xFF161F2E); // Elevated Card
  static const Color darkBorder = Color(0xFF2A364F);       // Subtle Midnight Blue Border
  static const Color darkGoldBorder = Color(0xFFC89B3C);   // Royal Gold Border
  static const Color darkTextPrimary = Color(0xFFF6F8FA);  // Pure Crisp White
  static const Color darkTextSecondary = Color(0xFF94A3B8);// Silver Slate Subtitles
  static const Color darkTextGold = Color(0xFFE8D29A);     // Luminous Radiant Gold

  // ==================== 2. LIGHT MODE COLOR PALETTE (DAYTIME IVORY & NAVY) ====================
  static const Color lightBgMain = Color(0xFFF8F6F0);      // Soft Warm Ivory
  static const Color lightBgSecondary = Color(0xFFF2F5F7); // Very Pale Blue-Gray
  static const Color lightCardBg = Color(0xFFFFFFFF);      // Pure White Card
  static const Color lightPrimaryNavy = Color(0xFF102A43);  // Deep Navy for branding & active pills
  static const Color lightSecondaryNavy = Color(0xFF183B5B);// Secondary Navy
  static const Color lightTeal = Color(0xFF0F6B78);         // Teal Accent (Hisn Al-Muslim)
  static const Color lightTealBg = Color(0xFFE8F3F3);       // Light Teal BG
  static const Color lightSoftSkyBlue = Color(0xFFDCEAF4);  // Soft Sky Blue (Qibla / Hero)
  static const Color lightPrimaryGold = Color(0xFFC89B3C);  // Primary Metallic Gold (Quran / Accents)
  static const Color lightSoftGold = Color(0xFFE8D29A);     // Soft Gold Glow & Borders
  static const Color lightPrimaryText = Color(0xFF172033);  // Primary Dark Text (Titles)
  static const Color lightSecondaryText = Color(0xFF667085);// Secondary Muted Gray-Navy Text
  static const Color lightBorder = Color(0xFFDCE3EC);       // Card & Container Subtle Border
  static const Color lightPurple = Color(0xFF6956B8);       // Purple Accent (Quran Radio)
  static const Color lightSoftPurple = Color(0xFFF0ECFA);   // Soft Purple BG
  static const Color lightWarmBeige = Color(0xFFF3EDE1);    // Very Light Warm Beige

  // ==================== DYNAMIC ADAPTIVE ACCESSORS ====================
  static Color get currentBgMain => isLightMode ? lightBgMain : darkBgMain;
  static Color get currentBgSecondary => isLightMode ? lightBgSecondary : darkBgSecondary;
  static Color get currentCardBg => isLightMode ? lightCardBg : darkCardBg;
  static Color get currentTextPrimary => isLightMode ? lightPrimaryText : darkTextPrimary;
  static Color get currentTextSecondary => isLightMode ? lightSecondaryText : darkTextSecondary;
  static Color get currentBorder => isLightMode ? lightBorder : darkBorder;

  // ==================== BACKGROUND CONSTANTS (FOR BACKWARD COMPATIBILITY) ====================
  static const Color bgDarkest = Color(0xFF07090E);
  static const Color bgDark = Color(0xFF0C1017);
  static const Color bgElevated = Color(0xFF161F2E);
  static const Color bgSurface = Color(0xFF111722);
  static const Color bgCard = Color(0xFF111722);
  static const Color bgCardHover = Color(0xFF1A2436);

  static const Color darkBgDarkest = Color(0xFF07090E);
  static const Color darkBgDark = Color(0xFF0C1017);
  static const Color darkBgElevated = Color(0xFF161F2E);
  static const Color darkBgSurface = Color(0xFF111722);
  static const Color darkBgCard = Color(0xFF111722);
  static const Color darkBgCardHover = Color(0xFF1A2436);

  // ==================== SACRED ROYAL GOLD PALETTE ====================
  static const Color gold = Color(0xFFC89B3C);
  static const Color goldLight = Color(0xFFE8D29A);
  static const Color goldDark = Color(0xFF996515);
  static const Color goldAmber = Color(0xFFE6B84A);
  static const Color goldMuted = Color(0x33C89B3C);
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
      Color(0xFF141E30), // Obsidian Navy
      Color(0xFF0A0F18), // Deep Night Black
      Color(0xFF05070B),
    ],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF131B2A),
      Color(0xFF0D1420),
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
      Color(0xFFDCEAF4), // Soft sky blue
      Color(0xFFF3F8FB), // Very pale ice
    ],
  );

  // ==================== SHADOW SYSTEM ====================
  static List<BoxShadow> get softCardShadow => isLightMode
      ? [
          BoxShadow(
            color: const Color(0xFF102A43).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: gold.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ];

  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: gold.withOpacity(0.35),
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
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBgMain,
        primaryColor: gold,
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: goldLight,
          surface: darkCardBg,
          error: error,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBgMain,
        primaryColor: lightPrimaryNavy,
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.light(
          primary: lightPrimaryNavy,
          secondary: gold,
          surface: lightCardBg,
          error: error,
        ),
      );
}

