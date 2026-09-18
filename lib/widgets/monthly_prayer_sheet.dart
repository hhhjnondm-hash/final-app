import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../services/prayer_service_v2.dart';
import '../utils/design_system.dart';

class MonthlyPrayerSheet extends StatefulWidget {
  const MonthlyPrayerSheet({super.key});

  @override
  State<MonthlyPrayerSheet> createState() => _MonthlyPrayerSheetState();
}

class _MonthlyPrayerSheetState extends State<MonthlyPrayerSheet> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isLoading = true;
  final Map<int, List<PrayerTiming>> _monthTimings = {};
  final PrayerServiceV2 _service = PrayerServiceV2();

  @override
  void initState() {
    super.initState();
    _loadMonthTimings();
  }

  Future<void> _loadMonthTimings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final Map<int, List<PrayerTiming>> timingsMap = {};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final timings = await _service.getPrayerTimingsForDate(date);
      timingsMap[day] = timings;
    }

    if (mounted) {
      setState(() {
        _monthTimings.clear();
        _monthTimings.addAll(timingsMap);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final now = DateTime.now();

    const monthNamesAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignSystem.radiusLarge)),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Header & Month Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جدول مواقيت الشهر',
                    style: TextStyle(
                      color: DesignSystem.goldLight,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${monthNamesAr[_currentMonth.month - 1]} ${_currentMonth.year}',
                    style: const TextStyle(color: DesignSystem.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: DesignSystem.goldLight),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                      });
                      _loadMonthTimings();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: DesignSystem.goldLight),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                      });
                      _loadMonthTimings();
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('اليوم', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('الفجر', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11))),
                Expanded(flex: 1, child: Text('الشروق', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11))),
                Expanded(flex: 1, child: Text('الظهر', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11))),
                Expanded(flex: 1, child: Text('العصر', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11))),
                Expanded(flex: 1, child: Text('المغرب', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11))),
                Expanded(flex: 1, child: Text('العشاء', textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.textSecondary, fontSize: 11))),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Days List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: DesignSystem.goldLight),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      final dayNum = index + 1;
                      final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                      final isToday = now.year == date.year && now.month == date.month && now.day == date.day;
                      final isSelected = _service.selectedDate.year == date.year &&
                          _service.selectedDate.month == date.month &&
                          _service.selectedDate.day == date.day;
                      final timings = _monthTimings[dayNum] ?? [];

                      return InkWell(
                        onTap: () {
                          _service.setSelectedDate(date);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DesignSystem.gold.withValues(alpha: 0.25)
                                : isToday
                                    ? DesignSystem.gold.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                            border: isSelected
                                ? Border.all(color: DesignSystem.goldLight, width: 1.5)
                                : isToday
                                    ? Border.all(color: DesignSystem.gold.withValues(alpha: 0.5))
                                    : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '$dayNum',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: (isToday || isSelected) ? DesignSystem.goldLight : DesignSystem.textWhite,
                                    fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (timings.isEmpty)
                                const Expanded(
                                  flex: 6,
                                  child: Center(
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: DesignSystem.goldLight),
                                    ),
                                  ),
                                )
                              else
                                ...timings.map((t) => Expanded(
                                  flex: 1,
                                  child: Text(
                                    t.time.format(context),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: (isToday || isSelected) ? DesignSystem.goldLight : DesignSystem.textSecondary,
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
