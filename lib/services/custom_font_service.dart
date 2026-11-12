import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _prefsKey = 'depth_studio_custom_fonts_v1';
  static final List<CustomFontItem> _loadedFonts = [];

  static List<CustomFontItem> get fonts => List.unmodifiable(_loadedFonts);

  static String? getPathForFamily(String familyName) {
    for (final f in _loadedFonts) {
      if (f.familyName == familyName) return f.filePath;
    }
    return null;
  }

  static Future<void> initAndLoadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_prefsKey) ?? [];
    _loadedFonts.clear();

    for (final raw in rawList) {
      try {
        final item = CustomFontItem.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        final file = File(item.filePath);
        if (await file.exists()) {
          await _registerFontInFlutter(item.familyName, file);
          _loadedFonts.add(item);
        }
      } catch (_) {}
    }
  }

  static Future<CustomFontItem?> pickAndRegisterFont() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (files.isEmpty || files.single.path == null) return null;

    final File srcFile = File(files.single.path!);
    final String ext = p.extension(srcFile.path).toLowerCase();
    if (ext != '.ttf' && ext != '.otf') return null;

    final String baseName = p.basenameWithoutExtension(srcFile.path);
    final String cleanFamily =
    baseName.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final String familyName = cleanFamily.isEmpty
        ? 'Custom ${DateTime.now().millisecondsSinceEpoch}'
        : cleanFamily;

    final docsDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory(p.join(docsDir.path, 'fonts'));
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final String destPath = p.join(
      fontsDir.path,
      'font_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    final File savedFile = await srcFile.copy(destPath);

    await _registerFontInFlutter(familyName, savedFile);

    final newItem = CustomFontItem(
      familyName: familyName,
      filePath: savedFile.path,
    );

    _loadedFonts.removeWhere((f) => f.familyName == familyName);
    _loadedFonts.add(newItem);
    await _persist();

    return newItem;
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