import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
      _NavItem(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'اقرأ'),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'القرآن'),
      _NavItem(Icons.access_time_outlined, Icons.access_time_filled, 'الصلاة'),
      _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'الأذكار'),
      _NavItem(Icons.headphones_outlined, Icons.headphones_rounded, 'صوتيات'),
      _NavItem(Icons.library_books_outlined, Icons.library_books_rounded, 'أحاديث'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'حسابي'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: DesignSystem.bgCard.withOpacity(0.88),
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: DesignSystem.electricBlue.withOpacity(0.08),
                  blurRadius: 25,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 12 : 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                DesignSystem.electricBlue.withOpacity(0.35),
                                DesignSystem.violet.withOpacity(0.25),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                      border: isSelected
                          ? Border.all(
                              color: DesignSystem.gold.withOpacity(0.55),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.unselectedIcon,
                          color: isSelected
                              ? DesignSystem.goldLight
                              : DesignSystem.textMuted,
                          size: isSelected ? 21 : 19,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 5),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: DesignSystem.textWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final String label;

  _NavItem(this.unselectedIcon, this.selectedIcon, this.label);
}
