import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../models/depth_scene_config.dart';
import '../models/scene_layers.dart';
import 'custom_font_service.dart';

class PlatformChannel {
  const PlatformChannel._();

  static const MethodChannel _engineChannel =
  MethodChannel('com.depthstudio.app/live_engine');

  static Future<int> getSdkInt() async {
    try {
      return await _engineChannel.invokeMethod<int>('queryAndroidSdk') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<String> getAppVersion() async {
    try {
      return await _engineChannel.invokeMethod<String>('queryBuildVersion') ??
          '1.0.0';
    } catch (_) {
      return '1.0.0';
    }
  }

  static Map<String, Object?> _buildPreferencesPayload(AppSettings settings) {
    final Map<String, dynamic> musicPayload = <String, dynamic>{
      ...settings.music.toJson(),
      'musicClockFontPath':
      CustomFontService.getPathForFamily(settings.musicClockFont),
      'musicDateFontPath':
      CustomFontService.getPathForFamily(settings.musicDateFont),
      'musicCardFontPath':
      CustomFontService.getPathForFamily(settings.musicCardFont),
    };

    return <String, Object?>{
      'homescreenClock': settings.homescreenClock,
      'use24Hour': settings.use24Hour,
      'musicModeEnabled': settings.musicModeEnabled,
      'musicTargetPackage': settings.musicTargetPackage,
      'appLanguage': settings.languageCode,
      'musicOverlayJson': jsonEncode(musicPayload),
    };
  }

  static Future<bool> registerBundledFont(String name, Uint8List bytes) async {
    try {
      return await _engineChannel.invokeMethod<bool>(
        'registerEmbeddedTypeface',
        <String, Object?>{
          'family': name,
          'fontBytes': bytes,
        },
      ) ??
          false;
    } catch (e) {
      debugPrint('PlatformChannel.registerBundledFont ($name) failed: $e');
      return false;
    }
  }

  static Future<void> syncSceneState({
    required DepthSceneConfig config,
    required SceneLayers layers,
    required AppSettings settings,
  }) async {
    final String? customClockFontPath =
    CustomFontService.getPathForFamily(config.fontFamily);
    final String? customDateFontPath =
    CustomFontService.getPathForFamily(config.dateFontFamily);

    await _engineChannel.invokeMethod<bool>('syncSceneState', <String, Object?>{
      'sceneJson': jsonEncode(config.toJson()),
      'backgroundAssetPath': layers.backgroundPath,
      'subjectAssetPath': layers.subjectPath,
      'customClockFontPath': customClockFontPath,
      'customDateFontPath': customDateFontPath,
      ..._buildPreferencesPayload(settings),
    });
  }

  static Future<void> launchSystemWallpaperPicker() async {
    await _engineChannel.invokeMethod<bool>('launchSystemWallpaperPicker');
  }

  static Future<void> applyLiveScene({
    required DepthSceneConfig config,
    required SceneLayers layers,
    required AppSettings settings,
  }) async {
    await syncSceneState(config: config, layers: layers, settings: settings);
    await launchSystemWallpaperPicker();
  }

  static Future<bool> syncAppPreferences(AppSettings settings) async {
    try {
      return await _engineChannel.invokeMethod<bool>(
        'syncAppPreferences',
        _buildPreferencesPayload(settings),
      ) ??
          false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel.syncAppPreferences failed: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('PlatformChannel.syncAppPreferences unavailable: $e');
      return false;
    } catch (e) {
      debugPrint('PlatformChannel.syncAppPreferences unexpected error: $e');
      return false;
    }
  }

  static Future<bool> isStoragePermissionGranted() async {
    try {
      return await _engineChannel.invokeMethod<bool>('checkMediaAccess') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestStoragePermission() async {
    try {
      await _engineChannel.invokeMethod<bool>('promptMediaAccess');
    } catch (_) {}
  }

  static Future<bool> isMusicPermissionGranted() async {
    try {
      return await _engineChannel
          .invokeMethod<bool>('checkNotificationListener') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openMusicPermissionSettings() async {
    try {
      await _engineChannel.invokeMethod<bool>('openNotificationListenerSettings');
    } catch (_) {}
  }

  static Future<void> openAppInfoSettings() async {
    try {
      await _engineChannel.invokeMethod<bool>('openSystemAppDetails');
    } catch (_) {}
  }
}