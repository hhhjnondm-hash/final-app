import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service.dart';
import '../services/athan_service.dart';
import '../services/notification_service.dart';
import '../utils/design_system.dart';

class PrayerSettingsSheet extends StatefulWidget {
  const PrayerSettingsSheet({super.key});

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  final AthanService _athanService = AthanService();

  @override
  void initState() {
    super.initState();
    _athanService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _athanService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final service = PrayerService();
    final settings = service.settings;
    final athanSettings = _athanService.settings;

    final sheetBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final cardBg = isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.06);
    final cardBorder = isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.25);
    final textTitle = isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite;
    final textSub = isLight ? const Color(0xFF78716C) : DesignSystem.textMuted;
    final goldAccent = isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight;
    final dropdownBg = isLight ? const Color(0xFFFFFFFF) : DesignSystem.bgCard;

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: cardBorder),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFD6C7A1) : DesignSystem.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'إعدادات الأذان والتنبيهات والمواقيت',
                style: TextStyle(
                  color: goldAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. نظام الأذان المتطور (صوت الأذان والتنبيهات)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: goldAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'تفعيل تنبيهات الأذان التلقائية',
                            style: TextStyle(
                              color: textTitle,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: athanSettings.enabled,
                        activeThumbColor: goldAccent,
                        activeTrackColor: goldAccent.withValues(alpha: 0.4),
                        onChanged: (val) {
                          _athanService.updateSettings(athanSettings.copyWith(enabled: val));
                        },
                      ),
                    ],
                  ),
                  Divider(color: isLight ? const Color(0xFFE5D4B3) : const Color(0xFF1E293B), height: 20),

                  // Sound Selection
                  Text(
                    'صوت الأذان المفضل',
                    style: TextStyle(color: textTitle, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: dropdownBg,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(color: cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AthanSound>(
                        value: athanSettings.sound,
                        isExpanded: true,
                        dropdownColor: dropdownBg,
                        icon: Icon(Icons.arrow_drop_down, color: goldAccent),
                        style: TextStyle(color: textTitle, fontSize: 13, fontWeight: FontWeight.w500),
                        onChanged: (val) {
                          if (val != null) {
                            _athanService.updateSettings(athanSettings.copyWith(sound: val));
                          }
                        },
                        items: AthanSound.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              _athanService.getSoundDisplayName(s),
                              style: TextStyle(color: textTitle),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Smart Short Athan on Silent Mode Switch
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF070B11).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.volume_down_rounded, color: goldAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'أذان مختصر في الوضع الصامت',
                                      style: TextStyle(
                                        color: textTitle,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: athanSettings.shortAthanOnSilent,
                              activeThumbColor: goldAccent,
                              activeTrackColor: goldAccent.withValues(alpha: 0.4),
                              onChanged: (val) {
                                _athanService.updateSettings(athanSettings.copyWith(shortAthanOnSilent: val));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'عندما يكون الهاتف على الوضع الصامت، ينطق الأذان بالتكبيرتين والشهادتين فقط ثم ينتهي بلطف.',
                          style: TextStyle(color: textSub, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Test Buttons Row: Full Athan & Short Athan
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLight ? const Color(0xFF854D0E) : DesignSystem.gold,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (_athanService.isPlayingAthan) {
                              _athanService.stopAthan();
                            } else {
                              _athanService.testAthan(context: context);
                            }
                          },
                          icon: Icon(_athanService.isPlayingAthan ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                          label: Text(
                            _athanService.isPlayingAthan ? 'إيقاف الأذان' : 'تجربة صوت الأذان 🔊',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (_athanService.isPlayingAthan) {
                              _athanService.stopAthan();
                            } else {
                              _athanService.testShortAthan(context: context);
                            }
                          },
                          icon: const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF16A34A)),
                          label: const Text(
                            'الأذان المختصر ⚡',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textTitle,
                        side: BorderSide(color: cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final notif = NotificationService();
                        await notif.requestPermissionsManually();
                        await notif.showPrayerAthanNotification(
                          id: 999,
                          prayerName: 'Dhuhr',
                          arabicName: 'الظهر',
                        );
                        await notif.showIslamicContentNotification(
                          id: 998,
                          title: '🕌 إشعار تجريبي: حان موعد الصلاة',
                          body: 'قال رسول الله ﷺ: «أحبّ الأعمال إلى الله الصلاة على وقتها»',
                          category: 'تجربة الإشعارات',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم إرسال إشعار تجريبي وتحديث الإشعارات بنجاح 🔔'),
                              backgroundColor: isLight ? const Color(0xFF854D0E) : DesignSystem.bgCard,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.notifications_active_rounded, size: 18, color: goldAccent),
                      label: const Text('اختبار إرسال الإشعارات وقفل الشاشة 🔔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Calculation Method
            Text(
              'طريقة الحساب المعتمدة',
              style: TextStyle(color: textTitle, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: dropdownBg,
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: settings.method,
                  isExpanded: true,
                  dropdownColor: dropdownBg,
                  icon: Icon(Icons.arrow_drop_down, color: goldAccent),
                  style: TextStyle(color: textTitle, fontSize: 13, fontWeight: FontWeight.w500),
                  onChanged: (val) {
                    if (val != null) {
                      service.updateSettings(PrayerCalculationSettings(
                        method: val,
                        juristicMethod: settings.juristicMethod,
                        fajrAngle: settings.fajrAngle,
                        ishaAngle: settings.ishaAngle,
                      ));
                      setState(() {});
                    }
                  },
                  items: [
                    'الهيئة المصرية العامة للمساحة',
                    'أم القرى - مكة المكرمة',
                    'رابطة العالم الإسلامي',
                    'جامعة العلوم الإسلامية بكراتشي',
                    'الاتحاد الإسلامي بأمريكا الشمالية (ISNA)',
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: textTitle)))).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Juristic Method (Shafii vs Hanafi)
            Text(
              'المذهب الفقهي (لحساب صلاة العصر)',
              style: TextStyle(color: textTitle, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRadioSchool('جمهور الفقهاء (شافعي، مالكي، حنبلي)', settings.juristicMethod == 'شافعي، مالكي، حنبلي', () {
                  service.updateSettings(PrayerCalculationSettings(
                    method: settings.method,
                    juristicMethod: 'شافعي، مالكي، حنبلي',
                    fajrAngle: settings.fajrAngle,
                    ishaAngle: settings.ishaAngle,
                  ));
                  setState(() {});
                }, isLight),
                const SizedBox(width: 10),
                _buildRadioSchool('حنفي', settings.juristicMethod == 'حنفي', () {
                  service.updateSettings(PrayerCalculationSettings(
                    method: settings.method,
                    juristicMethod: 'حنفي',
                    fajrAngle: settings.fajrAngle,
                    ishaAngle: settings.ishaAngle,
                  ));
                  setState(() {});
                }, isLight),
              ],
            ),

            const SizedBox(height: 20),

            // Angles
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('زاوية الفجر', style: TextStyle(color: textSub, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${settings.fajrAngle}°', style: TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('زاوية العشاء', style: TextStyle(color: textSub, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${settings.ishaAngle}°', style: TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioSchool(String title, bool isSelected, VoidCallback onTap, bool isLight) {
    final activeBg = isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.15);
    final inactiveBg = isLight ? const Color(0xFFF5F0E6) : Colors.white.withValues(alpha: 0.03);
    final border = isSelected
        ? (isLight ? const Color(0xFF854D0E) : DesignSystem.gold)
        : (isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.1));
    final textColor = isSelected
        ? (isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight)
        : (isLight ? const Color(0xFF78716C) : DesignSystem.textSecondary);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
