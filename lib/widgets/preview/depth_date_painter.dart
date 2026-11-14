import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/depth_scene_config.dart';
import 'glass_optical_utils.dart';

class DepthDatePainter extends CustomPainter {
  final DepthSceneConfig config;
  final ui.Image? bgImage;
  final String dateText;
  final double animProgress;

  DepthDatePainter({
    required this.config,
    required this.bgImage,
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

    final double effectiveOpacity =
    (config.dateOpacity * alphaFactor).clamp(0.0, 1.0);
    if (effectiveOpacity <= 0.01) return;

    final String? resolvedFamily =
    config.dateFontFamily == 'Sans-Serif' ? null : config.dateFontFamily;
    final FontWeight weight =
    config.dateBold ? FontWeight.w700 : FontWeight.w500;

    final tp = TextPainter(
      text: TextSpan(
        text: dateText,
        style: TextStyle(
          fontFamily: resolvedFamily,
          fontSize: fontSize,
          color: config.dateColor,
          fontWeight: weight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final double baselineOffset =
    tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final double centerX =
    ui.lerpDouble(-width * 0.5, width * 1.5, config.dateHorizontalPos)!;
    final double targetBaselineY =
        (config.dateVerticalPos * height) + (fontSize * 0.85) + offsetY;
    final Offset drawOffset =
    Offset(centerX - tp.width / 2.0, targetBaselineY - baselineOffset);

    final Rect textBounds = Rect.fromLTWH(
      drawOffset.dx,
      drawOffset.dy,
      tp.width,
      tp.height,
    ).inflate(18.0);

    final String mode = config.dateDepthMode;
    final bool isGlass = GlassOpticalUtils.isGlassMode(mode);

    void applyTransform() {
      if (scaleFactor != 1.0) {
        canvas.translate(centerX, targetBaselineY - (fontSize * 0.4));
        canvas.scale(scaleFactor, scaleFactor);
        canvas.translate(-centerX, -(targetBaselineY - (fontSize * 0.4)));
      }
    }

    if (config.dateShadowEnabled) {
      canvas.saveLayer(
        textBounds,
        Paint()..color = Colors.white.withValues(alpha: alphaFactor),
      );
      canvas.save();
      applyTransform();
      final tpShadow = TextPainter(
        text: TextSpan(
          text: dateText,
          style: TextStyle(
            fontFamily: resolvedFamily,
            fontSize: fontSize,
            color: Colors.black,
            fontWeight: weight,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: isGlass ? 0.34 : 0.54),
                offset: const Offset(0, 2),
                blurRadius: isGlass ? 8 : 6,
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tpShadow.paint(canvas, drawOffset);

      final Paint punchOut = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black
        ..blendMode = BlendMode.dstOut;
      final tpPunch = TextPainter(
        text: TextSpan(
          text: dateText,
          style: TextStyle(
            fontFamily: resolvedFamily,
            fontSize: fontSize,
            fontWeight: weight,
            foreground: punchOut,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tpPunch.paint(canvas, drawOffset);

      canvas.restore();
      canvas.restore();
    }

    if (!isGlass) {
      canvas.saveLayer(
        textBounds,
        Paint()..color = Colors.white.withValues(alpha: effectiveOpacity),
      );
      canvas.save();
      applyTransform();
      tp.paint(canvas, drawOffset);
      canvas.restore();
      canvas.restore();
      return;
    }

    canvas.saveLayer(
      textBounds,
      Paint()..color = Colors.white.withValues(alpha: effectiveOpacity),
    );
    canvas.save();
    applyTransform();
    final tpMask = TextPainter(
      text: TextSpan(
        text: dateText,
        style: TextStyle(
          fontFamily: resolvedFamily,
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: weight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tpMask.paint(canvas, drawOffset);
    canvas.restore();

    GlassOpticalUtils.applyGlassOverMask(
      canvas: canvas,
      canvasSize: size,
      bounds: textBounds,
      bgImage: bgImage,
      tintColor: config.dateColor,
      mode: mode,
      rawBlurAmount: config.dateBlurAmount,
      rimBrightness: config.dateRimBrightness,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DepthDatePainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.bgImage != bgImage ||
        oldDelegate.dateText != dateText ||
        oldDelegate.animProgress != animProgress;
  }
}