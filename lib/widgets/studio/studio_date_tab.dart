import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../../models/wallpaper_config.dart';
import '../../models/wallpaper_data.dart';
import '../../screens/date_position_screen.dart';
import 'dynamic_font_fit_painter.dart';
import 'ios_color_picker_dialog.dart';
import 'studio_common_widgets.dart';

class StudioDateTab extends StatelessWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final List<Color> palette;
  final ValueChanged<WallpaperConfig> onConfigChanged;
  final bool hasBottomDock;

  const StudioDateTab({
    super.key,
    required this.data,
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

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = data.originalImagePath != null;

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
                          SlidePageRoute(
                            child: DatePositionScreen(
                              data: data,
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
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: (38.0 *
                            MediaQuery.textScalerOf(context).scale(1.0))
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
                              onConfigChanged(
                                config.copyWith(dateFormat: fmt),
                              );
                            }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.secondarySurface
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.35),
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
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                          onFontSelected: (font) => onConfigChanged(
                            config.copyWith(dateFontFamily: font),
                          ),
                        ),
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