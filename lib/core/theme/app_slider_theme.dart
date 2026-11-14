import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSliderTheme {
  const AppSliderTheme._();

  static SliderThemeData of(BuildContext context) {
    final bool isLight = AppColors.isLight;
    return SliderTheme.of(context).copyWith(
      trackHeight: 4,
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: isLight
          ? Colors.black.withValues(alpha: 0.14)
          : AppColors.divider.withValues(alpha: 0.35),
      thumbColor: Colors.white,
      overlayColor: AppColors.accent.withValues(alpha: 0.15),
      thumbShape: _AdaptiveSliderThumbShape(
        enabledThumbRadius: 11,
        elevation: isLight ? 4.0 : 3.0,
        showBorder: isLight,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    );
  }
}

class _AdaptiveSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double elevation;
  final bool showBorder;

  const _AdaptiveSliderThumbShape({
    required this.enabledThumbRadius,
    required this.elevation,
    required this.showBorder,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;
    final Path thumbPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: enabledThumbRadius));

    canvas.drawShadow(
      thumbPath,
      Colors.black.withValues(alpha: showBorder ? 0.32 : 0.45),
      elevation,
      true,
    );

    canvas.drawCircle(
      center,
      enabledThumbRadius,
      Paint()
        ..color = sliderTheme.thumbColor ?? Colors.white
        ..style = PaintingStyle.fill,
    );

    if (showBorder) {
      canvas.drawCircle(
        center,
        enabledThumbRadius - 0.6,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
  }
}