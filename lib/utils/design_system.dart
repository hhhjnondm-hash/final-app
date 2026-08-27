import 'package:flutter/material.dart';

/// Design System for Islamyat App
/// Luxury Islamic Digital Product Design System
class DesignSystem {
  // ==================== OBSIDIAN & MIDNIGHT PALETTE ====================
  static const Color bgDarkest = Color(0xFF03050A);
  static const Color bgDark = Color(0xFF050914);
  static const Color bgElevated = Color(0xFF07111F);
  static const Color bgSurface = Color(0xFF0A1424);
  static const Color bgCard = Color(0xFF0D1B2A);
  static const Color bgCardHover = Color(0xFF132338);

  // ==================== SACRED GOLD PALETTE ====================
  static const Color gold = Color(0xFFD4A83F);
  static const Color goldLight = Color(0xFFF5D06F);
  static const Color goldDark = Color(0xFFB8862D);
  static const Color goldAmber = Color(0xFFE6B84A);
  static const Color goldMuted = Color(0x33D4A83F);

  // ==================== CELESTIAL BLUE & CYAN ====================
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color royalBlue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0xFF22D3EE);

  // ==================== COSMIC PURPLE & VIOLET ====================
  static const Color violet = Color(0xFF7C3AED);
  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleLight = Color(0xFF8B5CF6);

  // ==================== TEXT HIERARCHY ====================
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);

  // ==================== STATUS COLORS ====================
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);

  // ==================== LUXURY GRADIENTS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, violet],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient goldShimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDE68A),
      Color(0xFFD4A83F),
      Color(0xFF996515),
      Color(0xFFD4A83F),
    ],
  );

  static const LinearGradient celestialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanAccent, royalBlue, violet],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xEE0D1B2A),
      Color(0xDD07111F),
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x332563EB),
      Color(0x227C3AED),
      Color(0x1107111F),
    ],
  );

  // ==================== GLOW EFFECTS ====================
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: gold.withOpacity(0.35),
      blurRadius: 25,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> blueGlow = [
    BoxShadow(
      color: electricBlue.withOpacity(0.35),
      blurRadius: 25,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> purpleGlow = [
    BoxShadow(
      color: violet.withOpacity(0.35),
      blurRadius: 25,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cyanGlowShadow = [
    BoxShadow(
      color: cyanAccent.withOpacity(0.35),
      blurRadius: 25,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: electricBlue.withOpacity(0.04),
      blurRadius: 30,
      spreadRadius: 1,
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
  static const double radiusXLarge = 30;
  static const double radiusPill = 999;

  // ==================== GLASSMORPHISM HELPERS ====================
  static BoxDecoration glassCard({
    double borderRadius = radiusMedium,
    double opacity = 0.05,
    double borderOpacity = 0.12,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glassButton({
    double borderRadius = radiusSmall,
    double opacity = 0.08,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1,
      ),
    );
  }

  static BoxDecoration glassBox({
    double borderRadius = radiusMedium,
    Color? fillColor,
    Color? borderColor,
    double borderWidth = 1.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: fillColor ?? Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.08),
        width: borderWidth,
      ),
      boxShadow: shadows ?? softCardShadow,
    );
  }

  static BoxDecoration goldGlassBox({
    double borderRadius = radiusMedium,
    double fillOpacity = 0.06,
    double borderOpacity = 0.35,
  }) {
    return BoxDecoration(
      color: gold.withOpacity(fillOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: gold.withOpacity(borderOpacity),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: gold.withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration primaryGlassBox({
    double borderRadius = radiusMedium,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          electricBlue.withOpacity(0.15),
          violet.withOpacity(0.08),
          bgCard.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: electricBlue.withOpacity(0.3),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: electricBlue.withOpacity(0.15),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 15,
        ),
      ],
    );
  }

  // ==================== BACKGROUND DECORATION ====================
  static BoxDecoration radialGlowBackground() {
    return const BoxDecoration(
      color: bgDarkest,
      gradient: RadialGradient(
        center: Alignment(-0.6, -0.7),
        radius: 1.4,
        colors: [
          Color(0xFF0F203D), // Deep ambient blue orb
          Color(0xFF07111F),
          Color(0xFF03050A),
        ],
      ),
    );
  }

  static BoxDecoration premiumBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bgElevated,
          bgDark,
          bgDarkest,
        ],
      ),
    );
  }

  // ==================== TYPOGRAPHY ====================
  static const TextStyle displayLarge = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    color: textWhite,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textWhite,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.6,
    color: textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: textMuted,
  );

  static const TextStyle quranLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 2.3,
    letterSpacing: 0.5,
    color: textWhite,
  );

  // ==================== THEME CONFIGURATION ====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDarkest,
      colorScheme: const ColorScheme.dark(
        primary: electricBlue,
        secondary: violet,
        tertiary: gold,
        surface: bgElevated,
        surfaceContainerHighest: bgCard,
        error: error,
        onPrimary: textWhite,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
    );
  }
}