import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/wallpaper_config.dart';

class DepthDatePainter extends CustomPainter {
  final WallpaperConfig config;
  final String dateText;
  final double animProgress;

  DepthDatePainter({
    required this.config,
    required this.dateText,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double p = animProgress.clamp(0.0, 1.0);
    if (p <= 0.01) return;

    final double width = size.width;
    final double height = size.height;
    final double fontSize = config.dateFontSize * width;

    final String style = config.clockAnimStyle;
    double alphaFactor = 1.0;
    double offsetY = 0.0;
    double scaleFactor = 1.0;

    if (style != 'None') {
      alphaFactor = p;
      if (style == 'SlideUp') {
        offsetY = (1.0 - p) * (height * 0.08);
      } else if (style == 'SlideDown') {
        offsetY = -(1.0 - p) * (height * 0.08);
      } else if (style == 'ScaleUp') {
        scaleFactor = 0.72 + (0.28 * p);
      } else if (style == 'ScaleDown') {
        scaleFactor = 1.28 - (0.28 * p);
      }
    }

    final tp = TextPainter(
      text: TextSpan(
        text: dateText,
        style: TextStyle(
          fontFamily: config.dateFontFamily,
          fontSize: fontSize,
          color: config.dateColor.withValues(alpha: alphaFactor),
          fontWeight: config.dateBold ? FontWeight.w700 : FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.54 * alphaFactor),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final double baselineOffset =
    tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final double centerX =
        (width / 2.0) + (config.dateHorizontalPos - 0.50) * width * 2.0;
    final double targetBaselineY =
        (config.dateVerticalPos * height) + (fontSize * 0.85) + offsetY;

    canvas.save();
    if (scaleFactor != 1.0) {
      canvas.translate(centerX, targetBaselineY - (fontSize * 0.4));
      canvas.scale(scaleFactor, scaleFactor);
      canvas.translate(-centerX, -(targetBaselineY - (fontSize * 0.4)));
    }

    tp.paint(
      canvas,
      Offset(centerX - tp.width / 2.0, targetBaselineY - baselineOffset),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DepthDatePainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.dateText != dateText ||
        oldDelegate.animProgress != animProgress;
  }
}