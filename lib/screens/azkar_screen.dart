import 'package:flutter/material.dart';
import '../data/all_azkar_data.dart';
import '../models/azkar_models.dart';
import '../services/azkar_service.dart';
import '../utils/design_system.dart';
import '../widgets/dhikr_category_card.dart';
import '../widgets/dhikr_hero_card.dart';
import '../widgets/dhikr_wird_card.dart';
import 'dhikr_reader_screen.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  final AzkarService _azkarService = AzkarService();
  String _searchQuery = '';
  AzkarCategoryType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _azkarService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _azkarService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = AllAzkarData.categories;
    final allAzkar = AllAzkarData.getAllAzkar();
    final favorites = _azkarService.getFavorites();

    // Filtered azkar if searching
    final searchResults = _searchQuery.isEmpty
        ? []
        : allAzkar.where((d) {
            return d.title.contains(_searchQuery) ||
                d.text.contains(_searchQuery) ||
                (d.fadl?.contains(_searchQuery) ?? false);
          }).toList();

    return Scaffold(
      body: Container(
        decoration: DesignSystem.radialGlowBackground(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top Minimal Luxury Header
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

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacingL,
                        vertical: DesignSystem.spacingS,
                      ),
                      child: _buildSearchBar(),
                    ),
                  ),

                  // If searching, show search results
                  if (_searchQuery.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.all(DesignSystem.spacingL),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dhikr = searchResults[index];
                            return _buildSearchResultTile(context, dhikr);
                          },
                          childCount: searchResults.length,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Hero Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSystem.spacingL,
                          vertical: DesignSystem.spacingS,
                        ),
                        child: DhikrHeroCard(
                          onContinueTap: () {
                            _openCategory(context, categories[0]);
                          },
                        ),
                      ),
                    ),

                    // Daily Wird Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSystem.spacingL,
                          vertical: DesignSystem.spacingS,
                        ),
                        child: DhikrWirdCard(
                          onContinueTap: () {
                            _openCategory(context, categories[0]);
                          },
                        ),
                      ),
                    ),

                    // Section Title: الأقسام الرئيسية
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DesignSystem.spacingL,
                          DesignSystem.spacingM,
                          DesignSystem.spacingL,
                          DesignSystem.spacingS,
                        ),
                        child: const Text(
                          'أقسام الأذكار الرئيسية',
                          style: TextStyle(
                            color: DesignSystem.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 4 Main Feature Cards Grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final category = categories[index];
                            return DhikrCategoryCard(
                              category: category,
                              onTap: () => _openCategory(context, category),
                            );
                          },
                          childCount: categories.length,
                        ),
                      ),
                    ),

                    // Section Title: أذكارك المفضلة
                    if (favorites.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DesignSystem.spacingL,
                            DesignSystem.spacingL,
                            DesignSystem.spacingL,
                            DesignSystem.spacingS,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'أذكارك المفضلة',
                                style: TextStyle(
                                  color: DesignSystem.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingL),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dhikr = favorites[index];
                              return _buildFavoriteCompactCard(context, dhikr);
                            },
                            childCount: favorites.length,
                          ),
                        ),
                      ),
                    ],
                  ],

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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأذكار',
              style: TextStyle(
                color: DesignSystem.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'حصن المسلم ورفيقك اليومي لذكر الله',
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
            _buildHeaderCircleButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تفعيل التذكير اليومي للأذكار')),
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
          hintText: 'ابحث في الأذكار أو الفضل أو المصدر...',
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

  Widget _buildSearchResultTile(BuildContext context, DhikrItem dhikr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(color: DesignSystem.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dhikr.title,
            style: const TextStyle(color: DesignSystem.goldLight, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            dhikr.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: DesignSystem.textWhite, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCompactCard(BuildContext context, DhikrItem dhikr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dhikr.title,
                  style: const TextStyle(
                    color: DesignSystem.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dhikr.repetitionText,
                  style: const TextStyle(color: DesignSystem.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: DesignSystem.goldLight, size: 14),
            onPressed: () {
              final cat = AllAzkarData.categories.firstWhere((c) => c.type == dhikr.category);
              _openCategory(context, cat);
            },
          ),
        ],
      ),
    );
  }

  void _openCategory(BuildContext context, AzkarCategoryMeta category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DhikrReaderScreen(category: category),
      ),
    );
  }
}