import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/depth_scene_config.dart';
import '../../models/scene_layers.dart';
import '../../screens/date_position_screen.dart';
import '../preview/glass_optical_utils.dart';
import 'color_picker/color_picker_triggers.dart';
import 'dynamic_font_fit_painter.dart';
import 'studio_common_widgets.dart';

class StudioDateTab extends StatelessWidget {
  final SceneLayers layers;
  final DepthSceneConfig config;
  final List<Color> palette;
  final ValueChanged<DepthSceneConfig> onConfigChanged;
  final bool hasBottomDock;

  const StudioDateTab({
    super.key,
    required this.layers,
    required this.config,
    required this.palette,
    required this.onConfigChanged,
    this.hasBottomDock = true,
  });

  static const List<String> _dateFormats = [
    'EEE, MMM dd',
    'EEEE, MMMM dd',
    'MMM dd, yyyy',
    'dd/MM/yyyy',
  ];

  static const List<String> _modes = [
    'Standard',
    'Liquid',
    'Aero',
    'Acrylic',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = layers.hasBackground;
    final bool isDateGlass = GlassOpticalUtils.isGlassMode(config.dateDepthMode);
    final int modeIndex = _modes.indexOf(config.dateDepthMode).clamp(0, 3);

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
              header: AppStrings.secDateVisibility,
              child: Column(
                children: [
                  StudioToggleRow(
                    label: AppStrings.showDate,
                    value: config.showDate,
                    isEnabled: isEnabled,
                    onChanged: (val) =>
                        onConfigChanged(config.copyWith(showDate: val)),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.fastOutSlowIn,
                    child: config.showDate
                        ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StudioDivider(),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStyleToggleChip(
                                label: AppStrings.uppercaseText,
                                icon: CupertinoIcons.textformat_abc,
                                isSelected: config.dateAllCaps,
                                isEnabled: isEnabled,
                                onTap: () => onConfigChanged(
                                  config.copyWith(
                                    dateAllCaps: !config.dateAllCaps,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CompactStyleToggleChip(
                                label: AppStrings.boldWeight,
                                icon: CupertinoIcons.bold,
                                isSelected: config.dateBold,
                                isEnabled: isEnabled,
                                onTap: () => onConfigChanged(
                                  config.copyWith(
                                    dateBold: !config.dateBold,
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
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.fastOutSlowIn,
              child: config.showDate
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IosSectionCard(
                    header: AppStrings.secDatePosScale,
                    child: StudioNavigationTile(
                      icon: CupertinoIcons.move,
                      title: AppStrings.openDatePositionPicker,
                      subtitle: AppStrings.openDatePositionPickerSub,
                      isEnabled: isEnabled,
                      onTap: () async {
                        await Navigator.of(context).push(
                          GlassTransitionRoute(
                            child: DatePositionScreen(
                              layers: layers,
                              config: config,
                              onConfigChanged: onConfigChanged,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IosSectionCard(
                    header: AppStrings.secDateFormat,
                    child: _buildFormatGrid(context, isEnabled),
                  ),
                  IosSectionCard(
                    header: AppStrings.secDateColorAndFont,
                    trailingHeader: HexColorTriggerButton(
                      currentColor: config.dateColor,
                      isEnabled: isEnabled,
                      palette: palette,
                      onColorPicked: (c) =>
                          onConfigChanged(config.copyWith(dateColor: c)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaletteColorRow(
                          selectedColor: config.dateColor,
                          isEnabled: isEnabled,
                          palette: palette,
                          onColorSelected: (color) => onConfigChanged(
                            config.copyWith(dateColor: color),
                          ),
                        ),
                        const StudioDivider(),
                        FontSelectorGrid(
                          selectedFont: config.dateFontFamily,
                          isEnabled: isEnabled,
                          previewText: 'MON 24',
                          includeBuiltInDisplayFonts: false,
                          onFontSelected: (font) => onConfigChanged(
                            config.copyWith(dateFontFamily: font),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IosSectionCard(
                    header: AppStrings.secDateMaterial,
                    child: _buildDateMaterialControls(
                      isEnabled: isEnabled,
                      isDateGlass: isDateGlass,
                      modeIndex: modeIndex,
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatGrid(BuildContext context, bool isEnabled) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent:
        (38.0 * MediaQuery.textScalerOf(context).scale(1.0))
            .clamp(38.0, 52.0),
      ),
      itemCount: _dateFormats.length,
      itemBuilder: (context, idx) {
        final fmt = _dateFormats[idx];
        final bool isSelected = config.dateFormat == fmt;
        return PressScaleWrapper(
          child: GestureDetector(
            onTap: isEnabled
                ? () {
              HapticFeedback.selectionClick();
              onConfigChanged(config.copyWith(dateFormat: fmt));
            }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.secondarySurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fmt,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateMaterialControls({
    required bool isEnabled,
    required bool isDateGlass,
    required int modeIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: GlassSegmentedControl(
            selectedIndex: modeIndex,
            onSegmentSelected: isEnabled
                ? (int val) {
              onConfigChanged(
                config.copyWith(dateDepthMode: _modes[val]),
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
          child: isDateGlass
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioSliderRow(
                label: AppStrings.backdropBlur,
                valueText: '${config.dateBlurAmount.toInt()} px',
                value: config.dateBlurAmount,
                min: 1.0,
                max: 40.0,
                isEnabled: isEnabled,
                onChanged: (val) => onConfigChanged(
                  config.copyWith(dateBlurAmount: val),
                ),
                onReset: () => onConfigChanged(
                  config.copyWith(dateBlurAmount: 18.0),
                ),
              ),
              const StudioDivider(),
              StudioSliderRow(
                label: AppStrings.glassBrightness,
                valueText:
                '${(config.dateRimBrightness * 100).toInt()}%',
                value: config.dateRimBrightness,
                min: 0.0,
                max: 1.0,
                isEnabled: isEnabled,
                onChanged: (val) => onConfigChanged(
                  config.copyWith(dateRimBrightness: val),
                ),
                onReset: () => onConfigChanged(
                  config.copyWith(dateRimBrightness: 0.65),
                ),
              ),
              const StudioDivider(),
            ],
          )
              : const SizedBox.shrink(),
        ),
        StudioSliderRow(
          label: AppStrings.dateOpacity,
          valueText: '${(config.dateOpacity * 100).toInt()}%',
          value: config.dateOpacity,
          min: 0.15,
          max: 1.0,
          isEnabled: isEnabled,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(dateOpacity: val)),
          onReset: () => onConfigChanged(config.copyWith(dateOpacity: 1.0)),
        ),
        const StudioDivider(),
        StudioToggleRow(
          label: AppStrings.depthDropShadow,
          value: config.dateShadowEnabled,
          isEnabled: isEnabled,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(dateShadowEnabled: val)),
        ),
      ],
    );
  }
}

class _CompactStyleToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _CompactStyleToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScaleWrapper(
      child: GestureDetector(
        onTap: isEnabled
            ? () {
          HapticFeedback.selectionClick();
          onTap();
        }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.22)
                : AppColors.secondarySurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}