import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/depth_scene_config.dart';
import 'glass_optical_utils.dart';

class DepthClockPainter extends CustomPainter {
  final DepthSceneConfig config;
  final ui.Image? bgImage;
  final bool paintHours;
  final bool paintMinutes;
  final double animProgress;
  final String hourStr;
  final String minStr;

  DepthClockPainter({
    required this.config,
    required this.bgImage,
    required this.paintHours,
    required this.paintMinutes,
    required this.animProgress,
    required this.hourStr,
    required this.minStr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double p = animProgress.clamp(0.0, 1.0);
    if (p <= 0.01) return;

    final double width = size.width;
    final double height = size.height;
    final double fontSize = config.fontSize * width;
    final double letterSpacingPx = config.letterSpacing * fontSize;

    final String animStyle = config.clockAnimStyle;
    double animAlpha = 1.0;
    double animOffsetY = 0.0;
    double animScale = 1.0;

    if (animStyle != 'None') {
      animAlpha = p;
      if (animStyle == 'SlideUp') {
        animOffsetY = (1.0 - p) * (height * 0.12);
      } else if (animStyle == 'SlideDown') {
        animOffsetY = -(1.0 - p) * (height * 0.12);
      } else if (animStyle == 'ScaleUp') {
        animScale = 0.68 + (0.32 * p);
      } else if (animStyle == 'ScaleDown') {
        animScale = 1.32 - (0.32 * p);
      }
    }

    final double effectiveOpacity =
    (config.textOpacity * animAlpha).clamp(0.0, 1.0);
    if (effectiveOpacity <= 0.01) return;

    final String sepStr = config.clockFormat == 'HH:MM'
        ? ':'
        : (config.clockFormat == 'HH MM' ? ' ' : '');

    final String? resolvedFamily =
    config.fontFamily == 'Sans-Serif' ? null : config.fontFamily;

    final TextStyle baseStyle = TextStyle(
      fontFamily: resolvedFamily,
      fontSize: fontSize,
      letterSpacing: letterSpacingPx,
    );

    final double centerX = ui.lerpDouble(-width * 0.5, width * 1.5, config.horizontalPos)!;
    final double topY = (config.verticalPos * height) + animOffsetY;

    TextPainter buildTp(String text, Color color, {Paint? foreground}) {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: baseStyle.copyWith(
            color: foreground == null ? color : null,
            foreground: foreground,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
    }

    final tpHour = buildTp(hourStr, Colors.white);
    final tpSep = buildTp(sepStr, Colors.white);
    final tpMin = buildTp(minStr, Colors.white);

    final List<ui.LineMetrics> hourLm = tpHour.computeLineMetrics();
    final double realAscent =
    hourLm.isNotEmpty ? hourLm.first.ascent : (fontSize * 0.85);
    final double realDescent =
    hourLm.isNotEmpty ? hourLm.first.descent : (fontSize * 0.20);

    final double hourBaselineY = topY + (fontSize * 0.82);
    final double stepY = (fontSize * 0.88) + (config.lineSpacing * height);

    final double hourVisualW = tpHour.width - letterSpacingPx;
    final double minVisualW = tpMin.width - letterSpacingPx;

    late final double hourX;
    late final double sepX;
    late final double minX;
    late final double minBaselineY;
    late final Offset pivotPoint;

    if (config.clockDisplay == 'Vertical') {
      hourX = centerX - (hourVisualW / 2.0);
      sepX = 0.0;
      minX = centerX - (minVisualW / 2.0);
      minBaselineY = hourBaselineY + stepY;
      pivotPoint =
          Offset(centerX, hourBaselineY - (fontSize * 0.41) + (stepY / 2.0));
    } else {
      final double fullVisualW =
          tpHour.width + tpSep.width + tpMin.width - letterSpacingPx;
      final double startX = centerX - (fullVisualW / 2.0);
      hourX = startX;
      sepX = startX + tpHour.width;
      minX = startX + tpHour.width + tpSep.width;
      minBaselineY = hourBaselineY;
      pivotPoint = Offset(centerX, hourBaselineY - (fontSize * 0.41));
    }

    void paintAtBaseline(TextPainter tp, double x, double baselineY) {
      final double baseOff =
      tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp.paint(canvas, Offset(x, baselineY - baseOff));
    }

    final String mode = config.depthMode;
    final bool isGlass = GlassOpticalUtils.isGlassMode(mode);
    final bool isLiquid = mode == 'Liquid';
    final double glassBr = config.rimBrightness.clamp(0.0, 1.0);

    void applyStretchAndAnimTransform() {
      canvas.translate(pivotPoint.dx, pivotPoint.dy);
      canvas.scale(animScale, config.stretch * animScale);
      canvas.translate(-pivotPoint.dx, -pivotPoint.dy);
    }

    Rect computeStretchedBounds(
        double leftX,
        double widthSpan,
        double baselineY,
        ) {
      final double rawTop = baselineY - realAscent;
      final double rawBottom = baselineY + realDescent;
      final double stretchedTop = pivotPoint.dy +
          (rawTop - pivotPoint.dy) * config.stretch * animScale;
      final double stretchedBottom = pivotPoint.dy +
          (rawBottom - pivotPoint.dy) * config.stretch * animScale;
      return Rect.fromLTRB(
        leftX,
        stretchedTop,
        leftX + widthSpan,
        stretchedBottom,
      );
    }

    void paintComponentMask(
        bool isHoursComp, {
          Paint? customPaint,
          Color fillColor = Colors.white,
        }) {
      if (isHoursComp) {
        final tpH = customPaint != null
            ? buildTp(hourStr, fillColor, foreground: customPaint)
            : buildTp(hourStr, fillColor);
        paintAtBaseline(tpH, hourX, hourBaselineY);
        if (config.clockDisplay == 'Horizontal' && sepStr.isNotEmpty) {
          final tpS = customPaint != null
              ? buildTp(sepStr, fillColor, foreground: customPaint)
              : buildTp(sepStr, fillColor);
          paintAtBaseline(tpS, sepX, hourBaselineY);
        }
      } else {
        final tpM = customPaint != null
            ? buildTp(minStr, fillColor, foreground: customPaint)
            : buildTp(minStr, fillColor);
        paintAtBaseline(tpM, minX, minBaselineY);
      }
    }

    void drawRimContour(bool isHoursComp, Color tintColor) {
      if (!config.edgeStrokeEnabled) return;
      final double userWidth = config.rimWidth.clamp(0.5, 8.0);
      final double userOpacity = config.rimOpacity.clamp(0.05, 1.0);
      final double userBlur = config.rimBlur.clamp(0.0, 12.0);
      final Color rimColor =
      Color.lerp(tintColor, Colors.white, 0.35 + 0.65 * glassBr)!;

      canvas.save();
      applyStretchAndAnimTransform();

      if (isLiquid || userBlur > 0.1) {
        final double glowSigma =
        userBlur > 0.1 ? userBlur : (isLiquid ? 2.5 : 1.0);
        final Paint glowRimPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (userWidth * 1.65).clamp(1.2, 12.0)
          ..blendMode = BlendMode.srcATop
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma)
          ..color = rimColor.withValues(
            alpha: (userOpacity * (0.40 + 0.35 * glassBr)).clamp(0.10, 0.85),
          );
        paintComponentMask(isHoursComp, customPaint: glowRimPaint);
      }

      final Paint crispRimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = userWidth
        ..blendMode = BlendMode.srcATop
        ..color = rimColor.withValues(
          alpha: (userOpacity * (0.55 + 0.45 * glassBr)).clamp(0.10, 1.0),
        );
      paintComponentMask(isHoursComp, customPaint: crispRimPaint);

      canvas.restore();
    }

    void renderIsolatedComponent(bool isHoursComp) {
      final Color tintColor =
      isHoursComp ? config.fontColor : config.minuteColor;
      final double compLeft = isHoursComp ? hourX : minX;
      final double compWidth = isHoursComp
          ? (tpHour.width +
          (config.clockDisplay == 'Horizontal' ? tpSep.width : 0.0))
          : tpMin.width;
      final double compBaselineY = isHoursComp ? hourBaselineY : minBaselineY;
      final Rect compScreenBounds =
      computeStretchedBounds(compLeft, compWidth, compBaselineY);
      final Rect paddedBounds = compScreenBounds.inflate(28.0);

      if (config.shadowEnabled) {
        canvas.saveLayer(
          paddedBounds,
          Paint()..color = Colors.white.withValues(alpha: animAlpha),
        );
        canvas.save();
        applyStretchAndAnimTransform();

        void drawShadowText(String text, double x, double baseY) {
          if (text.isEmpty) return;
          final tpShadow = TextPainter(
            text: TextSpan(
              text: text,
              style: baseStyle.copyWith(
                color: Colors.black,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(
                      alpha: isLiquid ? 0.28 : (isGlass ? 0.24 : 0.38),
                    ),
                    offset: Offset(0, isLiquid ? 4 : 3),
                    blurRadius: isLiquid ? 14 : (isGlass ? 12 : 10),
                  ),
                ],
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          paintAtBaseline(tpShadow, x, baseY);
        }

        if (isHoursComp) {
          drawShadowText(hourStr, hourX, hourBaselineY);
          if (config.clockDisplay == 'Horizontal') {
            drawShadowText(sepStr, sepX, hourBaselineY);
          }
        } else {
          drawShadowText(minStr, minX, minBaselineY);
        }

        final Paint punchShadow = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black
          ..blendMode = BlendMode.dstOut;
        paintComponentMask(isHoursComp, customPaint: punchShadow);

        canvas.restore();
        canvas.restore();
      }

      if (!isGlass) {
        canvas.saveLayer(
          paddedBounds,
          Paint()..color = Colors.white.withValues(alpha: effectiveOpacity),
        );
        canvas.save();
        applyStretchAndAnimTransform();
        paintComponentMask(isHoursComp, fillColor: tintColor);
        canvas.restore();
        drawRimContour(isHoursComp, tintColor);
        canvas.restore();
        return;
      }

      canvas.saveLayer(
        paddedBounds,
        Paint()..color = Colors.white.withValues(alpha: effectiveOpacity),
      );

      canvas.save();
      applyStretchAndAnimTransform();
      paintComponentMask(isHoursComp, fillColor: Colors.white);
      canvas.restore();

      GlassOpticalUtils.applyGlassOverMask(
        canvas: canvas,
        canvasSize: size,
        bounds: paddedBounds,
        bgImage: bgImage,
        tintColor: tintColor,
        mode: mode,
        rawBlurAmount: config.blurAmount,
        rimBrightness: config.rimBrightness,
      );

      drawRimContour(isHoursComp, tintColor);
      canvas.restore();
    }

    if (paintHours) renderIsolatedComponent(true);
    if (paintMinutes) renderIsolatedComponent(false);
  }

  @override
  bool shouldRepaint(covariant DepthClockPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.bgImage != bgImage ||
        oldDelegate.paintHours != paintHours ||
        oldDelegate.paintMinutes != paintMinutes ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.hourStr != hourStr ||
        oldDelegate.minStr != minStr;
  }
}