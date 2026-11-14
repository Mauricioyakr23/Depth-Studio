import 'package:flutter/material.dart';

class DepthSceneConfig {
  final double fontSize;
  final double horizontalPos;
  final double verticalPos;
  final String clockDisplay;
  final String clockFormat;
  final String depthLayering;
  final Color fontColor;
  final Color minuteColor;
  final String fontFamily;
  final double letterSpacing;
  final double lineSpacing;
  final double stretch;
  final double textOpacity;
  final String depthMode;
  final double blurAmount;
  final bool shadowEnabled;
  final bool edgeStrokeEnabled;
  final double rimWidth;
  final double rimOpacity;
  final double rimBlur;
  final double rimBrightness;
  final String clockAnimStyle;
  final double clockAnimDuration;
  final bool animateOnScreenOn;
  final bool animateOnUnlock;
  final bool showDate;
  final String dateFontFamily;
  final double dateFontSize;
  final double dateHorizontalPos;
  final double dateVerticalPos;
  final Color dateColor;
  final String dateFormat;
  final bool dateAllCaps;
  final bool dateBold;
  final String dateDepthMode;
  final double dateBlurAmount;
  final double dateOpacity;
  final bool dateShadowEnabled;
  final double dateRimBrightness;
  final double backgroundDim;

  const DepthSceneConfig({
    this.fontSize = 0.30,
    this.horizontalPos = 0.50,
    this.verticalPos = 0.22,
    this.clockDisplay = 'Horizontal',
    this.clockFormat = 'HH:MM',
    this.depthLayering = 'Standard',
    this.fontColor = Colors.white,
    this.minuteColor = Colors.white,
    this.fontFamily = 'Display 1',
    this.letterSpacing = 0.0,
    this.lineSpacing = 0.04,
    this.stretch = 1.0,
    this.textOpacity = 1.0,
    this.depthMode = 'Standard',
    this.blurAmount = 18.0,
    this.shadowEnabled = true,
    this.edgeStrokeEnabled = false,
    this.rimWidth = 1.8,
    this.rimOpacity = 0.85,
    this.rimBlur = 0.0,
    this.rimBrightness = 0.65,
    this.clockAnimStyle = 'SlideUp',
    this.clockAnimDuration = 650.0,
    this.animateOnScreenOn = true,
    this.animateOnUnlock = true,
    this.showDate = true,
    this.dateFontFamily = 'Sans-Serif',
    this.dateFontSize = 0.04,
    this.dateHorizontalPos = 0.50,
    this.dateVerticalPos = 0.14,
    this.dateColor = Colors.white,
    this.dateFormat = 'EEE, MMM dd',
    this.dateAllCaps = false,
    this.dateBold = false,
    this.dateDepthMode = 'Standard',
    this.dateBlurAmount = 18.0,
    this.dateOpacity = 1.0,
    this.dateShadowEnabled = true,
    this.dateRimBrightness = 0.65,
    this.backgroundDim = 0.0,
  });

