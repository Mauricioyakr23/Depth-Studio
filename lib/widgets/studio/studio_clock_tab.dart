import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/wallpaper_config.dart';
import '../../models/wallpaper_data.dart';
import '../../screens/clock_position_screen.dart';
import 'dynamic_font_fit_painter.dart';
import 'ios_color_picker_dialog.dart';
import 'studio_common_widgets.dart';

class StudioClockTab extends StatefulWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final List<Color> palette;
  final ValueChanged<WallpaperConfig> onConfigChanged;
  final bool hasBottomDock;

  const StudioClockTab({
    super.key,
    required this.data,
    required this.config,
    required this.palette,
    required this.onConfigChanged,
    this.hasBottomDock = true,
  });

  @override
  State<StudioClockTab> createState() => _StudioClockTabState();
}

class _StudioClockTabState extends State<StudioClockTab> {
  late bool _separateMinutes;

  @override
  void initState() {
    super.initState();
    _separateMinutes = widget.config.fontColor.toARGB32() !=
        widget.config.minuteColor.toARGB32();
  }

  @override
  void didUpdateWidget(covariant StudioClockTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool hasDiffColors = widget.config.fontColor.toARGB32() !=
        widget.config.minuteColor.toARGB32();
    if (hasDiffColors && !_separateMinutes) {
      _separateMinutes = true;
    }
  }

  void _toggleSeparateMinutes(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _separateMinutes = value);
    if (!value) {
      widget.onConfigChanged(
        widget.config.copyWith(minuteColor: widget.config.fontColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final data = widget.data;
    final bool isEnabled = data.originalImagePath != null;

    final formats = const ['HH:MM', 'HH MM', 'HHMM'];
    final int formatIndex = formats.indexOf(config.clockFormat).clamp(0, 2);

    return StudioDisabledWrapper(
      isEnabled: isEnabled,
      child: SingleChildScrollView(
        padding: AppLayout.scrollableTabPadding(
          context,
          top: 4.0,
          hasBottomDock: widget.hasBottomDock,
        ),
        child: Column(
          children: [
            IosSectionCard(
              header: AppStrings.secClockPosition,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioNavigationTile(
                    icon: CupertinoIcons.move,
                    title: AppStrings.openPositionPicker,
                    subtitle: AppStrings.openPositionPickerSub,
                    isEnabled: isEnabled,
                    onTap: () async {
                      await Navigator.of(context).push(
                        SlidePageRoute(
                          child: ClockPositionScreen(
                            data: data,
                            config: config,
                            onConfigChanged: widget.onConfigChanged,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'H ${(config.horizontalPos * 100).toInt()}% · V ${(config.verticalPos * 100).toInt()}% · ${(config.fontSize * 100).toInt()}%',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            IosSectionCard(
              header: AppStrings.secClockStructure,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.clockDisplay,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: GlassSegmentedControl(
                      selectedIndex: config.clockDisplay == 'Vertical' ? 1 : 0,
                      onSegmentSelected: isEnabled
                          ? (int val) {
                        widget.onConfigChanged(
                          config.copyWith(
                            clockDisplay:
                            val == 1 ? 'Vertical' : 'Horizontal',
                          ),
                        );
                      }
                          : (int _) {},
                      segments: [
                        GlassSegment(label: AppStrings.horizontal),
                        GlassSegment(label: AppStrings.vertical),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: config.clockDisplay == 'Horizontal'
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StudioDivider(),
                        Text(
                          AppStrings.clockStyle,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: GlassSegmentedControl(
                            selectedIndex: formatIndex,
                            onSegmentSelected: isEnabled
                                ? (int val) {
                              widget.onConfigChanged(
                                config.copyWith(
                                  clockFormat: formats[val],
                                ),
                              );
                            }
                                : (int _) {},
                            segments: const [
                              GlassSegment(label: '12:30'),
                              GlassSegment(label: '12 30'),
                              GlassSegment(label: '1230'),
                            ],
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
              header: AppStrings.secTypeface,
              child: FontSelectorGrid(
                selectedFont: config.fontFamily,
                isEnabled: isEnabled,
                onFontSelected: (font) =>
                    widget.onConfigChanged(config.copyWith(fontFamily: font)),
              ),
            ),

            IosSectionCard(
              header: AppStrings.secClockColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudioToggleRow(
                    label: AppStrings.separateMinutes,
                    value: _separateMinutes,
                    isEnabled: isEnabled,
                    onChanged: _toggleSeparateMinutes,
                  ),
                  const StudioDivider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _separateMinutes
                              ? AppStrings.hourColor
                              : AppStrings.clockUnifiedColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      HexColorTriggerButton(
                        currentColor: config.fontColor,
                        isEnabled: isEnabled,
                        palette: widget.palette,
                        onColorPicked: (c) {
                          widget.onConfigChanged(
                            _separateMinutes
                                ? config.copyWith(fontColor: c)
                                : config.copyWith(
                              fontColor: c,
                              minuteColor: c,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PaletteColorRow(
                    selectedColor: config.fontColor,
                    isEnabled: isEnabled,
                    palette: widget.palette,
                    onColorSelected: (c) {
                      widget.onConfigChanged(
                        _separateMinutes
                            ? config.copyWith(fontColor: c)
                            : config.copyWith(fontColor: c, minuteColor: c),
                      );
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: _separateMinutes
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StudioDivider(),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                AppStrings.minuteColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            HexColorTriggerButton(
                              currentColor: config.minuteColor,
                              isEnabled: isEnabled,
                              palette: widget.palette,
                              onColorPicked: (c) =>
                                  widget.onConfigChanged(
                                    config.copyWith(minuteColor: c),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        PaletteColorRow(
                          selectedColor: config.minuteColor,
                          isEnabled: isEnabled,
                          palette: widget.palette,
                          onColorSelected: (c) =>
                              widget.onConfigChanged(
                                config.copyWith(minuteColor: c),
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
              header: AppStrings.secFontProportions,
              child: Column(
                children: [
                  StudioSliderRow(
                    label: AppStrings.letterSpacing,
                    valueText: config.letterSpacing.toStringAsFixed(2),
                    value: config.letterSpacing,
                    min: -0.15,
                    max: 0.30,
                    isEnabled: isEnabled,
                    onChanged: (val) => widget.onConfigChanged(
                      config.copyWith(letterSpacing: val),
                    ),
                    onReset: () => widget.onConfigChanged(
                      config.copyWith(letterSpacing: 0.0),
                    ),
                  ),
                  const StudioDivider(),
                  StudioSliderRow(
                    label: AppStrings.verticalStretch,
                    valueText: '${(config.stretch * 100).toInt()}%',
                    value: config.stretch,
                    min: 0.5,
                    max: 2.0,
                    isEnabled: isEnabled,
                    onChanged: (val) => widget.onConfigChanged(
                      config.copyWith(stretch: val),
                    ),
                    onReset: () => widget.onConfigChanged(
                      config.copyWith(stretch: 1.0),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: config.clockDisplay == 'Vertical'
                        ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StudioDivider(),
                        StudioSliderRow(
                          label: AppStrings.hoursMinutesGap,
                          valueText:
                          '${(config.lineSpacing * 100).toInt()}%',
                          value: config.lineSpacing,
                          min: -0.05,
                          max: 0.35,
                          isEnabled: isEnabled,
                          onChanged: (val) => widget.onConfigChanged(
                            config.copyWith(lineSpacing: val),
                          ),
                          onReset: () => widget.onConfigChanged(
                            config.copyWith(lineSpacing: 0.04),
                          ),
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