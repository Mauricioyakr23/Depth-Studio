import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../services/custom_font_service.dart';
import '../services/platform_channel.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/music/music_fonts_tab.dart';
import '../widgets/music/music_layout_tab.dart';
import '../widgets/music/music_material_tab.dart';
import '../widgets/music/music_preview_box.dart';
import '../widgets/studio/studio_common_widgets.dart';

class MusicScreen extends StatefulWidget {
  final bool isEmbeddedInDock;

  const MusicScreen({
    super.key,
    this.isEmbeddedInDock = false,
  });

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  AppSettings _settings = const AppSettings();
  AppSettings? _persisted;
  bool _loaded = false;
  bool _justApplied = false;
  Timer? _appliedBannerTimer;
  int _selectedSegment = 0;
  int _selectedTarget = 0;

  bool get _isDirty => _persisted != null && _settings != _persisted;

  @override
  void initState() {
    super.initState();
    CustomFontService.fontsVersionNotifier.addListener(_onFontsVersionChanged);
    appSettingsNotifier.addListener(_onGlobalSettingsChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _appliedBannerTimer?.cancel();
    CustomFontService.fontsVersionNotifier.removeListener(_onFontsVersionChanged);
    appSettingsNotifier.removeListener(_onGlobalSettingsChanged);
    super.dispose();
  }

  void _onGlobalSettingsChanged() {
    if (!mounted) return;
    final global = appSettingsNotifier.value;
    setState(() {
      _settings = _settings.copyWith(
        homescreenClock: global.homescreenClock,
        use24Hour: global.use24Hour,
        themeMode: global.themeMode,
        musicModeEnabled: global.musicModeEnabled,
        musicTargetPackage: global.musicTargetPackage,
        languageCode: global.languageCode,
      );
      if (_persisted != null) {
        _persisted = _persisted!.copyWith(
          homescreenClock: global.homescreenClock,
          use24Hour: global.use24Hour,
          themeMode: global.themeMode,
          musicModeEnabled: global.musicModeEnabled,
          musicTargetPackage: global.musicTargetPackage,
          languageCode: global.languageCode,
        );
      }
    });
  }

  void _onFontsVersionChanged() {
    if (!mounted) return;
    final validClock = CustomFontService.isValidFont(
      _settings.musicClockFont,
      includeBuiltInDisplay: false,
    );
    final validDate = CustomFontService.isValidFont(
      _settings.musicDateFont,
      includeBuiltInDisplay: false,
    );
    final validCard = CustomFontService.isValidFont(
      _settings.musicCardFont,
      includeBuiltInDisplay: false,
    );
    if (!validClock || !validDate || !validCard) {
      setState(() {
        _settings = _settings.copyWith(
          musicClockFont: validClock ? _settings.musicClockFont : 'Sans-Serif',
          musicDateFont: validDate ? _settings.musicDateFont : 'Sans-Serif',
          musicCardFont: validCard ? _settings.musicCardFont : 'Sans-Serif',
        );
        if (_persisted != null) {
          _persisted = _persisted!.copyWith(
            musicClockFont: CustomFontService.isValidFont(
              _persisted!.musicClockFont,
              includeBuiltInDisplay: false,
            )
                ? _persisted!.musicClockFont
                : 'Sans-Serif',
            musicDateFont: CustomFontService.isValidFont(
              _persisted!.musicDateFont,
              includeBuiltInDisplay: false,
            )
                ? _persisted!.musicDateFont
                : 'Sans-Serif',
            musicCardFont: CustomFontService.isValidFont(
              _persisted!.musicCardFont,
              includeBuiltInDisplay: false,
            )
                ? _persisted!.musicCardFont
                : 'Sans-Serif',
          );
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    final loaded = await AppSettings.load();
    final validated = loaded.copyWith(
      musicClockFont: CustomFontService.isValidFont(
        loaded.musicClockFont,
        includeBuiltInDisplay: false,
      )
          ? loaded.musicClockFont
          : 'Sans-Serif',
      musicDateFont: CustomFontService.isValidFont(
        loaded.musicDateFont,
        includeBuiltInDisplay: false,
      )
          ? loaded.musicDateFont
          : 'Sans-Serif',
      musicCardFont: CustomFontService.isValidFont(
        loaded.musicCardFont,
        includeBuiltInDisplay: false,
      )
          ? loaded.musicCardFont
          : 'Sans-Serif',
    );
    if (mounted) {
      appSettingsNotifier.value = validated;
      setState(() {
        _settings = validated;
        _persisted = validated;
        _loaded = true;
      });
    }
  }

  void _updateDraft(AppSettings next) {
    setState(() => _settings = next);
  }

  Future<void> _applySettings() async {
    HapticFeedback.mediumImpact();
    final latest = await AppSettings.load();
    final merged = latest.copyWith(
      musicCoverX: _settings.musicCoverX,
      musicCoverY: _settings.musicCoverY,
      musicCoverScale: _settings.musicCoverScale,
      musicCardX: _settings.musicCardX,
      musicCardY: _settings.musicCardY,
      musicCardScale: _settings.musicCardScale,
      musicClockX: _settings.musicClockX,
      musicClockY: _settings.musicClockY,
      musicClockScale: _settings.musicClockScale,
      musicClockFont: _settings.musicClockFont,
      musicDateFont: _settings.musicDateFont,
      musicCardFont: _settings.musicCardFont,
      musicClockMaterial: _settings.musicClockMaterial,
      musicClockBlur: _settings.musicClockBlur,
      musicClockBrightness: _settings.musicClockBrightness,
      musicClockOpacity: _settings.musicClockOpacity,
      musicClockShadowEnabled: _settings.musicClockShadowEnabled,
      musicClockEdgeStrokeEnabled: _settings.musicClockEdgeStrokeEnabled,
      musicClockRimWidth: _settings.musicClockRimWidth,
      musicClockRimBlur: _settings.musicClockRimBlur,
      musicCardMaterial: _settings.musicCardMaterial,
      musicCardBlur: _settings.musicCardBlur,
      musicCardBrightness: _settings.musicCardBrightness,
      musicCardOpacity: _settings.musicCardOpacity,
      musicCardShadowEnabled: _settings.musicCardShadowEnabled,
      musicCardEdgeStrokeEnabled: _settings.musicCardEdgeStrokeEnabled,
      musicCardRimWidth: _settings.musicCardRimWidth,
      musicCardRimBlur: _settings.musicCardRimBlur,
    );
    await merged.save();
    appSettingsNotifier.value = merged;
    final bool synced = await PlatformChannel.syncAppPreferences(merged);
    if (!mounted) return;

    if (!synced) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppStrings.syncSettingsError),
            action: SnackBarAction(
              label: AppStrings.retryBtn,
              onPressed: _applySettings,
            ),
          ),
        );
    }

    _appliedBannerTimer?.cancel();
    setState(() {
      _settings = merged;
      _persisted = merged;
      _justApplied = synced;
    });
    if (synced) {
      _appliedBannerTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() => _justApplied = false);
        }
      });
    }
  }

  void _resetAll() {
    HapticFeedback.mediumImpact();
    _updateDraft(
      _settings.copyWith(
        musicCoverX: 0.50,
        musicCoverY: 0.20,
        musicCoverScale: 1.0,
        musicCardX: 0.50,
        musicCardY: 0.65,
        musicCardScale: 1.0,
        musicClockX: 0.50,
        musicClockY: 0.14,
        musicClockScale: 1.0,
        musicClockFont: 'Sans-Serif',
        musicDateFont: 'Sans-Serif',
        musicCardFont: 'Sans-Serif',
        musicClockMaterial: 'Standard',
        musicClockBlur: 18.0,
        musicClockBrightness: 0.65,
        musicClockOpacity: 1.0,
        musicClockShadowEnabled: true,
        musicClockEdgeStrokeEnabled: false,
        musicClockRimWidth: 1.8,
        musicClockRimBlur: 0.0,
        musicCardMaterial: 'Liquid',
        musicCardBlur: 18.0,
        musicCardBrightness: 0.65,
        musicCardOpacity: 1.0,
        musicCardShadowEnabled: true,
        musicCardEdgeStrokeEnabled: false,
        musicCardRimWidth: 1.8,
        musicCardRimBlur: 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, lang, _) {
            final Color appliedAccent = AppColors.isLight
                ? const Color(0xFF1E8E3E)
                : const Color(0xFF30D158);

            return Scaffold(
              backgroundColor: AppColors.bg,
              body: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        18,
                        AppLayout.screenPaddingH,
                        10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.musicTitle,
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
                          if (_loaded && _isDirty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.circle_fill,
                                    size: 6,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    AppStrings.unsavedChangesBadge,
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          PressScaleWrapper(
                            isEnabled: _loaded,
                            onTap: _loaded ? _resetAll : null,
                            child: GlassContainer(
                              width: 36,
                              height: 36,
                              quality: GlassQuality.premium,
                              useOwnLayer: true,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 20,
                              ),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.arrow_counterclockwise,
                                  size: 17,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PressScaleWrapper(
                            isEnabled: _loaded,
                            onTap: _loaded ? _applySettings : null,
                            child: GlassContainer(
                              height: 36,
                              quality: GlassQuality.premium,
                              useOwnLayer: true,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_justApplied) ...[
                                    Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 14,
                                      color: appliedAccent,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppStrings.apply,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: _justApplied
                                              ? appliedAccent
                                              : AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_loaded)
                      const Expanded(
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            MusicPreviewBox(
                              settings: _settings,
                              selectedTarget: _selectedTarget,
                              onTargetSelected: (target) {
                                setState(() {
                                  _selectedTarget = target;
                                  _selectedSegment = 0;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppLayout.screenPaddingH,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: GlassSegmentedControl(
                                  selectedIndex: _selectedSegment.clamp(0, 2),
                                  onSegmentSelected: (int val) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedSegment = val);
                                  },
                                  segments: [
                                    GlassSegment(
                                      label: AppStrings.segMusicLayout,
                                    ),
                                    GlassSegment(
                                      label: AppStrings.segMusicFonts,
                                    ),
                                    GlassSegment(
                                      label: AppStrings.segMusicMaterial,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.03),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_selectedSegment),
                                  child: _buildActiveTab(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveTab() {
    switch (_selectedSegment) {
      case 1:
        return MusicFontsTab(
          settings: _settings,
          hasBottomDock: widget.isEmbeddedInDock,
          onSettingsChanged: _updateDraft,
        );
      case 2:
        return MusicMaterialTab(
          settings: _settings,
          hasBottomDock: widget.isEmbeddedInDock,
          onSettingsChanged: _updateDraft,
        );
      default:
        return MusicLayoutTab(
          settings: _settings,
          selectedTarget: _selectedTarget,
          hasBottomDock: widget.isEmbeddedInDock,
          onTargetChanged: (t) => setState(() => _selectedTarget = t),
          onSettingsChanged: _updateDraft,
        );
    }
  }
}