import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../services/platform_channel.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/settings_rows.dart';
import '../widgets/studio/studio_common_widgets.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  final bool isEmbeddedInDock;

  const SettingsScreen({
    super.key,
    this.onSettingsChanged,
    this.isEmbeddedInDock = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  AppSettings _settings = const AppSettings();
  bool _loaded = false;
  bool _hasMusicPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMusicPermission();
    }
  }

  Future<void> _load() async {
    final s = await AppSettings.load();
    await _checkMusicPermission();
    if (mounted) {
      setState(() {
        _settings = s;
        _loaded = true;
      });
    }
  }

  Future<void> _checkMusicPermission() async {
    final bool granted = await PlatformChannel.isMusicPermissionGranted();
    if (mounted) {
      setState(() => _hasMusicPermission = granted);
    }
  }

  Future<void> _openMusicPermissionSettings() async {
    HapticFeedback.mediumImpact();
    await PlatformChannel.openMusicPermissionSettings();
  }

  Future<void> _update(AppSettings updated) async {
    setState(() => _settings = updated);
    await updated.save();
    appThemeNotifier.value = updated.themeMode;
    await PlatformChannel.updateGlobalSettings(updated);
    widget.onSettingsChanged?.call();
  }

  Future<void> _changeLanguage(String langCode) async {
    HapticFeedback.selectionClick();
    appLanguageNotifier.value = langCode;
    final updated = _settings.copyWith(languageCode: langCode);
    setState(() => _settings = updated);
    await updated.save();
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, currentLang, _) {
            final themeModes = const ['dark', 'amoled', 'light'];
            final int themeIndex = themeModes
                .indexOf(_settings.themeMode)
                .clamp(0, 2);

            final musicPackages = const [
              'all',
              'com.apple.android.music',
              'com.google.android.apps.youtube.music',
              'com.spotify.music',
            ];
            final int musicPkgIndex = musicPackages
                .indexOf(_settings.musicTargetPackage)
                .clamp(0, 3);

            final Color statusColor = _hasMusicPermission
                ? const Color(0xFF30D158)
                : const Color(0xFFFF9F0A);

            final Widget screenContent = SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.screenPaddingH,
                      18,
                      AppLayout.screenPaddingH,
                      12,
                    ),
                    child: Text(
                      AppStrings.settingsHeader,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  if (!_loaded)
                    const Expanded(
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else
                    Expanded(
                      child: ListView(
                        padding: AppLayout.scrollableTabPadding(
                          context,
                          top: 4.0,
                          hasBottomDock: widget.isEmbeddedInDock,
                        ),
                        children: [
                          IosSectionCard(
                            header: AppStrings.secLiveMusic,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SettingsToggleRow(
                                  icon: CupertinoIcons.music_note_2,
                                  title: AppStrings.liquidAlbumArtTitle,
                                  subtitle: AppStrings.liquidAlbumArtSub,
                                  value: _settings.musicModeEnabled,
                                  onChanged: (v) => _update(
                                    _settings.copyWith(musicModeEnabled: v),
                                  ),
                                ),
                                const StudioDivider(),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _hasMusicPermission
                                      ? null
                                      : _openMusicPermissionSettings,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: statusColor.withValues(
                                            alpha: 0.14,
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.isEs
                                                  ? 'Sincronización multimedia'
                                                  : 'Media sync',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _hasMusicPermission
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
                                      if (_hasMusicPermission)
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
                                  child: !_hasMusicPermission
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: PressScaleWrapper(
                                              child: CupertinoButton(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 11,
                                                ),
                                                color: AppColors.accent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onPressed:
                                                    _openMusicPermissionSettings,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      CupertinoIcons
                                                          .lock_shield_fill,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          AppStrings
                                                              .musicPermGrantBtn,
                                                          maxLines: 1,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13.5,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                  child: _settings.musicModeEnabled
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                  HapticFeedback
                                                      .selectionClick();
                                                  _update(
                                                    _settings.copyWith(
                                                      musicTargetPackage:
                                                          musicPackages[val],
                                                    ),
                                                  );
                                                },
                                                segments: [
                                                  GlassSegment(
                                                    label: AppStrings.isEs
                                                        ? 'Todas'
                                                        : 'All',
                                                  ),
                                                  const GlassSegment(
                                                    label: 'Apple',
                                                  ),
                                                  const GlassSegment(
                                                    label: 'YT Music',
                                                  ),
                                                  const GlassSegment(
                                                    label: 'Spotify',
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

                          IosSectionCard(
                            header: AppStrings.secAppTheme,
                            child: SizedBox(
                              width: double.infinity,
                              child: GlassSegmentedControl(
                                selectedIndex: themeIndex,
                                onSegmentSelected: (val) {
                                  _update(
                                    _settings.copyWith(
                                      themeMode: themeModes[val],
                                    ),
                                  );
                                },
                                segments: [
                                  GlassSegment(label: AppStrings.themeDark),
                                  const GlassSegment(label: 'AMOLED'),
                                  GlassSegment(label: AppStrings.themeLight),
                                ],
                              ),
                            ),
                          ),

                          IosSectionCard(
                            header: AppStrings.secLanguageHeader,
                            child: SizedBox(
                              width: double.infinity,
                              child: GlassSegmentedControl(
                                selectedIndex: currentLang == 'en' ? 1 : 0,
                                onSegmentSelected: (val) {
                                  _changeLanguage(val == 1 ? 'en' : 'es');
                                },
                                segments: const [
                                  GlassSegment(label: 'Español'),
                                  GlassSegment(label: 'English'),
                                ],
                              ),
                            ),
                          ),

                          IosSectionCard(
                            header: AppStrings.secClockDisplayHeader,
                            child: Column(
                              children: [
                                SettingsToggleRow(
                                  icon: CupertinoIcons.device_phone_portrait,
                                  title: AppStrings.homescreenClock,
                                  subtitle: AppStrings.homescreenClockSub,
                                  value: _settings.homescreenClock,
                                  onChanged: (v) => _update(
                                    _settings.copyWith(homescreenClock: v),
                                  ),
                                ),
                                const StudioDivider(),
                                SettingsToggleRow(
                                  icon: CupertinoIcons.clock,
                                  title: AppStrings.use24HourFormat,
                                  subtitle: AppStrings.use24HourFormatSub,
                                  value: _settings.use24Hour,
                                  onChanged: (v) => _update(
                                    _settings.copyWith(use24Hour: v),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IosSectionCard(
                            header: AppStrings.secAboutHeader,
                            child: Column(
                              children: [
                                SettingsActionRow(
                                  icon: CupertinoIcons.sparkles,
                                  title: AppStrings.replayOnboarding,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      SlidePageRoute(
                                        child: OnboardingScreen(
                                          isReplay: true,
                                          onComplete: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const StudioDivider(),
                                SettingsInfoRow(
                                  icon: CupertinoIcons.info_circle,
                                  title: AppStrings.versionLabel,
                                  trailing: '1.1.0',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

            if (widget.isEmbeddedInDock) {
              return screenContent;
            }

            return Scaffold(
              backgroundColor: AppColors.bg,
              body: screenContent,
            );
          },
        );
      },
    );
  }
}
