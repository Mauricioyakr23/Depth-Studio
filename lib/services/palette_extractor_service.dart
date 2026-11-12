import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PaletteExtractorService {
  const PaletteExtractorService._();

  static const List<Color> defaultPalette = [
    Colors.white,
    Color(0xFFD0BCFF),
    Color(0xFF80D8FF),
    Color(0xFFFFB74D),
    Color(0xFFF48FB1),
    Color(0xFFA5D6A7),
    Color(0xFF90CAF9),
  ];

  static Future<List<Color>> extractPalette(String? path) async {
    if (path == null || path.isEmpty) return defaultPalette;

    ui.Codec? codec;
    ui.Image? image;
    try {
      final File file = File(path);
      if (!await file.exists()) return defaultPalette;

      final Uint8List bytes = await file.readAsBytes();
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 64,
        targetHeight: 64,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      image = frame.image;

      final ByteData? rawRgba =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rawRgba == null) return defaultPalette;

      final List<int> bucketCount = List.filled(12, 0);
      final List<double> bucketH = List.filled(12, 0.0);
      final List<double> bucketS = List.filled(12, 0.0);
      final List<double> bucketV = List.filled(12, 0.0);

      double avgLum = 0.0;
      int totalPixels = 0;

      for (int i = 0; i < rawRgba.lengthInBytes; i += 4) {
        final int r = rawRgba.getUint8(i);
        final int g = rawRgba.getUint8(i + 1);
        final int b = rawRgba.getUint8(i + 2);
        final int a = rawRgba.getUint8(i + 3);
        if (a < 128) continue;

        final Color c = Color.fromARGB(255, r, g, b);
        final HSVColor hsv = HSVColor.fromColor(c);
        avgLum += hsv.value;
        totalPixels++;

        if (hsv.value < 0.12 || hsv.saturation < 0.12) continue;

        final int bucketIdx = (hsv.hue ~/ 30) % 12;
        bucketCount[bucketIdx]++;
        bucketH[bucketIdx] += hsv.hue;
        bucketS[bucketIdx] += hsv.saturation;
        bucketV[bucketIdx] += hsv.value;
      }

      final List<int> sortedIndices = List.generate(12, (i) => i)
        ..sort((a, b) => bucketCount[b].compareTo(bucketCount[a]));

      final List<Color> extracted = [Colors.white];

      for (final int idx in sortedIndices) {
        if (bucketCount[idx] < 6) continue;
        final double meanH = (bucketH[idx] / bucketCount[idx]) % 360.0;
        final double meanS =
        (bucketS[idx] / bucketCount[idx]).clamp(0.25, 1.0);
        final double meanV =
        (bucketV[idx] / bucketCount[idx]).clamp(0.35, 1.0);

        final Color pastelTone = HSVColor.fromAHSV(
          1.0,
          meanH,
          (meanS * 0.58).clamp(0.28, 0.65),
          0.96,
        ).toColor();

        final Color vibrantTone = HSVColor.fromAHSV(
          1.0,
          meanH,
          (meanS * 1.15).clamp(0.50, 0.95),
          meanV.clamp(0.75, 0.95),
        ).toColor();

        final Color deepTone = HSVColor.fromAHSV(
          1.0,
          meanH,
          (meanS * 1.10).clamp(0.55, 0.95),
          0.55,
        ).toColor();

        for (final candidate in [pastelTone, vibrantTone, deepTone]) {
          if (!_isColorTooSimilar(candidate, extracted)) {
            extracted.add(candidate);
          }
        }
        if (extracted.length >= 12) break;
      }

      if (totalPixels > 0) {
        final double mLum = (avgLum / totalPixels).clamp(0.2, 0.9);
        extracted.add(
          Color.lerp(const Color(0xFFCFD8DC), const Color(0xFF263238), mLum)!,
        );
      }

      return extracted.length > 1 ? extracted : defaultPalette;
    } catch (_) {
      return defaultPalette;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  static bool _isColorTooSimilar(Color c, List<Color> existing) {
    final int r1 = (c.r * 255.0).round();
    final int g1 = (c.g * 255.0).round();
    final int b1 = (c.b * 255.0).round();
    for (final e in existing) {
      final int r2 = (e.r * 255.0).round();
      final int g2 = (e.g * 255.0).round();
      final int b2 = (e.b * 255.0).round();
      final double dist = math.sqrt(
        (r1 - r2) * (r1 - r2) +
            (g1 - g2) * (g1 - g2) +
            (b1 - b2) * (b1 - b2),
      );
      if (dist < 36.0) return true;
    }
    return false;
  }
}