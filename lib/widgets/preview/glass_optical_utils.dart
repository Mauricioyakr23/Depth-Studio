import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlassOpticalUtils {
  const GlassOpticalUtils._();

  static bool isGlassMode(String mode) =>
      mode == 'Liquid' || mode == 'Acrylic' || mode == 'Aero';

  static List<double> buildOpticalGlassMatrix(
      Color tintColor,
      double brightness,
      String mode,
      ) {
    final double b = brightness.clamp(0.0, 1.0);
    final double tr = (tintColor.r * 255.0).round().clamp(0, 255) / 255.0;
    final double tg = (tintColor.g * 255.0).round().clamp(0, 255) / 255.0;
    final double tb = (tintColor.b * 255.0).round().clamp(0, 255) / 255.0;

    final double sat =
    mode == 'Aero' ? 1.65 : (mode == 'Liquid' ? 1.45 : 1.48);
    final double invSat = 1.0 - sat;
    final double lumR = 0.2126 * invSat;
    final double lumG = 0.7152 * invSat;
    final double lumB = 0.0722 * invSat;

    final double baseGain =
    mode == 'Acrylic' ? (0.96 + b * 0.28) : (0.94 + b * 0.24);
    final double rGain = baseGain * (0.65 + 0.35 * tr);
    final double gGain = baseGain * (0.65 + 0.35 * tg);
    final double bGain = baseGain * (0.65 + 0.35 * tb);

    final double frostLift = mode == 'Acrylic'
        ? (18.0 + b * 20.0)
        : (mode == 'Aero' ? (10.0 + b * 15.0) : (6.0 + b * 10.0));

    return [
      (lumR + sat) * rGain, lumG * rGain, lumB * rGain, 0.0, frostLift,
      lumR * gGain, (lumG + sat) * gGain, lumB * gGain, 0.0, frostLift,
      lumR * bGain, lumG * bGain, (lumB + sat) * bGain, 0.0, frostLift,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  static void applyGlassOverMask({
    required Canvas canvas,
    required Size canvasSize,
    required Rect bounds,
    required ui.Image? bgImage,
    required Color tintColor,
    required String mode,
    required double rawBlurAmount,
    required double rimBrightness,
  }) {
    final bool isLiquid = mode == 'Liquid';
    final bool isAcrylic = mode == 'Acrylic';
    final double glassBr = rimBrightness.clamp(0.0, 1.0);

    if (bgImage != null) {
      final double rawBlur = rawBlurAmount.clamp(1.0, 45.0);
      final double sigma = isLiquid
          ? (rawBlur * 0.15).clamp(1.5, 5.0)
          : (mode == 'Aero'
          ? (rawBlur * 1.15).clamp(14.0, 30.0)
          : (rawBlur * 0.95).clamp(12.0, 28.0));

      final Paint blurBgPaint = Paint()
        ..blendMode = BlendMode.srcIn
        ..colorFilter = ColorFilter.matrix(
          buildOpticalGlassMatrix(tintColor, glassBr, mode),
        )
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        );

      final Size imgSize =
      Size(bgImage.width.toDouble(), bgImage.height.toDouble());
      final FittedSizes fitted = applyBoxFit(BoxFit.cover, imgSize, canvasSize);
      final Rect srcRect =
      Alignment.center.inscribe(fitted.source, Offset.zero & imgSize);
      final Rect dstRect = Alignment.center
          .inscribe(fitted.destination, Offset.zero & canvasSize);

      canvas.save();
      if (isLiquid) {
        final Offset lensCenter = bounds.center;
        canvas.translate(lensCenter.dx, lensCenter.dy + 1.0);
        canvas.scale(1.015, 1.015);
        canvas.translate(-lensCenter.dx, -lensCenter.dy);
      }
      canvas.drawImageRect(bgImage, srcRect, dstRect, blurBgPaint);
      canvas.restore();
    }

    final bool isNearWhite =
        tintColor.r > 0.92 && tintColor.g > 0.92 && tintColor.b > 0.92;
    final double frostVeilAlpha = isAcrylic
        ? (isNearWhite ? 0.20 : 0.28)
        : (isLiquid
        ? (isNearWhite ? 0.08 : 0.16)
        : (isNearWhite ? 0.12 : 0.22));

    final Paint uniformFrostPaint = Paint()
      ..blendMode = BlendMode.srcATop
      ..color = tintColor.withValues(alpha: frostVeilAlpha);
    canvas.drawRect(bounds, uniformFrostPaint);
  }
}