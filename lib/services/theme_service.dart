import 'dart:async';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// App Theme Preset IDs
class ThemePresetIds {
  static const String autoDark = 'auto_dark';       // ديناميكي داكن حسب الوقت
  static const String autoLight = 'auto_light';     // ديناميكي فاتح حسب الوقت
  static const String darkBlack = 'dark_black';     // 🖤 الأسود الليلي (#08090B)
  static const String darkSapphire = 'dark_sapphire'; // 🔵 سفير الصباح (#102A43)
  static const String darkEmerald = 'dark_emerald'; // 🟢 زمرد المساء (#0B3D35)
  static const String lightSkyBlue = 'light_sky_blue'; // ☀️ سماوي الصباح (#DCEAF4)
  static const String lightWarmSand = 'light_warm_sand'; // 🌤️ رمل العصر الدافئ (#F3E8D0)
  static const String lightSoftRose = 'light_soft_rose'; // 🌅 ورد المساء الترابي (#F0DFE1)

  // Legacy mappings
  static const String legacyDark = 'dark';
  static const String legacyLight = 'light';
}

/// Unified Theme Palette Definition
class AppThemePalette {
  final String id;
  final String nameArabic;
  final String timeLabelArabic;
  final String descriptionArabic;
  final bool isDark;
  final Color bgMain;
  final Color bgSecondary;
  final Color cardBg;
  final Color cardElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color goldAccent;
  final Color accentGlow;
  final Color primaryNavy;
  final LinearGradient heroGradient;
  final LinearGradient cardGradient;
  final List<BoxShadow> cardShadow;

  const AppThemePalette({
    required this.id,
    required this.nameArabic,
    required this.timeLabelArabic,
    required this.descriptionArabic,
    required this.isDark,
    required this.bgMain,
    required this.bgSecondary,
    required this.cardBg,
    required this.cardElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.goldAccent,
    required this.accentGlow,
    required this.primaryNavy,
    required this.heroGradient,
    required this.cardGradient,
    required this.cardShadow,
  });

  // ==================== 1. DARK PALETTES ====================

