import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import 'settings_rows.dart';
import 'studio/studio_common_widgets.dart';

class SettingsMusicCard extends StatelessWidget {
  final AppSettings settings;
  final bool hasMusicPermission;
  final ValueChanged<AppSettings> onUpdate;
  final VoidCallback onOpenMusicPermissionSettings;

  const SettingsMusicCard({
    super.key,
    required this.settings,
    required this.hasMusicPermission,
    required this.onUpdate,
    required this.onOpenMusicPermissionSettings,
  });

  static const List<String> _musicPackages = [
    'all',
    'com.apple.android.music',
    'com.google.android.apps.youtube.music',
    'com.spotify.music',
  ];

  @override
  Widget build(BuildContext context) {
    final int musicPkgIndex =
    _musicPackages.indexOf(settings.musicTargetPackage).clamp(0, 3);

    final Color statusColor = hasMusicPermission
        ? const Color(0xFF30D158)
        : const Color(0xFFFF9F0A);

    return IosSectionCard(
      header: AppStrings.secLiveMusic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsToggleRow(
            icon: CupertinoIcons.music_note_2,
            title: AppStrings.liquidAlbumArtTitle,
            subtitle: AppStrings.liquidAlbumArtSub,
            value: settings.musicModeEnabled,
            onChanged: (v) => onUpdate(
              settings.copyWith(musicModeEnabled: v),
            ),
          ),
          const StudioDivider(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasMusicPermission ? null : onOpenMusicPermissionSettings,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.14),
                  ),
                  child: Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.mediaSyncTitle,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasMusicPermission
                            ? AppStrings.musicSyncActive
                            : AppStrings.musicSyncRequired,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasMusicPermission)
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: statusColor,
                    size: 20,
                  )
                else
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            child: !hasMusicPermission
                ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: PressScaleWrapper(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: onOpenMusicPermissionSettings,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.lock_shield_fill,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.musicPermGrantBtn,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            child: settings.musicModeEnabled
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const StudioDivider(),
                Text(
                  AppStrings.targetMusicPlayer,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GlassSegmentedControl(
                    selectedIndex: musicPkgIndex,
                    onSegmentSelected: (val) {
                      HapticFeedback.selectionClick();
                      onUpdate(
                        settings.copyWith(
                          musicTargetPackage: _musicPackages[val],
                        ),
                      );
                    },
                    segments: [
                      GlassSegment(
                        label: AppStrings.isEs ? 'Todas' : 'All',
                      ),
                      const GlassSegment(label: 'Apple'),
                      const GlassSegment(label: 'YT Music'),
                      const GlassSegment(label: 'Spotify'),
                    ],
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