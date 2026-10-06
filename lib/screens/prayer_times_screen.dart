import 'package:flutter/material.dart';
import '../data/all_azkar_data.dart';
import '../models/azkar_models.dart';
import '../models/prayer_models.dart';
import '../services/location_service.dart';
import '../services/prayer_service_v2.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/islamic_background.dart';
import '../widgets/monthly_prayer_sheet.dart';
import '../widgets/prayer_alert_sheet.dart';
import '../widgets/prayer_hero_card.dart';
import '../widgets/prayer_settings_sheet.dart';
import '../widgets/prayer_timeline_card.dart';
import '../widgets/qibla_compass_sheet.dart';
import 'dhikr_reader_screen.dart';
import 'qibla_screen.dart';
import '../widgets/developer_credits_badge.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initDefaultTimings();
    _prayerService.addListener(_onUpdate);
    _loadPrayerData();
  }

  void _initDefaultTimings() {
    _timings = [
      PrayerTiming(
        type: PrayerType.fajr,
        nameArabic: 'الفجر',
        nameEnglish: 'Fajr',
        time: const TimeOfDay(hour: 5, minute: 3),
        icon: Icons.nightlight_round,
      ),
      PrayerTiming(
        type: PrayerType.sunrise,
        nameArabic: 'الشروق',
        nameEnglish: 'Sunrise',
        time: const TimeOfDay(hour: 6, minute: 33),
        icon: Icons.wb_twilight_rounded,
      ),
      PrayerTiming(
        type: PrayerType.dhuhr,
        nameArabic: 'الظهر',
        nameEnglish: 'Dhuhr',
        time: const TimeOfDay(hour: 12, minute: 54),
        icon: Icons.wb_sunny_rounded,
      ),
      PrayerTiming(
        type: PrayerType.asr,
        nameArabic: 'العصر',
        nameEnglish: 'Asr',
        time: const TimeOfDay(hour: 16, minute: 28),
        icon: Icons.cloud_queue_rounded,
      ),
      PrayerTiming(
        type: PrayerType.maghrib,
        nameArabic: 'المغرب',
        nameEnglish: 'Maghrib',
        time: const TimeOfDay(hour: 19, minute: 15),
        icon: Icons.wb_sunny_outlined,
      ),
      PrayerTiming(
        type: PrayerType.isha,
        nameArabic: 'العشاء',
        nameEnglish: 'Isha',
        time: const TimeOfDay(hour: 20, minute: 35),
        icon: Icons.nightlight_round,
      ),
    ];
    _currentPrayer = _timings.length > 2 ? _timings[2] : null;
    _nextPrayer = _timings.length > 3 ? _timings[3] : null;
    _isLoading = false;
  }

  @override
  void dispose() {
    _prayerService.removeListener(_onUpdate);
    super.dispose();
  }

  DateTime? _lastLoadedDate;

  void _onUpdate() {
    if (!mounted) return;
    if (_lastLoadedDate == null ||
        _lastLoadedDate!.year != _prayerService.selectedDate.year ||
        _lastLoadedDate!.month != _prayerService.selectedDate.month ||
        _lastLoadedDate!.day != _prayerService.selectedDate.day) {
      _loadPrayerData();
    } else {
      setState(() {});
    }
  }

  Future<void> _loadPrayerData() async {
    _lastLoadedDate = _prayerService.selectedDate;
    if (_timings.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
          if (_timings.isEmpty) {
            _errorMessage = 'فشل تحميل بيانات الصلاة: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final location = _prayerService.currentLocation ?? const LocationProfile(
      cityName: 'القاهرة',
      countryName: 'مصر',
      latitude: 30.0444,
      longitude: 31.2357,
      qiblaAngle: 136.0,
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: IslamicBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: isLight ? const Color(0xFFC89B3C) : DesignSystem.goldLight),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل بيانات الصلاة...',
                    style: TextStyle(color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: IslamicBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite),
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
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IslamicBackground(
        child: SafeArea(
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
                      child: _buildTopHeader(context, location, isLight),
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
                      child: _buildDateSelectorBar(context, isLight),
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
                        children: [
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerRight,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'مواقيت الصلاة اليوم',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const MonthlyPrayerSheet(),
                              );
                            },
                            icon: Icon(Icons.calendar_month_rounded, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 15),
                            label: Text('جدول الشهر', style: TextStyle(color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, fontSize: 11)),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              _showAthanSettings(context);
                            },
                            icon: Icon(Icons.notifications_active_rounded, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 15),
                            label: Text('الأذان', style: TextStyle(color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, fontSize: 11)),
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
                      child: _buildQuickToolsSection(context, isLight),
                    ),
                  ),

                  // Developer Credits Badge
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacingL, vertical: 8),
                      child: Center(
                        child: DeveloperCreditsBadge(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, LocationProfile location, bool isLight) {
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
                  color: isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.15),
                  border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.location_on_rounded, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${location.cityName}، ${location.countryName}',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted, size: 16),
                    ],
                  ),
                  Text(
                    _prayerService.getFormattedHijriDate(),
                    style: TextStyle(
                      color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
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
              isLight: isLight,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => QiblaCompassSheet(),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderCircleButton(
              icon: Icons.settings_rounded,
              isLight: isLight,
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

  Widget _buildHeaderCircleButton({required IconData icon, required VoidCallback onTap, required bool isLight}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : DesignSystem.bgCard.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            if (isLight)
              BoxShadow(
                color: const Color(0xFFC89B3C).withValues(alpha: 0.08),
                blurRadius: 6,
              ),
          ],
        ),
        child: Icon(icon, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 20),
      ),
    );
  }

  Widget _buildDateSelectorBar(BuildContext context, bool isLight) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: isLight ? const Color(0xFFE5D4B3) : Colors.white10,
        ),
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: const Color(0xFFC89B3C).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: isLight ? const Color(0xFF854D0E) : DesignSystem.cyanAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                _prayerService.getFormattedGregorianDate(),
                style: TextStyle(
                  color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
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
                      colorScheme: isLight
                          ? const ColorScheme.light(
                              primary: Color(0xFFC89B3C),
                              onPrimary: Colors.white,
                              surface: Color(0xFFFFFDF8),
                              onSurface: Color(0xFF1C1917),
                            )
                          : const ColorScheme.dark(
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
                color: isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Text(
                    'تغيير اليوم',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_calendar_rounded, color: isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolsSection(BuildContext context, bool isLight) {
    final tools = [
      {
        'title': 'اتجاه القبلة',
        'icon': Icons.explore_rounded,
        'color': isLight ? const Color(0xFF854D0E) : DesignSystem.gold,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        ),
      },
      {
        'title': 'جدول الشهر',
        'icon': Icons.calendar_month_rounded,
        'color': isLight ? const Color(0xFF0284C7) : DesignSystem.cyanAccent,
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
        'color': isLight ? const Color(0xFF2563EB) : DesignSystem.electricBlue,
        'onTap': () {
          final afterPrayerCategory = AllAzkarData.categories.firstWhere(
            (c) => c.type == AzkarCategoryType.afterPrayer,
            orElse: () => AllAzkarData.categories.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DhikrReaderScreen(category: afterPrayerCategory),
            ),
          );
        },
      },
      {
        'title': 'إعدادات الحساب',
        'icon': Icons.tune_rounded,
        'color': isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight,
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
        Text(
          'أدوات ومميزات الصلاة',
          style: TextStyle(
            color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
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
            return InkWell(
              onTap: tool['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
              child: Container(
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0C131D),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE5D4B3) : Colors.white10,
                  ),
                  boxShadow: [
                    if (isLight)
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLight ? const Color(0xFFFBF4E4) : (tool['color'] as Color).withValues(alpha: 0.15),
                        border: Border.all(color: isLight ? const Color(0xFFE5D4B3) : (tool['color'] as Color).withValues(alpha: 0.4)),
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
                        style: TextStyle(
                          color: isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNotificationModeDialog(PrayerType prayer) {
    final isLight = DesignSystem.isLightMode;
    final dialogBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final goldAccent = isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight;
    final dialogBorder = isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            side: BorderSide(color: dialogBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'وضع التنبيه للصلاة',
                  style: TextStyle(
                    color: goldAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildNotificationOption(prayer, NotificationMode.athan, 'الأذان كاملاً 🔊', Icons.volume_up_rounded, isLight),
                _buildNotificationOption(prayer, NotificationMode.notificationOnly, 'تنبيه هادئ فقط 🔔', Icons.notifications_active_rounded, isLight),
                _buildNotificationOption(prayer, NotificationMode.silent, 'بدون صوت (صامت) 🔕', Icons.notifications_off_rounded, isLight),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationOption(PrayerType prayer, NotificationMode mode, String title, IconData icon, bool isLight) {
    final isSelected = _prayerService.notificationSettings[prayer] == mode;
    final activeBg = isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.15);
    final inactiveBg = isLight ? Colors.white : Colors.white.withValues(alpha: 0.03);
    final border = isSelected
        ? (isLight ? const Color(0xFF854D0E) : DesignSystem.gold)
        : (isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08));
    final textColor = isSelected
        ? (isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight)
        : (isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite);
    final iconColor = isSelected
        ? (isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight)
        : (isLight ? const Color(0xFF78716C) : DesignSystem.textSecondary);

    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await _prayerService.setNotificationMode(prayer, mode);
        await _loadPrayerData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSelectorDialog(BuildContext context) {
    final isLight = DesignSystem.isLightMode;
    final dialogBg = isLight ? const Color(0xFFFFFDF8) : const Color(0xFF0F1621);
    final goldAccent = isLight ? const Color(0xFF854D0E) : DesignSystem.goldLight;
    final dialogBorder = isLight ? const Color(0xFFE5D4B3) : DesignSystem.gold.withValues(alpha: 0.4);
    final textTitle = isLight ? const Color(0xFF1C1917) : DesignSystem.textWhite;

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
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
            side: BorderSide(color: dialogBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختيار المدينة والموقع',
                    style: TextStyle(
                      color: goldAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📍 Real Device GPS Auto-detect Button
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: goldAccent),
                              ),
                              const SizedBox(width: 12),
                              const Text('جاري تحديد موقعك الدقيق عبر GPS...'),
                            ],
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );

                      try {
                        final locService = LocationService();
                        await locService.getCurrentPosition();
                        if (locService.currentLocation != null) {
                          await _prayerService.setLocation(locService.currentLocation!);
                          await _loadPrayerData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تحديث الموقع بنجاح: ${locService.currentLocation!.cityName}'),
                                backgroundColor: isLight ? const Color(0xFF16A34A) : Colors.green.shade800,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تعذر تحديد الموقع تلقائياً: $e'),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLight
                              ? [const Color(0xFFFBF4E4), const Color(0xFFFFFDF8)]
                              : [
                                  DesignSystem.gold.withValues(alpha: 0.25),
                                  DesignSystem.goldLight.withValues(alpha: 0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                        border: Border.all(color: goldAccent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.my_location_rounded, color: goldAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'تحديد موقعي الحالي تلقائياً (GPS)',
                            style: TextStyle(
                              color: goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(color: isLight ? const Color(0xFFE5D4B3) : Colors.white24, height: 16),

                  ...cities.map((city) {
                    final isCurrent = _prayerService.currentLocation?.cityName == city.cityName;
                    final itemBg = isCurrent
                        ? (isLight ? const Color(0xFFFBF4E4) : DesignSystem.gold.withValues(alpha: 0.15))
                        : (isLight ? Colors.white : Colors.white.withValues(alpha: 0.03));
                    final itemBorder = isCurrent
                        ? goldAccent
                        : (isLight ? const Color(0xFFE5D4B3) : Colors.white.withValues(alpha: 0.08));

                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await _prayerService.setLocation(city);
                        await _loadPrayerData();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                          border: Border.all(color: itemBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${city.cityName}، ${city.countryName}',
                              style: TextStyle(
                                color: isCurrent ? goldAccent : textTitle,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.location_city_rounded, color: isLight ? const Color(0xFF78716C) : DesignSystem.textMuted, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAthanSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrayerSettingsSheet(),
    );
  }
}
