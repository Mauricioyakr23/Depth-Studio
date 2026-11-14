import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:uuid/uuid.dart';

import '../core/core.dart';
import '../models/depth_scene_config.dart';
import '../models/saved_scene.dart';
import '../models/scene_layers.dart';
import '../services/asset_storage_manager.dart';
import '../services/custom_font_service.dart';
import '../services/palette_extractor_service.dart';
import '../services/permission_service.dart';
import '../services/platform_channel.dart';
import '../services/scene_storage_service.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/studio/studio_background_tab.dart';
import '../widgets/studio/studio_clock_tab.dart';
import '../widgets/studio/studio_common_widgets.dart';
import '../widgets/studio/studio_date_tab.dart';
import '../widgets/studio/studio_material_tab.dart';
import '../widgets/studio/studio_preview_box.dart';
import 'fullscreen_preview_screen.dart';

class EditorWorkspaceScreen extends StatefulWidget {
  final SavedScene? initialScene;
  final bool isEmbeddedInDock;
  final VoidCallback? onSceneSaved;

  const EditorWorkspaceScreen({
    super.key,
    this.initialScene,
    this.isEmbeddedInDock = false,
    this.onSceneSaved,
  });

  @override
  State<EditorWorkspaceScreen> createState() => _EditorWorkspaceScreenState();
}

