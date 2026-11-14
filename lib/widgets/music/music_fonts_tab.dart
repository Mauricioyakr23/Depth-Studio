import 'package:flutter/cupertino.dart';

import '../../core/core.dart';
import '../../models/app_settings.dart';
import '../studio/dynamic_font_fit_painter.dart';
import '../studio/studio_common_widgets.dart';

class MusicFontsTab extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final bool hasBottomDock;

  const MusicFontsTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.hasBottomDock = true,
  });

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
          IosSectionCard(
            header: AppStrings.secMusicClockFont,
            child: FontSelectorGrid(
              selectedFont: settings.musicClockFont,
              isEnabled: true,
              previewText: '12:30',
              includeBuiltInDisplayFonts: false,
              onFontSelected: (font) =>
                  onSettingsChanged(settings.copyWith(musicClockFont: font)),
            ),
          ),
          IosSectionCard(
            header: AppStrings.secMusicDateFont,
            child: FontSelectorGrid(
              selectedFont: settings.musicDateFont,
              isEnabled: true,
              previewText: 'NOV 12',
              includeBuiltInDisplayFonts: false,
              onFontSelected: (font) =>
                  onSettingsChanged(settings.copyWith(musicDateFont: font)),
            ),
          ),
          IosSectionCard(
            header: AppStrings.secMusicCardFont,
            child: FontSelectorGrid(
              selectedFont: settings.musicCardFont,
              isEnabled: true,
              previewText: 'Music',
              includeBuiltInDisplayFonts: false,
              onFontSelected: (font) =>
                  onSettingsChanged(settings.copyWith(musicCardFont: font)),
            ),
          ),
        ],
      ),
    );
  }
}