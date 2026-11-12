import 'dart:convert';
import 'wallpaper_config.dart';

class WallpaperProject {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? thumbnailPath;
  final bool isActive;
  final String? originalImagePath;
  final String? foregroundImagePath;
  final String configJson;

  const WallpaperProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.thumbnailPath,
    this.isActive = false,
    this.originalImagePath,
    this.foregroundImagePath,
    required this.configJson,
  });

  WallpaperConfig get config {
    try {
      final decoded = jsonDecode(configJson);
      if (decoded is Map<String, dynamic>) {
        return WallpaperConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return WallpaperConfig.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const WallpaperConfig();
  }

  WallpaperProject copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? thumbnailPath,
    bool? isActive,
    String? originalImagePath,
    String? foregroundImagePath,
    String? configJson,
    bool clearThumbnail = false,
    bool clearOriginalImage = false,
    bool clearForegroundImage = false,
  }) {
    return WallpaperProject(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      thumbnailPath: clearThumbnail
          ? null
          : _emptyToNull(thumbnailPath ?? this.thumbnailPath),
      isActive: isActive ?? this.isActive,
      originalImagePath: clearOriginalImage
          ? null
          : _emptyToNull(originalImagePath ?? this.originalImagePath),
      foregroundImagePath: clearForegroundImage
          ? null
          : _emptyToNull(foregroundImagePath ?? this.foregroundImagePath),
      configJson: configJson ?? this.configJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'isActive': isActive,
      'originalImagePath': originalImagePath,
      'foregroundImagePath': foregroundImagePath,
      'configJson': configJson,
    };
  }

  static String? _emptyToNull(String? s) =>
      (s == null || s.isEmpty) ? null : s;

  factory WallpaperProject.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      }
      return DateTime.now();
    }

    String rawConfig = '{}';
    final dynamic cfgField = json['configJson'] ?? json['config'];
    if (cfgField is String) {
      rawConfig = cfgField;
    } else if (cfgField is Map) {
      rawConfig = jsonEncode(cfgField);
    }

    return WallpaperProject(
      id: (json['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? 'Lock Screen',
      createdAt: parseDate(json['createdAt']),
      modifiedAt: parseDate(json['modifiedAt']),
      thumbnailPath: _emptyToNull(json['thumbnailPath'] as String?),
      isActive: (json['isActive'] as bool?) ?? false,
      originalImagePath: _emptyToNull(json['originalImagePath'] as String?),
      foregroundImagePath: _emptyToNull(json['foregroundImagePath'] as String?),
      configJson: rawConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WallpaperProject &&
        other.id == id &&
        other.name == name &&
        other.modifiedAt == modifiedAt &&
        other.thumbnailPath == thumbnailPath &&
        other.isActive == isActive &&
        other.originalImagePath == originalImagePath &&
        other.foregroundImagePath == foregroundImagePath &&
        other.configJson == configJson;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    modifiedAt,
    thumbnailPath,
    isActive,
    originalImagePath,
    foregroundImagePath,
    configJson,
  );
}