  DepthSceneConfig copyWith({
    double? fontSize,
    double? horizontalPos,
    double? verticalPos,
    String? clockDisplay,
    String? clockFormat,
    String? depthLayering,
    Color? fontColor,
    Color? minuteColor,
    String? fontFamily,
    double? letterSpacing,
    double? lineSpacing,
    double? stretch,
    double? textOpacity,
    String? depthMode,
    double? blurAmount,
    bool? shadowEnabled,
    bool? edgeStrokeEnabled,
    double? rimWidth,
    double? rimOpacity,
    double? rimBlur,
    double? rimBrightness,
    String? clockAnimStyle,
    double? clockAnimDuration,
    bool? animateOnScreenOn,
    bool? animateOnUnlock,
    bool? showDate,
    String? dateFontFamily,
    double? dateFontSize,
    double? dateHorizontalPos,
    double? dateVerticalPos,
    Color? dateColor,
    String? dateFormat,
    bool? dateAllCaps,
    bool? dateBold,
    String? dateDepthMode,
    double? dateBlurAmount,
    double? dateOpacity,
    bool? dateShadowEnabled,
    double? dateRimBrightness,
    double? backgroundDim,
  }) {
    return DepthSceneConfig(
      fontSize: fontSize ?? this.fontSize,
      horizontalPos: horizontalPos ?? this.horizontalPos,
      verticalPos: verticalPos ?? this.verticalPos,
      clockDisplay: clockDisplay ?? this.clockDisplay,
      clockFormat: clockFormat ?? this.clockFormat,
      depthLayering: depthLayering ?? this.depthLayering,
      fontColor: fontColor ?? this.fontColor,
      minuteColor: minuteColor ?? this.minuteColor,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      stretch: stretch ?? this.stretch,
      textOpacity: textOpacity ?? this.textOpacity,
      depthMode: depthMode ?? this.depthMode,
      blurAmount: blurAmount ?? this.blurAmount,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      edgeStrokeEnabled: edgeStrokeEnabled ?? this.edgeStrokeEnabled,
      rimWidth: rimWidth ?? this.rimWidth,
      rimOpacity: rimOpacity ?? this.rimOpacity,
      rimBlur: rimBlur ?? this.rimBlur,
      rimBrightness: rimBrightness ?? this.rimBrightness,
      clockAnimStyle: clockAnimStyle ?? this.clockAnimStyle,
      clockAnimDuration: clockAnimDuration ?? this.clockAnimDuration,
      animateOnScreenOn: animateOnScreenOn ?? this.animateOnScreenOn,
      animateOnUnlock: animateOnUnlock ?? this.animateOnUnlock,
      showDate: showDate ?? this.showDate,
      dateFontFamily: dateFontFamily ?? this.dateFontFamily,
      dateFontSize: dateFontSize ?? this.dateFontSize,
      dateHorizontalPos: dateHorizontalPos ?? this.dateHorizontalPos,
      dateVerticalPos: dateVerticalPos ?? this.dateVerticalPos,
      dateColor: dateColor ?? this.dateColor,
      dateFormat: dateFormat ?? this.dateFormat,
      dateAllCaps: dateAllCaps ?? this.dateAllCaps,
      dateBold: dateBold ?? this.dateBold,
      dateDepthMode: dateDepthMode ?? this.dateDepthMode,
      dateBlurAmount: dateBlurAmount ?? this.dateBlurAmount,
      dateOpacity: dateOpacity ?? this.dateOpacity,
      dateShadowEnabled: dateShadowEnabled ?? this.dateShadowEnabled,
      dateRimBrightness: dateRimBrightness ?? this.dateRimBrightness,
      backgroundDim: backgroundDim ?? this.backgroundDim,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 1,
      'scene': {
        'depthLayering': depthLayering,
        'backgroundDim': backgroundDim,
      },
      'clock': {
        'scale': fontSize,
        'x': horizontalPos,
        'y': verticalPos,
        'display': clockDisplay,
        'format': clockFormat,
        'hourArgb': fontColor.toARGB32(),
        'minuteArgb': minuteColor.toARGB32(),
        'typeface': fontFamily,
        'letterSpacing': letterSpacing,
        'lineSpacing': lineSpacing,
        'stretch': stretch,
        'opacity': textOpacity,
        'animStyle': clockAnimStyle,
        'animDurationMs': clockAnimDuration,
        'animOnWake': animateOnScreenOn,
        'animOnUnlock': animateOnUnlock,
      },
      'optical': {
        'material': depthMode,
        'blur': blurAmount,
        'shadow': shadowEnabled,
        'rimEnabled': edgeStrokeEnabled,
        'rimWidth': rimWidth,
        'rimOpacity': rimOpacity,
        'rimBlur': rimBlur,
        'rimBrightness': rimBrightness,
      },
      'date': {
        'enabled': showDate,
        'typeface': dateFontFamily,
        'scale': dateFontSize,
        'x': dateHorizontalPos,
        'y': dateVerticalPos,
        'argb': dateColor.toARGB32(),
        'format': dateFormat,
        'uppercase': dateAllCaps,
        'bold': dateBold,
        'material': dateDepthMode,
        'blur': dateBlurAmount,
        'opacity': dateOpacity,
        'shadow': dateShadowEnabled,
        'rimBrightness': dateRimBrightness,
      },
    };
  }

  factory DepthSceneConfig.fromJson(Map<String, dynamic> json) {
    double toD(dynamic val, double fallback) =>
        val is num ? val.toDouble() : fallback;
    int toI(dynamic val, int fallback) => val is num ? val.toInt() : fallback;
    bool toB(dynamic val, bool fallback) => val is bool ? val : fallback;
    String toS(dynamic val, String fallback) =>
        val is String ? val : fallback;

    Map<String, dynamic> section(String key) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return const {};
    }

    final scene = section('scene');
    final clock = section('clock');
    final optical = section('optical');
    final date = section('date');

