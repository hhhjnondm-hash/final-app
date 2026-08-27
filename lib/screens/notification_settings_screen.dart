import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/adhan_service.dart';
import '../services/islamic_notification_service.dart';
import '../utils/design_system.dart';
import '../widgets/glass_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final IslamicNotificationService _notifService = IslamicNotificationService();
  final AdhanService _adhanService = AdhanService();

  String _formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final periodStr = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour12:$minuteStr $periodStr';
  }

  Future<void> _pickTime(NotificationContentType type, TimeOfDay initialTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignSystem.gold,
              onPrimary: DesignSystem.bgDarkest,
              surface: DesignSystem.bgCard,
              onSurface: DesignSystem.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _notifService.updateScheduleTime(type, picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.textWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إعدادات الإشعارات والأذان',
          style: TextStyle(
            color: DesignSystem.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master Switch Card
              _buildMasterSwitchCard(),

              const SizedBox(height: 24),

              // Content Categories
              _buildSectionTitle('أقسام التذكير الإيماني اليومي', Icons.notifications_active_rounded),
              const SizedBox(height: 12),
              _buildCategoryTile(
                type: NotificationContentType.ayah,
                title: 'آيات قرآنية وتدبر',
                subtitle: 'تذكير يومي بآيات محكمة من كتاب الله (${_notifService.totalAyatCount}+ آية متوفرة)',
                icon: Icons.menu_book_rounded,
              ),
              _buildCategoryTile(
                type: NotificationContentType.dua,
                title: 'أدعية مأثورة ومستجابة',
                subtitle: 'أدعية نبوية وقرآنية جامعة (${_notifService.totalDuasCount}+ دعاء متوفر)',
                icon: Icons.volunteer_activism_rounded,
              ),
              _buildCategoryTile(
                type: NotificationContentType.dhikr,
                title: 'أذكار وفوائد إيمانية',
                subtitle: 'أذكار الصباح والمساء والفضائل (${_notifService.totalAdhkarCount}+ ذكر متوفر)',
                icon: Icons.fingerprint_rounded,
              ),
              _buildCategoryTile(
                type: NotificationContentType.quote,
                title: 'درر وحكم من السلف',
                subtitle: 'مواعظ وخواطر إيمانية مضيئة (${_notifService.totalQuotesCount}+ حكمة متوفرة)',
                icon: Icons.auto_stories_rounded,
              ),

              const SizedBox(height: 28),

              // Adhan & Prayer Section
              _buildSectionTitle('الأذان ومواقيت الصلاة', Icons.mosque_rounded),
              const SizedBox(height: 12),
              _buildAdhanSettingsCard(),

              const SizedBox(height: 28),

              // Quiet Hours Section
              _buildSectionTitle('أوقات عدم الإزعاج (Quiet Hours)', Icons.bedtime_rounded),
              const SizedBox(height: 12),
              _buildQuietHoursCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DesignSystem.goldLight, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: DesignSystem.goldLight,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMasterSwitchCard() {
    final isEnabled = _notifService.preferences.masterEnabled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [DesignSystem.gold.withValues(alpha: 0.22), DesignSystem.bgCard]
              : [DesignSystem.bgCard, DesignSystem.bgDarkest],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isEnabled ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? DesignSystem.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            ),
            child: Icon(
              isEnabled ? Icons.notifications_on_rounded : Icons.notifications_off_rounded,
              color: isEnabled ? DesignSystem.goldLight : DesignSystem.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفعيل جميع الإشعارات',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled ? 'نظام التذكير الإيماني الذكي مفعل' : 'الإشعارات متوقفة حالياً',
                  style: const TextStyle(
                    color: DesignSystem.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            activeColor: DesignSystem.gold,
            onChanged: (val) => setState(() => _notifService.toggleMaster(val)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({
    required NotificationContentType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final schedule = _notifService.preferences.schedules[type];
    final isEnabled = schedule?.isEnabled ?? false;
    final time = schedule?.preferredTime ?? const TimeOfDay(hour: 8, minute: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled ? DesignSystem.gold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: isEnabled ? DesignSystem.goldLight : DesignSystem.textMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isEnabled ? DesignSystem.textWhite : DesignSystem.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                activeColor: DesignSystem.gold,
                onChanged: (val) => setState(() => _notifService.toggleCategory(type, val)),
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(color: Colors.white12, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'وقت التذكير اليومي المفضل:',
                  style: TextStyle(color: DesignSystem.textMuted, fontSize: 12),
                ),
                InkWell(
                  onTap: () => _pickTime(type, time),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignSystem.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: DesignSystem.goldLight, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimeOfDay(time),
                          style: const TextStyle(
                            color: DesignSystem.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdhanSettingsCard() {
    final adhanEnabled = _adhanService.adhanSoundEnabled;
    final preReminder = _adhanService.preAdhanReminderEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: DesignSystem.goldLight, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أذان الصلوات التلقائي',
                      style: TextStyle(color: DesignSystem.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'تشغيل صوت الأذان المحلي عند حلول وقت الصلاة',
                      style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: adhanEnabled,
                activeColor: DesignSystem.gold,
                onChanged: (val) => setState(() => _adhanService.toggleAdhanSound(val)),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'صوت المؤذن:',
                style: TextStyle(color: DesignSystem.textMuted, fontSize: 13),
              ),
              DropdownButton<AdhanVoice>(
                value: _adhanService.selectedVoice,
                dropdownColor: DesignSystem.bgCard,
                style: const TextStyle(color: DesignSystem.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
                underline: const SizedBox.shrink(),
                items: AdhanVoice.values.map((voice) {
                  return DropdownMenuItem(
                    value: voice,
                    child: Text(_adhanService.getVoiceNameArabic(voice)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _adhanService.selectVoice(v));
                },
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: DesignSystem.goldLight, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التنبيه قبل الأذان',
                      style: TextStyle(color: DesignSystem.textWhite, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إشعار تذكيري قبل دخول الصلاة بـ 10 دقائق',
                      style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: preReminder,
                activeColor: DesignSystem.gold,
                onChanged: (val) => setState(() => _adhanService.setPreAdhanReminder(val, 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    final prefs = _notifService.preferences;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: DesignSystem.goldLight, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفعيل ساعات الهدوء',
                      style: TextStyle(color: DesignSystem.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إيقاف الإشعارات العامة ليلاً تلقائياً',
                      style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: prefs.quietHoursEnabled,
                activeColor: DesignSystem.gold,
                onChanged: (val) => setState(() => _notifService.toggleQuietHours(val)),
              ),
            ],
          ),
          if (prefs.quietHoursEnabled) ...[
            const Divider(color: Colors.white12, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'من ${_formatTimeOfDay(prefs.quietHoursStart)} حتى ${_formatTimeOfDay(prefs.quietHoursEnd)}',
                  style: const TextStyle(color: DesignSystem.goldLight, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Text(
                  '(أوقات النوم)',
                  style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
