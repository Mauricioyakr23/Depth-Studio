import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';

class PlatformChannel {
  const PlatformChannel._();

  static const MethodChannel _channel =
  MethodChannel('com.depthstudio.wallpaper/wallpaper');

  static Future<int> getSdkInt() async {
    try {
      return await _channel.invokeMethod<int>('getSdkInt') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveConfig({
    required WallpaperConfig config,
    required WallpaperData data,
    required AppSettings settings,
  }) async {
    await _channel.invokeMethod<bool>('saveConfig', <String, Object?>{
      'fontSize': config.fontSize,
      'horizontalPos': config.horizontalPos,
      'verticalPos': config.verticalPos,
      'clockDisplay': config.clockDisplay,
      'clockFormat': config.clockFormat,
      'depthLayering': config.depthLayering,
      'fontColor': config.fontColor.toARGB32(),
      'minuteColor': config.minuteColor.toARGB32(),
      'fontFamily': config.fontFamily,
      'letterSpacing': config.letterSpacing,
      'lineSpacing': config.lineSpacing,
      'stretch': config.stretch,
      'textOpacity': config.textOpacity,
      'depthMode': config.depthMode,
      'blurAmount': config.blurAmount,
      'shadowEnabled': config.shadowEnabled,
      'edgeStrokeEnabled': config.edgeStrokeEnabled,
      'rimWidth': config.rimWidth,
      'rimOpacity': config.rimOpacity,
      'rimBlur': config.rimBlur,
      'rimBrightness': config.rimBrightness,
      'clockAnimStyle': config.clockAnimStyle,
      'clockAnimDuration': config.clockAnimDuration,
      'animateOnScreenOn': config.animateOnScreenOn,
      'animateOnUnlock': config.animateOnUnlock,
      'backgroundPath': data.originalImagePath,
      'foregroundPath': data.foregroundImagePath,
      'showDate': config.showDate,
      'dateFontFamily': config.dateFontFamily,
      'dateFontSize': config.dateFontSize,
      'dateHorizontalPos': config.dateHorizontalPos,
      'dateVerticalPos': config.dateVerticalPos,
      'dateColor': config.dateColor.toARGB32(),
      'dateFormat': config.dateFormat,
      'dateAllCaps': config.dateAllCaps,
      'dateBold': config.dateBold,
      'backgroundDim': config.backgroundDim,
      'homescreenClock': settings.homescreenClock,
      'use24Hour': settings.use24Hour,
      'musicModeEnabled': settings.musicModeEnabled,
      'musicTargetPackage': settings.musicTargetPackage,
    });
  }

  static Future<void> setWallpaper() async {
    await _channel.invokeMethod<bool>('setWallpaper');
  }

  static Future<void> saveAndApplyWallpaper({
    required WallpaperConfig config,
    required WallpaperData data,
    required AppSettings settings,
  }) async {
    await saveConfig(config: config, data: data, settings: settings);
    await setWallpaper();
  }

  static Future<void> updateGlobalSettings(AppSettings settings) async {
    try {
      await _channel.invokeMethod<bool>('updateGlobalSettings', <String, Object>{
        'homescreenClock': settings.homescreenClock,
        'use24Hour': settings.use24Hour,
        'musicModeEnabled': settings.musicModeEnabled,
        'musicTargetPackage': settings.musicTargetPackage,
      });
    } catch (_) {}
  }

  static Future<bool> isStoragePermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isStoragePermissionGranted') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestStoragePermission() async {
    try {
      await _channel.invokeMethod<bool>('requestStoragePermission');
    } catch (_) {}
  }

  static Future<bool> isMusicPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isMusicPermissionGranted') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openMusicPermissionSettings() async {
    try {
      await _channel.invokeMethod<bool>('openMusicPermissionSettings');
    } catch (_) {}
  }

  static Future<void> openAppInfoSettings() async {
    try {
      await _channel.invokeMethod<bool>('openAppInfoSettings');
    } catch (_) {}
  }
}