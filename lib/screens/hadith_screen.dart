import 'package:flutter/material.dart';
import '../data/hadith_data.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../utils/design_system.dart';
import '../widgets/hadith_card.dart';
import '../widgets/hadith_details_sheet.dart';
import '../widgets/hadith_hero_card.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final HadithService _service = HadithService();
  String _searchQuery = '';
  HadithCategory _selectedCategory = HadithCategory.all;
  String? _selectedBookFilter;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allAhadith = HadithData.ahadith;

    final filteredAhadith = allAhadith.where((h) {
      final matchesCat = _selectedCategory == HadithCategory.all || h.category == _selectedCategory;
      final matchesBook = _selectedBookFilter == null || h.book.contains(_selectedBookFilter!);
      final matchesSearch = _searchQuery.isEmpty ||
          h.text.contains(_searchQuery) ||
          h.narrator.contains(_searchQuery) ||
          h.book.contains(_searchQuery) ||
          h.topic.contains(_searchQuery);
      return matchesCat && matchesBook && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: DesignSystem.bgDarkest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Luxury Header
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

                // 2. Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingL,
                      vertical: DesignSystem.spacingS,
                    ),
                    child: _buildSearchBar(),
                  ),
                ),

                // 3. Hero Section (Artwork + Hadith of the Day)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingL,
                      vertical: DesignSystem.spacingS,
                    ),
                    child: HadithHeroCard(
                      hadith: _service.dailyHadith,
                      onOpenHadithTap: () => _openHadithDetails(_service.dailyHadith),
                      onShareTap: () => _shareHadith(_service.dailyHadith),
                    ),
                  ),
                ),

                // 4. Statistics & Reading Streak Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacingL),
                    child: _buildStatsAndStreakRow(),
                  ),
                ),

                // 5. Horizontal Categories Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacingS),
                    child: _buildCategoriesBar(),
                  ),
                ),

                // 6. Section: أشهر كتب الحديث النبوي
                if (_searchQuery.isEmpty && _selectedCategory == HadithCategory.all) ...[
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
                          const Row(
                            children: [
                              Icon(Icons.library_books_rounded, color: DesignSystem.goldLight, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'أمهات كتب الحديث الشريف',
                                style: TextStyle(
                                  color: DesignSystem.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedBookFilter != null)
                            InkWell(
                              onTap: () => setState(() => _selectedBookFilter = null),
                              child: const Text('إلغاء الفلتر', style: TextStyle(color: DesignSystem.goldLight, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Horizontal Books List
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 125,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                        itemCount: HadithData.books.length,
                        itemBuilder: (context, index) {
                          final book = HadithData.books[index];
                          final isSelected = _selectedBookFilter != null && book.titleArabic.contains(_selectedBookFilter!);

                          return _buildBookCard(book, isSelected);
                        },
                      ),
                    ),
                  ),
                ],

                // 7. Section: الأحاديث الشريفة
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spacingL,
                      DesignSystem.spacingL,
                      DesignSystem.spacingL,
                      DesignSystem.spacingS,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الأحاديث النبوية',
                          style: TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${filteredAhadith.length} حديث',
                          style: const TextStyle(color: DesignSystem.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // 8. Hadith Cards List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                  sliver: filteredAhadith.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(DesignSystem.spacingXL),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.search_off_rounded, color: DesignSystem.textMuted, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'لا توجد أحاديث مطابقة لبحثك',
                                  style: TextStyle(color: DesignSystem.textMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final hadith = filteredAhadith[index];
                              return HadithCard(
                                hadith: hadith,
                                onTap: () => _openHadithDetails(hadith),
                                onShareTap: () => _shareHadith(hadith),
                              );
                            },
                            childCount: filteredAhadith.length,
                          ),
                        ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأحاديث النبوية',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'خير الناس أنفعهم للناس • سنة المصطفى ﷺ',
              style: TextStyle(
                color: DesignSystem.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        style: const TextStyle(color: DesignSystem.textWhite),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: 'ابحث في نصوص الأحاديث، الراوي، أو الباب...',
          hintStyle: const TextStyle(color: DesignSystem.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: DesignSystem.goldLight),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: DesignSystem.textMuted),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsAndStreakRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Column(
            children: [
              _buildStreakCard(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatItem('إجمالي الأحاديث', '42,759', Icons.menu_book_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatItem('أحاديث اليوم', '${_service.todayReadCount}', Icons.today_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatItem('المفضلة', '${_service.favoriteHadithIds.length}', Icons.favorite_rounded)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: _buildStreakCard()),
            const SizedBox(width: 14),
            Expanded(child: _buildStatItem('إجمالي الأحاديث', '42,759', Icons.menu_book_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatItem('أحاديث اليوم', '${_service.todayReadCount}', Icons.today_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatItem('المفضلة', '${_service.favoriteHadithIds.length}', Icons.favorite_rounded)),
          ],
        );
      },
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DesignSystem.gold, width: 2.5),
              color: DesignSystem.gold.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '${_service.readStreakDays}',
                style: const TextStyle(
                  color: DesignSystem.goldLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلسلة القراءة اليومية 🔥',
                  style: TextStyle(
                    color: DesignSystem.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'أحسنت! واصل قراءة الأحاديث يومياً',
                  style: TextStyle(color: DesignSystem.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: DesignSystem.goldLight, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: DesignSystem.goldLight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: DesignSystem.textMuted, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesBar() {
    final categories = [
      {'title': 'كل الأحاديث', 'cat': HadithCategory.all},
      {'title': 'الإيمان والتوحيد', 'cat': HadithCategory.faith},
      {'title': 'الأخلاق والآداب', 'cat': HadithCategory.manners},
      {'title': 'الدعاء والذكر', 'cat': HadithCategory.dua},
      {'title': 'الفقه والعبادات', 'cat': HadithCategory.fiqh},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = _selectedCategory == item['cat'];

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategory = item['cat'] as HadithCategory);
              },
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? DesignSystem.goldGradient : null,
                  color: isSelected ? null : DesignSystem.bgCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                  border: Border.all(
                    color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: isSelected ? DesignSystem.goldGlow : null,
                ),
                child: Center(
                  child: Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected ? DesignSystem.bgDarkest : DesignSystem.textWhite,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookCard(HadithBook book, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBookFilter = isSelected ? null : book.titleArabic.split(' ').last;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignSystem.bgCard.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? DesignSystem.gold : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? DesignSystem.goldGlow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(book.icon, color: isSelected ? DesignSystem.goldLight : DesignSystem.textMuted, size: 22),
            const SizedBox(height: 8),
            Text(
              book.titleArabic,
              style: TextStyle(
                color: isSelected ? DesignSystem.goldLight : DesignSystem.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${book.hadithCount} حديث',
              style: const TextStyle(color: DesignSystem.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _openHadithDetails(HadithItem hadith) {
    _service.markHadithRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HadithDetailsSheet(hadith: hadith),
    );
  }

  void _shareHadith(HadithItem hadith) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ «${hadith.text}» للمشاركة'),
        backgroundColor: const Color(0xFF064E3B),
      ),
    );
  }
}