import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:uuid/uuid.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';
import '../models/wallpaper_project.dart';
import '../services/file_manager.dart';
import '../services/palette_extractor_service.dart';
import '../services/permission_service.dart';
import '../services/platform_channel.dart';
import '../services/project_repository.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/studio/dynamic_font_fit_painter.dart';
import '../widgets/studio/studio_background_tab.dart';
import '../widgets/studio/studio_clock_tab.dart';
import '../widgets/studio/studio_date_tab.dart';
import '../widgets/studio/studio_material_tab.dart';
import '../widgets/studio/studio_preview_box.dart';
import 'preview_screen.dart';

class StudioScreen extends StatefulWidget {
  final WallpaperProject? project;
  final bool isEmbeddedInDock;
  final VoidCallback? onProjectSaved;

  const StudioScreen({
    super.key,
    this.project,
    this.isEmbeddedInDock = false,
    this.onProjectSaved,
  });

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen>
    with SingleTickerProviderStateMixin {
  int _selectedSegment = 0;
  late WallpaperData _wallpaperData;
  late WallpaperConfig _wallpaperConfig;
  bool _isLoading = false;
  bool _isSaving = false;
  String _loadingText = '';
  final GlobalKey _previewKey = GlobalKey();
  final ProjectRepository _repo = ProjectRepository();

  late AnimationController _previewAnimController;
  late Animation<double> _previewCurvedAnim;

  List<Color> _imagePaletteColors = PaletteExtractorService.defaultPalette;

  @override
  void initState() {
    super.initState();
    _initFromProject();
    _previewAnimController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _wallpaperConfig.clockAnimDuration.toInt(),
      ),
      value: 1.0,
    );
    _previewCurvedAnim = CurvedAnimation(
      parent: _previewAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _refreshPalette(_wallpaperData.originalImagePath);
  }

