import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/app_settings.dart';
import '../preview/glass_optical_utils.dart';
import '../studio/studio_common_widgets.dart';

class MusicMaterialTab extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final bool hasBottomDock;

  const MusicMaterialTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.hasBottomDock = true,
  });

  static const List<String> _modes = [
    'Standard',
    'Liquid',
    'Aero',
    'Acrylic',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppLayout.scrollableTabPadding(
        context,
        top: 4.0,
        hasBottomDock: hasBottomDock,
      ),
      child: Column(
        children: [
          _buildClockMaterialSection(),
          _buildClockRimSection(),
          _buildCardMaterialSection(),
          _buildCardRimSection(),
        ],
      ),
    );
  }

  Widget _buildClockMaterialSection() {
    final int modeIndex =
    _modes.indexOf(settings.musicClockMaterial).clamp(0, 3);
    final bool isGlass =
    GlassOpticalUtils.isGlassMode(settings.musicClockMaterial);

    return IosSectionCard(
      header: AppStrings.secMusicClockMaterial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: GlassSegmentedControl(
              selectedIndex: modeIndex,
              onSegmentSelected: (val) {
                HapticFeedback.selectionClick();
                onSettingsChanged(
                  settings.copyWith(musicClockMaterial: _modes[val]),
                );
              },
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
                  valueText: '${settings.musicClockBlur.toInt()} px',
                  value: settings.musicClockBlur,
                  min: 1.0,
                  max: 40.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicClockBlur: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicClockBlur: 18.0),
                  ),
                ),
                const StudioDivider(),
                StudioSliderRow(
                  label: AppStrings.glassBrightness,
                  valueText:
                  '${(settings.musicClockBrightness * 100).toInt()}%',
                  value: settings.musicClockBrightness,
                  min: 0.0,
                  max: 1.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicClockBrightness: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicClockBrightness: 0.65),
                  ),
                ),
                const StudioDivider(),
              ],
            )
                : const SizedBox.shrink(),
          ),
          StudioSliderRow(
            label: AppStrings.clockOpacity,
            valueText: '${(settings.musicClockOpacity * 100).toInt()}%',
            value: settings.musicClockOpacity,
            min: 0.15,
            max: 1.0,
            isEnabled: true,
            onChanged: (val) => onSettingsChanged(
              settings.copyWith(musicClockOpacity: val),
            ),
            onReset: () => onSettingsChanged(
              settings.copyWith(musicClockOpacity: 1.0),
            ),
          ),
          const StudioDivider(),
          StudioToggleRow(
            label: AppStrings.depthDropShadow,
            value: settings.musicClockShadowEnabled,
            isEnabled: true,
            onChanged: (val) => onSettingsChanged(
              settings.copyWith(musicClockShadowEnabled: val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockRimSection() {
    return IosSectionCard(
      header: AppStrings.secMusicClockRim,
      child: Column(
        children: [
          StudioToggleRow(
            label: AppStrings.enableGlassRim,
            value: settings.musicClockEdgeStrokeEnabled,
            isEnabled: true,
            onChanged: (val) => onSettingsChanged(
              settings.copyWith(musicClockEdgeStrokeEnabled: val),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            child: settings.musicClockEdgeStrokeEnabled
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StudioDivider(),
                StudioSliderRow(
                  label: AppStrings.rimThickness,
                  valueText:
                  '${settings.musicClockRimWidth.toStringAsFixed(1)} px',
                  value: settings.musicClockRimWidth,
                  min: 0.5,
                  max: 8.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicClockRimWidth: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicClockRimWidth: 1.8),
                  ),
                ),
                const StudioDivider(),
                StudioSliderRow(
                  label: AppStrings.rimGlowBlur,
                  valueText:
                  '${settings.musicClockRimBlur.toStringAsFixed(1)} px',
                  value: settings.musicClockRimBlur,
                  min: 0.0,
                  max: 12.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicClockRimBlur: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicClockRimBlur: 0.0),
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMaterialSection() {
    final int modeIndex =
    _modes.indexOf(settings.musicCardMaterial).clamp(0, 3);
    final bool isGlass =
    GlassOpticalUtils.isGlassMode(settings.musicCardMaterial);

    return IosSectionCard(
      header: AppStrings.secMusicCardMaterial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: GlassSegmentedControl(
              selectedIndex: modeIndex,
              onSegmentSelected: (val) {
                HapticFeedback.selectionClick();
                onSettingsChanged(
                  settings.copyWith(musicCardMaterial: _modes[val]),
                );
              },
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
                  valueText: '${settings.musicCardBlur.toInt()} px',
                  value: settings.musicCardBlur,
                  min: 1.0,
                  max: 40.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicCardBlur: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicCardBlur: 18.0),
                  ),
                ),
                const StudioDivider(),
                StudioSliderRow(
                  label: AppStrings.glassBrightness,
                  valueText:
                  '${(settings.musicCardBrightness * 100).toInt()}%',
                  value: settings.musicCardBrightness,
                  min: 0.0,
                  max: 1.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicCardBrightness: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicCardBrightness: 0.65),
                  ),
                ),
                const StudioDivider(),
              ],
            )
                : const SizedBox.shrink(),
          ),
          StudioSliderRow(
            label: AppStrings.clockOpacity,
            valueText: '${(settings.musicCardOpacity * 100).toInt()}%',
            value: settings.musicCardOpacity,
            min: 0.15,
            max: 1.0,
            isEnabled: true,
            onChanged: (val) => onSettingsChanged(
              settings.copyWith(musicCardOpacity: val),
            ),
            onReset: () => onSettingsChanged(
              settings.copyWith(musicCardOpacity: 1.0),
            ),
          ),
          const StudioDivider(),
          StudioToggleRow(
            label: AppStrings.depthDropShadow,
            value: settings.musicCardShadowEnabled,
            isEnabled: true,
            onChanged: (val) => onSettingsChanged(
              settings.copyWith(musicCardShadowEnabled: val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRimSection() {
    return IosSectionCard(
      header: AppStrings.secMusicCardRim,
      child: Column(
        children: [
          StudioToggleRow(
            label: AppStrings.enableGlassRim,
            value: settings.musicCardEdgeStrokeEnabled,
            isEnabled: true,
            onChanged: (val) => onSettingsChanged(
              settings.copyWith(musicCardEdgeStrokeEnabled: val),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            child: settings.musicCardEdgeStrokeEnabled
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StudioDivider(),
                StudioSliderRow(
                  label: AppStrings.rimThickness,
                  valueText:
                  '${settings.musicCardRimWidth.toStringAsFixed(1)} px',
                  value: settings.musicCardRimWidth,
                  min: 0.5,
                  max: 8.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicCardRimWidth: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicCardRimWidth: 1.8),
                  ),
                ),
                const StudioDivider(),
                StudioSliderRow(
                  label: AppStrings.rimGlowBlur,
                  valueText:
                  '${settings.musicCardRimBlur.toStringAsFixed(1)} px',
                  value: settings.musicCardRimBlur,
                  min: 0.0,
                  max: 12.0,
                  isEnabled: true,
                  onChanged: (val) => onSettingsChanged(
                    settings.copyWith(musicCardRimBlur: val),
                  ),
                  onReset: () => onSettingsChanged(
                    settings.copyWith(musicCardRimBlur: 0.0),
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}