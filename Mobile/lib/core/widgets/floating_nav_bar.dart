import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FloatingNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
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

    final backgroundColor = isDark ? AppColors.surfaceTile1 : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return SafeArea(
      bottom: true,
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / items.length;

            return Stack(
              children: [
                // Sliding Active Tab Highlight Pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  left: currentIndex * tabWidth,
                  width: tabWidth,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColors.primary.withValues(alpha: 0.15) 
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),

                // Tab Items
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    const activeColor = AppColors.primary;
                    final inactiveColor = isDark ? Colors.grey.shade500 : const Color(0xFF64748B);

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: AnimatedScale(
                          scale: isSelected ? 1.02 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? activeColor : inactiveColor,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? activeColor : inactiveColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
