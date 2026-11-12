class WallpaperData {
  final String? originalImagePath;
  final String? foregroundImagePath;

  const WallpaperData({
    this.originalImagePath,
    this.foregroundImagePath,
  });

  WallpaperData copyWith({
    String? originalImagePath,
    String? foregroundImagePath,
    bool clearOriginalImage = false,
    bool clearForegroundImage = false,
  }) {
    return WallpaperData(
      originalImagePath: clearOriginalImage
          ? null
          : (originalImagePath ?? this.originalImagePath),
      foregroundImagePath: clearForegroundImage
          ? null
          : (foregroundImagePath ?? this.foregroundImagePath),
    );
  }

  WallpaperData clear() {
    return const WallpaperData(
      originalImagePath: null,
      foregroundImagePath: null,
    );
  }

  Set<String> get activePaths => {
    if (originalImagePath != null && originalImagePath!.isNotEmpty)
      originalImagePath!,
    if (foregroundImagePath != null && foregroundImagePath!.isNotEmpty)
      foregroundImagePath!,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WallpaperData &&
        other.originalImagePath == originalImagePath &&
        other.foregroundImagePath == foregroundImagePath;
  }

  @override
  int get hashCode => Object.hash(originalImagePath, foregroundImagePath);
}