import 'package:flutter/material.dart';

class WallpaperConfig {
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
  final double backgroundDim;

  const WallpaperConfig({
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
    this.dateFontFamily = 'Display 1',
    this.dateFontSize = 0.04,
    this.dateHorizontalPos = 0.50,
    this.dateVerticalPos = 0.14,
    this.dateColor = Colors.white,
    this.dateFormat = 'EEE, MMM dd',
    this.dateAllCaps = false,
    this.dateBold = false,
    this.backgroundDim = 0.0,
  });

  WallpaperConfig copyWith({
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
    double? backgroundDim,
  }) {
    return WallpaperConfig(
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
      backgroundDim: backgroundDim ?? this.backgroundDim,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'horizontalPos': horizontalPos,
      'verticalPos': verticalPos,
      'clockDisplay': clockDisplay,
      'clockFormat': clockFormat,
      'depthLayering': depthLayering,
      'fontColor': fontColor.toARGB32(),
      'minuteColor': minuteColor.toARGB32(),
      'fontFamily': fontFamily,
      'letterSpacing': letterSpacing,
      'lineSpacing': lineSpacing,
      'stretch': stretch,
      'textOpacity': textOpacity,
      'depthMode': depthMode,
      'blurAmount': blurAmount,
      'shadowEnabled': shadowEnabled,
      'edgeStrokeEnabled': edgeStrokeEnabled,
      'rimWidth': rimWidth,
      'rimOpacity': rimOpacity,
      'rimBlur': rimBlur,
      'rimBrightness': rimBrightness,
      'clockAnimStyle': clockAnimStyle,
      'clockAnimDuration': clockAnimDuration,
      'animateOnScreenOn': animateOnScreenOn,
      'animateOnUnlock': animateOnUnlock,
      'showDate': showDate,
      'dateFontFamily': dateFontFamily,
      'dateFontSize': dateFontSize,
      'dateHorizontalPos': dateHorizontalPos,
      'dateVerticalPos': dateVerticalPos,
      'dateColor': dateColor.toARGB32(),
      'dateFormat': dateFormat,
      'dateAllCaps': dateAllCaps,
      'dateBold': dateBold,
      'backgroundDim': backgroundDim,
    };
  }

  factory WallpaperConfig.fromJson(Map<String, dynamic> json) {
    double toD(dynamic val, double fallback) =>
        val is num ? val.toDouble() : fallback;
    int toI(dynamic val, int fallback) => val is num ? val.toInt() : fallback;
    bool toB(dynamic val, bool fallback) => val is bool ? val : fallback;
    String toS(dynamic val, String fallback) =>
        val is String ? val : fallback;

    final int mainCol = toI(json['fontColor'], 0xFFFFFFFF);
    return WallpaperConfig(
      fontSize: toD(json['fontSize'], 0.30),
      horizontalPos: toD(json['horizontalPos'], 0.50),
      verticalPos: toD(json['verticalPos'], 0.22),
      clockDisplay: toS(json['clockDisplay'], 'Horizontal'),
      clockFormat: toS(json['clockFormat'], 'HH:MM'),
      depthLayering: toS(json['depthLayering'], 'Standard'),
      fontColor: Color(mainCol),
      minuteColor: Color(toI(json['minuteColor'], mainCol)),
      fontFamily: toS(json['fontFamily'], 'Display 1'),
      letterSpacing: toD(json['letterSpacing'], 0.0),
      lineSpacing: toD(json['lineSpacing'], 0.04),
      stretch: toD(json['stretch'], 1.0),
      textOpacity: toD(json['textOpacity'], 1.0),
      depthMode: toS(json['depthMode'], 'Standard'),
      blurAmount: toD(json['blurAmount'], 18.0),
      shadowEnabled: toB(json['shadowEnabled'], true),
      edgeStrokeEnabled: toB(json['edgeStrokeEnabled'], false),
      rimWidth: toD(json['rimWidth'], 1.8),
      rimOpacity: toD(json['rimOpacity'], 0.85),
      rimBlur: toD(json['rimBlur'], 0.0),
      rimBrightness: toD(json['rimBrightness'], 0.65),
      clockAnimStyle: toS(json['clockAnimStyle'], 'SlideUp'),
      clockAnimDuration: toD(json['clockAnimDuration'], 650.0),
      animateOnScreenOn: toB(json['animateOnScreenOn'], true),
      animateOnUnlock: toB(json['animateOnUnlock'], true),
      showDate: toB(json['showDate'], true),
      dateFontFamily: toS(json['dateFontFamily'], 'Display 1'),
      dateFontSize: toD(json['dateFontSize'], 0.04),
      dateHorizontalPos: toD(json['dateHorizontalPos'], 0.50),
      dateVerticalPos: toD(json['dateVerticalPos'], 0.14),
      dateColor: Color(toI(json['dateColor'], 0xFFFFFFFF)),
      dateFormat: toS(json['dateFormat'], 'EEE, MMM dd'),
      dateAllCaps: toB(json['dateAllCaps'], false),
      dateBold: toB(json['dateBold'], false),
      backgroundDim: toD(json['backgroundDim'], 0.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WallpaperConfig &&
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
    backgroundDim,
  ]);
}