import 'package:shared_preferences/shared_preferences.dart';

class MusicSettings {
  final bool musicModeEnabled;
  final String musicTargetPackage;

  final double musicCoverX;
  final double musicCoverY;
  final double musicCoverScale;

  final double musicCardX;
  final double musicCardY;
  final double musicCardScale;

  final double musicClockX;
  final double musicClockY;
  final double musicClockScale;

  final String musicClockFont;
  final String musicDateFont;
  final String musicCardFont;

  final String musicClockMaterial;
  final double musicClockBlur;
  final double musicClockBrightness;
  final double musicClockOpacity;
  final bool musicClockShadowEnabled;
  final bool musicClockEdgeStrokeEnabled;
  final double musicClockRimWidth;
  final double musicClockRimBlur;

  final String musicCardMaterial;
  final double musicCardBlur;
  final double musicCardBrightness;
  final double musicCardOpacity;
  final bool musicCardShadowEnabled;
  final bool musicCardEdgeStrokeEnabled;
  final double musicCardRimWidth;
  final double musicCardRimBlur;

  const MusicSettings({
    this.musicModeEnabled = true,
    this.musicTargetPackage = 'all',
    this.musicCoverX = 0.50,
    this.musicCoverY = 0.20,
    this.musicCoverScale = 1.0,
    this.musicCardX = 0.50,
    this.musicCardY = 0.65,
    this.musicCardScale = 1.0,
    this.musicClockX = 0.50,
    this.musicClockY = 0.14,
    this.musicClockScale = 1.0,
    this.musicClockFont = 'Sans-Serif',
    this.musicDateFont = 'Sans-Serif',
    this.musicCardFont = 'Sans-Serif',
    this.musicClockMaterial = 'Standard',
    this.musicClockBlur = 18.0,
    this.musicClockBrightness = 0.65,
    this.musicClockOpacity = 1.0,
    this.musicClockShadowEnabled = true,
    this.musicClockEdgeStrokeEnabled = false,
    this.musicClockRimWidth = 1.8,
    this.musicClockRimBlur = 0.0,
    this.musicCardMaterial = 'Liquid',
    this.musicCardBlur = 18.0,
    this.musicCardBrightness = 0.65,
    this.musicCardOpacity = 1.0,
    this.musicCardShadowEnabled = true,
    this.musicCardEdgeStrokeEnabled = false,
    this.musicCardRimWidth = 1.8,
    this.musicCardRimBlur = 0.0,
  });

