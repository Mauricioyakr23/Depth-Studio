import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/app_settings.dart';
import '../preview/glass_optical_utils.dart';

class _TextPainterCacheKey {
  final String text;
  final String? family;
  final double fontSize;
  final FontWeight weight;
  final int colorArgb;
  final bool isStroke;
  final double strokeWidth;
  final double blurSigma;
  final BlendMode? blendMode;

  const _TextPainterCacheKey({
    required this.text,
    required this.family,
    required this.fontSize,
    required this.weight,
    required this.colorArgb,
    required this.isStroke,
    required this.strokeWidth,
    required this.blurSigma,
    required this.blendMode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TextPainterCacheKey &&
        other.text == text &&
        other.family == family &&
        other.fontSize == fontSize &&
        other.weight == weight &&
        other.colorArgb == colorArgb &&
        other.isStroke == isStroke &&
        other.strokeWidth == strokeWidth &&
        other.blurSigma == blurSigma &&
        other.blendMode == blendMode;
  }

  @override
  int get hashCode => Object.hash(
    text,
    family,
    fontSize,
    weight,
    colorArgb,
    isStroke,
    strokeWidth,
    blurSigma,
    blendMode,
  );
}

class _MusicTextPainterCache {
  _MusicTextPainterCache._();

  static const int _maxEntries = 64;
  static final LinkedHashMap<_TextPainterCacheKey, TextPainter> _entries =
  LinkedHashMap<_TextPainterCacheKey, TextPainter>();

  static TextPainter obtain({
    required String text,
    required String? family,
    required double fontSize,
    required FontWeight weight,
    required Color color,
    bool isStroke = false,
    double strokeWidth = 0.0,
    double blurSigma = 0.0,
    BlendMode? blendMode,
  }) {
    final key = _TextPainterCacheKey(
      text: text,
      family: family,
      fontSize: fontSize,
      weight: weight,
      colorArgb: color.toARGB32(),
      isStroke: isStroke,
      strokeWidth: strokeWidth,
      blurSigma: blurSigma,
      blendMode: blendMode,
    );

    final TextPainter? cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }

    final bool needsCustomPaint =
        isStroke || blurSigma > 0.0 || blendMode != null;
    Paint? foregroundPaint;
    if (needsCustomPaint) {
      foregroundPaint = Paint()..color = color;
      if (isStroke) {
        foregroundPaint
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;
      }
      if (blurSigma > 0.0) {
        foregroundPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      }
      if (blendMode != null) {
        foregroundPaint.blendMode = blendMode;
      }
    }

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: family,
          fontSize: fontSize,
          fontWeight: weight,
          color: foregroundPaint == null ? color : null,
          foreground: foregroundPaint,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    if (_entries.length >= _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = tp;
    return tp;
  }
}

class MusicOpticalPainter extends CustomPainter {
  final AppSettings settings;
  final ui.Image? bgImage;
  final String clockText;
  final String dateText;
  final Rect cardRect;
  final double cardCorner;

