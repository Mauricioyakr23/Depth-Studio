import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/saved_scene.dart';
import '../services/asset_storage_manager.dart';
import '../services/platform_channel.dart';
import '../services/scene_storage_service.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/empty_wallpapers_state.dart';
import '../widgets/expanding_glass_nav_bar.dart';
import '../widgets/rename_project_dialog.dart';
import '../widgets/scene_card.dart';
import '../widgets/studio/studio_common_widgets.dart';
import 'editor_workspace_screen.dart';
import 'music_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SceneStorageService _storage = SceneStorageService();

  List<SavedScene> _scenes = [];
  bool _isLoading = true;
  String _sortMode = 'recent';
  String? _applyingSceneId;

  int _activeDockIndex = 0;
  SavedScene? _editingScene;
  int _editorSessionCounter = 0;

  late final AnimationController _tabAnimController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _tabAnimController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimController,
      curve: Curves.easeOut,
    ));
    _loadScenes();
  }

  @override
  void dispose() {
    _tabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadScenes() async {
    final list = await _storage.fetchAllScenes();
    if (!mounted) return;
    setState(() {
      _scenes = list;
      if (_sortMode == 'name') {
        _scenes.sort((a, b) => a.title.compareTo(b.title));
      }
      if (_editingScene != null) {
        final updatedMatch =
            _scenes.where((s) => s.sceneId == _editingScene!.sceneId).firstOrNull;
        if (updatedMatch != null) {
          _editingScene = updatedMatch;
        }
      }
      _isLoading = false;
    });
    final int deletedCount = await AssetStorageManager.purgeOrphanAssets(list);
    if (deletedCount > 0) {
      debugPrint(
        'AssetStorageManager.purgeOrphanAssets removed $deletedCount orphan files',
      );
    }
  }

  void _animateToTab(int newIndex) {
    if (newIndex == _activeDockIndex) return;
    final double direction = newIndex > _activeDockIndex ? 1.0 : -1.0;

    setState(() {
      _activeDockIndex = newIndex;
      _slideAnimation = Tween<Offset>(
        begin: Offset(0.065 * direction, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _tabAnimController,
        curve: Curves.easeOutCubic,
      ));
      _fadeAnimation = Tween<double>(
        begin: 0.35,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _tabAnimController,
        curve: Curves.easeOut,
      ));
    });

    _tabAnimController.forward(from: 0.0);
  }

  void _switchToEditor({SavedScene? scene}) {
    HapticFeedback.selectionClick();
    final double direction = 1 > _activeDockIndex ? 1.0 : -1.0;
    setState(() {
      _editingScene = scene;
      _editorSessionCounter++;
      _activeDockIndex = 1;
      _slideAnimation = Tween<Offset>(
        begin: Offset(0.065 * direction, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _tabAnimController,
        curve: Curves.easeOutCubic,
      ));
      _fadeAnimation = Tween<double>(
        begin: 0.35,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _tabAnimController,
        curve: Curves.easeOut,
      ));
    });
    _tabAnimController.forward(from: 0.0);
  }

  Future<void> _deleteScene(SavedScene scene) async {
    bool confirmed = false;
    await GlassDialog.show(
      context: context,
      title: AppStrings.deleteWallpaperTitle,
      message: AppStrings.deleteWallpaperConfirm(scene.title),
      actions: [
        GlassDialogAction(
          label: AppStrings.cancel,
          onPressed: () {
            confirmed = false;
            Navigator.of(context).pop();
          },
        ),
        GlassDialogAction(
          label: AppStrings.delete,
          isDestructive: true,
          onPressed: () {
            confirmed = true;
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    if (confirmed) {
      HapticFeedback.mediumImpact();
      await _storage.deleteScene(scene.sceneId);
      if (_editingScene?.sceneId == scene.sceneId) {
        _editingScene = null;
      }
      await _loadScenes();
    }
  }

  Future<void> _duplicateScene(SavedScene scene) async {
    setState(() => _isLoading = true);
    await _storage.cloneScene(scene);
    HapticFeedback.selectionClick();
    await _loadScenes();
  }

  Future<void> _renameScene(SavedScene scene) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final String? newName = await showRenameProjectDialog(
      context: context,
      currentName: scene.title,
    );

    if (newName != null && newName != scene.title) {
      await _storage.renameScene(scene.sceneId, newName);
      await _loadScenes();
    }
  }

  Future<void> _setActiveWallpaper(SavedScene scene) async {
    if (!scene.layers.hasBackground) return;
    if (_applyingSceneId != null) return;

    setState(() => _applyingSceneId = scene.sceneId);
    try {
      await PlatformChannel.applyLiveScene(
        config: scene.styleConfig,
        layers: scene.layers,
        settings: appSettingsNotifier.value,
      );
      await _storage.markAsCurrentWallpaper(scene.sceneId);
      HapticFeedback.mediumImpact();
      await _loadScenes();
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
                onPressed: () => _setActiveWallpaper(scene),
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _applyingSceneId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, lang, _) {
            return GlassScaffold(
              backgroundColor: AppColors.bg,
              bottomBar: ExpandingGlassNavBar(
                selectedIndex: _activeDockIndex,
                onTabSelected: (index) {
                  _animateToTab(index);
                  if (index == 0) {
                    _loadScenes();
                  }
                },
                items: [
                  ExpandingGlassNavItem(
                    label: AppStrings.dockWallpapers,
                    icon: CupertinoIcons.rectangle_stack,
                    activeIcon: CupertinoIcons.rectangle_stack_fill,
                  ),
                  ExpandingGlassNavItem(
                    label: AppStrings.dockStudio,
                    icon: CupertinoIcons.paintbrush,
                    activeIcon: CupertinoIcons.paintbrush_fill,
                  ),
                  ExpandingGlassNavItem(
                    label: AppStrings.dockMusic,
                    icon: CupertinoIcons.music_note_2,
                    activeIcon: CupertinoIcons.music_albums_fill,
                  ),
                  ExpandingGlassNavItem(
                    label: AppStrings.dockSettings,
                    icon: CupertinoIcons.gear_alt,
                    activeIcon: CupertinoIcons.gear_alt_fill,
                  ),
                ],
              ),
              body: RepaintBoundary(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: IndexedStack(
                      index: _activeDockIndex,
                      children: [
                        RepaintBoundary(child: _buildWallpapersTab()),
                        RepaintBoundary(
                          child: EditorWorkspaceScreen(
                            key: ValueKey(
                              'editor_${_editingScene?.sceneId ?? "new"}_$_editorSessionCounter',
                            ),
                            initialScene: _editingScene,
                            isEmbeddedInDock: true,
                            onSceneSaved: () async {
                              await _loadScenes();
                              if (mounted) {
                                _animateToTab(0);
                              }
                            },
                          ),
                        ),
                        const RepaintBoundary(
                          child: MusicScreen(isEmbeddedInDock: true),
                        ),
                        const RepaintBoundary(
                          child: SettingsScreen(isEmbeddedInDock: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWallpapersTab() {
    return SafeArea(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    AppStrings.wallpapersTitle,
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
                const SizedBox(width: 12),
                PressScaleWrapper(
                  onTap: () => _switchToEditor(scene: null),
                  child: GlassContainer(
                    height: 36,
                    quality: GlassQuality.premium,
                    useOwnLayer: true,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          color: AppColors.textPrimary,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.newBtn,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.textPrimary,
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
          if (_isLoading)
            Expanded(
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          else ...[
            if (_scenes.isNotEmpty)
              WallpapersSortRow(
                count: _scenes.length,
                sortMode: _sortMode,
                onToggleSort: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _sortMode = _sortMode == 'recent' ? 'name' : 'recent';
                  });
                  _loadScenes();
                },
              ),
            Expanded(
              child: _scenes.isEmpty
                  ? EmptyWallpapersState(
                onOpenStudio: () => _switchToEditor(scene: null),
              )
                  : _buildSceneGrid(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSceneGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width >= 840
            ? 4
            : width >= 560
            ? 3
            : 2;

        final Size screenSize = MediaQuery.sizeOf(context);
        final double rawRatio = screenSize.height > 0
            ? (screenSize.width / crossAxisCount) / (screenSize.height * 0.48)
            : 0.52;
        final double itemRatio = rawRatio.clamp(0.48, 0.58);

        return GridView.builder(
          padding: AppLayout.scrollableTabPadding(context, top: 4.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: itemRatio,
          ),
          itemCount: _scenes.length,
          itemBuilder: (_, index) {
            final scene = _scenes[index];
            return SceneCard(
              key: ValueKey(scene.sceneId),
              scene: scene,
              index: index,
              isApplying: _applyingSceneId == scene.sceneId,
              onTap: () => _switchToEditor(scene: scene),
              onEdit: () => _switchToEditor(scene: scene),
              onRename: () => _renameScene(scene),
              onDuplicate: () => _duplicateScene(scene),
              onDelete: () => _deleteScene(scene),
              onSetWallpaper: () => _setActiveWallpaper(scene),
            );
          },
        );
      },
    );
  }
}