  MusicSettings copyWith({
    bool? musicModeEnabled,
    String? musicTargetPackage,
    double? musicCoverX,
    double? musicCoverY,
    double? musicCoverScale,
    double? musicCardX,
    double? musicCardY,
    double? musicCardScale,
    double? musicClockX,
    double? musicClockY,
    double? musicClockScale,
    String? musicClockFont,
    String? musicDateFont,
    String? musicCardFont,
    String? musicClockMaterial,
    double? musicClockBlur,
    double? musicClockBrightness,
    double? musicClockOpacity,
    bool? musicClockShadowEnabled,
    bool? musicClockEdgeStrokeEnabled,
    double? musicClockRimWidth,
    double? musicClockRimBlur,
    String? musicCardMaterial,
    double? musicCardBlur,
    double? musicCardBrightness,
    double? musicCardOpacity,
    bool? musicCardShadowEnabled,
    bool? musicCardEdgeStrokeEnabled,
    double? musicCardRimWidth,
    double? musicCardRimBlur,
  }) {
    return MusicSettings(
      musicModeEnabled: musicModeEnabled ?? this.musicModeEnabled,
      musicTargetPackage: musicTargetPackage ?? this.musicTargetPackage,
      musicCoverX: musicCoverX ?? this.musicCoverX,
      musicCoverY: musicCoverY ?? this.musicCoverY,
      musicCoverScale: musicCoverScale ?? this.musicCoverScale,
      musicCardX: musicCardX ?? this.musicCardX,
      musicCardY: musicCardY ?? this.musicCardY,
      musicCardScale: musicCardScale ?? this.musicCardScale,
      musicClockX: musicClockX ?? this.musicClockX,
      musicClockY: musicClockY ?? this.musicClockY,
      musicClockScale: musicClockScale ?? this.musicClockScale,
      musicClockFont: musicClockFont ?? this.musicClockFont,
      musicDateFont: musicDateFont ?? this.musicDateFont,
      musicCardFont: musicCardFont ?? this.musicCardFont,
      musicClockMaterial: musicClockMaterial ?? this.musicClockMaterial,
      musicClockBlur: musicClockBlur ?? this.musicClockBlur,
      musicClockBrightness: musicClockBrightness ?? this.musicClockBrightness,
      musicClockOpacity: musicClockOpacity ?? this.musicClockOpacity,
      musicClockShadowEnabled:
      musicClockShadowEnabled ?? this.musicClockShadowEnabled,
      musicClockEdgeStrokeEnabled:
      musicClockEdgeStrokeEnabled ?? this.musicClockEdgeStrokeEnabled,
      musicClockRimWidth: musicClockRimWidth ?? this.musicClockRimWidth,
      musicClockRimBlur: musicClockRimBlur ?? this.musicClockRimBlur,
      musicCardMaterial: musicCardMaterial ?? this.musicCardMaterial,
      musicCardBlur: musicCardBlur ?? this.musicCardBlur,
      musicCardBrightness: musicCardBrightness ?? this.musicCardBrightness,
      musicCardOpacity: musicCardOpacity ?? this.musicCardOpacity,
      musicCardShadowEnabled:
      musicCardShadowEnabled ?? this.musicCardShadowEnabled,
      musicCardEdgeStrokeEnabled:
      musicCardEdgeStrokeEnabled ?? this.musicCardEdgeStrokeEnabled,
      musicCardRimWidth: musicCardRimWidth ?? this.musicCardRimWidth,
      musicCardRimBlur: musicCardRimBlur ?? this.musicCardRimBlur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'musicModeEnabled': musicModeEnabled,
      'musicTargetPackage': musicTargetPackage,
      'musicCoverX': musicCoverX,
      'musicCoverY': musicCoverY,
      'musicCoverScale': musicCoverScale,
      'musicCardX': musicCardX,
      'musicCardY': musicCardY,
      'musicCardScale': musicCardScale,
      'musicClockX': musicClockX,
      'musicClockY': musicClockY,
      'musicClockScale': musicClockScale,
      'musicClockFont': musicClockFont,
      'musicDateFont': musicDateFont,
      'musicCardFont': musicCardFont,
      'musicClockMaterial': musicClockMaterial,
      'musicClockBlur': musicClockBlur,
      'musicClockBrightness': musicClockBrightness,
      'musicClockOpacity': musicClockOpacity,
      'musicClockShadowEnabled': musicClockShadowEnabled,
      'musicClockEdgeStrokeEnabled': musicClockEdgeStrokeEnabled,
      'musicClockRimWidth': musicClockRimWidth,
      'musicClockRimBlur': musicClockRimBlur,
      'musicCardMaterial': musicCardMaterial,
      'musicCardBlur': musicCardBlur,
      'musicCardBrightness': musicCardBrightness,
      'musicCardOpacity': musicCardOpacity,
      'musicCardShadowEnabled': musicCardShadowEnabled,
      'musicCardEdgeStrokeEnabled': musicCardEdgeStrokeEnabled,
      'musicCardRimWidth': musicCardRimWidth,
      'musicCardRimBlur': musicCardRimBlur,
    };
  }