  MusicOpticalPainter({
    required this.settings,
    required this.bgImage,
    required this.clockText,
    required this.dateText,
    required this.cardRect,
    required this.cardCorner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintClockAndDate(canvas, size);
    _paintPlayerCard(canvas, size);
  }

  void _paintClockAndDate(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double unitScale = w / 360.0;
    final double scale = settings.musicClockScale;
    final double opacity = settings.musicClockOpacity.clamp(0.15, 1.0);
    final String mode = settings.musicClockMaterial;
    final bool isGlass = GlassOpticalUtils.isGlassMode(mode);
    final bool isLiquid = mode == 'Liquid';
    final double br = settings.musicClockBrightness.clamp(0.0, 1.0);

    final String? clockFamily = settings.musicClockFont == 'Sans-Serif'
        ? null
        : settings.musicClockFont;
    final String? dateFamily = settings.musicDateFont == 'Sans-Serif'
        ? null
        : settings.musicDateFont;

    final double clockSize = w * 0.068 * scale;
    final double dateSize = w * 0.052 * scale;
    final double gap = 13.0 * unitScale * scale;

    final tpClock = _MusicTextPainterCache.obtain(
      text: clockText,
      family: clockFamily,
      fontSize: clockSize,
      weight: FontWeight.w700,
      color: Colors.white,
    );
    final tpDate = _MusicTextPainterCache.obtain(
      text: dateText,
      family: dateFamily,
      fontSize: dateSize,
      weight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.88),
    );

    final double totalW = tpClock.width + gap + tpDate.width;
    final double centerX = (w / 2.0) + (settings.musicClockX - 0.50) * w * 1.4;
    final double minMargin = 12.0 * unitScale;
    final double maxStartX = (w - totalW - minMargin).clamp(minMargin, w);
    final double startX =
    (centerX - totalW / 2.0).clamp(minMargin, maxStartX);
    final double baselineY = (h * settings.musicClockY) + (clockSize * 0.85);

    final double clockBaseOff =
    tpClock.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final double dateBaseOff =
    tpDate.computeDistanceToActualBaseline(TextBaseline.alphabetic);

    final Offset clockPos = Offset(startX, baselineY - clockBaseOff);
    final Offset datePos = Offset(
      startX + tpClock.width + gap,
      baselineY - dateBaseOff - (1.5 * unitScale),
    );

    final Rect bounds = Rect.fromLTWH(
      startX,
      clockPos.dy,
      totalW,
      tpClock.height,
    ).inflate(16.0 * unitScale + 6.0);

    void paintTexts({
      Color fillColor = Colors.white,
      bool isStroke = false,
      double strokeWidth = 0.0,
      double blurSigma = 0.0,
      BlendMode? blendMode,
    }) {
      final cTp = _MusicTextPainterCache.obtain(
        text: clockText,
        family: clockFamily,
        fontSize: clockSize,
        weight: FontWeight.w700,
        color: fillColor,
        isStroke: isStroke,
        strokeWidth: strokeWidth,
        blurSigma: blurSigma,
        blendMode: blendMode,
      );
      final dTp = _MusicTextPainterCache.obtain(
        text: dateText,
        family: dateFamily,
        fontSize: dateSize,
        weight: FontWeight.w500,
        color: fillColor.withValues(alpha: fillColor.a * 0.88),
        isStroke: isStroke,
        strokeWidth: strokeWidth,
        blurSigma: blurSigma,
        blendMode: blendMode,
      );
      cTp.paint(canvas, clockPos);
      dTp.paint(canvas, datePos);
    }

    if (settings.musicClockShadowEnabled) {
      canvas.saveLayer(bounds, Paint());
      final double shadowBlur =
          (isLiquid ? 6.0 : (isGlass ? 5.0 : 4.0)) * unitScale + 1.0;
      canvas.save();
      canvas.translate(0, 1.5 * unitScale);
      paintTexts(
        fillColor: Colors.black,
        blurSigma: shadowBlur,
      );
      canvas.restore();
      paintTexts(
        fillColor: Colors.black,
        blendMode: BlendMode.dstOut,
      );
      canvas.restore();
    }

    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    if (!isGlass) {
      paintTexts(fillColor: Colors.white);
    } else {
      paintTexts(fillColor: Colors.white);
      GlassOpticalUtils.applyGlassOverMask(
        canvas: canvas,
        canvasSize: size,
        bounds: bounds,
        bgImage: bgImage,
        tintColor: Colors.white,
        mode: mode,
        rawBlurAmount: settings.musicClockBlur,
        rimBrightness: br,
      );
    }

    if (settings.musicClockEdgeStrokeEnabled) {
      final double userW =
      (settings.musicClockRimWidth * 0.55 * unitScale).clamp(0.4, 4.0);
      final double userBlur = settings.musicClockRimBlur.clamp(0.0, 12.0);
      final Color rimColor =
      Color.lerp(Colors.white, const Color(0xFFE5F2FF), 0.35 + 0.65 * br)!;

      if (isLiquid || userBlur > 0.1) {
        final double sigma =
            (userBlur > 0.1 ? userBlur * 0.5 : 1.5) * unitScale + 0.4;
        paintTexts(
          fillColor: rimColor.withValues(alpha: 0.65),
          isStroke: true,
          strokeWidth: userW * 1.6,
          blurSigma: sigma,
          blendMode: BlendMode.srcATop,
        );
      }

      paintTexts(
        fillColor: rimColor.withValues(alpha: 0.85),
        isStroke: true,
        strokeWidth: userW,
        blendMode: BlendMode.srcATop,
      );
    }

    canvas.restore();
  }

