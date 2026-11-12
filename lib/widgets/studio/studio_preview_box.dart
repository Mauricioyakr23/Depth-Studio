import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';
import '../../models/wallpaper_config.dart';
import '../../models/wallpaper_data.dart';
import '../wallpaper_preview.dart';

class StudioPreviewBox extends StatelessWidget {
  final GlobalKey previewKey;
  final WallpaperData wallpaperData;
  final WallpaperConfig wallpaperConfig;
  final Animation<double> previewCurvedAnim;
  final bool isLoading;
  final String loadingText;
  final VoidCallback onTap;

  const StudioPreviewBox({
    super.key,
    required this.previewKey,
    required this.wallpaperData,
    required this.wallpaperConfig,
    required this.previewCurvedAnim,
    required this.isLoading,
    required this.loadingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double usableHeight = constraints.maxHeight;
        final double targetFraction = screenHeight < 700.0 ? 0.25 : 0.32;
        final double desiredPreviewHeight = screenHeight * targetFraction;
        final double maxPreviewForHalfControls = (usableHeight * 0.50) - 54.0;
        final double effectivePreviewHeight = desiredPreviewHeight.clamp(
          136.0,
          maxPreviewForHalfControls.clamp(136.0, 340.0),
        );

        return Center(
          child: GestureDetector(
            onTap: isLoading ? null : onTap,
            child: SizedBox(
              height: effectivePreviewHeight,
              child: Stack(
                children: [
                  Hero(
                    tag: 'wallpaper_preview_hero',
                    child: RepaintBoundary(
                      key: previewKey,
                      child: AnimatedBuilder(
                        animation: previewCurvedAnim,
                        builder: (context, _) {
                          return WallpaperPreview(
                            data: wallpaperData,
                            config: wallpaperConfig,
                            showFrame: true,
                            animProgress: previewCurvedAnim.value,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isLoading
                          ? GlassContainer(
                              key: const ValueKey('loading_overlay'),
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 30,
                              ),
                              settings: const LiquidGlassSettings(
                                blur: 16.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CupertinoActivityIndicator(radius: 14),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      loadingText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('not_loading'),
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