    final int mainCol = toI(clock['hourArgb'], 0xFFFFFFFF);
    return DepthSceneConfig(
      fontSize: toD(clock['scale'], 0.30),
      horizontalPos: toD(clock['x'], 0.50),
      verticalPos: toD(clock['y'], 0.22),
      clockDisplay: toS(clock['display'], 'Horizontal'),
      clockFormat: toS(clock['format'], 'HH:MM'),
      depthLayering: toS(scene['depthLayering'], 'Standard'),
      fontColor: Color(mainCol),
      minuteColor: Color(toI(clock['minuteArgb'], mainCol)),
      fontFamily: toS(clock['typeface'], 'Display 1'),
      letterSpacing: toD(clock['letterSpacing'], 0.0),
      lineSpacing: toD(clock['lineSpacing'], 0.04),
      stretch: toD(clock['stretch'], 1.0),
      textOpacity: toD(clock['opacity'], 1.0),
      depthMode: toS(optical['material'], 'Standard'),
      blurAmount: toD(optical['blur'], 18.0),
      shadowEnabled: toB(optical['shadow'], true),
      edgeStrokeEnabled: toB(optical['rimEnabled'], false),
      rimWidth: toD(optical['rimWidth'], 1.8),
      rimOpacity: toD(optical['rimOpacity'], 0.85),
      rimBlur: toD(optical['rimBlur'], 0.0),
      rimBrightness: toD(optical['rimBrightness'], 0.65),
      clockAnimStyle: toS(clock['animStyle'], 'SlideUp'),
      clockAnimDuration: toD(clock['animDurationMs'], 650.0),
      animateOnScreenOn: toB(clock['animOnWake'], true),
      animateOnUnlock: toB(clock['animOnUnlock'], true),
      showDate: toB(date['enabled'], true),
      dateFontFamily: toS(date['typeface'], 'Sans-Serif'),
      dateFontSize: toD(date['scale'], 0.04),
      dateHorizontalPos: toD(date['x'], 0.50),
      dateVerticalPos: toD(date['y'], 0.14),
      dateColor: Color(toI(date['argb'], 0xFFFFFFFF)),
      dateFormat: toS(date['format'], 'EEE, MMM dd'),
      dateAllCaps: toB(date['uppercase'], false),
      dateBold: toB(date['bold'], false),
      dateDepthMode: toS(date['material'], 'Standard'),
      dateBlurAmount: toD(date['blur'], 18.0),
      dateOpacity: toD(date['opacity'], 1.0),
      dateShadowEnabled: toB(date['shadow'], true),
      dateRimBrightness: toD(date['rimBrightness'], 0.65),
      backgroundDim: toD(scene['backgroundDim'], 0.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DepthSceneConfig &&
        other.fontSize == fontSize &&
        other.horizontalPos == horizontalPos &&
        other.verticalPos == verticalPos &&
        other.clockDisplay == clockDisplay &&
        other.clockFormat == clockFormat &&
        other.depthLayering == depthLayering &&
        other.fontColor.toARGB32() == fontColor.toARGB32() &&
        other.minuteColor.toARGB32() == minuteColor.toARGB32() &&
        other.fontFamily == fontFamily &&
        other.letterSpacing == letterSpacing &&
        other.lineSpacing == lineSpacing &&
        other.stretch == stretch &&
        other.textOpacity == textOpacity &&
        other.depthMode == depthMode &&
        other.blurAmount == blurAmount &&
        other.shadowEnabled == shadowEnabled &&
        other.edgeStrokeEnabled == edgeStrokeEnabled &&
        other.rimWidth == rimWidth &&
        other.rimOpacity == rimOpacity &&
        other.rimBlur == rimBlur &&
        other.rimBrightness == rimBrightness &&
        other.clockAnimStyle == clockAnimStyle &&
        other.clockAnimDuration == clockAnimDuration &&
        other.animateOnScreenOn == animateOnScreenOn &&
        other.animateOnUnlock == animateOnUnlock &&
        other.showDate == showDate &&
        other.dateFontFamily == dateFontFamily &&
        other.dateFontSize == dateFontSize &&
        other.dateHorizontalPos == dateHorizontalPos &&
        other.dateVerticalPos == dateVerticalPos &&
        other.dateColor.toARGB32() == dateColor.toARGB32() &&
        other.dateFormat == dateFormat &&
        other.dateAllCaps == dateAllCaps &&
        other.dateBold == dateBold &&
        other.dateDepthMode == dateDepthMode &&
        other.dateBlurAmount == dateBlurAmount &&
        other.dateOpacity == dateOpacity &&
        other.dateShadowEnabled == dateShadowEnabled &&
        other.dateRimBrightness == dateRimBrightness &&
        other.backgroundDim == backgroundDim;
  }

  @override
  int get hashCode => Object.hashAll([
    fontSize,
    horizontalPos,
    verticalPos,
    clockDisplay,
    clockFormat,
    depthLayering,
    fontColor.toARGB32(),
    minuteColor.toARGB32(),
    fontFamily,
    letterSpacing,
    lineSpacing,
    stretch,
    textOpacity,
    depthMode,
    blurAmount,
    shadowEnabled,
    edgeStrokeEnabled,
    rimWidth,
    rimOpacity,
    rimBlur,
    rimBrightness,
    clockAnimStyle,
    clockAnimDuration,
    animateOnScreenOn,
    animateOnUnlock,
    showDate,
    dateFontFamily,
    dateFontSize,
    dateHorizontalPos,
    dateVerticalPos,
    dateColor.toARGB32(),
    dateFormat,
    dateAllCaps,
    dateBold,
    dateDepthMode,
    dateBlurAmount,
    dateOpacity,
    dateShadowEnabled,
    dateRimBrightness,
    backgroundDim,
  ]);
}