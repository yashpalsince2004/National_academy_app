import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FloatingNavBarItem {
  final IconData? icon;
  final IconData? activeIcon;
  final String? customIconPath;
  final String label;

  const FloatingNavBarItem({
    this.icon,
    this.activeIcon,
    this.customIconPath,
    required this.label,
  });
}

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavBarItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define premium color palettes matching the design in the image
    final barBgColor = isDark ? const Color(0xFF131315) : Colors.white;
    final activeBgColor = isDark 
        ? const Color(0xFF2C2C2F) 
        : AppColors.primary.withValues(alpha: 0.08);
    final activeColor = isDark ? Colors.white : AppColors.primary;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF94A3B8);
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.06) 
        : Colors.black.withValues(alpha: 0.04);

    return SafeArea(
      bottom: true,
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: barBgColor,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 20 : 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? activeBgColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    item.customIconPath != null
                        ? Image.asset(
                            item.customIconPath!,
                            width: 24,
                            height: 24,
                            color: isSelected ? activeColor : inactiveColor,
                          )
                        : Icon(
                            isSelected ? item.activeIcon! : item.icon!,
                            color: isSelected ? activeColor : inactiveColor,
                            size: 24,
                          ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      child: ClipRect(
                        child: Container(
                          constraints: isSelected
                              ? const BoxConstraints(maxWidth: 120)
                              : const BoxConstraints(maxWidth: 0),
                          child: isSelected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 8),
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        color: activeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
