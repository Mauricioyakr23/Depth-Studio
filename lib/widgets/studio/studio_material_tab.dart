import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/depth_scene_config.dart';
import '../../models/scene_layers.dart';
import '../preview/glass_optical_utils.dart';
import 'studio_animation_card.dart';
import 'studio_common_widgets.dart';

class StudioMaterialTab extends StatelessWidget {
  final SceneLayers layers;
  final DepthSceneConfig config;
  final List<Color> palette;
  final ValueChanged<DepthSceneConfig> onConfigChanged;
  final ValueChanged<bool>? onTriggerPreviewAnimation;
  final bool hasBottomDock;

  const StudioMaterialTab({
    super.key,
    required this.layers,
    required this.config,
    required this.palette,
    required this.onConfigChanged,
    this.onTriggerPreviewAnimation,
    this.hasBottomDock = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = layers.hasBackground;
    final bool isGlass = GlassOpticalUtils.isGlassMode(config.depthMode);

    final modes = const ['Standard', 'Liquid', 'Aero', 'Acrylic'];
    final int modeIndex = modes.indexOf(config.depthMode).clamp(0, 3);

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
            StudioAnimationCard(
              config: config,
              isEnabled: isEnabled,
              onConfigChanged: onConfigChanged,
              onTriggerPreviewAnimation: onTriggerPreviewAnimation,
            ),
          ],
        ),
      ),
    );
  }
}