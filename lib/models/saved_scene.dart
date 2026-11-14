import 'dart:convert';
import 'depth_scene_config.dart';
import 'scene_layers.dart';

class SavedScene {
  final String sceneId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? previewCardPath;
  final bool isCurrentWallpaper;
  final SceneLayers layers;
  final DepthSceneConfig styleConfig;

  const SavedScene({
    required this.sceneId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.previewCardPath,
    this.isCurrentWallpaper = false,
    this.layers = const SceneLayers(),
    this.styleConfig = const DepthSceneConfig(),
  });

  String? get backgroundPath => layers.backgroundPath;
  String? get subjectPath => layers.subjectPath;

  SavedScene copyWith({
    String? sceneId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? previewCardPath,
    bool? isCurrentWallpaper,
    SceneLayers? layers,
    DepthSceneConfig? styleConfig,
    bool clearPreviewCard = false,
  }) {
    final String? resolvedPreview = clearPreviewCard
        ? null
        : _emptyToNull(previewCardPath ?? this.previewCardPath);

    return SavedScene(
      sceneId: sceneId ?? this.sceneId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previewCardPath: resolvedPreview,
      isCurrentWallpaper: isCurrentWallpaper ?? this.isCurrentWallpaper,
      layers: layers ?? this.layers,
      styleConfig: styleConfig ?? this.styleConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sceneId': sceneId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'previewCardPath': previewCardPath,
      'isCurrentWallpaper': isCurrentWallpaper,
      'assets': {
        'background': layers.backgroundPath,
        'subject': layers.subjectPath,
      },
      'style': styleConfig.toJson(),
    };
  }

  static String? _emptyToNull(String? s) =>
      (s == null || s.isEmpty) ? null : s;

  factory SavedScene.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      }
      return DateTime.now();
    }

    Map<String, dynamic> extractMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return const {};
    }

    final assetsMap = extractMap(json['assets']);
    final styleMap = extractMap(json['style']);

    return SavedScene(
      sceneId: (json['sceneId'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: (json['title'] as String?) ?? 'Lock Screen',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      previewCardPath: _emptyToNull(json['previewCardPath'] as String?),
      isCurrentWallpaper: (json['isCurrentWallpaper'] as bool?) ?? false,
      layers: SceneLayers(
        backgroundPath: _emptyToNull(assetsMap['background'] as String?),
        subjectPath: _emptyToNull(assetsMap['subject'] as String?),
      ),
      styleConfig: DepthSceneConfig.fromJson(styleMap),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedScene &&
        other.sceneId == sceneId &&
        other.title == title &&
        other.updatedAt == updatedAt &&
        other.previewCardPath == previewCardPath &&
        other.isCurrentWallpaper == isCurrentWallpaper &&
        other.layers == layers &&
        other.styleConfig == styleConfig;
  }

  @override
  int get hashCode => Object.hash(
    sceneId,
    title,
    updatedAt,
    previewCardPath,
    isCurrentWallpaper,
    layers,
    styleConfig,
  );
}