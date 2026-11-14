import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import 'music_canvas_view.dart';

class MusicPreviewBox extends StatelessWidget {
  final AppSettings settings;
  final int selectedTarget;
  final ValueChanged<int> onTargetSelected;

  const MusicPreviewBox({
    super.key,
    required this.settings,
    required this.selectedTarget,
    required this.onTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double screenHeight = screenSize.height;
    final double aspectRatio = (screenSize.width > 0 && screenSize.height > 0)
        ? (screenSize.width / screenSize.height)
        : (9.0 / 19.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double usableHeight = constraints.maxHeight;
        final double targetFraction = screenHeight < 700.0 ? 0.25 : 0.32;
        final double desiredHeight = screenHeight * targetFraction;
        final double maxForHalf = (usableHeight * 0.50) - 54.0;
        final double effectiveHeight = desiredHeight.clamp(
          136.0,
          maxForHalf.clamp(136.0, 340.0),
        );

        return Center(
          child: SizedBox(
            height: effectiveHeight,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: MusicCanvasView(
                    settings: settings,
                    selectedTarget: selectedTarget,
                    onTargetSelected: onTargetSelected,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}