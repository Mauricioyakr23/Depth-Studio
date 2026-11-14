import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/depth_scene_config.dart';
import '../models/scene_layers.dart';
import '../widgets/circular_glass_icon_button.dart';
import '../widgets/scene_canvas_preview.dart';

class FullscreenPreviewScreen extends StatefulWidget {
  final SceneLayers layers;
  final DepthSceneConfig config;

  const FullscreenPreviewScreen({
    super.key,
    required this.layers,
    this.config = const DepthSceneConfig(),
  });

  @override
  State<FullscreenPreviewScreen> createState() =>
      _FullscreenPreviewScreenState();
}

class _FullscreenPreviewScreenState extends State<FullscreenPreviewScreen> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.viewPaddingOf(context).top + 16.0;
    final double bottomPadding =
        MediaQuery.viewPaddingOf(context).bottom + 10.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'scene_canvas_hero',
                child: SceneCanvasPreview(
                  layers: widget.layers,
                  config: widget.config,
                  showFrame: false,
                ),
              ),
            ),
            Positioned(
              top: topPadding,
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
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Container(
                      width: 134,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
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