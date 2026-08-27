import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service.dart';
import '../utils/design_system.dart';

class PrayerSettingsSheet extends StatefulWidget {
  const PrayerSettingsSheet({super.key});

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final service = PrayerService();
    final settings = service.settings;

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
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
                  color: DesignSystem.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Center(
              child: Text(
                'إعدادات الحساب الفلكي والمواقيت',
                style: TextStyle(
                  color: DesignSystem.goldLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Calculation Method
            const Text(
              'طريقة الحساب المعتمدة',
              style: TextStyle(color: DesignSystem.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: settings.method,
                  isExpanded: true,
                  dropdownColor: DesignSystem.bgCard,
                  icon: const Icon(Icons.arrow_drop_down, color: DesignSystem.goldLight),
                  style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13),
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
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Juristic Method (Shafii vs Hanafi)
            const Text(
              'المذهب الفقهي (لحساب صلاة العصر)',
              style: TextStyle(color: DesignSystem.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRadioSchool('شافعي، مالكي، حنبلي', settings.juristicMethod == 'شافعي، مالكي، حنبلي', () {
                  service.updateSettings(PrayerCalculationSettings(
                    method: settings.method,
                    juristicMethod: 'شافعي، مالكي، حنبلي',
                    fajrAngle: settings.fajrAngle,
                    ishaAngle: settings.ishaAngle,
                  ));
                  setState(() {});
                }),
                const SizedBox(width: 10),
                _buildRadioSchool('حنفي', settings.juristicMethod == 'حنفي', () {
                  service.updateSettings(PrayerCalculationSettings(
                    method: settings.method,
                    juristicMethod: 'حنفي',
                    fajrAngle: settings.fajrAngle,
                    ishaAngle: settings.ishaAngle,
                  ));
                  setState(() {});
                }),
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
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('زاوية الفجر', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${settings.fajrAngle}°', style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('زاوية العشاء', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${settings.ishaAngle}°', style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildRadioSchool(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? DesignSystem.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            border: Border.all(
              color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? DesignSystem.goldLight : DesignSystem.textSecondary,
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
