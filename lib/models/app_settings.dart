import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_settings.dart';

class AppSettings {
  static const String preferencesStorageKey = 'ds_app_preferences_v1';
  static const String musicStorageKey = 'ds_music_overlay_v1';

  final bool homescreenClock;
  final bool use24Hour;
  final bool hasSeenOnboarding;
  final String themeMode;
  final String languageCode;
  final MusicSettings music;

  const AppSettings({
    this.homescreenClock = false,
    this.use24Hour = true,
    this.hasSeenOnboarding = false,
    this.themeMode = 'dark',
    this.languageCode = 'es',
    this.music = const MusicSettings(),
  });

  bool get musicModeEnabled => music.musicModeEnabled;
  String get musicTargetPackage => music.musicTargetPackage;

  double get musicCoverX => music.musicCoverX;
  double get musicCoverY => music.musicCoverY;
  double get musicCoverScale => music.musicCoverScale;

  double get musicCardX => music.musicCardX;
  double get musicCardY => music.musicCardY;
  double get musicCardScale => music.musicCardScale;

  double get musicClockX => music.musicClockX;
  double get musicClockY => music.musicClockY;
  double get musicClockScale => music.musicClockScale;

  String get musicClockFont => music.musicClockFont;
  String get musicDateFont => music.musicDateFont;
  String get musicCardFont => music.musicCardFont;

  String get musicClockMaterial => music.musicClockMaterial;
  double get musicClockBlur => music.musicClockBlur;
  double get musicClockBrightness => music.musicClockBrightness;
  double get musicClockOpacity => music.musicClockOpacity;
  bool get musicClockShadowEnabled => music.musicClockShadowEnabled;
  bool get musicClockEdgeStrokeEnabled => music.musicClockEdgeStrokeEnabled;
  double get musicClockRimWidth => music.musicClockRimWidth;
  double get musicClockRimBlur => music.musicClockRimBlur;

  String get musicCardMaterial => music.musicCardMaterial;
  double get musicCardBlur => music.musicCardBlur;
  double get musicCardBrightness => music.musicCardBrightness;
  double get musicCardOpacity => music.musicCardOpacity;
  bool get musicCardShadowEnabled => music.musicCardShadowEnabled;
  bool get musicCardEdgeStrokeEnabled => music.musicCardEdgeStrokeEnabled;
  double get musicCardRimWidth => music.musicCardRimWidth;
  double get musicCardRimBlur => music.musicCardRimBlur;

  AppSettings copyWith({
    bool? homescreenClock,
    bool? use24Hour,
    bool? hasSeenOnboarding,
    String? themeMode,
    String? languageCode,
    MusicSettings? music,
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
    final MusicSettings baseMusic = music ?? this.music;
    final MusicSettings updatedMusic = baseMusic.copyWith(
      musicModeEnabled: musicModeEnabled,
      musicTargetPackage: musicTargetPackage,
      musicCoverX: musicCoverX,
      musicCoverY: musicCoverY,
      musicCoverScale: musicCoverScale,
      musicCardX: musicCardX,
      musicCardY: musicCardY,
      musicCardScale: musicCardScale,
      musicClockX: musicClockX,
      musicClockY: musicClockY,
      musicClockScale: musicClockScale,
      musicClockFont: musicClockFont,
      musicDateFont: musicDateFont,
      musicCardFont: musicCardFont,
      musicClockMaterial: musicClockMaterial,
      musicClockBlur: musicClockBlur,
      musicClockBrightness: musicClockBrightness,
      musicClockOpacity: musicClockOpacity,
      musicClockShadowEnabled: musicClockShadowEnabled,
      musicClockEdgeStrokeEnabled: musicClockEdgeStrokeEnabled,
      musicClockRimWidth: musicClockRimWidth,
      musicClockRimBlur: musicClockRimBlur,
      musicCardMaterial: musicCardMaterial,
      musicCardBlur: musicCardBlur,
      musicCardBrightness: musicCardBrightness,
      musicCardOpacity: musicCardOpacity,
      musicCardShadowEnabled: musicCardShadowEnabled,
      musicCardEdgeStrokeEnabled: musicCardEdgeStrokeEnabled,
      musicCardRimWidth: musicCardRimWidth,
      musicCardRimBlur: musicCardRimBlur,
    );

    return AppSettings(
      homescreenClock: homescreenClock ?? this.homescreenClock,
      use24Hour: use24Hour ?? this.use24Hour,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      music: updatedMusic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homescreenClock': homescreenClock,
      'use24Hour': use24Hour,
      'hasSeenOnboarding': hasSeenOnboarding,
      'themeMode': themeMode,
      'languageCode': languageCode,
      'music': music.toJson(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    MusicSettings parsedMusic = const MusicSettings();
    final rawMusic = json['music'];
    if (rawMusic is Map<String, dynamic>) {
      parsedMusic = MusicSettings.fromJson(rawMusic);
    } else if (rawMusic is Map) {
      parsedMusic = MusicSettings.fromJson(Map<String, dynamic>.from(rawMusic));
    }

    return AppSettings(
      homescreenClock: (json['homescreenClock'] as bool?) ?? false,
      use24Hour: (json['use24Hour'] as bool?) ?? true,
      hasSeenOnboarding: (json['hasSeenOnboarding'] as bool?) ?? false,
      themeMode: (json['themeMode'] as String?) ?? 'dark',
      languageCode: (json['languageCode'] as String?) ?? 'es',
      music: parsedMusic,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawPrefsJson = prefs.getString(preferencesStorageKey);

    if (rawPrefsJson != null && rawPrefsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPrefsJson);
        if (decoded is Map<String, dynamic>) {
          return AppSettings.fromJson(decoded);
        }
        if (decoded is Map) {
          return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    const defaults = AppSettings();
    await defaults.save();
    return defaults;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferencesStorageKey, jsonEncode(toJson()));
    await prefs.setString(musicStorageKey, jsonEncode(music.toJson()));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.homescreenClock == homescreenClock &&
        other.use24Hour == use24Hour &&
        other.hasSeenOnboarding == hasSeenOnboarding &&
        other.themeMode == themeMode &&
        other.languageCode == languageCode &&
        other.music == music;
  }

  @override
  int get hashCode => Object.hash(
    homescreenClock,
    use24Hour,
    hasSeenOnboarding,
    themeMode,
    languageCode,
    music,
  );
}