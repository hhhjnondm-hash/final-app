import 'package:flutter/material.dart';
import '../services/quran_storage_service.dart';
import '../utils/design_system.dart';
import 'ai_assistant_screen.dart';
import 'azkar_screen.dart';
import 'iqra_screen.dart';
import 'notification_settings_screen.dart';
import 'tasbih_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final QuranStorageService _storage = QuranStorageService();
  int _selectedTab = 0; // 0: العلامات المرجعية, 1: المفضلة

  @override
  Widget build(BuildContext context) {
    final progress = _storage.readingProgress;
    final bookmarks = _storage.bookmarks;

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spacingL,
                      DesignSystem.spacingM,
                      DesignSystem.spacingL,
                      DesignSystem.spacingS,
                    ),
                    child: _buildHeader(context),
                  ),
                ),

                // 2. Profile Hero Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingL,
                      vertical: DesignSystem.spacingS,
                    ),
                    child: _buildProfileHeroCard(),
                  ),
                ),

                // 3. Quick Actions (Including Tasbih)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: _buildQuickActions(context),
                  ),
                ),

                // 4. Today Progress (رحلتي اليوم)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildTodayProgressSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 5. Quran Journey (متابعة القراءة)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildQuranJourneyCard(context, progress),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 6. Khatmah + Streak Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildKhatmahAndStreakSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 7. Statistics (إحصائياتي)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildStatisticsSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 8. Bookmarks & Favorites (المحفوظات)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildBookmarksSection(bookmarks),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 9. Islamic Assistant Advice
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildIslamicAssistantCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 10. Account Settings (الإعدادات)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                    child: _buildSettingsSection(context),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الملف الشخصي',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'رفيقك في رحلتك الإيمانية',
              style: TextStyle(
                color: DesignSystem.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا توجد إشعارات جديدة')),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildCircleIconButton(
              icon: Icons.tune_rounded,
              onTap: () => _showGeneralSettings(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DesignSystem.bgCard.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: DesignSystem.goldLight, size: 20),
      ),
    );
  }

  Widget _buildProfileHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1D3A),
            const Color(0xFF071324),
            DesignSystem.bgDarkest,
          ],
        ),
        border: Border.all(
          color: DesignSystem.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.gold.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Islamic Mosque Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/profile_hero.png',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox(height: 220),
            ),
          ),

          // Deep Dark Gradient Overlay
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignSystem.bgDarkest.withValues(alpha: 0.75),
                  DesignSystem.bgDarkest.withValues(alpha: 0.98),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content Layer
          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Avatar with gold ring
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DesignSystem.goldGradient,
                    boxShadow: DesignSystem.goldGlow,
                  ),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF0F2644),
                    child: Icon(Icons.person, color: DesignSystem.goldLight, size: 40),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'مرحباً بك، قارئ القرآن',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: DesignSystem.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: DesignSystem.goldLight, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'رفيق القرآن',
                            style: TextStyle(color: DesignSystem.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '• عضو منذ 2026',
                      style: TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final items = [
          _QuickActionItem(
            icon: Icons.menu_book_rounded,
            title: 'متابعة القرآن',
            subtitle: 'استكمل قراءتك',
            isSpecial: false,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen()));
            },
          ),
          _QuickActionItem(
            icon: Icons.all_inclusive_rounded,
            title: 'السبحة',
            subtitle: 'ابدأ ذكرك الآن',
            isSpecial: true, // Special emerald + gold accent
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen()));
            },
          ),
          _QuickActionItem(
            icon: Icons.auto_awesome_rounded,
            title: 'الأذكار',
            subtitle: 'وردك اليومي',
            isSpecial: false,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen()));
            },
          ),
          _QuickActionItem(
            icon: Icons.favorite_rounded,
            title: 'المفضلة',
            subtitle: 'آياتك المحفوظة',
            isSpecial: false,
            onTap: () {
              setState(() => _selectedTab = 1);
            },
          ),
        ];

        if (isMobile) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildQuickActionCard(items[index]),
          );
        }

        return Row(
          children: items.map((item) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: _buildQuickActionCard(item)))).toList(),
        );
      },
    );
  }

  Widget _buildQuickActionCard(_QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isSpecial ? const Color(0xFF07241A) : DesignSystem.bgCard.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isSpecial ? const Color(0xFF38B982) : Colors.white.withValues(alpha: 0.08),
            width: item.isSpecial ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (item.isSpecial)
              BoxShadow(
                color: const Color(0xFF38B982).withValues(alpha: 0.18),
                blurRadius: 16,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: item.isSpecial ? const Color(0xFF38B982) : DesignSystem.goldLight,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              item.subtitle,
              style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgressSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رحلتي اليوم',
                style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '78% إنجاز اليوم',
                style: TextStyle(color: DesignSystem.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricItem('القرآن', '12 صفحة', Icons.menu_book_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricItem('الأذكار', '18 ذكر', Icons.auto_awesome_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricItem('الصلوات', '5 / 5', Icons.access_time_filled_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricItem('الأحاديث', '3 أحاديث', Icons.library_books_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: DesignSystem.goldLight, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildQuranJourneyCard(BuildContext context, dynamic progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignSystem.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.book_online_rounded, color: DesignSystem.goldLight, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سورة ${progress.lastSurahName}',
                  style: const TextStyle(color: DesignSystem.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'الآية ${progress.lastAyahNumber} • الجزء ${progress.lastJuz}',
                  style: const TextStyle(color: DesignSystem.goldLight, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.gold,
              foregroundColor: DesignSystem.bgDarkest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IqraScreen()));
            },
            child: const Text('متابعة القراءة ←', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildKhatmahAndStreakSection() {
    return Row(
      children: [
        // Khatmah Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignSystem.bgCard.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ختمتي الحالية', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                SizedBox(height: 4),
                Text('37% منجز', style: TextStyle(color: DesignSystem.goldLight, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('المتبقي: 18 يوماً', style: TextStyle(color: DesignSystem.textWhite, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignSystem.bgCard.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سلسلة الأيام 🔥', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
                SizedBox(height: 4),
                Text('12 يوماً متتالياً', style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('واصل الحفظ والتدبر', style: TextStyle(color: DesignSystem.goldLight, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إحصائياتي', style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol('126', 'يوم قراءة'),
              _buildStatCol('1,240', 'صفحة'),
              _buildStatCol('37', 'سورة'),
              _buildStatCol('24', 'ساعة استماع'),
              _buildStatCol('84', 'آية محفوظة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: DesignSystem.goldLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildBookmarksSection(List<dynamic> bookmarks) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المحفوظات', style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildTabBtn('العلامات', 0),
                  const SizedBox(width: 8),
                  _buildTabBtn('المفضلة', 1),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedTab == 0) ...[
            if (bookmarks.isEmpty)
              const Center(child: Text('لا توجد علامات مرجعية', style: TextStyle(color: DesignSystem.textMuted, fontSize: 12)))
            else
              ...bookmarks.take(3).map((b) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark_rounded, color: DesignSystem.goldLight, size: 18),
                  title: Text('سورة ${b.surahName} — آية ${b.ayahNumber}',
                      style: const TextStyle(color: DesignSystem.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(b.ayahSnippet, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
                );
              }),
          ] else ...[
            const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 18),
              title: Text('سورة الكهف • آية 1-10', style: TextStyle(color: DesignSystem.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: Text('قراءة يوم الجمعة نور ما بين الجمعتين', style: TextStyle(color: DesignSystem.textMuted, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? DesignSystem.bgDarkest : DesignSystem.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildIslamicAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF315BEA).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF536DFF), size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المساعد القرآني ✨', style: TextStyle(color: DesignSystem.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('ننصحك اليوم بتدبر سورة يس وورد الاستغفار', style: TextStyle(color: DesignSystem.textMuted, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF536DFF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusPill)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
            },
            child: const Text('تحدث مع المساعد', style: TextStyle(color: Color(0xFF536DFF), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final settings = [
      {'title': 'البيانات الشخصية', 'icon': Icons.person_outline_rounded},
      {'title': 'المظهر والخلفية', 'icon': Icons.palette_outlined},
      {'title': 'الإشعارات والتنبيهات', 'icon': Icons.notifications_none_rounded},
      {'title': 'إعدادات خط القرآن', 'icon': Icons.format_size_rounded},
      {'title': 'الخصوصية والأمان', 'icon': Icons.lock_outline_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الإعدادات', style: TextStyle(color: DesignSystem.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...settings.map((item) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(item['icon'] as IconData, color: DesignSystem.goldLight, size: 20),
                title: Text(item['title'] as String, style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: DesignSystem.textMuted, size: 14),
                onTap: () {
                  if (item['title'] == 'الإشعارات والتنبيهات') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    );
                  } else {
                    _showGeneralSettings(context);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showGeneralSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعدادات بنجاح'),
        backgroundColor: Color(0xFF064E3B),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSpecial;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSpecial,
    required this.onTap,
  });
}