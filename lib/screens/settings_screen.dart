import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../services/platform_channel.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/settings_music_card.dart';
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
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appSettingsNotifier.addListener(_onGlobalSettingsChanged);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appSettingsNotifier.removeListener(_onGlobalSettingsChanged);
    super.dispose();
  }

  void _onGlobalSettingsChanged() {
    if (!mounted) return;
    if (_settings != appSettingsNotifier.value) {
      setState(() => _settings = appSettingsNotifier.value);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMusicPermission();
    }
  }

  Future<void> _load() async {
    final s = await AppSettings.load();
    final version = await PlatformChannel.getAppVersion();
    await _checkMusicPermission();
    if (mounted) {
      appSettingsNotifier.value = s;
      setState(() {
        _settings = s;
        _appVersion = version;
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
    appSettingsNotifier.value = updated;
    appThemeNotifier.value = updated.themeMode;
    final bool synced = await PlatformChannel.syncAppPreferences(updated);
    if (!synced && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppStrings.syncSettingsError),
            action: SnackBarAction(
              label: AppStrings.retryBtn,
              onPressed: () => _update(updated),
            ),
          ),
        );
    }
    widget.onSettingsChanged?.call();
  }

  Future<void> _changeLanguage(String langCode) async {
    HapticFeedback.selectionClick();
    appLanguageNotifier.value = langCode;
    final updated = _settings.copyWith(languageCode: langCode);
    setState(() => _settings = updated);
    await updated.save();
    appSettingsNotifier.value = updated;
    final bool synced = await PlatformChannel.syncAppPreferences(updated);
    if (!synced && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppStrings.syncSettingsError),
            action: SnackBarAction(
              label: AppStrings.retryBtn,
              onPressed: () => _changeLanguage(langCode),
            ),
          ),
        );
    }
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
            const themeModes = ['dark', 'amoled', 'light'];
            final int themeIndex =
            themeModes.indexOf(_settings.themeMode).clamp(0, 2);

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
                          SettingsMusicCard(
                            settings: _settings,
                            hasMusicPermission: _hasMusicPermission,
                            onUpdate: _update,
                            onOpenMusicPermissionSettings:
                            _openMusicPermissionSettings,
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
                                      GlassTransitionRoute(
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
                                  trailing: _appVersion,
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