import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';

class ExpandingGlassNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const ExpandingGlassNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class ExpandingGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<ExpandingGlassNavItem> items;

  const ExpandingGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final Color pillTint = AppColors.isLight
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.12);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset + 6 : 16,
      ),
      child: Center(
        heightFactor: 1.0,
        child: GlassContainer(
          quality: GlassQuality.premium,
          useOwnLayer: true,
          shape: const LiquidRoundedSuperellipse(borderRadius: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isSelected = index == selectedIndex;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                  }
                  onTabSelected(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 22 : 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? pillTint : Colors.transparent,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 25,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.centerLeft,
                          child: isSelected
                              ? Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
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
    );
  }
}