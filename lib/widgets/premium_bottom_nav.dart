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
    // 8 Required Sections in Exact Order
    final navItems = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
      _NavItem(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'اقرأ'),
      _NavItem(Icons.record_voice_over_outlined, Icons.record_voice_over_rounded, 'المصاحف الصوتية'),
      _NavItem(Icons.radio_outlined, Icons.radio_rounded, 'الراديو'),
      _NavItem(Icons.access_time_outlined, Icons.access_time_filled, 'مواقيت الصلاة'),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'القرآن الكريم'),
      _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'الأذكار'),
      _NavItem(Icons.library_books_outlined, Icons.library_books_rounded, 'الأحاديث النبوية'),
    ];

    final isLight = DesignSystem.isLightMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0C1017),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isLight ? const Color(0xFFDCE3EC) : const Color(0xFFC89B3C).withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLight
                      ? const Color(0xFF102A43).withOpacity(0.08)
                      : Colors.black.withOpacity(0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                if (!isLight)
                  BoxShadow(
                    color: const Color(0xFFC89B3C).withOpacity(0.12),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = currentIndex == index;

                  if (isSelected) {
                    // Active Pill (#102A43 navy in light, royal gold gradient in dark)
                    return GestureDetector(
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: isLight
                              ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF183B5B)])
                              : const LinearGradient(colors: [Color(0xFFC89B3C), Color(0xFF996515)]),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                          border: Border.all(
                            color: isLight ? const Color(0xFFC89B3C) : const Color(0xFFFFD56B),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isLight
                                  ? const Color(0xFF102A43).withOpacity(0.25)
                                  : const Color(0xFFC89B3C).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.selectedIcon,
                              color: isLight ? const Color(0xFFE8D29A) : const Color(0xFF07090E),
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isLight ? const Color(0xFFE8D29A) : const Color(0xFF07090E),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Inactive Item
                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.unselectedIcon,
                            color: isLight ? const Color(0xFF667085) : const Color(0xFF8C9BAE),
                            size: 19,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF667085) : const Color(0xFF8C9BAE),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
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
