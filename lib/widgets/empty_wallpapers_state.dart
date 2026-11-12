import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../core/core.dart';

class WallpapersSortRow extends StatelessWidget {
  final int count;
  final String sortMode;
  final VoidCallback onToggleSort;

  const WallpapersSortRow({
    super.key,
    required this.count,
    required this.sortMode,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        4,
        AppLayout.screenPaddingH,
        12,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              AppStrings.savedLockScreens(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GlassButton.custom(
            onTap: onToggleSort,
            height: 32,
            shape: const LiquidRoundedSuperellipse(borderRadius: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    color: AppColors.accent,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sortMode == 'recent'
                        ? AppStrings.sortRecent
                        : AppStrings.sortName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyWallpapersState extends StatelessWidget {
  final VoidCallback onOpenStudio;

  const EmptyWallpapersState({
    super.key,
    required this.onOpenStudio,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppLayout.screenPaddingH,
          16,
          AppLayout.screenPaddingH,
          AppLayout.bottomDockPadding(context),
        ),
        child: GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.rectangle_stack_fill,
                  size: 28,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noWallpapersTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.noWallpapersDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: onOpenStudio,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.paintbrush_fill,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.openStudio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
