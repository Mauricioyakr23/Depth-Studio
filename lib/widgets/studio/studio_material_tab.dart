import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/wallpaper_config.dart';
import '../../models/wallpaper_data.dart';
import 'studio_common_widgets.dart';

class StudioMaterialTab extends StatelessWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final List<Color> palette;
  final ValueChanged<WallpaperConfig> onConfigChanged;
  final ValueChanged<bool>? onTriggerPreviewAnimation;
  final bool hasBottomDock;

  const StudioMaterialTab({
    super.key,
    required this.data,
    required this.config,
    required this.palette,
    required this.onConfigChanged,
    this.onTriggerPreviewAnimation,
    this.hasBottomDock = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = data.originalImagePath != null;
    final bool isGlass = config.depthMode == 'Liquid' ||
        config.depthMode == 'Acrylic' ||
        config.depthMode == 'Aero';

    final modes = const ['Standard', 'Liquid', 'Aero', 'Acrylic'];
    final int modeIndex = modes.indexOf(config.depthMode).clamp(0, 3);

    final List animStyles = [
      {
        'id': 'None',
        'label': AppStrings.animNone,
        'icon': CupertinoIcons.nosign,
      },
      {
        'id': 'Fade',
        'label': AppStrings.animFade,
        'icon': CupertinoIcons.sparkles,
      },
      {
        'id': 'SlideUp',
        'label': AppStrings.animSlideUp,
        'icon': CupertinoIcons.arrow_up_circle,
      },
      {
        'id': 'SlideDown',
        'label': AppStrings.animSlideDown,
        'icon': CupertinoIcons.arrow_down_circle,
      },
      {
        'id': 'ScaleUp',
        'label': AppStrings.animScaleUp,
        'icon': CupertinoIcons.fullscreen,
      },
      {
        'id': 'ScaleDown',
        'label': AppStrings.animScaleDown,
        'icon': CupertinoIcons.fullscreen_exit,
      },
    ];

    return StudioDisabledWrapper(
      isEnabled: isEnabled,
      child: SingleChildScrollView(
        padding: AppLayout.scrollableTabPadding(
          context,
          top: 4.0,
          hasBottomDock: hasBottomDock,
        ),
        child: Column(
          children: [
            IosSectionCard(
              header: AppStrings.secSurfaceMaterial,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: GlassSegmentedControl(
                      selectedIndex: modeIndex,
                      onSegmentSelected: isEnabled
                          ? (int val) {
                        onConfigChanged(
                          config.copyWith(depthMode: modes[val]),
                        );
                      }
                          : (int _) {},
                      segments: [
                        GlassSegment(label: AppStrings.matSolid),
                        GlassSegment(label: AppStrings.matLiquid),
                        GlassSegment(label: AppStrings.matAero),
                        GlassSegment(label: AppStrings.matAcrylic),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: isGlass
                        ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StudioSliderRow(
                          label: AppStrings.backdropBlur,
                          valueText: '${config.blurAmount.toInt()} px',
                          value: config.blurAmount,
                          min: 1.0,
                          max: 40.0,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(blurAmount: val),
                          ),
                          onReset: () => onConfigChanged(
                            config.copyWith(blurAmount: 18.0),
                          ),
                        ),
                        const StudioDivider(),
                        StudioSliderRow(
                          label: AppStrings.glassBrightness,
                          valueText:
                          '${(config.rimBrightness * 100).toInt()}%',
                          value: config.rimBrightness,
                          min: 0.0,
                          max: 1.0,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(rimBrightness: val),
                          ),
                          onReset: () => onConfigChanged(
                            config.copyWith(rimBrightness: 0.65),
                          ),
                        ),
                        const StudioDivider(),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),
                  StudioSliderRow(
                    label: AppStrings.clockOpacity,
                    valueText: '${(config.textOpacity * 100).toInt()}%',
                    value: config.textOpacity,
                    min: 0.15,
                    max: 1.0,
                    isEnabled: isEnabled,
                    onChanged: (val) =>
                        onConfigChanged(config.copyWith(textOpacity: val)),
                    onReset: () =>
                        onConfigChanged(config.copyWith(textOpacity: 1.0)),
                  ),
                  const StudioDivider(),
                  StudioToggleRow(
                    label: AppStrings.depthDropShadow,
                    value: config.shadowEnabled,
                    isEnabled: isEnabled,
                    onChanged: (val) =>
                        onConfigChanged(config.copyWith(shadowEnabled: val)),
                  ),
                ],
              ),
            ),

            IosSectionCard(
              header: AppStrings.secGlassRim,
              child: Column(
                children: [
                  StudioToggleRow(
                    label: AppStrings.enableGlassRim,
                    value: config.edgeStrokeEnabled,
                    isEnabled: isEnabled,
                    onChanged: (val) => onConfigChanged(
                      config.copyWith(edgeStrokeEnabled: val),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: config.edgeStrokeEnabled
                        ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StudioDivider(),
                        StudioSliderRow(
                          label: AppStrings.rimThickness,
                          valueText:
                          '${config.rimWidth.toStringAsFixed(1)} px',
                          value: config.rimWidth,
                          min: 0.5,
                          max: 8.0,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(rimWidth: val),
                          ),
                          onReset: () => onConfigChanged(
                            config.copyWith(rimWidth: 1.8),
                          ),
                        ),
                        const StudioDivider(),
                        StudioSliderRow(
                          label: AppStrings.rimGlowBlur,
                          valueText:
                          '${config.rimBlur.toStringAsFixed(1)} px',
                          value: config.rimBlur,
                          min: 0.0,
                          max: 12.0,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(rimBlur: val),
                          ),
                          onReset: () => onConfigChanged(
                            config.copyWith(rimBlur: 0.0),
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
              header: AppStrings.secAnimStyle,
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: (54.0 *
                          MediaQuery.textScalerOf(context).scale(1.0))
                          .clamp(54.0, 72.0),
                    ),
                    itemCount: animStyles.length,
                    itemBuilder: (context, index) {
                      final item = animStyles[index];
                      final String id = item['id']! as String;
                      final bool isSelected = config.clockAnimStyle == id;

                      return PressScaleWrapper(
                        child: GestureDetector(
                          onTap: isEnabled
                              ? () {
                            HapticFeedback.selectionClick();
                            onConfigChanged(
                              config.copyWith(clockAnimStyle: id),
                            );
                            if (id != 'None') {
                              onTriggerPreviewAnimation?.call(true);
                            }
                          }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.22)
                                  : AppColors.secondarySurface
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item['icon']! as IconData,
                                  size: 19,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                                const SizedBox(height: 5),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item['label']! as String,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: config.clockAnimStyle != 'None'
                        ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StudioDivider(),
                        StudioSliderRow(
                          label: AppStrings.animDuration,
                          valueText:
                          '${config.clockAnimDuration.toInt()} ms',
                          value: config.clockAnimDuration,
                          min: 200.0,
                          max: 1500.0,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(clockAnimDuration: val),
                          ),
                          onReset: () => onConfigChanged(
                            config.copyWith(clockAnimDuration: 650.0),
                          ),
                        ),
                        const StudioDivider(),
                        StudioToggleRow(
                          label: AppStrings.animOnScreenOn,
                          value: config.animateOnScreenOn,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(animateOnScreenOn: val),
                          ),
                        ),
                        const StudioDivider(),
                        StudioToggleRow(
                          label: AppStrings.animOnUnlock,
                          value: config.animateOnUnlock,
                          isEnabled: isEnabled,
                          onChanged: (val) => onConfigChanged(
                            config.copyWith(animateOnUnlock: val),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: PressScaleWrapper(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  color: AppColors.accent,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  onPressed: isEnabled
                                      ? () => onTriggerPreviewAnimation
                                      ?.call(true)
                                      : null,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.play_fill,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            AppStrings.btnTestAnimIn,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PressScaleWrapper(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  color: AppColors.isLight
                                      ? Colors.black
                                      .withValues(alpha: 0.05)
                                      : Colors.white
                                      .withValues(alpha: 0.08),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  onPressed: isEnabled
                                      ? () => onTriggerPreviewAnimation
                                      ?.call(false)
                                      : null,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.eye_slash_fill,
                                        size: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            AppStrings.btnTestAnimOut,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color:
                                              AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}