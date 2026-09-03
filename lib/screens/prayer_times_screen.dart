import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service_v2.dart';
import '../services/athan_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/monthly_prayer_sheet.dart';
import '../widgets/prayer_alert_sheet.dart';
import '../widgets/prayer_hero_card.dart';
import '../widgets/prayer_settings_sheet.dart';
import '../widgets/prayer_timeline_card.dart';
import '../widgets/qibla_compass_sheet.dart';
import 'qibla_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerServiceV2 _prayerService = PrayerServiceV2();
  
  List<PrayerTiming> _timings = [];
  PrayerTiming? _currentPrayer;
  PrayerTiming? _nextPrayer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prayerService.addListener(_onUpdate);
    _loadPrayerData();
  }

  @override
  void dispose() {
    _prayerService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrayerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final timings = await _prayerService.getPrayerTimingsForDate(_prayerService.selectedDate);
      final currentPrayer = await _prayerService.getCurrentPrayer();
      final nextPrayer = await _prayerService.getNextPrayer();

      if (mounted) {
        setState(() {
          _timings = timings;
          _currentPrayer = currentPrayer;
          _nextPrayer = nextPrayer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات الصلاة: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = _prayerService.currentLocation ?? const LocationProfile(
      cityName: 'القاهرة',
      countryName: 'مصر',
      latitude: 30.0444,
      longitude: 31.2357,
      qiblaAngle: 136.0,
    );

    if (_isLoading) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: DesignSystem.goldLight),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل بيانات الصلاة...',
                style: TextStyle(color: DesignSystem.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: DesignSystem.textWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPrayerData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Luxury Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacingL,
                    DesignSystem.spacingM,
                    DesignSystem.spacingL,
                    DesignSystem.spacingS,
                  ),
                  child: _buildTopHeader(context, location),
                ),
              ),

              // Hero Prayer Card with Artwork & Live Countdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: PrayerHeroCard(
                    onAthanTap: () {
                      if (_nextPrayer != null) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PrayerAlertSheet(timing: _nextPrayer!),
                        );
                      }
                    },
                  ),
                ),
              ),

              // Date Bar & Date Picker Shortcut
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacingL,
                    vertical: DesignSystem.spacingS,
                  ),
                  child: _buildDateSelectorBar(context),
                ),
              ),

              // Section Title: مواقيت الصلاة اليوم
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacingL,
                    DesignSystem.spacingM,
                    DesignSystem.spacingL,
                    DesignSystem.spacingS,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مواقيت الصلاة اليوم',
                        style: TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const MonthlyPrayerSheet(),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded, color: DesignSystem.goldLight, size: 16),
                        label: const Text('جدول الشهر', style: TextStyle(color: DesignSystem.goldLight, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showAthanSettings(context);
                        },
                        icon: const Icon(Icons.notifications_active_rounded, color: DesignSystem.goldLight, size: 16),
                        label: const Text('الأذان', style: TextStyle(color: DesignSystem.goldLight, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),

              // Prayer Timelines List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final timing = _timings[index];
                      final isCurrent = _currentPrayer != null && timing.type == _currentPrayer?.type;
                      final isNext = _nextPrayer != null && timing.type == _nextPrayer?.type;

                      return PrayerTimelineCard(
                        timing: timing,
                        isCurrent: isCurrent,
                        isNext: isNext,
                        onNotificationToggle: () {
                          _showNotificationModeDialog(timing.type);
                        },
                      );
                    },
                    childCount: _timings.length,
                  ),
                ),
              ),

              // Quick Prayer Tools (القبلة • المساجد القريبة • أذكار الصلاة • إعدادات الحساب)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignSystem.spacingL),
                  child: _buildQuickToolsSection(context),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, LocationProfile location) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Location Info & City Switcher
        InkWell(
          onTap: () => _showLocationSelectorDialog(context),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.gold.withValues(alpha: 0.15),
                  border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.location_on_rounded, color: DesignSystem.goldLight, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${location.cityName}، ${location.countryName}',
                        style: const TextStyle(
                          color: DesignSystem.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: DesignSystem.textMuted, size: 16),
                    ],
                  ),
                  Text(
                    _prayerService.getFormattedHijriDate(),
                    style: const TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons (Settings & Compass)
        Row(
          children: [
            _buildHeaderCircleButton(
              icon: Icons.explore_rounded,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const QiblaCompassSheet(),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderCircleButton(
              icon: Icons.settings_rounded,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const PrayerSettingsSheet(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCircleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DesignSystem.bgCard.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(icon, color: DesignSystem.goldLight, size: 20),
      ),
    );
  }

  Widget _buildDateSelectorBar(BuildContext context) {
    return GlassCard(
      borderRadius: DesignSystem.radiusLarge,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: DesignSystem.cyanAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                _prayerService.getFormattedGregorianDate(),
                style: const TextStyle(
                  color: DesignSystem.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _prayerService.selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: DesignSystem.gold,
                        onPrimary: DesignSystem.bgDarkest,
                        surface: DesignSystem.bgCard,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                _prayerService.setSelectedDate(picked);
                _loadPrayerData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DesignSystem.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Text(
                    'تغيير اليوم',
                    style: TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.edit_calendar_rounded, color: DesignSystem.goldLight, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolsSection(BuildContext context) {
    final tools = [
      {
        'title': 'اتجاه القبلة',
        'icon': Icons.explore_rounded,
        'color': DesignSystem.gold,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        ),
      },
      {
        'title': 'جدول الشهر',
        'icon': Icons.calendar_month_rounded,
        'color': DesignSystem.cyanAccent,
        'onTap': () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const MonthlyPrayerSheet(),
            ),
      },
      {
        'title': 'أذكار الصلاة',
        'icon': Icons.menu_book_rounded,
        'color': DesignSystem.electricBlue,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم فتح أذكار ما بعد الصلاة')),
          );
        },
      },
      {
        'title': 'إعدادات الحساب',
        'icon': Icons.tune_rounded,
        'color': DesignSystem.goldLight,
        'onTap': () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const PrayerSettingsSheet(),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أدوات ومميزات الصلاة',
          style: TextStyle(
            color: DesignSystem.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return GlassCard(
              borderRadius: DesignSystem.radiusLarge,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: tool['onTap'] as VoidCallback,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (tool['color'] as Color).withValues(alpha: 0.15),
                      border: Border.all(color: (tool['color'] as Color).withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: tool['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tool['title'] as String,
                      style: const TextStyle(
                        color: DesignSystem.textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNotificationModeDialog(PrayerType prayer) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: DesignSystem.bgDarkest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'وضع التنبيه للصلاة',
                  style: TextStyle(
                    color: DesignSystem.goldLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildNotificationOption(prayer, NotificationMode.athan, 'الأذان كاملاً', Icons.volume_up_rounded),
                _buildNotificationOption(prayer, NotificationMode.notificationOnly, 'تنبيه هادئ فقط', Icons.notifications_active_rounded),
                _buildNotificationOption(prayer, NotificationMode.silent, 'بدون صوت (صامت)', Icons.notifications_off_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationOption(PrayerType prayer, NotificationMode mode, String title, IconData icon) {
    final isSelected = _prayerService.notificationSettings[prayer] == mode;
    return InkWell(
      onTap: () {
        _prayerService.setNotificationMode(prayer, mode);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          border: Border.all(color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? DesignSystem.goldLight : DesignSystem.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? DesignSystem.goldLight : DesignSystem.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSelectorDialog(BuildContext context) {
    final cities = [
      const LocationProfile(cityName: 'القاهرة', countryName: 'مصر', latitude: 30.0444, longitude: 31.2357, qiblaAngle: 136.0),
      const LocationProfile(cityName: 'الإسكندرية', countryName: 'مصر', latitude: 31.2001, longitude: 29.9187, qiblaAngle: 138.0),
      const LocationProfile(cityName: 'مكة المكرمة', countryName: 'السعودية', latitude: 21.3891, longitude: 39.8579, qiblaAngle: 0.0),
      const LocationProfile(cityName: 'المدينة المنورة', countryName: 'السعودية', latitude: 24.5247, longitude: 39.5692, qiblaAngle: 175.0),
      const LocationProfile(cityName: 'الرياض', countryName: 'السعودية', latitude: 24.7136, longitude: 46.6753, qiblaAngle: 243.0),
      const LocationProfile(cityName: 'دبي', countryName: 'الإمارات', latitude: 25.2048, longitude: 55.2708, qiblaAngle: 258.0),
      const LocationProfile(cityName: 'القدس', countryName: 'فلسطين', latitude: 31.7683, longitude: 35.2137, qiblaAngle: 155.0),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: DesignSystem.bgDarkest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            side: BorderSide(color: DesignSystem.gold.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختيار المدينة والموقع',
                  style: TextStyle(
                    color: DesignSystem.goldLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...cities.map((city) => InkWell(
                  onTap: () {
                    _prayerService.setLocation(city);
                    _loadPrayerData();
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _prayerService.currentLocation?.cityName == city.cityName
                          ? DesignSystem.gold.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(
                        color: _prayerService.currentLocation?.cityName == city.cityName
                            ? DesignSystem.gold
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${city.cityName}، ${city.countryName}',
                          style: TextStyle(
                            color: _prayerService.currentLocation?.cityName == city.cityName
                                ? DesignSystem.goldLight
                                : DesignSystem.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.location_city_rounded, color: DesignSystem.textMuted, size: 18),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAthanSettings(BuildContext context) {
    // Temporarily disabled - needs service integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('إعدادات الأذان قيد التطوير')),
    );
  }
}
