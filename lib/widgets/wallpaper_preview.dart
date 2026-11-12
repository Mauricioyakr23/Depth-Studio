import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/core.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';
import 'preview/depth_clock_painter.dart';
import 'preview/depth_date_painter.dart';

class WallpaperPreview extends StatefulWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final bool showFrame;
  final double animProgress;

  const WallpaperPreview({
    super.key,
    required this.data,
    required this.config,
    this.showFrame = true,
    this.animProgress = 1.0,
  });

  @override
  State<WallpaperPreview> createState() => _WallpaperPreviewState();
}

class _WallpaperPreviewState extends State<WallpaperPreview> {
  ui.Image? _decodedBgImage;
  String? _loadedBgPath;
  int _loadToken = 0;
  Timer? _minuteSyncTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadBgUiImage();
    _startLiveClock();
  }

  void _startLiveClock() {
    _minuteSyncTimer?.cancel();
    _clockTimer?.cancel();
    final DateTime now = DateTime.now();
    final int msUntilNextMinute =
        ((60 - now.second) * 1000) - now.millisecond + 50;
    _minuteSyncTimer = Timer(Duration(milliseconds: msUntilNextMinute), () {
      if (!mounted) return;
      setState(() {});
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _minuteSyncTimer?.cancel();
    _clockTimer?.cancel();
    _decodedBgImage?.dispose();
    _decodedBgImage = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WallpaperPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.originalImagePath != _loadedBgPath) {
      _loadBgUiImage();
    }
  }

  Future<void> _loadBgUiImage() async {
    final String? path = widget.data.originalImagePath;
    final int currentToken = ++_loadToken;

    if (path == null || path.isEmpty) {
      if (mounted) {
        setState(() {
          _decodedBgImage?.dispose();
          _decodedBgImage = null;
          _loadedBgPath = null;
        });
      }
      return;
    }

    ui.Codec? codec;
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      codec = await ui.instantiateImageCodec(bytes, targetWidth: 540);
      final frame = await codec.getNextFrame();

      if (!mounted || currentToken != _loadToken) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _decodedBgImage?.dispose();
        _decodedBgImage = frame.image;
        _loadedBgPath = path;
      });
    } catch (_) {
    } finally {
      codec?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final config = widget.config;

    final Size screenSize = MediaQuery.sizeOf(context);
    final double deviceAspectRatio =
    (screenSize.width > 0 && screenSize.height > 0)
        ? (screenSize.width / screenSize.height)
        : (9.0 / 19.5);

    final DateTime now = DateTime.now();
    final String hourStr = DateFormat('HH').format(now);
    final String minStr = DateFormat('mm').format(now);
    final String dateStr =
    _getFormattedDate(now, config.dateFormat, config.dateAllCaps);

    final Widget previewArea = LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int targetCacheWidth = (width * 2.0).toInt();

        final bool drawHoursBehind = config.depthLayering != 'Hours Forward';
        final bool drawMinutesBehind =
            config.depthLayering != 'Minutes Forward';

        final bool drawHoursInFront = config.depthLayering == 'Hours Forward';
        final bool drawMinutesInFront =
            config.depthLayering == 'Minutes Forward';

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (data.originalImagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(data.originalImagePath!),
                  fit: BoxFit.cover,
                  cacheWidth: targetCacheWidth > 0 ? targetCacheWidth : null,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF1C1C1E),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.photo_on_rectangle,
                            size: 36,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.noLayersLoaded,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.selectLayersBelow,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (data.originalImagePath != null && config.backgroundDim > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: config.backgroundDim),
                  ),
                ),
              ),
            if (data.originalImagePath != null &&
                (drawHoursBehind || drawMinutesBehind))
              Positioned.fill(
                child: CustomPaint(
                  painter: DepthClockPainter(
                    config: config,
                    bgImage: _decodedBgImage,
                    paintHours: drawHoursBehind,
                    paintMinutes: drawMinutesBehind,
                    animProgress: widget.animProgress,
                    hourStr: hourStr,
                    minStr: minStr,
                  ),
                ),
              ),
            if (data.originalImagePath != null &&
                data.foregroundImagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(data.foregroundImagePath!),
                  fit: BoxFit.cover,
                  cacheWidth: targetCacheWidth > 0 ? targetCacheWidth : null,
                ),
              ),
            if (data.originalImagePath != null &&
                (drawHoursInFront || drawMinutesInFront))
              Positioned.fill(
                child: CustomPaint(
                  painter: DepthClockPainter(
                    config: config,
                    bgImage: _decodedBgImage,
                    paintHours: drawHoursInFront,
                    paintMinutes: drawMinutesInFront,
                    animProgress: widget.animProgress,
                    hourStr: hourStr,
                    minStr: minStr,
                  ),
                ),
              ),
            if (config.showDate && data.originalImagePath != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: DepthDatePainter(
                    config: config,
                    dateText: dateStr,
                    animProgress: widget.animProgress,
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (widget.showFrame) {
      return AspectRatio(
        aspectRatio: deviceAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: previewArea,
          ),
        ),
      );
    } else {
      return previewArea;
    }
  }

  String _getFormattedDate(DateTime now, String format, bool allCaps) {
    try {
      final dateStr = DateFormat(format).format(now);
      return allCaps ? dateStr.toUpperCase() : dateStr;
    } catch (_) {
      final fallback = DateFormat('EEE, MMM dd').format(now);
      return allCaps ? fallback.toUpperCase() : fallback;
    }
  }
}