  factory MusicSettings.fromJson(Map<String, dynamic> json) {
    double toD(dynamic val, double fallback) =>
        val is num ? val.toDouble() : fallback;
    bool toB(dynamic val, bool fallback) => val is bool ? val : fallback;
    String toS(dynamic val, String fallback) =>
        val is String ? val : fallback;

    return MusicSettings(
      musicModeEnabled: toB(json['musicModeEnabled'], true),
      musicTargetPackage: toS(json['musicTargetPackage'], 'all'),
      musicCoverX: toD(json['musicCoverX'], 0.50),
      musicCoverY: toD(json['musicCoverY'], 0.20),
      musicCoverScale: toD(json['musicCoverScale'], 1.0),
      musicCardX: toD(json['musicCardX'], 0.50),
      musicCardY: toD(json['musicCardY'], 0.65),
      musicCardScale: toD(json['musicCardScale'], 1.0),
      musicClockX: toD(json['musicClockX'], 0.50),
      musicClockY: toD(json['musicClockY'], 0.14),
      musicClockScale: toD(json['musicClockScale'], 1.0),
      musicClockFont: toS(json['musicClockFont'], 'Sans-Serif'),
      musicDateFont: toS(json['musicDateFont'], 'Sans-Serif'),
      musicCardFont: toS(json['musicCardFont'], 'Sans-Serif'),
      musicClockMaterial: toS(json['musicClockMaterial'], 'Standard'),
      musicClockBlur: toD(json['musicClockBlur'], 18.0),
      musicClockBrightness: toD(json['musicClockBrightness'], 0.65),
      musicClockOpacity: toD(json['musicClockOpacity'], 1.0),
      musicClockShadowEnabled: toB(json['musicClockShadowEnabled'], true),
      musicClockEdgeStrokeEnabled:
      toB(json['musicClockEdgeStrokeEnabled'], false),
      musicClockRimWidth: toD(json['musicClockRimWidth'], 1.8),
      musicClockRimBlur: toD(json['musicClockRimBlur'], 0.0),
      musicCardMaterial: toS(json['musicCardMaterial'], 'Liquid'),
      musicCardBlur: toD(json['musicCardBlur'], 18.0),
      musicCardBrightness: toD(json['musicCardBrightness'], 0.65),
      musicCardOpacity: toD(json['musicCardOpacity'], 1.0),
      musicCardShadowEnabled: toB(json['musicCardShadowEnabled'], true),
      musicCardEdgeStrokeEnabled:
      toB(json['musicCardEdgeStrokeEnabled'], false),
      musicCardRimWidth: toD(json['musicCardRimWidth'], 1.8),
      musicCardRimBlur: toD(json['musicCardRimBlur'], 0.0),
    );
  }

