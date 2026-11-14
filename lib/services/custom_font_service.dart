import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/studio/dynamic_font_fit_painter.dart';
import 'platform_channel.dart';
import 'scene_storage_service.dart';

class CustomFontItem {
  final String familyName;
  final String filePath;

  const CustomFontItem({
    required this.familyName,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'familyName': familyName,
    'filePath': filePath,
  };

  factory CustomFontItem.fromJson(Map<String, dynamic> json) => CustomFontItem(
    familyName: json['familyName'] as String,
    filePath: json['filePath'] as String,
  );
}

class CustomFontService {
  const CustomFontService._();

  static const String _prefsKey = 'ds_custom_typefaces_v1';
  static final List<CustomFontItem> _loadedFonts = [];
  static final ValueNotifier<int> fontsVersionNotifier = ValueNotifier<int>(0);

  static List<CustomFontItem> get fonts => List.unmodifiable(_loadedFonts);

  static String? getPathForFamily(String familyName) {
    final int idx = _loadedFonts.indexWhere((f) => f.familyName == familyName);
    if (idx < 0) return null;

    final CustomFontItem item = _loadedFonts[idx];
    if (File(item.filePath).existsSync()) {
      return item.filePath;
    }

    _loadedFonts.removeAt(idx);
    Future.microtask(() async {
      await _persist();
      await _cleanupReferences(familyName);
      fontsVersionNotifier.value++;
    });
    return null;
  }

  static bool isValidFont(
      String familyName, {
        bool includeBuiltInDisplay = true,
      }) {
    if (familyName == 'Sans-Serif') return true;
    if (includeBuiltInDisplay && kStudioFonts.contains(familyName)) {
      return true;
    }
    return getPathForFamily(familyName) != null;
  }

  static Future<void> initAndLoadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_prefsKey) ?? [];
    _loadedFonts.clear();
    final Set<String> validPaths = <String>{};
    final List<String> missingFamilies = <String>[];
    bool hasStaleEntries = false;

    for (final raw in rawList) {
      try {
        final item = CustomFontItem.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        final file = File(item.filePath);
        if (await file.exists()) {
          await _registerFontInFlutter(item.familyName, file);
          _loadedFonts.add(item);
          validPaths.add(item.filePath);
        } else {
          hasStaleEntries = true;
          missingFamilies.add(item.familyName);
          debugPrint('CustomFontService: missing font file ${item.filePath}');
        }
      } catch (e) {
        hasStaleEntries = true;
        debugPrint('CustomFontService: failed to load entry ($e)');
      }
    }

    if (hasStaleEntries) {
      await _persist();
      for (final family in missingFamilies) {
        await _cleanupReferences(family);
      }
    }
    await _gcOrphanFonts(validPaths);
    fontsVersionNotifier.value++;
  }

  static Future<void> _gcOrphanFonts(Set<String> validPaths) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory(p.join(docsDir.path, 'ds_fonts'));
      if (!await fontsDir.exists()) return;

      await for (final entity in fontsDir.list()) {
        if (entity is File && !validPaths.contains(entity.path)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('CustomFontService: _gcOrphanFonts error ($e)');
    }
  }

  static Future<CustomFontItem?> pickAndRegisterFont() async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (picked.isEmpty || picked.single.path == null) {
      return null;
    }

    final File srcFile = File(picked.single.path!);
    final String ext = p.extension(srcFile.path).toLowerCase();
    if (ext != '.ttf' && ext != '.otf') return null;

    final String baseName = p.basenameWithoutExtension(srcFile.path);
    final String cleanFamily =
    baseName.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final String familyName = cleanFamily.isEmpty
        ? 'Custom ${DateTime.now().millisecondsSinceEpoch}'
        : cleanFamily;

    final docsDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory(p.join(docsDir.path, 'ds_fonts'));
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final String destPath = p.join(
      fontsDir.path,
      'typeface_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    final File savedFile = await srcFile.copy(destPath);

    await _registerFontInFlutter(familyName, savedFile);

    final int existingIdx =
    _loadedFonts.indexWhere((f) => f.familyName == familyName);
    if (existingIdx >= 0) {
      final String oldPath = _loadedFonts[existingIdx].filePath;
      if (oldPath != savedFile.path) {
        try {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
      _loadedFonts.removeAt(existingIdx);
    }

    final newItem = CustomFontItem(
      familyName: familyName,
      filePath: savedFile.path,
    );

    _loadedFonts.add(newItem);
    await _persist();
    fontsVersionNotifier.value++;

    return newItem;
  }

  static Future<void> removeFont(String familyName) async {
    final idx = _loadedFonts.indexWhere((f) => f.familyName == familyName);
    if (idx < 0) return;

    final removed = _loadedFonts.removeAt(idx);
    try {
      final file = File(removed.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    await _persist();
    await _cleanupReferences(familyName);
    fontsVersionNotifier.value++;
  }

  static Future<void> _cleanupReferences(String removedFamily) async {
    final current = await AppSettings.load();
    final bool clockAffected = current.musicClockFont == removedFamily;
    final bool dateAffected = current.musicDateFont == removedFamily;
    final bool cardAffected = current.musicCardFont == removedFamily;

    if (clockAffected || dateAffected || cardAffected) {
      final updated = current.copyWith(
        musicClockFont: clockAffected ? 'Sans-Serif' : current.musicClockFont,
        musicDateFont: dateAffected ? 'Sans-Serif' : current.musicDateFont,
        musicCardFont: cardAffected ? 'Sans-Serif' : current.musicCardFont,
      );
      await updated.save();
      appSettingsNotifier.value = updated;
      await PlatformChannel.syncAppPreferences(updated);
    }

    final storage = SceneStorageService();
    final scenes = await storage.fetchAllScenes();
    for (final scene in scenes) {
      final cfg = scene.styleConfig;
      final bool sceneClockAffected = cfg.fontFamily == removedFamily;
      final bool sceneDateAffected = cfg.dateFontFamily == removedFamily;
      if (sceneClockAffected || sceneDateAffected) {
        final cleanedCfg = cfg.copyWith(
          fontFamily: sceneClockAffected ? 'Display 1' : cfg.fontFamily,
          dateFontFamily:
          sceneDateAffected ? 'Sans-Serif' : cfg.dateFontFamily,
        );
        await storage.upsertScene(
          scene.copyWith(
            styleConfig: cleanedCfg,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  static Future<void> _registerFontInFlutter(
      String familyName,
      File fontFile,
      ) async {
    final Uint8List bytes = await fontFile.readAsBytes();
    final fontLoader = FontLoader(familyName);
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _loadedFonts.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_prefsKey, encoded);
  }
}