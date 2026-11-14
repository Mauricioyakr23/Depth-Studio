import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../../models/depth_scene_config.dart';
import '../../models/scene_layers.dart';
import '../../state/notifiers/app_notifiers.dart';
import '../circular_glass_icon_button.dart';
import '../liquid_glass.dart';
import '../scene_canvas_preview.dart';
import 'position_dpad_controls.dart';
import 'position_grid_painter.dart';

class PositionEditorScaffold extends StatelessWidget {
  final String title;
  final SceneLayers layers;
  final DepthSceneConfig config;
  final double horizontalPos;
  final double verticalPos;
  final List<double> presetHValues;
  final List<double> presetVValues;
  final double scaleValue;
  final double scaleMin;
  final double scaleMax;
  final String scaleLabelText;
  final void Function(double dx, double dy) onMoveBy;
  final void Function(int col, int row) onSelectPreset;
  final VoidCallback onResetCenter;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onConfirm;

  const PositionEditorScaffold({
    super.key,
    required this.title,
    required this.layers,
    required this.config,
    required this.horizontalPos,
    required this.verticalPos,
    required this.presetHValues,
    required this.presetVValues,
    required this.scaleValue,
    required this.scaleMin,
    required this.scaleMax,
    required this.scaleLabelText,
    required this.onMoveBy,
    required this.onSelectPreset,
    required this.onResetCenter,
    required this.onScaleChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double safeTop = MediaQuery.paddingOf(context).top;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final bool isCompactScreen = screenSize.height < 700.0;
    final double controlBoxSize = isCompactScreen ? 128.0 : 138.0;
    final double maxPanelHeight =
    (screenSize.height - safeTop - safeBottom - 88.0).clamp(190.0, 340.0);

    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, lang, _) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: SceneCanvasPreview(
                        layers: layers,
                        config: config,
                        showFrame: false,
                        animProgress: 1.0,
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: PositionGridPainter()),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppLayout.screenPaddingH,
                          8,
                          AppLayout.screenPaddingH,
                          8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircularGlassIconButton(
                              icon: CupertinoIcons.xmark,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircularGlassIconButton(
                              icon: CupertinoIcons.checkmark,
                              isPrimary: true,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                onConfirm();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppLayout.screenPaddingH,
                    right: AppLayout.screenPaddingH,
                    bottom: 16 + safeBottom,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxPanelHeight),
                      child: LiquidGlass(
                        useOwnLayer: true,
                        borderRadius: 22,
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: PositionPresetGrid(
                                      boxHeight: controlBoxSize,
                                      horizontalPos: horizontalPos,
                                      verticalPos: verticalPos,
                                      presetHValues: presetHValues,
                                      presetVValues: presetVValues,
                                      onSelectPreset: onSelectPreset,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  PositionDPad(
                                    boxSize: controlBoxSize,
                                    onMoveBy: onMoveBy,
                                    onResetCenter: onResetCenter,
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: AppColors.divider.withValues(alpha: 0.35),
                                  height: 1,
                                  thickness: AppLayout.dividerThickness,
                                ),
                              ),
                              _buildScaleSlider(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScaleSlider(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.sizeLabel,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              scaleLabelText,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: AppSliderTheme.of(context),
          child: Slider(
            value: scaleValue.clamp(scaleMin, scaleMax),
            min: scaleMin,
            max: scaleMax,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onScaleChanged(v);
            },
          ),
        ),
      ],
    );
  }
}