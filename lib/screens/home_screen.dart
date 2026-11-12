import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../models/wallpaper_data.dart';
import '../models/wallpaper_project.dart';
import '../services/file_manager.dart';
import '../services/platform_channel.dart';
import '../services/project_repository.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/empty_wallpapers_state.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/project_card.dart';
import 'settings_screen.dart';
import 'studio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ProjectRepository _repo = ProjectRepository();

  List<WallpaperProject> _projects = [];
  bool _isLoading = true;
  String _sortMode = 'recent';

  int _activeDockIndex = 0;
  WallpaperProject? _editingProject;
  int _studioSessionCounter = 0;

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
    _loadProjects();
  }

  @override
  void dispose() {
    _tabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final list = await _repo.getAllProjects();
    if (!mounted) return;
    setState(() {
      _projects = list;
      if (_sortMode == 'name') {
        _projects.sort((a, b) => a.name.compareTo(b.name));
      }
      _isLoading = false;
    });
    await FileManager.gcOrphanFiles(list);
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

  void _switchToStudio({WallpaperProject? project}) {
    HapticFeedback.selectionClick();
    final double direction = 1 > _activeDockIndex ? 1.0 : -1.0;
    setState(() {
      _editingProject = project;
      _studioSessionCounter++;
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

  Future<void> _deleteProject(WallpaperProject project) async {
    bool confirmed = false;
    await GlassDialog.show(
      context: context,
      title: AppStrings.deleteWallpaperTitle,
      message: AppStrings.deleteWallpaperConfirm(project.name),
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
      await _repo.deleteProject(project.id);
      if (_editingProject?.id == project.id) {
        _editingProject = null;
      }
      await _loadProjects();
    }
  }

  Future<void> _duplicateProject(WallpaperProject project) async {
    setState(() => _isLoading = true);
    await _repo.duplicateProject(project);
    HapticFeedback.selectionClick();
    await _loadProjects();
  }

  Future<void> _renameProject(WallpaperProject project) async {
    final TextEditingController textController =
        TextEditingController(text: project.name);

    try {
      await showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => AnimatedPadding(
          padding: MediaQuery.viewInsetsOf(dialogCtx) +
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutQuad,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: LiquidGlass(
                  useOwnLayer: true,
                  borderRadius: 22,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.renameWallpaperTitle,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CupertinoTextField(
                        controller: textController,
                        autofocus: true,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        placeholderStyle: TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 15,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.secondarySurface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.6,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(
                              AppStrings.cancel,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () async {
                              final newName = textController.text.trim();
                              if (newName.isNotEmpty && newName != project.name) {
                                HapticFeedback.selectionClick();
                                await _repo.renameProject(project.id, newName);
                                await _loadProjects();
                              }
                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              }
                            },
                            child: Text(
                              AppStrings.apply,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      textController.dispose();
    }
  }

  Future<void> _setActiveWallpaper(WallpaperProject project) async {
    if (project.originalImagePath == null) return;

    final appSettings = await AppSettings.load();
    try {
      await PlatformChannel.saveAndApplyWallpaper(
        config: project.config,
        data: WallpaperData(
          originalImagePath: project.originalImagePath,
          foregroundImagePath: project.foregroundImagePath,
        ),
        settings: appSettings,
      );
      await _repo.setActive(project.id);
      HapticFeedback.mediumImpact();
      await _loadProjects();
    } catch (_) {}
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
              bottomBar: GlassTabBar.bottom(
                selectedIndex: _activeDockIndex,
                quality: GlassQuality.premium,
                onTabSelected: (index) {
                  _animateToTab(index);
                  if (index == 0) {
                    _loadProjects();
                  }
                },
                tabs: [
                  GlassTab(
                    label: AppStrings.dockWallpapers,
                    icon: Icon(
                      CupertinoIcons.rectangle_stack,
                      color: AppColors.textSecondary,
                    ),
                    activeIcon: const Icon(
                      CupertinoIcons.rectangle_stack_fill,
                      color: AppColors.accent,
                    ),
                  ),
                  GlassTab(
                    label: AppStrings.dockStudio,
                    icon: Icon(
                      CupertinoIcons.paintbrush,
                      color: AppColors.textSecondary,
                    ),
                    activeIcon: const Icon(
                      CupertinoIcons.paintbrush_fill,
                      color: AppColors.accent,
                    ),
                  ),
                  GlassTab(
                    label: AppStrings.dockSettings,
                    icon: Icon(
                      CupertinoIcons.gear_alt,
                      color: AppColors.textSecondary,
                    ),
                    activeIcon: const Icon(
                      CupertinoIcons.gear_alt_fill,
                      color: AppColors.accent,
                    ),
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
                          child: StudioScreen(
                            key: ValueKey(
                              'studio_${_editingProject?.id ?? "new"}_$_studioSessionCounter',
                            ),
                            project: _editingProject,
                            isEmbeddedInDock: true,
                            onProjectSaved: () async {
                              await _loadProjects();
                              if (mounted) {
                                _animateToTab(0);
                              }
                            },
                          ),
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
    final Color buttonContentColor =
    AppColors.isLight ? Colors.black : Colors.white;

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
                GlassButton.custom(
                  height: 34,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                  glowColor: AppColors.accent,
                  onTap: () => _switchToStudio(project: null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          color: buttonContentColor,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.newBtn,
                              maxLines: 1,
                              style: TextStyle(
                                color: buttonContentColor,
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
            if (_projects.isNotEmpty)
              WallpapersSortRow(
                count: _projects.length,
                sortMode: _sortMode,
                onToggleSort: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _sortMode = _sortMode == 'recent' ? 'name' : 'recent';
                  });
                  _loadProjects();
                },
              ),
            Expanded(
              child: _projects.isEmpty
                  ? EmptyWallpapersState(
                onOpenStudio: () => _switchToStudio(project: null),
              )
                  : _buildProjectGrid(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectGrid() {
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
          itemCount: _projects.length,
          itemBuilder: (_, index) {
            final project = _projects[index];
            return ProjectCard(
              key: ValueKey(project.id),
              project: project,
              index: index,
              onTap: () => _switchToStudio(project: project),
              onEdit: () => _switchToStudio(project: project),
              onRename: () => _renameProject(project),
              onDuplicate: () => _duplicateProject(project),
              onDelete: () => _deleteProject(project),
              onSetWallpaper: () => _setActiveWallpaper(project),
            );
          },
        );
      },
    );
  }
}