  factory MusicSettings.fromLegacyPrefs(SharedPreferences prefs) {
    return MusicSettings(
      musicModeEnabled: prefs.getBool('musicModeEnabled') ?? true,
      musicTargetPackage: prefs.getString('musicTargetPackage') ?? 'all',
      musicCoverX: prefs.getDouble('musicCoverX') ?? 0.50,
      musicCoverY: prefs.getDouble('musicCoverY') ?? 0.20,
      musicCoverScale: prefs.getDouble('musicCoverScale') ?? 1.0,
      musicCardX: prefs.getDouble('musicCardX') ?? 0.50,
      musicCardY: prefs.getDouble('musicCardY') ?? 0.65,
      musicCardScale: prefs.getDouble('musicCardScale') ?? 1.0,
      musicClockX: prefs.getDouble('musicClockX') ?? 0.50,
      musicClockY: prefs.getDouble('musicClockY') ?? 0.14,
      musicClockScale: prefs.getDouble('musicClockScale') ?? 1.0,
      musicClockFont: prefs.getString('musicClockFont') ?? 'Sans-Serif',
      musicDateFont: prefs.getString('musicDateFont') ?? 'Sans-Serif',
      musicCardFont: prefs.getString('musicCardFont') ?? 'Sans-Serif',
      musicClockMaterial: prefs.getString('musicClockMaterial') ?? 'Standard',
      musicClockBlur: prefs.getDouble('musicClockBlur') ?? 18.0,
      musicClockBrightness: prefs.getDouble('musicClockBrightness') ?? 0.65,
      musicClockOpacity: prefs.getDouble('musicClockOpacity') ?? 1.0,
      musicClockShadowEnabled: prefs.getBool('musicClockShadowEnabled') ?? true,
      musicClockEdgeStrokeEnabled:
      prefs.getBool('musicClockEdgeStrokeEnabled') ?? false,
      musicClockRimWidth: prefs.getDouble('musicClockRimWidth') ?? 1.8,
      musicClockRimBlur: prefs.getDouble('musicClockRimBlur') ?? 0.0,
      musicCardMaterial: prefs.getString('musicCardMaterial') ?? 'Liquid',
      musicCardBlur: prefs.getDouble('musicCardBlur') ?? 18.0,
      musicCardBrightness: prefs.getDouble('musicCardBrightness') ?? 0.65,
      musicCardOpacity: prefs.getDouble('musicCardOpacity') ?? 1.0,
      musicCardShadowEnabled: prefs.getBool('musicCardShadowEnabled') ?? true,
      musicCardEdgeStrokeEnabled:
      prefs.getBool('musicCardEdgeStrokeEnabled') ?? false,
      musicCardRimWidth: prefs.getDouble('musicCardRimWidth') ?? 1.8,
      musicCardRimBlur: prefs.getDouble('musicCardRimBlur') ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicSettings &&
        other.musicModeEnabled == musicModeEnabled &&
        other.musicTargetPackage == musicTargetPackage &&
        other.musicCoverX == musicCoverX &&
        other.musicCoverY == musicCoverY &&
        other.musicCoverScale == musicCoverScale &&
        other.musicCardX == musicCardX &&
        other.musicCardY == musicCardY &&
        other.musicCardScale == musicCardScale &&
        other.musicClockX == musicClockX &&
        other.musicClockY == musicClockY &&
        other.musicClockScale == musicClockScale &&
        other.musicClockFont == musicClockFont &&
        other.musicDateFont == musicDateFont &&
        other.musicCardFont == musicCardFont &&
        other.musicClockMaterial == musicClockMaterial &&
        other.musicClockBlur == musicClockBlur &&
        other.musicClockBrightness == musicClockBrightness &&
        other.musicClockOpacity == musicClockOpacity &&
        other.musicClockShadowEnabled == musicClockShadowEnabled &&
        other.musicClockEdgeStrokeEnabled == musicClockEdgeStrokeEnabled &&
        other.musicClockRimWidth == musicClockRimWidth &&
        other.musicClockRimBlur == musicClockRimBlur &&
        other.musicCardMaterial == musicCardMaterial &&
        other.musicCardBlur == musicCardBlur &&
        other.musicCardBrightness == musicCardBrightness &&
        other.musicCardOpacity == musicCardOpacity &&
        other.musicCardShadowEnabled == musicCardShadowEnabled &&
        other.musicCardEdgeStrokeEnabled == musicCardEdgeStrokeEnabled &&
        other.musicCardRimWidth == musicCardRimWidth &&
        other.musicCardRimBlur == musicCardRimBlur;
  }

  @override
  int get hashCode => Object.hashAll([
    musicModeEnabled,
    musicTargetPackage,
    musicCoverX,
    musicCoverY,
    musicCoverScale,
    musicCardX,
    musicCardY,
    musicCardScale,
    musicClockX,
    musicClockY,
    musicClockScale,
    musicClockFont,
    musicDateFont,
    musicCardFont,
    musicClockMaterial,
    musicClockBlur,
    musicClockBrightness,
    musicClockOpacity,
    musicClockShadowEnabled,
    musicClockEdgeStrokeEnabled,
    musicClockRimWidth,
    musicClockRimBlur,
    musicCardMaterial,
    musicCardBlur,
    musicCardBrightness,
    musicCardOpacity,
    musicCardShadowEnabled,
    musicCardEdgeStrokeEnabled,
    musicCardRimWidth,
    musicCardRimBlur,
  ]);
}