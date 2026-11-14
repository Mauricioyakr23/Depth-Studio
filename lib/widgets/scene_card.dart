import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/saved_scene.dart';
import '../state/notifiers/app_notifiers.dart';
import 'scene_canvas_preview.dart';
import 'studio/studio_common_widgets.dart';

class SceneCard extends StatelessWidget {
  final SavedScene scene;
  final int index;
  final bool isApplying;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onSetWallpaper;

  const SceneCard({
    super.key,
    required this.scene,
    required this.index,
    this.isApplying = false,
    required this.onTap,
    required this.onEdit,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSetWallpaper,
  });

  void _showIosActions(BuildContext context) {
    if (isApplying) return;
    showGlassActionSheet(
      context: context,
      title: scene.title,
      actions: [
        GlassActionSheetAction(
          label: AppStrings.setAsWallpaper,
          icon: const Icon(CupertinoIcons.device_phone_portrait),
          onPressed: () {
            Navigator.pop(context);
            onSetWallpaper();
          },
        ),
        GlassActionSheetAction(
          label: AppStrings.customizeLockScreen,
          icon: const Icon(CupertinoIcons.paintbrush),
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        GlassActionSheetAction(
          label: AppStrings.rename,
          icon: const Icon(CupertinoIcons.pencil),
          onPressed: () {
            Navigator.pop(context);
            onRename();
          },
        ),
        GlassActionSheetAction(
          label: AppStrings.duplicate,
          icon: const Icon(CupertinoIcons.doc_on_doc),
          onPressed: () {
            Navigator.pop(context);
            onDuplicate();
          },
        ),
        GlassActionSheetAction(
          label: AppStrings.delete,
          icon: const Icon(CupertinoIcons.trash),
          style: GlassActionSheetStyle.destructive,
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
      cancelLabel: AppStrings.cancel,
    );
  }

  Widget _buildLiveFallback() {
    return SceneCanvasPreview(
      layers: scene.layers,
      config: scene.styleConfig,
      showFrame: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        final String? thumbPath = scene.previewCardPath;
        final bool hasThumbPath = thumbPath != null && thumbPath.isNotEmpty;

        return PressScaleWrapper(
          isEnabled: !isApplying,
          onTap: isApplying ? null : onTap,
          onLongPress: isApplying ? null : () => _showIosActions(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scene.isCurrentWallpaper
                    ? AppColors.accent
                    : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              shape: const LiquidRoundedSuperellipse(borderRadius: 20),
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                hasThumbPath
                                    ? Image.file(
                                  File(thumbPath),
                                  cacheWidth: 540,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                      _buildLiveFallback(),
                                )
                                    : _buildLiveFallback(),
                                if (isApplying)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.48),
                                    child: const Center(
                                      child: CupertinoActivityIndicator(
                                        radius: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                scene.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(28, 28),
                              onPressed: isApplying
                                  ? null
                                  : () => _showIosActions(context),
                              child: Icon(
                                CupertinoIcons.ellipsis_circle,
                                color: AppColors.textSecondary,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (scene.isCurrentWallpaper)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}