import 'dart:ui';
import 'package:flutter/material.dart';

/// Navigation item model for [CustomBottomBar].
class CustomBottomBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
  final bool showBadgeDot;

  const CustomBottomBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.showBadgeDot = false,
  });
}

/// Floating Island style bottom navigation bar with translucent frosted glass dock,
/// transparent outer frame letting screen components flow full till the bottom behind it,
/// enlarged 25px icons, and clean solid terracotta sliding pill (zero glow).
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<CustomBottomBarItem> items;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Translucent frosted glass surface for the floating island dock
    final dockBgColor = isDark
        ? const Color(0xD91E1E22) // Translucent dark carbon
        : const Color(0xE8FFFFFF); // Translucent clean white
    final borderColor = isDark
        ? const Color(0x38FFFFFF)
        : const Color(0x26000000);

    // Selected pill color: rich solid terracotta in both modes, NO blur glow
    const pillColor = Color(0xFFC2410C);

    final activeLabelColor = isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
    final inactiveColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF78716C);

    const dockHeight = 66.0;
    const pillHeight = 32.0;
    const pillWidth = 52.0;
    const topPadding = 9.0;
    const labelSpacing = 3.0;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomInset > 0 ? (bottomInset * 0.45) : 8.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(dockHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: dockHeight,
            decoration: BoxDecoration(
              color: dockBgColor,
              borderRadius: BorderRadius.circular(dockHeight / 2),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final tabWidth = totalWidth / items.length;
                final pillLeft = (tabWidth * currentIndex) + (tabWidth - pillWidth) / 2;

                return Stack(
                  children: [
                    // Smooth sliding active pill indicator (clean solid fill, NO glow)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: topPadding,
                      width: pillWidth,
                      height: pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(pillHeight / 2),
                        ),
                      ),
                    ),

                    // Tab item buttons with unified top alignment and generous touch target
                    Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTabSelected(index),
                            child: SizedBox(
                              height: dockHeight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: topPadding),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Icon container with badge support (matches pill bounds)
                                    SizedBox(
                                      height: pillHeight,
                                      width: pillWidth,
                                      child: Center(
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.center,
                                          children: [
                                            AnimatedScale(
                                              scale: isSelected ? 1.05 : 1.0,
                                              duration: const Duration(milliseconds: 200),
                                              curve: Curves.easeOutCubic,
                                              child: Icon(
                                                isSelected ? item.selectedIcon : item.icon,
                                                size: 22.0,
                                                color: isSelected ? Colors.white : inactiveColor,
                                              ),
                                            ),

                                            // Cart numeric badge
                                            if (item.badgeCount > 0)
                                              Positioned(
                                                top: -2,
                                                right: -6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 4.5,
                                                    vertical: 1.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? (isDark ? const Color(0xFF18181B) : Colors.white)
                                                        : (isDark
                                                            ? const Color(0xFFFB923C)
                                                            : const Color(0xFFC2410C)),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${item.badgeCount}',
                                                    style: TextStyle(
                                                      fontSize: 9.0,
                                                      fontWeight: FontWeight.w700,
                                                      color: isSelected
                                                          ? (isDark ? Colors.white : const Color(0xFFC2410C))
                                                          : Colors.white,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Dot notification badge (e.g. Admin)
                                            if (item.showBadgeDot && item.badgeCount == 0)
                                              Positioned(
                                                top: 1,
                                                right: -3,
                                                child: Container(
                                                  width: 7.0,
                                                  height: 7.0,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : (isDark
                                                            ? const Color(0xFFFB923C)
                                                            : const Color(0xFFC2410C)),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: labelSpacing),

                                    // Text label with animated color & weight
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? activeLabelColor : inactiveColor,
                                        letterSpacing: 0.1,
                                        height: 1.1,
                                      ),
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ),
    );
  }
}
