import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';
import '../state/notifiers/app_notifiers.dart';
import 'circular_glass_icon_button.dart';
import 'liquid_glass.dart';
import 'position_grid_painter.dart';
import 'studio/studio_common_widgets.dart';
import 'wallpaper_preview.dart';

class PositionEditorScaffold extends StatelessWidget {
  final String title;
  final WallpaperData data;
  final WallpaperConfig config;
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
    required this.data,
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
                      child: WallpaperPreview(
                        data: data,
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
                                    child: _buildPresetGrid(controlBoxSize),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildDPad(controlBoxSize),
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

  Widget _buildPresetGrid(double boxHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.presetsLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: boxHeight,
          child: Column(
            children: [
              for (int row = 0; row < 3; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (int col = 0; col < 3; col++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: _presetButton(col, row),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetButton(int col, int row) {
    final bool isSelected =
        (horizontalPos - presetHValues[col]).abs() < 0.03 &&
            (verticalPos - presetVValues[row]).abs() < 0.03;

    return PressScaleWrapper(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onSelectPreset(col, row);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.22)
                : AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.accent, width: 1.2)
                : null,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDPad(double boxSize) {
    final double btnSize = (boxSize * 0.32).clamp(44.0, 48.0);
    final double centerOffset = (boxSize - btnSize) / 2.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppStrings.fineAdjustLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: boxSize,
          height: boxSize,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: centerOffset,
                child: _ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_up,
                  size: btnSize,
                  onTrigger: () => onMoveBy(0, -0.01),
                ),
              ),
              Positioned(
                bottom: 0,
                left: centerOffset,
                child: _ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_down,
                  size: btnSize,
                  onTrigger: () => onMoveBy(0, 0.01),
                ),
              ),
              Positioned(
                left: 0,
                top: centerOffset,
                child: _ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_left,
                  size: btnSize,
                  onTrigger: () => onMoveBy(-0.01, 0),
                ),
              ),
              Positioned(
                right: 0,
                top: centerOffset,
                child: _ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_right,
                  size: btnSize,
                  onTrigger: () => onMoveBy(0.01, 0),
                ),
              ),
              Positioned(
                top: centerOffset,
                left: centerOffset,
                child: PressScaleWrapper(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onResetCenter();
                    },
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        CupertinoIcons.scope,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.divider.withValues(alpha: 0.35),
            thumbColor: Colors.white,
            overlayColor: AppColors.accent.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 11,
              elevation: 3,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
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

class _ContinuousDpadButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTrigger;

  const _ContinuousDpadButton({
    required this.icon,
    required this.size,
    required this.onTrigger,
  });

  @override
  State<_ContinuousDpadButton> createState() => _ContinuousDpadButtonState();
}

class _ContinuousDpadButtonState extends State<_ContinuousDpadButton> {
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      HapticFeedback.selectionClick();
      widget.onTrigger();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScaleWrapper(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTrigger();
        },
        onLongPressStart: (_) {
          HapticFeedback.selectionClick();
          widget.onTrigger();
          _startTimer();
        },
        onLongPressEnd: (_) => _stopTimer(),
        onLongPressCancel: () => _stopTimer(),
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
