import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/wallpaper_config.dart';
import '../../models/wallpaper_data.dart';
import 'studio_common_widgets.dart';

class StudioBackgroundTab extends StatelessWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final VoidCallback onPickBackground;
  final VoidCallback onPickForeground;
  final VoidCallback onRemoveForeground;
  final ValueChanged<WallpaperConfig> onConfigChanged;
  final bool hasBottomDock;

  const StudioBackgroundTab({
    super.key,
    required this.data,
    required this.config,
    required this.onPickBackground,
    required this.onPickForeground,
    required this.onRemoveForeground,
    required this.onConfigChanged,
    this.hasBottomDock = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBg = data.originalImagePath != null;
    final bool hasFg = data.foregroundImagePath != null;
    final bool canUseDepth = hasBg && hasFg;

    final layeringKeys = const ['Standard', 'Hours Forward', 'Minutes Forward'];
    final int layeringIndex = layeringKeys.indexOf(config.depthLayering).clamp(0, 2);

    return SingleChildScrollView(
      padding: AppLayout.scrollableTabPadding(
        context,
        top: 4.0,
        hasBottomDock: hasBottomDock,
      ),
      child: Column(
        children: [
          IosSectionCard(
            header: AppStrings.secWallpaperLayers,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StudioCardActionButton(
                        label: hasBg
                            ? AppStrings.btnChangeBg
                            : AppStrings.btnStep1Bg,
                        icon: CupertinoIcons.photo,
                        isPrimary: !hasBg,
                        onPressed: onPickBackground,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StudioCardActionButton(
                        label: hasFg
                            ? AppStrings.btnChangePng
                            : AppStrings.btnStep2Png,
                        icon: CupertinoIcons.person_crop_rectangle,
                        isPrimary: hasBg && !hasFg,
                        onPressed: onPickForeground,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.fastOutSlowIn,
                  child: hasFg
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StudioDivider(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: onRemoveForeground,
                        child: Text(
                          AppStrings.removeSubjectOverlay,
                          style: const TextStyle(
                            color: Color(0xFFFF453A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          IosSectionCard(
            header: AppStrings.secDepth,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: canUseDepth ? 1.0 : 0.45,
              child: IgnorePointer(
                ignoring: !canUseDepth,
                child: SizedBox(
                  width: double.infinity,
                  child: GlassSegmentedControl(
                    selectedIndex: layeringIndex,
                    onSegmentSelected: (val) {
                      onConfigChanged(
                        config.copyWith(depthLayering: layeringKeys[val]),
                      );
                    },
                    segments: [
                      GlassSegment(label: AppStrings.layerStandard),
                      GlassSegment(label: AppStrings.layerHoursFront),
                      GlassSegment(label: AppStrings.layerMinutesFront),
                    ],
                  ),
                ),
              ),
            ),
          ),

          IosSectionCard(
            header: AppStrings.secBackgroundDim,
            child: StudioSliderRow(
              label: AppStrings.dimBackgroundLabel,
              valueText: '${(config.backgroundDim * 100).toInt()}%',
              value: config.backgroundDim,
              min: 0.0,
              max: 1.0,
              isEnabled: hasBg,
              onChanged: (val) =>
                  onConfigChanged(config.copyWith(backgroundDim: val)),
              onReset: () =>
                  onConfigChanged(config.copyWith(backgroundDim: 0.0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioCardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _StudioCardActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isPrimary
        ? AppColors.accent
        : (AppColors.isLight
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.08));
    final Color fg = isPrimary ? Colors.white : AppColors.textPrimary;

    return PressScaleWrapper(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: bg,
        borderRadius: BorderRadius.circular(12),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}