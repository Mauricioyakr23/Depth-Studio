import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';

import '../../core/core.dart';
import '../../models/app_settings.dart';
import '../../screens/music_position_screen.dart';
import '../studio/studio_common_widgets.dart';

class MusicLayoutTab extends StatelessWidget {
  final AppSettings settings;
  final int selectedTarget;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<AppSettings> onSettingsChanged;
  final bool hasBottomDock;

  const MusicLayoutTab({
    super.key,
    required this.settings,
    required this.selectedTarget,
    required this.onTargetChanged,
    required this.onSettingsChanged,
    this.hasBottomDock = true,
  });

  @override
  Widget build(BuildContext context) {
    final String summary =
        '${AppStrings.targetCover} ${(settings.musicCoverScale * 100).toInt()}% · '
        '${AppStrings.targetCard} ${(settings.musicCardScale * 100).toInt()}% · '
        '${AppStrings.targetClockDate} ${(settings.musicClockScale * 100).toInt()}%';

    return SingleChildScrollView(
      padding: AppLayout.scrollableTabPadding(
        context,
        top: 4.0,
        hasBottomDock: hasBottomDock,
      ),
      child: IosSectionCard(
        header: AppStrings.secClockPosition,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioNavigationTile(
              icon: CupertinoIcons.move,
              title: AppStrings.openPositionPicker,
              subtitle: AppStrings.openPositionPickerSub,
              isEnabled: true,
              onTap: () async {
                await Navigator.of(context).push(
                  GlassTransitionRoute(
                    child: MusicPositionScreen(
                      settings: settings,
                      initialTarget: selectedTarget,
                      onTargetChanged: onTargetChanged,
                      onSettingsChanged: onSettingsChanged,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    );
  }
}