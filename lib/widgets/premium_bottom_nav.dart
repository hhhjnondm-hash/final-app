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
    // 9 Sections in Exact Order
    final navItems = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
      _NavItem(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'اقرأ'),
      _NavItem(Icons.record_voice_over_outlined, Icons.record_voice_over_rounded, 'المصاحف'),
      _NavItem(Icons.radio_outlined, Icons.radio_rounded, 'الراديو'),
      _NavItem(Icons.access_time_outlined, Icons.access_time_filled, 'المواقيت'),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'القرآن'),
      _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'الأذكار'),
      _NavItem(Icons.library_books_outlined, Icons.library_books_rounded, 'الأحاديث'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'حسابي'),
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
                  return _buildItem(
                    icon: item.icon,
                    activeIcon: item.activeIcon,
                    label: item.label,
                    isSelected: isSelected,
                    isLight: isLight,
                    onTap: () => onTap(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    final activeTextColor = isLight ? const Color(0xFF0F172A) : const Color(0xFF07090E);
    final inactiveTextColor = isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BAE);
    final activeBg = isLight
        ? const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          )
        : const LinearGradient(
            colors: [Color(0xFFFFD56B), Color(0xFFC89B3C)],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? activeBg : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              boxShadow: isSelected && !isLight
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC89B3C).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 19,
                  color: isSelected
                      ? activeTextColor
                      : (isLight ? const Color(0xFF475569) : const Color(0xFFA0AEC0)),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: activeTextColor,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: inactiveTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem(this.icon, this.activeIcon, this.label);
}