  /// 🖤 1. الأسود — Night (#08090B)
  static const AppThemePalette darkNight = AppThemePalette(
    id: ThemePresetIds.darkBlack,
    nameArabic: 'الأسود الليلي الملكي',
    timeLabelArabic: '🌙 ليل (18:00 - 05:00)',
    descriptionArabic: 'فخامة الأسود المطلق مع بريق الذهب الملكي',
    isDark: true,
    bgMain: Color(0xFF08090B),
    bgSecondary: Color(0xFF0E1117),
    cardBg: Color(0xFF131722),
    cardElevated: Color(0xFF1A2130),
    border: Color(0xFF263248),
    textPrimary: Color(0xFFF6F8FA),
    textSecondary: Color(0xFF94A3B8),
    goldAccent: Color(0xFFD4AF57),
    accentGlow: Color(0xFFFFD56B),
    primaryNavy: Color(0xFF0F172A),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF141A26), Color(0xFF0C1018), Color(0xFF08090B)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF151C2B), Color(0xFF0E131E)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x99000000),
        blurRadius: 24,
        offset: Offset(0, 6),
      ),
      BoxShadow(
        color: Color(0x1AD4AF57),
        blurRadius: 16,
        offset: Offset(0, 2),
      ),
    ],
  );

  /// 🔵 2. Deep Sapphire — Morning (#102A43)
  static const AppThemePalette darkSapphire = AppThemePalette(
    id: ThemePresetIds.darkSapphire,
    nameArabic: 'سفير الصباح العميق',
    timeLabelArabic: '☀️ صباح (05:00 - 12:00)',
    descriptionArabic: 'أزرق ياقوتي عميق وهادئ يبعث على السكينة مع الذهب',
    isDark: true,
    bgMain: Color(0xFF102A43),
    bgSecondary: Color(0xFF0C2034),
    cardBg: Color(0xFF163756),
    cardElevated: Color(0xFF1E466D),
    border: Color(0xFF2D5C8A),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFA5C2DE),
    goldAccent: Color(0xFFD4AF57),
    accentGlow: Color(0xFF38BDF8),
    primaryNavy: Color(0xFF102A43),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1C436A), Color(0xFF102A43), Color(0xFF091A2B)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B4167), Color(0xFF122F4B)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 22,
        offset: Offset(0, 6),
      ),
      BoxShadow(
        color: Color(0x2638BDF8),
        blurRadius: 14,
        offset: Offset(0, 2),
      ),
    ],
  );

  /// 🟢 3. Deep Emerald — Evening (#0B3D35)
  static const AppThemePalette darkEmerald = AppThemePalette(
    id: ThemePresetIds.darkEmerald,
    nameArabic: 'زمرد المساء الفاخر',
    timeLabelArabic: '🌤️ عصر ومساء (12:00 - 18:00)',
    descriptionArabic: 'أخضر زمردي إسلامي غامق يعكس روحانية المساء',
    isDark: true,
    bgMain: Color(0xFF0B3D35),
    bgSecondary: Color(0xFF072C26),
    cardBg: Color(0xFF114E44),
    cardElevated: Color(0xFF186256),
    border: Color(0xFF267D6F),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFA2D4CB),
    goldAccent: Color(0xFFD4AF57),
    accentGlow: Color(0xFF10B981),
    primaryNavy: Color(0xFF0B3D35),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF165C50), Color(0xFF0B3D35), Color(0xFF062520)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF15594E), Color(0xFF0E433A)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 22,
        offset: Offset(0, 6),
      ),
      BoxShadow(
        color: Color(0x2610B981),
        blurRadius: 14,
        offset: Offset(0, 2),
      ),
    ],
  );

  // ==================== 2. LIGHT PALETTES ====================

  /// ☀️ 1. الصبح — Sky Blue (#DCEAF4)
  static const AppThemePalette lightSkyBlue = AppThemePalette(
    id: ThemePresetIds.lightSkyBlue,
    nameArabic: 'سماوي الصباح الهادئ',
    timeLabelArabic: '☀️ صباح (05:00 - 12:00)',
    descriptionArabic: 'نقاء السماء الصافية وهدوء الصباح المشرق',
    isDark: false,
    bgMain: Color(0xFFDCEAF4),
    bgSecondary: Color(0xFFEEF6FA),
    cardBg: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF5FAFD),
    border: Color(0xFFBDD8EA),
    textPrimary: Color(0xFF102A43),
    textSecondary: Color(0xFF2B6F9B),
    goldAccent: Color(0xFFC9A24D),
    accentGlow: Color(0xFF2B6F9B),
    primaryNavy: Color(0xFF102A43),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4E6F1), Color(0xFFEEF6FA), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF2F8FC)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x14102A43),
        blurRadius: 18,
        offset: Offset(0, 4),
      ),
    ],
  );

  /// 🌤️ 2. العصر — Warm Sand (#F3E8D0)
  static const AppThemePalette lightWarmSand = AppThemePalette(
    id: ThemePresetIds.lightWarmSand,
    nameArabic: 'رمل العصر الدافئ',
    timeLabelArabic: '🌤️ عصر ومساء (12:00 - 18:00)',
    descriptionArabic: 'أصالة ودفء رمال الصحراء الذهبية وقت العصر',
    isDark: false,
    bgMain: Color(0xFFF3E8D0),
    bgSecondary: Color(0xFFFBF6EA),
    cardBg: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFFAF5EB),
    border: Color(0xFFE2D1AF),
    textPrimary: Color(0xFF382914),
    textSecondary: Color(0xFFA87824),
    goldAccent: Color(0xFFC9A24D),
    accentGlow: Color(0xFFA87824),
    primaryNavy: Color(0xFF593F19),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEDE0C5), Color(0xFFFBF6EA), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFDF9F2)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x17593F19),
        blurRadius: 18,
        offset: Offset(0, 4),
      ),
    ],
  );

  /// 🌅 3. المغرب/المساء/الليل — Soft Rose (#F0DFE1)
  static const AppThemePalette lightSoftRose = AppThemePalette(
    id: ThemePresetIds.lightSoftRose,
    nameArabic: 'ورد المساء الترابي',
    timeLabelArabic: '🌙 ليل ومغرب (18:00 - 05:00)',
    descriptionArabic: 'لمسة الغروب الترابية الراقية مع الدفء والسكينة',
    isDark: false,
    bgMain: Color(0xFFF0DFE1),
    bgSecondary: Color(0xFFFAF1F2),
    cardBg: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF9EFF1),
    border: Color(0xFFDEC1C5),
    textPrimary: Color(0xFF3B1820),
    textSecondary: Color(0xFF8B3F4B),
    goldAccent: Color(0xFFC9A24D),
    accentGlow: Color(0xFF8B3F4B),
    primaryNavy: Color(0xFF4A2029),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEBD7DA), Color(0xFFFAF1F2), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFDF4F6)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x174A2029),
        blurRadius: 18,
        offset: Offset(0, 4),
      ),
    ],
  );
}