  void _paintPlayerCard(Canvas canvas, Size size) {
    final double unitScale = size.width / 360.0;
    final double opacity = settings.musicCardOpacity.clamp(0.15, 1.0);
    final String mode = settings.musicCardMaterial;
    final bool isGlass = GlassOpticalUtils.isGlassMode(mode);
    final bool isLiquid = mode == 'Liquid';
    final double br = settings.musicCardBrightness.clamp(0.0, 1.0);
    final RRect rrect = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(cardCorner),
    );
    final Rect paddedBounds = cardRect.inflate(18.0 * unitScale + 6.0);

    if (settings.musicCardShadowEnabled) {
      canvas.saveLayer(paddedBounds, Paint());
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: isGlass ? 0.34 : 0.48)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (isLiquid ? 14.0 : (isGlass ? 11.0 : 8.0)) * unitScale + 2.0,
        );
      canvas.drawRRect(rrect.shift(Offset(0, 6.0 * unitScale)), shadowPaint);
      final punch = Paint()
        ..color = Colors.black
        ..blendMode = BlendMode.dstOut;
      canvas.drawRRect(rrect, punch);
      canvas.restore();
    }

    canvas.saveLayer(
      paddedBounds,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    if (!isGlass) {
      canvas.drawRRect(
        rrect,
        Paint()..color = const Color(0xFF18181C).withValues(alpha: 0.84),
      );
    } else {
      canvas.drawRRect(rrect, Paint()..color = Colors.white);
      GlassOpticalUtils.applyGlassOverMask(
        canvas: canvas,
        canvasSize: size,
        bounds: paddedBounds,
        bgImage: bgImage,
        tintColor: Colors.white,
        mode: mode,
        rawBlurAmount: settings.musicCardBlur,
        rimBrightness: br,
      );
    }

    if (settings.musicCardEdgeStrokeEnabled) {
      final double userW =
      (settings.musicCardRimWidth * unitScale).clamp(0.5, 8.0);
      final double userBlur = settings.musicCardRimBlur.clamp(0.0, 12.0);
      final Color rimColor =
      Color.lerp(Colors.white, const Color(0xFFE5F2FF), 0.35 + 0.65 * br)!;

      if (isLiquid || userBlur > 0.1) {
        final double sigma =
            (userBlur > 0.1 ? userBlur : 2.2) * unitScale + 0.4;
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (userW * 1.6).clamp(1.0, 12.0)
          ..blendMode = BlendMode.srcATop
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma)
          ..color = rimColor.withValues(alpha: 0.65);
        canvas.drawRRect(rrect, glowPaint);
      }

      final crispPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = userW
        ..blendMode = BlendMode.srcATop
        ..color = rimColor.withValues(alpha: 0.85);
      canvas.drawRRect(rrect, crispPaint);
    } else {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (0.95 * unitScale).clamp(0.5, 1.5)
          ..blendMode = BlendMode.srcATop
          ..color = Colors.white.withValues(alpha: 0.25),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MusicOpticalPainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.bgImage != bgImage ||
        oldDelegate.clockText != clockText ||
        oldDelegate.dateText != dateText ||
        oldDelegate.cardRect != cardRect ||
        oldDelegate.cardCorner != cardCorner;
  }
}