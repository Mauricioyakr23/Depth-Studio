import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper/models/app_settings.dart';
import 'package:wallpaper/models/depth_scene_config.dart';
import 'package:wallpaper/models/saved_scene.dart';
import 'package:wallpaper/models/scene_layers.dart';

void main() {
  group('Depth Studio Models Roundtrip', () {
    test('DepthSceneConfig serializes and deserializes hierarchically', () {
      const original = DepthSceneConfig(
        fontSize: 0.34,
        horizontalPos: 0.42,
        verticalPos: 0.28,
        clockDisplay: 'Vertical',
        clockFormat: 'HH MM',
        depthLayering: 'Hours Forward',
        fontColor: Color(0xFF0A84FF),
        minuteColor: Color(0xFFFF375F),
        fontFamily: 'Display 3',
        depthMode: 'Liquid',
        blurAmount: 22.0,
        showDate: true,
        dateFontFamily: 'Sans-Serif',
        dateColor: Color(0xFF30D158),
        backgroundDim: 0.15,
      );

      final json = original.toJson();
      final restored = DepthSceneConfig.fromJson(json);

      expect(restored, equals(original));
    });

    test('AppSettings serializes and deserializes with nested MusicSettings', () {
      const original = AppSettings(
        homescreenClock: true,
        use24Hour: false,
        hasSeenOnboarding: true,
        themeMode: 'amoled',
        languageCode: 'en',
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored, equals(original));
      expect(AppSettings.musicStorageKey, equals('ds_music_overlay_v1'));
    });

    test('SavedScene and SceneLayers preserve asset paths and style config', () {
      final now = DateTime(2026, 11, 14, 17, 0);
      final original = SavedScene(
        sceneId: 'scene-001',
        title: 'Lock Screen Test',
        createdAt: now,
        updatedAt: now,
        previewCardPath: '/tmp/preview.png',
        isCurrentWallpaper: true,
        layers: const SceneLayers(
          backgroundPath: '/tmp/bg.png',
          subjectPath: '/tmp/fg.png',
        ),
        styleConfig: const DepthSceneConfig(fontSize: 0.38),
      );

      final json = original.toJson();
      final restored = SavedScene.fromJson(json);

      expect(restored, equals(original));
      expect(restored.layers.isDepthReady, isTrue);
    });
  });
}