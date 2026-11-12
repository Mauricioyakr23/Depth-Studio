import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wallpaper_project.dart';

class ProjectRepository {
  static const String _storageKey = 'depth_studio_saved_projects_v2';
  static const String _legacyKey = 'wallpaper_projects';

  Future<List<WallpaperProject>> getAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final List<WallpaperProject> result = [];

    final List<String>? rawList = prefs.getStringList(_storageKey);
    if (rawList != null) {
      for (final item in rawList) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(item) as Map);
          result.add(WallpaperProject.fromJson(map));
        } catch (_) {}
      }
    } else {
      final String? legacyJson = prefs.getString(_legacyKey);
      if (legacyJson != null && legacyJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(legacyJson) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map) {
              result.add(
                WallpaperProject.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
          if (result.isNotEmpty) {
            await _persistList(prefs, result);
          }
        } catch (_) {}
      }
    }

    result.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return result;
  }

  Future<void> _persistList(
      SharedPreferences prefs,
      List<WallpaperProject> projects,
      ) async {
    final List<String> encoded =
    projects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> saveProject(WallpaperProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getAllProjects();

    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      projects[idx] = project;
    } else {
      projects.insert(0, project);
    }

    await _persistList(prefs, projects);
  }

  Future<void> renameProject(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getAllProjects();
    final idx = projects.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    projects[idx] = projects[idx].copyWith(
      name: trimmed,
      modifiedAt: DateTime.now(),
    );
    await _persistList(prefs, projects);
  }

  Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getAllProjects();
    final int idx = projects.indexWhere((p) => p.id == id);
    if (idx < 0) return;

    final WallpaperProject removed = projects.removeAt(idx);
    await _persistList(prefs, projects);

    final Set<String> stillUsed = <String>{};
    for (final p in projects) {
      if (p.originalImagePath != null) stillUsed.add(p.originalImagePath!);
      if (p.foregroundImagePath != null) stillUsed.add(p.foregroundImagePath!);
      if (p.thumbnailPath != null) stillUsed.add(p.thumbnailPath!);
    }

    for (final String? path in [
      removed.originalImagePath,
      removed.foregroundImagePath,
      removed.thumbnailPath,
    ]) {
      if (path != null && path.isNotEmpty && !stillUsed.contains(path)) {
        try {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> duplicateProject(WallpaperProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getAllProjects();
    final now = DateTime.now();
    final uuid = const Uuid().v4();

    final newBg =
    await _duplicateFile(project.originalImagePath, 'original', uuid);
    final newFg =
    await _duplicateFile(project.foregroundImagePath, 'foreground', uuid);
    final newThumb =
    await _duplicateFile(project.thumbnailPath, 'thumb', uuid);

    final copy = project.copyWith(
      id: uuid,
      name: '${project.name} (Copy)',
      createdAt: now,
      modifiedAt: now,
      isActive: false,
      thumbnailPath: newThumb,
      originalImagePath: newBg,
      foregroundImagePath: newFg,
    );

    projects.insert(0, copy);
    await _persistList(prefs, projects);
  }

  Future<String?> _duplicateFile(String? src, String prefix, String tag) async {
    if (src == null || src.isEmpty) return null;
    final srcFile = File(src);
    if (!await srcFile.exists()) return null;
    final dir = await getApplicationDocumentsDirectory();
    final wallpapersDir = Directory(p.join(dir.path, 'wallpapers'));
    if (!await wallpapersDir.exists()) {
      await wallpapersDir.create(recursive: true);
    }
    final ext = p.extension(src).isEmpty ? '.png' : p.extension(src);
    final dest = p.join(
      wallpapersDir.path,
      '${prefix}_${tag}_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await srcFile.copy(dest);
    return dest;
  }

  Future<void> setActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getAllProjects();
    final updated =
    projects.map((p) => p.copyWith(isActive: p.id == id)).toList();
    await _persistList(prefs, updated);
  }
}