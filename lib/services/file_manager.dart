import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper_project.dart';

class FileManager {
  static final Set<String> _sessionProtectedPaths = <String>{};

  static void protectPath(String? path) {
    if (path != null && path.isNotEmpty) {
      _sessionProtectedPaths.add(path);
    }
  }

  static void unprotectPath(String? path) {
    if (path != null && path.isNotEmpty) {
      _sessionProtectedPaths.remove(path);
    }
  }

  static Future<Directory> getAppDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final wallpapersDir = Directory(p.join(docsDir.path, 'wallpapers'));

    if (!await wallpapersDir.exists()) {
      await wallpapersDir.create(recursive: true);
    }

    return wallpapersDir;
  }

  static Future<String> saveImage(XFile pickedFile) async {
    final wallpapersDir = await getAppDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = p.extension(pickedFile.path).toLowerCase();
    final ext = fileExtension.isNotEmpty ? fileExtension : '.png';
    final newFileName = 'original_$timestamp$ext';

    final destinationPath = p.join(wallpapersDir.path, newFileName);
    final sourceFile = File(pickedFile.path);
    final copiedFile = await sourceFile.copy(destinationPath);

    protectPath(copiedFile.path);
    return copiedFile.path;
  }

  static Future<String> saveForegroundFile(XFile pickedFile) async {
    final wallpapersDir = await getAppDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = 'foreground_manual_$timestamp.png';

    final destinationPath = p.join(wallpapersDir.path, newFileName);
    final sourceFile = File(pickedFile.path);
    final copiedFile = await sourceFile.copy(destinationPath);

    protectPath(copiedFile.path);
    return copiedFile.path;
  }

  static Future<void> deleteImage(String path) async {
    unprotectPath(path);
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<String> saveThumbnailBytes(Uint8List bytes) async {
    final wallpapersDir = await getAppDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'thumb_$timestamp.png';
    final filePath = p.join(wallpapersDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    protectPath(filePath);
    return filePath;
  }

  Future<String> saveThumbnail(Uint8List bytes) => saveThumbnailBytes(bytes);

  static Future<void> gcOrphanFiles(
      List<WallpaperProject> projects, {
        Set<String> extraProtectedPaths = const {},
      }) async {
    try {
      final dir = await getAppDirectory();
      final used = <String>{
        ..._sessionProtectedPaths,
        ...extraProtectedPaths,
      };
      for (final p in projects) {
        if (p.originalImagePath != null) used.add(p.originalImagePath!);
        if (p.foregroundImagePath != null) used.add(p.foregroundImagePath!);
        if (p.thumbnailPath != null) used.add(p.thumbnailPath!);
      }
      await for (final entity in dir.list()) {
        if (entity is File && !used.contains(entity.path)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}