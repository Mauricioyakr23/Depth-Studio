import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/saved_scene.dart';

class AssetStorageManager {
  const AssetStorageManager._();

  static final Set<String> _pinnedPaths = <String>{};

  static void pinAsset(String? path) {
    if (path != null && path.isNotEmpty) {
      _pinnedPaths.add(path);
    }
  }

  static void unpinAsset(String? path) {
    if (path != null && path.isNotEmpty) {
      _pinnedPaths.remove(path);
    }
  }

  static Future<Directory> getScenesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final scenesDir = Directory(p.join(docsDir.path, 'depth_scenes'));

    if (!await scenesDir.exists()) {
      await scenesDir.create(recursive: true);
    }

    return scenesDir;
  }

  static Future<String> storeBackgroundAsset(XFile pickedFile) async {
    final scenesDir = await getScenesDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawExt = p.extension(pickedFile.path).toLowerCase();
    final ext = rawExt.isNotEmpty ? rawExt : '.png';
    final targetPath = p.join(scenesDir.path, 'bg_$timestamp$ext');

    final copiedFile = await File(pickedFile.path).copy(targetPath);
    pinAsset(copiedFile.path);
    return copiedFile.path;
  }

  static Future<String> storeSubjectAsset(XFile pickedFile) async {
    final scenesDir = await getScenesDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = p.join(scenesDir.path, 'fg_$timestamp.png');

    final copiedFile = await File(pickedFile.path).copy(targetPath);
    pinAsset(copiedFile.path);
    return copiedFile.path;
  }

  static Future<String> storePreviewCardBytes(Uint8List bytes) async {
    final scenesDir = await getScenesDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = p.join(scenesDir.path, 'preview_$timestamp.png');

    final file = File(targetPath);
    await file.writeAsBytes(bytes);
    pinAsset(targetPath);
    return targetPath;
  }

  static Future<void> removeAsset(String path) async {
    unpinAsset(path);
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('AssetStorageManager.removeAsset error ($path): $e');
    }
  }

  static Future<int> purgeOrphanAssets(
      List<SavedScene> scenes, {
        Set<String> extraPinnedPaths = const {},
      }) async {
    int removedCount = 0;
    try {
      final dir = await getScenesDirectory();
      final activeSet = <String>{
        ..._pinnedPaths,
        ...extraPinnedPaths,
      };

      for (final scene in scenes) {
        activeSet.addAll(scene.layers.activePaths);
        if (scene.previewCardPath != null &&
            scene.previewCardPath!.isNotEmpty) {
          activeSet.add(scene.previewCardPath!);
        }
      }

      await for (final entity in dir.list()) {
        if (entity is File && !activeSet.contains(entity.path)) {
          try {
            await entity.delete();
            removedCount++;
          } catch (e) {
            debugPrint(
              'AssetStorageManager.purgeOrphanAssets failed (${entity.path}): $e',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AssetStorageManager.purgeOrphanAssets error: $e');
    }
    return removedCount;
  }
}