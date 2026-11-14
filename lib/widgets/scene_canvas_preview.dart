import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/core.dart';
import '../models/app_settings.dart';
import '../models/depth_scene_config.dart';
import '../models/scene_layers.dart';
import '../state/notifiers/app_notifiers.dart';
import 'preview/depth_clock_painter.dart';
import 'preview/depth_date_painter.dart';

class SceneCanvasPreview extends StatefulWidget {
  final SceneLayers layers;
  final DepthSceneConfig config;
  final bool showFrame;
  final double animProgress;

  const SceneCanvasPreview({
    super.key,
    required this.layers,
    required this.config,
    this.showFrame = true,
    this.animProgress = 1.0,
  });

  @override
  State<SceneCanvasPreview> createState() => _SceneCanvasPreviewState();
}

class _SceneCanvasPreviewState extends State<SceneCanvasPreview> {
  static const Set<String> _supportedDatePatterns = {
    'EEE, MMM dd',
    'EEEE, MMMM dd',
    'MMM dd, yyyy',
    'dd/MM/yyyy',
    'MM-dd-yyyy',
  };

  ui.Image? _decodedBgImage;
  String? _loadedBgPath;
  int _loadedTargetWidth = 0;
  int _targetDecodeWidth = 1080;
  bool _bgLoadFailed = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    MinuteClock.ensureRunning();
    MinuteClock.now.addListener(_onMinuteChanged);
  }

  void _onMinuteChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Size screenSize = MediaQuery.sizeOf(context);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int computedTarget = screenSize.width > 0
        ? (screenSize.width * dpr).round().clamp(540, 1440)
        : 1080;

    if (computedTarget != _targetDecodeWidth ||
        widget.layers.backgroundPath != _loadedBgPath) {
      _targetDecodeWidth = computedTarget;
      _loadBgUiImage();
    }
  }

  @override
  void dispose() {
    MinuteClock.now.removeListener(_onMinuteChanged);
    _decodedBgImage?.dispose();
    _decodedBgImage = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SceneCanvasPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layers.backgroundPath != _loadedBgPath ||
        _targetDecodeWidth != _loadedTargetWidth) {
      _loadBgUiImage();
    }
  }

  Future<void> _loadBgUiImage() async {
    final String? path = widget.layers.backgroundPath;
    final int targetWidth = _targetDecodeWidth;
    final int currentToken = ++_loadToken;

    if (path == null || path.isEmpty) {
      if (mounted) {
        setState(() {
          _decodedBgImage?.dispose();
          _decodedBgImage = null;
          _loadedBgPath = null;
          _loadedTargetWidth = 0;
          _bgLoadFailed = false;
        });
      }
      return;
    }

    ui.Codec? codec;
    try {
      final file = File(path);
      if (!await file.exists()) {
        if (mounted && currentToken == _loadToken) {
          setState(() {
            _decodedBgImage?.dispose();
            _decodedBgImage = null;
            _loadedBgPath = path;
            _loadedTargetWidth = targetWidth;
            _bgLoadFailed = true;
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();

      if (!mounted || currentToken != _loadToken) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _decodedBgImage?.dispose();
        _decodedBgImage = frame.image;
        _loadedBgPath = path;
        _loadedTargetWidth = targetWidth;
        _bgLoadFailed = false;
      });
    } catch (_) {
      if (mounted && currentToken == _loadToken) {
        setState(() {
          _decodedBgImage?.dispose();
          _decodedBgImage = null;
          _loadedBgPath = path;
          _loadedTargetWidth = targetWidth;
          _bgLoadFailed = true;
        });
      }
    } finally {
      codec?.dispose();
    }
  }

  Widget _buildEmptyOrMissingPlaceholder({bool isMissing = false}) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMissing
                    ? CupertinoIcons.exclamationmark_triangle
                    : CupertinoIcons.photo_on_rectangle,
                size: 36,
                color: const Color(0xFF8E8E93),
              ),
              const SizedBox(height: 10),
              Text(
                isMissing
                    ? AppStrings.missingImageFile
                    : AppStrings.noLayersLoaded,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              if (!isMissing) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime instant, String pattern, bool uppercase) {
    final activePattern =
    _supportedDatePatterns.contains(pattern) ? pattern : 'EEE, MMM dd';
    final formatted = DateFormat(activePattern).format(instant);
    return uppercase ? formatted.toUpperCase() : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final layers = widget.layers;
    final config = widget.config;

    final Size screenSize = MediaQuery.sizeOf(context);
    final double deviceAspectRatio =
    (screenSize.width > 0 && screenSize.height > 0)
        ? (screenSize.width / screenSize.height)
        : (9.0 / 19.5);

    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final DateTime now = MinuteClock.now.value;
        final String hourPattern = settings.use24Hour ? 'HH' : 'hh';
        final String hourStr = DateFormat(hourPattern).format(now);
        final String minStr = DateFormat('mm').format(now);
        final String dateStr =
        _formatDateLabel(now, config.dateFormat, config.dateAllCaps);

        final Widget previewArea = LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final int targetCacheWidth = (width * 2.0).toInt();

            final bool drawHoursBehind =
                config.depthLayering != 'Hours Forward';
            final bool drawMinutesBehind =
                config.depthLayering != 'Minutes Forward';

            final bool drawHoursInFront =
                config.depthLayering == 'Hours Forward';
            final bool drawMinutesInFront =
                config.depthLayering == 'Minutes Forward';

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (!layers.hasBackground)
                  Positioned.fill(
                    child: _buildEmptyOrMissingPlaceholder(),
                  )
                else if (_bgLoadFailed)
                  Positioned.fill(
                    child: _buildEmptyOrMissingPlaceholder(isMissing: true),
                  )
                else if (_decodedBgImage != null)
                    Positioned.fill(
                      child: RawImage(
                        image: _decodedBgImage,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0xFF1C1C1E)),
                    ),
                if (layers.hasBackground &&
                    !_bgLoadFailed &&
                    config.backgroundDim > 0.001)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color:
                        Colors.black.withValues(alpha: config.backgroundDim),
                      ),
                    ),
                  ),
                if (layers.hasBackground &&
                    !_bgLoadFailed &&
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
                if (layers.hasBackground &&
                    !_bgLoadFailed &&
                    layers.hasSubject)
                  Positioned.fill(
                    child: Image.file(
                      File(layers.subjectPath!),
                      fit: BoxFit.cover,
                      cacheWidth: targetCacheWidth > 0 ? targetCacheWidth : null,
                      errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                    ),
                  ),
                if (layers.hasBackground &&
                    !_bgLoadFailed &&
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
                if (config.showDate &&
                    layers.hasBackground &&
                    !_bgLoadFailed)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DepthDatePainter(
                        config: config,
                        bgImage: _decodedBgImage,
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
      },
    );
  }
}