class _EditorWorkspaceScreenState extends State<EditorWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  int _selectedSegment = 0;
  late SceneLayers _layers;
  late DepthSceneConfig _config;
  SavedScene? _persistedScene;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _justSaved = false;
  Timer? _savedBannerTimer;
  String _loadingText = '';
  final GlobalKey _previewKey = GlobalKey();
  final SceneStorageService _storage = SceneStorageService();

  late AnimationController _previewAnimController;
  late Animation<double> _previewCurvedAnim;

  List<Color> _imagePaletteColors = PaletteExtractorService.defaultPalette;

  @override
  void initState() {
    super.initState();
    _initFromScene();
    CustomFontService.fontsVersionNotifier.addListener(_onFontsVersionChanged);
    _previewAnimController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _config.clockAnimDuration.toInt(),
      ),
      value: 1.0,
    );
    _previewCurvedAnim = CurvedAnimation(
      parent: _previewAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _refreshPalette(_layers.backgroundPath);
  }

  @override
  void dispose() {
    _savedBannerTimer?.cancel();
    CustomFontService.fontsVersionNotifier.removeListener(_onFontsVersionChanged);
    _previewAnimController.dispose();
    final String? bg = _layers.backgroundPath;
    final String? fg = _layers.subjectPath;
    final String? savedBg = _persistedScene?.backgroundPath;
    final String? savedFg = _persistedScene?.subjectPath;
    if (bg != null && bg != savedBg) {
      AssetStorageManager.unpinAsset(bg);
    }
    if (fg != null && fg != savedFg) {
      AssetStorageManager.unpinAsset(fg);
    }
    super.dispose();
  }

  void _onFontsVersionChanged() {
    if (!mounted) return;
    final bool validClock = CustomFontService.isValidFont(_config.fontFamily);
    final bool validDate = CustomFontService.isValidFont(
      _config.dateFontFamily,
      includeBuiltInDisplay: false,
    );
    if (!validClock || !validDate) {
      setState(() {
        _config = _config.copyWith(
          fontFamily: validClock ? _config.fontFamily : 'Display 1',
          dateFontFamily:
          validDate ? _config.dateFontFamily : 'Sans-Serif',
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant EditorWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScene?.sceneId != widget.initialScene?.sceneId) {
      _initFromScene();
      _syncPreviewAnimationDuration();
      _previewAnimController.value = 1.0;
      _refreshPalette(_layers.backgroundPath);
    }
  }

  void _initFromScene() {
    final scene = widget.initialScene;
    _persistedScene = scene;
    if (scene != null) {
      final cfg = scene.styleConfig;
      _config = cfg.copyWith(
        fontFamily: CustomFontService.isValidFont(cfg.fontFamily)
            ? cfg.fontFamily
            : 'Display 1',
        dateFontFamily: CustomFontService.isValidFont(
          cfg.dateFontFamily,
          includeBuiltInDisplay: false,
        )
            ? cfg.dateFontFamily
            : 'Sans-Serif',
      );
      _layers = scene.layers;
      AssetStorageManager.pinAsset(scene.backgroundPath);
      AssetStorageManager.pinAsset(scene.subjectPath);
    } else {
      _layers = const SceneLayers();
      _config = const DepthSceneConfig(
        fontFamily: 'Display 1',
        dateFontFamily: 'Sans-Serif',
      );
    }
  }

  void _syncPreviewAnimationDuration() {
    final int targetMs = _config.clockAnimDuration.toInt();
    if (_previewAnimController.duration?.inMilliseconds != targetMs) {
      _previewAnimController.duration = Duration(milliseconds: targetMs);
    }
  }

  void _onConfigChanged(DepthSceneConfig cfg) {
    setState(() => _config = cfg);
    _syncPreviewAnimationDuration();
  }

  Future<void> _refreshPalette(String? path) async {
    final palette = await PaletteExtractorService.extractPalette(path);
    if (mounted) {
      setState(() => _imagePaletteColors = palette);
    }
  }

  void _triggerPreviewAnimation({required bool entrance}) {
    _syncPreviewAnimationDuration();
    HapticFeedback.mediumImpact();
    if (entrance) {
      _previewAnimController.forward(from: 0.0);
    } else {
      _previewAnimController.reverse(from: 1.0).then((_) {
        final int holdMs = (_config.clockAnimDuration * 0.7).round();
        Future.delayed(Duration(milliseconds: holdMs), () {
          if (mounted) _previewAnimController.forward(from: 0.0);
        });
      });
    }
  }

  Future<void> _pickManualBackground() async {
    try {
      final bool isGranted =
      await PermissionService.checkAndRequestGalleryPermission();
      if (!isGranted) return;

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _loadingText = AppStrings.loadingBg;
      });

      final String savedPath =
      await AssetStorageManager.storeBackgroundAsset(pickedFile);
      await _refreshPalette(savedPath);

      if (!mounted) return;
      final String? oldPath = _layers.backgroundPath;
      setState(() {
        _layers = _layers.copyWith(backgroundPath: savedPath);
        _isLoading = false;
      });
      if (oldPath != null && oldPath != _persistedScene?.backgroundPath) {
        await AssetStorageManager.removeAsset(oldPath);
      }
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickManualForegroundPng() async {
    if (!_layers.hasBackground) {
      await GlassDialog.show(
        context: context,
        title: AppStrings.bgRequiredTitle,
        message: AppStrings.bgRequiredDesc,
        actions: [
          GlassDialogAction(
            label: 'OK',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      return;
    }

    try {
      final bool isGranted =
      await PermissionService.checkAndRequestGalleryPermission();
      if (!isGranted) return;

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
      await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _loadingText = AppStrings.loadingFg;
      });

      final String savedFgPath =
      await AssetStorageManager.storeSubjectAsset(pickedFile);

      if (!mounted) return;
      final String? oldFg = _layers.subjectPath;
      setState(() {
        _layers = _layers.copyWith(subjectPath: savedFgPath);
        _isLoading = false;
      });
      if (oldFg != null && oldFg != _persistedScene?.subjectPath) {
        await AssetStorageManager.removeAsset(oldFg);
      }
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetSettings() async {
    if (!_layers.hasBackground) return;

    bool confirm = false;
    await GlassDialog.show(
      context: context,
      title: AppStrings.resetStudioTitle,
      message: AppStrings.resetStudioDesc,
      actions: [
        GlassDialogAction(
          label: AppStrings.cancel,
          onPressed: () {
            confirm = false;
            Navigator.of(context).pop();
          },
        ),
        GlassDialogAction(
          label: AppStrings.reset,
          isDestructive: true,
          onPressed: () {
            confirm = true;
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    if (!confirm) return;

    const emptyConfig = DepthSceneConfig(
      fontFamily: 'Display 1',
      dateFontFamily: 'Sans-Serif',
    );

    final SavedScene? existing = _persistedScene;
    if (existing != null) {
      final cleared = existing.copyWith(
        layers: const SceneLayers(),
        clearPreviewCard: true,
        styleConfig: emptyConfig,
        updatedAt: DateTime.now(),
      );
      try {
        await _storage.upsertScene(cleared);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(AppStrings.resetError)),
            );
        }
        return;
      }
      _persistedScene = cleared;
    }

    final String? oldBg = _layers.backgroundPath;
    final String? oldFg = _layers.subjectPath;
    final String? oldThumb = existing?.previewCardPath;
    if (oldBg != null) {
      await AssetStorageManager.removeAsset(oldBg);
    }
    if (oldFg != null) {
      await AssetStorageManager.removeAsset(oldFg);
    }
    if (oldThumb != null) {
      await AssetStorageManager.removeAsset(oldThumb);
    }

    if (!mounted) return;
    setState(() {
      _layers = _layers.clear();
      _config = emptyConfig;
    });
    _syncPreviewAnimationDuration();
  }

  Future<SavedScene> _persistSceneSnapshot({
    required bool markAsActive,
  }) async {
    String? thumbPath;
    ui.Image? capturedImage;
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary != null) {
        capturedImage = await boundary.toImage(pixelRatio: 1.5);
        final byteData =
        await capturedImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          thumbPath = await AssetStorageManager.storePreviewCardBytes(
            byteData.buffer.asUint8List(),
          );
        }
      }
    } catch (_) {
    } finally {
      capturedImage?.dispose();
    }

    final now = DateTime.now();
    final existing = _persistedScene;

    final scene = SavedScene(
      sceneId: existing?.sceneId ?? const Uuid().v4(),
      title:
      existing?.title ?? AppStrings.defaultProjectName(now.day, now.month),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      previewCardPath: thumbPath ?? existing?.previewCardPath,
      isCurrentWallpaper:
      markAsActive ? true : (existing?.isCurrentWallpaper ?? false),
      layers: _layers,
      styleConfig: _config,
    );

    if (thumbPath != null &&
        existing?.previewCardPath != null &&
        existing!.previewCardPath != thumbPath) {
      await AssetStorageManager.removeAsset(existing.previewCardPath!);
    }

    await _storage.upsertScene(scene);
    if (markAsActive) {
      await _storage.markAsCurrentWallpaper(scene.sceneId);
    }
    _persistedScene = scene;
    return scene;
  }

  Future<void> _applyWallpaper() async {
    if (!_layers.hasBackground) return;

    setState(() {
      _isLoading = true;
      _loadingText = AppStrings.applyingWallpaper;
    });

    try {
      await _persistSceneSnapshot(markAsActive: true);
      await PlatformChannel.applyLiveScene(
        config: _config,
        layers: _layers,
        settings: appSettingsNotifier.value,
      );
      HapticFeedback.mediumImpact();
    } catch (_) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppStrings.applyWallpaperError),
              action: SnackBarAction(
                label: AppStrings.retryBtn,
                onPressed: _applyWallpaper,
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveScene() async {
    setState(() => _isSaving = true);
    try {
      await _persistSceneSnapshot(markAsActive: false);
      if (mounted) {
        HapticFeedback.lightImpact();
        if (widget.isEmbeddedInDock) {
          _savedBannerTimer?.cancel();
          setState(() => _justSaved = true);
          _savedBannerTimer = Timer(const Duration(milliseconds: 1400), () {
            if (mounted) {
              setState(() => _justSaved = false);
            }
          });
        } else {
          widget.onSceneSaved?.call();
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBackground = _layers.hasBackground;
    final Color savedAccent = AppColors.isLight
        ? const Color(0xFF1E8E3E)
        : const Color(0xFF30D158);

    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, lang, _) {
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
                              AppStrings.studioTitle,
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
                          if (hasBackground) ...[
                            PressScaleWrapper(
                              isEnabled: !_isLoading,
                              onTap: _isLoading ? null : _resetSettings,
                              child: GlassContainer(
                                width: 36,
                                height: 36,
                                quality: GlassQuality.premium,
                                useOwnLayer: true,
                                shape: const LiquidRoundedSuperellipse(
                                  borderRadius: 20,
                                ),
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons.trash,
                                    size: 17,
                                    color: Color(0xFFFF453A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            PressScaleWrapper(
                              isEnabled: !(_isLoading || _isSaving),
                              onTap: _isLoading || _isSaving ? null : _saveScene,
                              child: GlassContainer(
                                width: 36,
                                height: 36,
                                quality: GlassQuality.premium,
                                useOwnLayer: true,
                                shape: const LiquidRoundedSuperellipse(
                                  borderRadius: 20,
                                ),
                                child: Center(
                                  child: _isSaving
                                      ? const CupertinoActivityIndicator(
                                    radius: 8,
                                  )
                                      : Icon(
                                    _justSaved
                                        ? CupertinoIcons.checkmark_alt
                                        : CupertinoIcons.tray_arrow_down,
                                    size: 17,
                                    color: _justSaved
                                        ? savedAccent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PressScaleWrapper(
                              isEnabled: !_isLoading,
                              onTap: _isLoading ? null : _applyWallpaper,
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
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      AppStrings.apply,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          StudioPreviewBox(
                            previewKey: _previewKey,
                            layers: _layers,
                            config: _config,
                            previewCurvedAnim: _previewCurvedAnim,
                            isLoading: _isLoading,
                            loadingText: _loadingText,
                            onTap: () {
                              Navigator.of(context).push(
                                GlassTransitionRoute(
                                  child: FullscreenPreviewScreen(
                                    layers: _layers,
                                    config: _config,
                                  ),
                                ),
                              );
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
                                selectedIndex: _selectedSegment.clamp(0, 3),
                                onSegmentSelected: (int val) {
                                  setState(() => _selectedSegment = val);
                                },
                                segments: [
                                  GlassSegment(
                                    label: AppStrings.segBackground,
                                  ),
                                  GlassSegment(label: AppStrings.segClock),
                                  GlassSegment(label: AppStrings.segDate),
                                  GlassSegment(
                                    label: AppStrings.segMaterial,
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
                                child: _buildActiveSection(),
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

  Widget _buildActiveSection() {
    switch (_selectedSegment) {
      case 1:
        return StudioClockTab(
          layers: _layers,
          config: _config,
          palette: _imagePaletteColors,
          hasBottomDock: widget.isEmbeddedInDock,
          onConfigChanged: _onConfigChanged,
        );
      case 2:
        return StudioDateTab(
          layers: _layers,
          config: _config,
          palette: _imagePaletteColors,
          hasBottomDock: widget.isEmbeddedInDock,
          onConfigChanged: _onConfigChanged,
        );
      case 3:
        return StudioMaterialTab(
          layers: _layers,
          config: _config,
          palette: _imagePaletteColors,
          hasBottomDock: widget.isEmbeddedInDock,
          onConfigChanged: _onConfigChanged,
          onTriggerPreviewAnimation: (entrance) =>
              _triggerPreviewAnimation(entrance: entrance),
        );
      default:
        return StudioBackgroundTab(
          layers: _layers,
          config: _config,
          hasBottomDock: widget.isEmbeddedInDock,
          onPickBackground: _pickManualBackground,
          onPickForeground: _pickManualForegroundPng,
          onRemoveForeground: () {
            setState(() {
              _layers = _layers.copyWith(clearSubject: true);
            });
          },
          onConfigChanged: _onConfigChanged,
        );
    }
  }
}