import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/core.dart';
import '../models/saved_scene.dart';
import '../models/scene_layers.dart';
import 'asset_storage_manager.dart';

class SceneStorageService {
  static const String _registryKey = 'ds_scenes_registry_v1';

  Future<List<SavedScene>> fetchAllScenes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawEntries = prefs.getStringList(_registryKey) ?? [];
    final List<SavedScene> scenes = [];

    for (final entry in rawEntries) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(entry) as Map);
        scenes.add(SavedScene.fromJson(decoded));
      } catch (_) {}
    }

    scenes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return scenes;
  }

  Future<void> _writeRegistry(
      SharedPreferences prefs,
      List<SavedScene> scenes,
      ) async {
    final encoded = scenes.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_registryKey, encoded);
  }

  Future<void> upsertScene(SavedScene scene) async {
    final prefs = await SharedPreferences.getInstance();
    final scenes = await fetchAllScenes();

    final existingIdx = scenes.indexWhere((s) => s.sceneId == scene.sceneId);
    if (existingIdx >= 0) {
      scenes[existingIdx] = scene;
    } else {
      scenes.insert(0, scene);
    }

    await _writeRegistry(prefs, scenes);
  }

  Future<void> renameScene(String sceneId, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final scenes = await fetchAllScenes();
    final idx = scenes.indexWhere((s) => s.sceneId == sceneId);
    if (idx < 0) return;

    scenes[idx] = scenes[idx].copyWith(
      title: trimmed,
      updatedAt: DateTime.now(),
    );
    await _writeRegistry(prefs, scenes);
  }

  Future<void> deleteScene(String sceneId) async {
    final prefs = await SharedPreferences.getInstance();
    final scenes = await fetchAllScenes();
    final idx = scenes.indexWhere((s) => s.sceneId == sceneId);
    if (idx < 0) return;

    final SavedScene target = scenes.removeAt(idx);
    await _writeRegistry(prefs, scenes);

    final Set<String> retainedPaths = <String>{};
    for (final item in scenes) {
      retainedPaths.addAll(item.layers.activePaths);
      if (item.previewCardPath != null) {
        retainedPaths.add(item.previewCardPath!);
      }
    }

    final candidates = <String?>[
      target.backgroundPath,
      target.subjectPath,
      target.previewCardPath,
    ];

    for (final path in candidates) {
      if (path != null && path.isNotEmpty && !retainedPaths.contains(path)) {
        await AssetStorageManager.removeAsset(path);
      }
    }
  }

  Future<void> cloneScene(SavedScene source) async {
    final prefs = await SharedPreferences.getInstance();
    final scenes = await fetchAllScenes();
    final now = DateTime.now();
    final newId = const Uuid().v4();

    final results = await Future.wait<String?>([
      _cloneAssetFile(source.backgroundPath, 'bg', newId),
      _cloneAssetFile(source.subjectPath, 'fg', newId),
      _cloneAssetFile(source.previewCardPath, 'preview', newId),
    ]);

    final cloned = source.copyWith(
      sceneId: newId,
      title: AppStrings.duplicateProjectName(source.title),
      createdAt: now,
      updatedAt: now,
      isCurrentWallpaper: false,
      layers: SceneLayers(
        backgroundPath: results[0],
        subjectPath: results[1],
      ),
      previewCardPath: results[2],
    );

    scenes.insert(0, cloned);
    await _writeRegistry(prefs, scenes);
  }

  Future<String?> _cloneAssetFile(
      String? sourcePath,
      String prefix,
      String tag,
      ) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final srcFile = File(sourcePath);
    if (!await srcFile.exists()) return null;

    final dir = await AssetStorageManager.getScenesDirectory();
    final ext = p.extension(sourcePath).isEmpty ? '.png' : p.extension(sourcePath);
    final destPath = p.join(
      dir.path,
      '${prefix}_${tag}_${DateTime.now().millisecondsSinceEpoch}$ext',
    );

    await srcFile.copy(destPath);
    return destPath;
  }

  Future<void> markAsCurrentWallpaper(String sceneId) async {
    final prefs = await SharedPreferences.getInstance();
    final scenes = await fetchAllScenes();
    final updated = scenes
        .map((s) => s.copyWith(isCurrentWallpaper: s.sceneId == sceneId))
        .toList();
    await _writeRegistry(prefs, updated);
  }
}