import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';
import '../widgets/circular_glass_icon_button.dart';
import '../widgets/wallpaper_preview.dart';

class PreviewScreen extends StatefulWidget {
  final String? originalImagePath;
  final String? foregroundImagePath;
  final WallpaperConfig? wallpaperConfig;

  const PreviewScreen({
    super.key,
    this.originalImagePath,
    this.foregroundImagePath,
    this.wallpaperConfig,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    final wallpaperData = WallpaperData(
      originalImagePath: widget.originalImagePath,
      foregroundImagePath: widget.foregroundImagePath,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'wallpaper_preview_hero',
                child: WallpaperPreview(
                  data: wallpaperData,
                  config: widget.wallpaperConfig ?? WallpaperConfig(),
                  showFrame: false,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: CircularGlassIconButton(
                    icon: CupertinoIcons.xmark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 8.0,
                  ),
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