  @override
  void dispose() {
    _previewAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project?.id != widget.project?.id) {
      _initFromProject();
      _refreshPalette(_wallpaperData.originalImagePath);
    }
  }

  void _initFromProject() {
    final proj = widget.project;
    if (proj != null) {
      final cfg = proj.config;
      _wallpaperConfig = cfg.copyWith(
        fontFamily: kStudioFonts.contains(cfg.fontFamily)
            ? cfg.fontFamily
            : 'Display 1',
        dateFontFamily: kStudioFonts.contains(cfg.dateFontFamily)
            ? cfg.dateFontFamily
            : 'Sans-Serif',
      );
      _wallpaperData = WallpaperData(
        originalImagePath: proj.originalImagePath,
        foregroundImagePath: proj.foregroundImagePath,
      );
      FileManager.protectPath(proj.originalImagePath);
      FileManager.protectPath(proj.foregroundImagePath);
    } else {
      _wallpaperData = const WallpaperData();
      _wallpaperConfig = const WallpaperConfig(
        fontFamily: 'Display 1',
        dateFontFamily: 'Sans-Serif',
      );
    }
  }

  Future<void> _refreshPalette(String? path) async {
    final palette = await PaletteExtractorService.extractPalette(path);
    if (mounted) {
      setState(() => _imagePaletteColors = palette);
    }
  }

  void _triggerPreviewAnimation({required bool entrance}) {
    _previewAnimController.duration = Duration(
      milliseconds: _wallpaperConfig.clockAnimDuration.toInt(),
    );
    HapticFeedback.mediumImpact();
    if (entrance) {
      _previewAnimController.forward(from: 0.0);
    } else {
      _previewAnimController.reverse(from: 1.0).then((_) {
        final int holdMs = (_wallpaperConfig.clockAnimDuration * 0.7).round();
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

      final String savedPath = await FileManager.saveImage(pickedFile);
      await _refreshPalette(savedPath);

      if (!mounted) return;
      final String? oldPath = _wallpaperData.originalImagePath;
      setState(() {
        _wallpaperData = _wallpaperData.copyWith(originalImagePath: savedPath);
        _isLoading = false;
      });
      if (oldPath != null && oldPath != widget.project?.originalImagePath) {
        await FileManager.deleteImage(oldPath);
      }
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickManualForegroundPng() async {
    if (_wallpaperData.originalImagePath == null) {
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
      await FileManager.saveForegroundFile(pickedFile);

      if (!mounted) return;
      final String? oldFg = _wallpaperData.foregroundImagePath;
      setState(() {
        _wallpaperData =
            _wallpaperData.copyWith(foregroundImagePath: savedFgPath);
        _isLoading = false;
      });
      if (oldFg != null && oldFg != widget.project?.foregroundImagePath) {
        await FileManager.deleteImage(oldFg);
      }
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetSettings() async {
    if (_wallpaperData.originalImagePath == null) return;

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

    if (confirm) {
      if (_wallpaperData.originalImagePath != null) {
        await FileManager.deleteImage(_wallpaperData.originalImagePath!);
      }
      if (_wallpaperData.foregroundImagePath != null) {
        await FileManager.deleteImage(_wallpaperData.foregroundImagePath!);
      }

      const emptyConfig = WallpaperConfig(
        fontFamily: 'Display 1',
        dateFontFamily: 'Sans-Serif',
      );
      setState(() {
        _wallpaperData = _wallpaperData.clear();
        _wallpaperConfig = emptyConfig;
      });

      final existing = widget.project;
      if (existing != null) {
        await _repo.saveProject(
          existing.copyWith(
            clearOriginalImage: true,
            clearForegroundImage: true,
            configJson: jsonEncode(emptyConfig.toJson()),
            modifiedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> _applyWallpaper() async {
    if (_wallpaperData.originalImagePath == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = AppStrings.applyingWallpaper;
    });

    try {
      final appSettings = await AppSettings.load();
      await PlatformChannel.saveAndApplyWallpaper(
        config: _wallpaperConfig,
        data: _wallpaperData,
        settings: appSettings,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProject() async {
    setState(() => _isSaving = true);
    try {
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
            thumbPath = await FileManager.saveThumbnailBytes(
              byteData.buffer.asUint8List(),
            );
          }
        }
      } catch (_) {
      } finally {
        capturedImage?.dispose();
      }

      final now = DateTime.now();
      final existing = widget.project;
      final configJson = jsonEncode(_wallpaperConfig.toJson());

      final project = WallpaperProject(
        id: existing?.id ?? const Uuid().v4(),
        name: existing?.name ?? 'Lock Screen ${now.day}/${now.month}',
        createdAt: existing?.createdAt ?? now,
        modifiedAt: now,
        thumbnailPath: thumbPath ?? existing?.thumbnailPath,
        isActive: existing?.isActive ?? false,
        originalImagePath: _wallpaperData.originalImagePath,
        foregroundImagePath: _wallpaperData.foregroundImagePath,
        configJson: configJson,
      );

      if (thumbPath != null &&
          existing?.thumbnailPath != null &&
          existing!.thumbnailPath != thumbPath) {
        await FileManager.deleteImage(existing.thumbnailPath!);
      }

      await _repo.saveProject(project);
      if (mounted) {
        HapticFeedback.lightImpact();
        if (widget.isEmbeddedInDock) {
          widget.onProjectSaved?.call();
        } else {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? originalImagePath = _wallpaperData.originalImagePath;
    final Color applyButtonTextColor =
    AppColors.isLight ? Colors.black : Colors.white;

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
                          if (originalImagePath != null) ...[
                            GlassIconButton(
                              size: 34,
                              icon: const Icon(
                                CupertinoIcons.trash,
                                size: 17,
                                color: Color(0xFFFF453A),
                              ),
                              onPressed: _isLoading ? null : _resetSettings,
                            ),
                            const SizedBox(width: 6),
                            GlassIconButton(
                              size: 34,
                              icon: _isSaving
                                  ? const CupertinoActivityIndicator(radius: 8)
                                  : Icon(
                                CupertinoIcons.tray_arrow_down,
                                size: 17,
                                color: AppColors.textPrimary,
                              ),
                              onPressed:
                              _isLoading || _isSaving ? null : _saveProject,
                            ),
                            const SizedBox(width: 8),
                            GlassButton.custom(
                              height: 34,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 18,
                              ),
                              glowColor: AppColors.accent,
                              onTap: _isLoading ? () {} : _applyWallpaper,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    AppStrings.apply,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: applyButtonTextColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            children: [
                              StudioPreviewBox(
                                previewKey: _previewKey,
                                wallpaperData: _wallpaperData,
                                wallpaperConfig: _wallpaperConfig,
                                previewCurvedAnim: _previewCurvedAnim,
                                isLoading: _isLoading,
                                loadingText: _loadingText,
                                onTap: () {
                                  Navigator.of(context).push(
                                    SlidePageRoute(
                                      child: PreviewScreen(
                                        originalImagePath: originalImagePath,
                                        foregroundImagePath:
                                        _wallpaperData.foregroundImagePath,
                                        wallpaperConfig: _wallpaperConfig,
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
                          );
                        },
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
          data: _wallpaperData,
          config: _wallpaperConfig,
          palette: _imagePaletteColors,
          hasBottomDock: widget.isEmbeddedInDock,
          onConfigChanged: (cfg) => setState(() => _wallpaperConfig = cfg),
        );
      case 2:
        return StudioDateTab(
          data: _wallpaperData,
          config: _wallpaperConfig,
          palette: _imagePaletteColors,
          hasBottomDock: widget.isEmbeddedInDock,
          onConfigChanged: (cfg) => setState(() => _wallpaperConfig = cfg),
        );
      case 3:
        return StudioMaterialTab(
          data: _wallpaperData,
          config: _wallpaperConfig,
          palette: _imagePaletteColors,
          hasBottomDock: widget.isEmbeddedInDock,
          onConfigChanged: (cfg) => setState(() => _wallpaperConfig = cfg),
          onTriggerPreviewAnimation: (entrance) =>
              _triggerPreviewAnimation(entrance: entrance),
        );
      default:
        return StudioBackgroundTab(
          data: _wallpaperData,
          config: _wallpaperConfig,
          hasBottomDock: widget.isEmbeddedInDock,
          onPickBackground: _pickManualBackground,
          onPickForeground: _pickManualForegroundPng,
          onRemoveForeground: () {
            setState(() {
              _wallpaperData =
                  _wallpaperData.copyWith(clearForegroundImage: true);
            });
          },
          onConfigChanged: (cfg) => setState(() => _wallpaperConfig = cfg),
        );
    }
  }
}