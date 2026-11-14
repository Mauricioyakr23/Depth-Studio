class SceneLayers {
  final String? backgroundPath;
  final String? subjectPath;

  const SceneLayers({
    this.backgroundPath,
    this.subjectPath,
  });

  bool get hasBackground =>
      backgroundPath != null && backgroundPath!.isNotEmpty;

  bool get hasSubject => subjectPath != null && subjectPath!.isNotEmpty;

  bool get isDepthReady => hasBackground && hasSubject;

  SceneLayers copyWith({
    String? backgroundPath,
    String? subjectPath,
    bool clearBackground = false,
    bool clearSubject = false,
  }) {
    return SceneLayers(
      backgroundPath:
      clearBackground ? null : (backgroundPath ?? this.backgroundPath),
      subjectPath: clearSubject ? null : (subjectPath ?? this.subjectPath),
    );
  }

  SceneLayers clear() {
    return const SceneLayers(
      backgroundPath: null,
      subjectPath: null,
    );
  }

  Set<String> get activePaths => {
    if (hasBackground) backgroundPath!,
    if (hasSubject) subjectPath!,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SceneLayers &&
        other.backgroundPath == backgroundPath &&
        other.subjectPath == subjectPath;
  }

  @override
  int get hashCode => Object.hash(backgroundPath, subjectPath);
}