import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';

/// Luxury Theme & Palette Selection Modal
class ThemeSelectionModal extends StatelessWidget {
  const ThemeSelectionModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeSelectionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final currentPalette = themeService.effectivePalette;
    final isDark = currentPalette.isDark;

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final activePreset = themeService.currentPreset;
        final isAuto = themeService.isAutoMode;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: currentPalette.bgMain,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: currentPalette.goldAccent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle & Header
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: currentPalette.goldAccent.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: currentPalette.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: currentPalette.goldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: currentPalette.goldAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مظهر وألوان التطبيق',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: currentPalette.textPrimary,
                            ),
                          ),
                          Text(
                            isAuto
                                ? 'الوضع التلقائي مفعل (يتغير حسب أوقات اليوم)'
                                : 'ثيم يدوي مثبت ومحفوظ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: currentPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: currentPalette.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Divider(
                color: currentPalette.border.withValues(alpha: 0.4),
                thickness: 1,
              ),

              // 2. Scrollable Theme Options
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ===== A. AUTO ADAPTIVE SECTION =====
                    _buildSectionTitle('⏱️ النظام الزمني التلقائي (يتغير مع ساعات اليوم)', currentPalette),
                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: 'الوضع الليلي التلقائي (Dark Auto)',
                      subtitle: 'سفير صباحاً 🔵 ➔ زمرد عصراً 🟢 ➔ أسود ليلاً 🖤',
                      badgeText: 'مُوصى به',
                      presetId: ThemePresetIds.autoDark,
                      isSelected: activePreset == ThemePresetIds.autoDark,
                      colorsPreview: const [
                        Color(0xFF102A43), // Sapphire
                        Color(0xFF0B3D35), // Emerald
                        Color(0xFF08090B), // Black
                      ],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.autoDark);
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: 'الوضع النهاري التلقائي (Light Auto)',
                      subtitle: 'سماوي صباحاً ☀️ ➔ رملي عصراً 🌤️ ➔ وردي غروباً 🌅',
                      presetId: ThemePresetIds.autoLight,
                      isSelected: activePreset == ThemePresetIds.autoLight,
                      colorsPreview: const [
                        Color(0xFFDCEAF4), // Sky Blue
                        Color(0xFFF3E8D0), // Warm Sand
                        Color(0xFFF0DFE1), // Soft Rose
                      ],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.autoLight);
                      },
                    ),

                    const SizedBox(height: 24),

                    // ===== B. DARK MANUAL PRESETS =====
                    _buildSectionTitle('🌙 الثيمات الداكنة الثابتة (Dark Mode)', currentPalette),
                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: '🖤 الأسود — Night',
                      subtitle: 'الأسود الملكي الفاخر (#08090B) مع بريق الذهب',
                      presetId: ThemePresetIds.darkBlack,
                      isSelected: activePreset == ThemePresetIds.darkBlack,
                      colorsPreview: const [Color(0xFF08090B), Color(0xFF131722), Color(0xFFD4AF57)],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.darkBlack);
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: '🔵 Deep Sapphire — Morning',
                      subtitle: 'أزرق ياقوتي عميق وهادئ (#102A43) ومناسب لواجهة إسلامية',
                      presetId: ThemePresetIds.darkSapphire,
                      isSelected: activePreset == ThemePresetIds.darkSapphire,
                      colorsPreview: const [Color(0xFF102A43), Color(0xFF163756), Color(0xFFD4AF57)],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.darkSapphire);
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: '🟢 Deep Emerald — Evening',
                      subtitle: 'أخضر زمردي إسلامي غامق (#0B3D35) فخم ومهيب',
                      presetId: ThemePresetIds.darkEmerald,
                      isSelected: activePreset == ThemePresetIds.darkEmerald,
                      colorsPreview: const [Color(0xFF0B3D35), Color(0xFF114E44), Color(0xFFD4AF57)],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.darkEmerald);
                      },
                    ),

                    const SizedBox(height: 24),

                    // ===== C. LIGHT MANUAL PRESETS =====
                    _buildSectionTitle('☀️ الثيمات الفاتحة الثابتة (Light Mode)', currentPalette),
                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: '☀️ الصبح — Sky Blue',
                      subtitle: 'سماوي صافٍ ونظيف (#DCEAF4) مع لمسات كحلية',
                      presetId: ThemePresetIds.lightSkyBlue,
                      isSelected: activePreset == ThemePresetIds.lightSkyBlue,
                      colorsPreview: const [Color(0xFFDCEAF4), Color(0xFFEEF6FA), Color(0xFF2B6F9B)],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.lightSkyBlue);
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: '🌤️ العصر — Warm Sand',
                      subtitle: 'رمل العصر الدافئ والفخم (#F3E8D0) مع درجات الكراميل والذهب',
                      presetId: ThemePresetIds.lightWarmSand,
                      isSelected: activePreset == ThemePresetIds.lightWarmSand,
                      colorsPreview: const [Color(0xFFF3E8D0), Color(0xFFFBF6EA), Color(0xFFA87824)],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.lightWarmSand);
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildThemeCard(
                      title: '🌅 المغرب والمساء — Soft Rose',
                      subtitle: 'وردي ترابي راقٍ ودافئ (#F0DFE1) مع لمسات عنابية فاخرة',
                      presetId: ThemePresetIds.lightSoftRose,
                      isSelected: activePreset == ThemePresetIds.lightSoftRose,
                      colorsPreview: const [Color(0xFFF0DFE1), Color(0xFFFAF1F2), Color(0xFF8B3F4B)],
                      goldAccent: currentPalette.goldAccent,
                      palette: currentPalette,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeService.setThemePreset(ThemePresetIds.lightSoftRose);
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, AppThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: palette.goldAccent,
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    String? badgeText,
    required String presetId,
    required bool isSelected,
    required List<Color> colorsPreview,
    required Color goldAccent,
    required AppThemePalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? goldAccent
                : palette.border.withValues(alpha: palette.isDark ? 0.3 : 0.6),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : palette.cardShadow,
        ),
        child: Row(
          children: [
            // Color Swatches Capsule
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: goldAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Row(
                  children: colorsPreview
                      .map((c) => Expanded(child: Container(color: c)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? goldAccent : palette.textPrimary,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: goldAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: goldAccent, width: 0.8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: goldAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Selection Radio Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? goldAccent : palette.textSecondary.withValues(alpha: 0.4),
                  width: 2,
                ),
                color: isSelected ? goldAccent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: Colors.black,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