/// Central Theme Management Service
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  factory ThemeService() => instance;
  ThemeService._internal();

  String _currentPreset = ThemePresetIds.autoDark;
  Timer? _timeSyncTimer;

  String get currentPreset => _currentPreset;

  /// Returns whether the user is in an automatic adaptive time mode
  bool get isAutoMode =>
      _currentPreset == ThemePresetIds.autoDark ||
      _currentPreset == ThemePresetIds.autoLight;

  /// Returns whether currently resolved palette is Dark Mode
  bool get isLightMode => !effectivePalette.isDark;

  /// Resolves the actual palette based on preset and current hour
  AppThemePalette get effectivePalette {
    final hour = DateTime.now().hour;

    switch (_currentPreset) {
      case ThemePresetIds.autoDark:
        if (hour >= 5 && hour < 12) {
          return AppThemePalette.darkSapphire; // ☀️ الصباح -> Deep Sapphire
        } else if (hour >= 12 && hour < 18) {
          return AppThemePalette.darkEmerald;  // 🌤️ العصر -> Deep Emerald
        } else {
          return AppThemePalette.darkNight;    // 🌙 الليل -> Black
        }

      case ThemePresetIds.autoLight:
        if (hour >= 5 && hour < 12) {
          return AppThemePalette.lightSkyBlue; // ☀️ الصباح -> Sky Blue
        } else if (hour >= 12 && hour < 18) {
          return AppThemePalette.lightWarmSand; // 🌤️ العصر -> Warm Sand
        } else {
          return AppThemePalette.lightSoftRose; // 🌙 المغرب/الليل -> Soft Rose
        }

      case ThemePresetIds.darkBlack:
      case ThemePresetIds.legacyDark:
        return AppThemePalette.darkNight;

      case ThemePresetIds.darkSapphire:
        return AppThemePalette.darkSapphire;

      case ThemePresetIds.darkEmerald:
        return AppThemePalette.darkEmerald;

      case ThemePresetIds.lightSkyBlue:
      case ThemePresetIds.legacyLight:
        return AppThemePalette.lightSkyBlue;

      case ThemePresetIds.lightWarmSand:
        return AppThemePalette.lightWarmSand;

      case ThemePresetIds.lightSoftRose:
        return AppThemePalette.lightSoftRose;

      default:
        return AppThemePalette.darkNight;
    }
  }

  /// Initialize theme on app startup from persistent storage
  Future<void> init() async {
    final storage = StorageService();
    await storage.init();
    final savedTheme = storage.getTheme();
    if (savedTheme != null && savedTheme.isNotEmpty) {
      _currentPreset = savedTheme;
    } else {
      _currentPreset = ThemePresetIds.autoDark; // Default to adaptive dynamic dark
    }

    _startTimeSync();
    notifyListeners();
  }

  /// Periodically check time in auto mode to smoothly transition palettes
  void _startTimeSync() {
    _timeSyncTimer?.cancel();
    _timeSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isAutoMode) {
        notifyListeners();
      }
    });
  }

  /// Explicitly set and persist theme preset
  Future<void> setThemePreset(String presetId) async {
    _currentPreset = presetId;
    final storage = StorageService();
    await storage.setTheme(presetId);
    notifyListeners();
  }

  /// Toggle between Dark & Light mode while preserving user choice
  Future<void> toggleDarkLight() async {
    if (effectivePalette.isDark) {
      // Switch to Light
      if (_currentPreset == ThemePresetIds.autoDark) {
        await setThemePreset(ThemePresetIds.autoLight);
      } else if (_currentPreset == ThemePresetIds.darkSapphire) {
        await setThemePreset(ThemePresetIds.lightSkyBlue);
      } else if (_currentPreset == ThemePresetIds.darkEmerald) {
        await setThemePreset(ThemePresetIds.lightWarmSand);
      } else {
        await setThemePreset(ThemePresetIds.lightSoftRose);
      }
    } else {
      // Switch to Dark
      if (_currentPreset == ThemePresetIds.autoLight) {
        await setThemePreset(ThemePresetIds.autoDark);
      } else if (_currentPreset == ThemePresetIds.lightSkyBlue) {
        await setThemePreset(ThemePresetIds.darkSapphire);
      } else if (_currentPreset == ThemePresetIds.lightWarmSand) {
        await setThemePreset(ThemePresetIds.darkEmerald);
      } else {
        await setThemePreset(ThemePresetIds.darkBlack);
      }
    }
  }

  /// Legacy helper for setting light mode boolean
  Future<void> setLightMode(bool isLight) async {
    if (isLight && effectivePalette.isDark) {
      await toggleDarkLight();
    } else if (!isLight && !effectivePalette.isDark) {
      await toggleDarkLight();
    }
  }

  @override
  void dispose() {
    _timeSyncTimer?.cancel();
    super.dispose();
  }
}
