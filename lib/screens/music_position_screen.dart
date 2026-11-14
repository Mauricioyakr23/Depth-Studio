import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/circular_glass_icon_button.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/music/music_canvas_view.dart';
import '../widgets/position/position_dpad_controls.dart';
import '../widgets/position/position_grid_painter.dart';

class MusicPositionScreen extends StatefulWidget {
  final AppSettings settings;
  final int initialTarget;
  final ValueChanged<AppSettings> onSettingsChanged;
  final ValueChanged<int> onTargetChanged;

  const MusicPositionScreen({
    super.key,
    required this.settings,
    required this.initialTarget,
    required this.onSettingsChanged,
    required this.onTargetChanged,
  });

  @override
  State<MusicPositionScreen> createState() => _MusicPositionScreenState();
}

class _MusicPositionScreenState extends State<MusicPositionScreen> {
  static const List<double> _hPresets = [0.25, 0.50, 0.75];
  static const List<double> _coverVPresets = [0.12, 0.28, 0.46];
  static const List<double> _cardVPresets = [0.22, 0.52, 0.78];
  static const List<double> _clockVPresets = [0.06, 0.36, 0.72];

  late AppSettings _draft;
  late int _target;
  bool _panelVisible = true;

  @override
  void initState() {
    super.initState();
    _draft = widget.settings;
    _target = widget.initialTarget.clamp(0, 2);
  }

  double get _curX => _target == 0
      ? _draft.musicCoverX
      : _target == 1
      ? _draft.musicCardX
      : _draft.musicClockX;

  double get _curY => _target == 0
      ? _draft.musicCoverY
      : _target == 1
      ? _draft.musicCardY
      : _draft.musicClockY;

  double get _curScale => _target == 0
      ? _draft.musicCoverScale
      : _target == 1
      ? _draft.musicCardScale
      : _draft.musicClockScale;

  List<double> get _vPresets => _target == 0
      ? _coverVPresets
      : _target == 1
      ? _cardVPresets
      : _clockVPresets;

  void _updateElement({double? x, double? y, double? scale}) {
    setState(() {
      if (_target == 0) {
        _draft = _draft.copyWith(
          musicCoverX: x,
          musicCoverY: y,
          musicCoverScale: scale,
        );
      } else if (_target == 1) {
        _draft = _draft.copyWith(
          musicCardX: x,
          musicCardY: y,
          musicCardScale: scale,
        );
      } else {
        _draft = _draft.copyWith(
          musicClockX: x,
          musicClockY: y,
          musicClockScale: scale,
        );
      }
    });
  }

  void _moveBy(double dx, double dy) {
    _updateElement(
      x: (_curX + dx).clamp(0.10, 0.90),
      y: (_curY + dy).clamp(0.04, 0.88),
    );
  }

  void _resetCenter() {
    _updateElement(
      x: 0.50,
      y: _target == 0
          ? 0.20
          : _target == 1
          ? 0.65
          : 0.14,
    );
  }

  double _computeCanvasShiftY(
      double screenHeight,
      double safeTop,
      double safeBottom,
      double panelHeight,
      ) {
    if (!_panelVisible || screenHeight <= 0) return 0.0;

    final double visibleBottom = screenHeight - panelHeight - safeBottom - 28.0;
    final double elementBottomApprox = (_curY * screenHeight) +
        (_target == 0
            ? screenHeight * 0.22 * _curScale
            : _target == 1
            ? screenHeight * 0.11 * _curScale
            : screenHeight * 0.06 * _curScale);

    if (elementBottomApprox <= visibleBottom) return 0.0;

    final double neededShift = elementBottomApprox - visibleBottom;
    final double maxSafeShift =
    ((_curY * screenHeight) - (safeTop + 68.0)).clamp(0.0, panelHeight);
    return neededShift.clamp(0.0, maxSafeShift);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double safeTop = MediaQuery.paddingOf(context).top;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final bool isCompact = screenSize.height < 700.0;
    final double controlBoxSize = isCompact ? 116.0 : 128.0;
    final double maxPanelHeight =
    (screenSize.height - safeTop - safeBottom - 84.0).clamp(240.0, 390.0);

    final double canvasShiftY = _computeCanvasShiftY(
      screenSize.height,
      safeTop,
      safeBottom,
      maxPanelHeight,
    );

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
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    top: -canvasShiftY,
                    bottom: canvasShiftY,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (details) {
                        if (screenSize.width <= 0 || screenSize.height <= 0) {
                          return;
                        }
                        final double dx =
                            details.delta.dx / (screenSize.width * 1.4);
                        final double dy = details.delta.dy / screenSize.height;
                        _moveBy(dx, dy);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MusicCanvasView(
                            settings: _draft,
                            selectedTarget: _target,
                            onTargetSelected: (t) =>
                                setState(() => _target = t),
                          ),
                          const IgnorePointer(
                            child: CustomPaint(painter: PositionGridPainter()),
                          ),
                        ],
                      ),
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
                                    AppStrings.secMusicTarget,
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
                              icon: _panelVisible
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _panelVisible = !_panelVisible);
                              },
                            ),
                            const SizedBox(width: 8),
                            CircularGlassIconButton(
                              icon: CupertinoIcons.checkmark,
                              isPrimary: true,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                widget.onTargetChanged(_target);
                                widget.onSettingsChanged(_draft);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: AppLayout.screenPaddingH,
                    right: AppLayout.screenPaddingH,
                    bottom: _panelVisible
                        ? (16 + safeBottom)
                        : -(maxPanelHeight + 32 + safeBottom),
                    child: IgnorePointer(
                      ignoring: !_panelVisible,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _panelVisible ? 1.0 : 0.0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxPanelHeight),
                          child: LiquidGlass(
                            useOwnLayer: true,
                            borderRadius: 22,
                            padding: const EdgeInsets.all(14),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: GlassSegmentedControl(
                                      selectedIndex: _target,
                                      onSegmentSelected: (idx) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _target = idx);
                                      },
                                      segments: [
                                        GlassSegment(
                                            label: AppStrings.targetCover),
                                        GlassSegment(
                                            label: AppStrings.targetCard),
                                        GlassSegment(
                                          label: AppStrings.targetClockDate,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: PositionPresetGrid(
                                          boxHeight: controlBoxSize,
                                          horizontalPos: _curX,
                                          verticalPos: _curY,
                                          presetHValues: _hPresets,
                                          presetVValues: _vPresets,
                                          onSelectPreset: (col, row) {
                                            _updateElement(
                                              x: _hPresets[col],
                                              y: _vPresets[row],
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      PositionDPad(
                                        boxSize: controlBoxSize,
                                        onMoveBy: _moveBy,
                                        onResetCenter: _resetCenter,
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Divider(
                                      color: AppColors.divider
                                          .withValues(alpha: 0.35),
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
              '${(_curScale * 100).toInt()}%',
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
            value: _curScale.clamp(0.65, 1.35),
            min: 0.65,
            max: 1.35,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              _updateElement(scale: v);
            },
          ),
        ),
      ],
    );
  }
}