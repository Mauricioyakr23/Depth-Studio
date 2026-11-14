import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../../models/app_settings.dart';
import 'music_optical_painter.dart';

class MusicCanvasView extends StatefulWidget {
  final AppSettings settings;
  final int selectedTarget;
  final ValueChanged<int>? onTargetSelected;
  final bool showSelectionOutline;

  const MusicCanvasView({
    super.key,
    required this.settings,
    required this.selectedTarget,
    this.onTargetSelected,
    this.showSelectionOutline = true,
  });

  @override
  State<MusicCanvasView> createState() => _MusicCanvasViewState();
}

class _MusicCanvasViewState extends State<MusicCanvasView>
    with SingleTickerProviderStateMixin {
  ui.Image? _backdropImage;
  late final AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _generateBackdropImage();
  }

  @override
  void dispose() {
    _eqController.dispose();
    _backdropImage?.dispose();
    _backdropImage = null;
    super.dispose();
  }

  Future<void> _generateBackdropImage() async {
    const double w = 240.0;
    const double h = 520.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF140B24),
            Color(0xFF2D103B),
            Color(0xFF0A192F),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawCircle(
      const Offset(w * 0.22, h * 0.24),
      w * 0.52,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF2D55).withValues(alpha: 0.72),
            const Color(0xFFFF9F0A).withValues(alpha: 0.25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: const Offset(w * 0.22, h * 0.24),
            radius: w * 0.52,
          ),
        ),
    );

    canvas.drawCircle(
      const Offset(w * 0.82, h * 0.68),
      w * 0.56,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF5E5CE6).withValues(alpha: 0.75),
            const Color(0xFF32ADE6).withValues(alpha: 0.28),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: const Offset(w * 0.82, h * 0.68),
            radius: w * 0.56,
          ),
        ),
    );

    final wavePath = Path()
      ..moveTo(0, h * 0.58)
      ..cubicTo(w * 0.35, h * 0.48, w * 0.65, h * 0.74, w, h * 0.62)
      ..lineTo(w, h * 0.86)
      ..cubicTo(w * 0.60, h * 0.94, w * 0.30, h * 0.72, 0, h * 0.82)
      ..close();

    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFBF5AF2).withValues(alpha: 0.42),
            const Color(0xFF64D2FF).withValues(alpha: 0.45),
          ],
        ).createShader(const Rect.fromLTWH(0, h * 0.48, w, h * 0.46)),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    picture.dispose();
    if (mounted) {
      setState(() => _backdropImage = img);
    } else {
      img.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final bool isEs = AppStrings.isEs;
    final String clockText = s.use24Hour ? '16:30' : '04:30';
    final String dateText = isEs ? 'Jue, 12 Nov' : 'Thu, Nov 12';
    final String songTitle = isEs ? 'Título de la canción' : 'Song Title';
    final String artistName = isEs ? 'Artista' : 'Artist Name';

    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        final double unitScale = w / 360.0;
        final double safeMarginX = 12.0 * unitScale;

        final double baseCoverSize = (w * 0.85).clamp(0.0, h * 0.42);
        final double coverSize =
        (baseCoverSize * s.musicCoverScale).clamp(w * 0.30, w * 0.94);
        final double coverCenterX =
            (w / 2.0) + (s.musicCoverX - 0.50) * w * 1.4;
        final double maxCoverLeft =
        (w - coverSize - safeMarginX).clamp(safeMarginX, w);
        final double coverLeft =
        (coverCenterX - (coverSize / 2.0)).clamp(safeMarginX, maxCoverLeft);
        final double coverTop =
        (h * s.musicCoverY).clamp(0.0, (h - coverSize).clamp(0.0, h));
        final double coverCorner =
        (20.0 * unitScale * s.musicCoverScale.clamp(0.75, 1.25))
            .clamp(6.0, 28.0);

        final double cardScaleClamped = s.musicCardScale.clamp(0.85, 1.25);
        final double cardW =
        (w * 0.85 * s.musicCardScale).clamp(w * 0.58, w * 0.94);
        final double baseCardH = (98.0 * unitScale).clamp(h * 0.10, h * 0.19);
        final double cardH =
        (baseCardH * cardScaleClamped).clamp(38.0, h * 0.26);
        final double cardCenterX =
            (w / 2.0) + (s.musicCardX - 0.50) * w * 1.4;
        final double maxCardLeft =
        (w - cardW - safeMarginX).clamp(safeMarginX, w);
        final double cardLeft =
        (cardCenterX - (cardW / 2.0)).clamp(safeMarginX, maxCardLeft);
        final double cardTop =
        (h * s.musicCardY).clamp(0.0, (h - cardH).clamp(0.0, h));
        final double cardCorner =
        (26.0 * unitScale * s.musicCardScale.clamp(0.80, 1.20))
            .clamp(8.0, 32.0);
        final Rect cardRect = Rect.fromLTWH(cardLeft, cardTop, cardW, cardH);

        final double clockFontSize = w * 0.068 * s.musicClockScale;
        final double clockTop = h * s.musicClockY;
        final double clockHitH = (clockFontSize * 1.45).clamp(16.0, 56.0);
        final double clockHitW =
        (w * 0.62 * s.musicClockScale).clamp(60.0, w - safeMarginX * 2);
        final double clockCenterX =
            (w / 2.0) + (s.musicClockX - 0.50) * w * 1.4;
        final double maxClockLeft =
        (w - clockHitW - safeMarginX).clamp(safeMarginX, w);
        final double clockLeft =
        (clockCenterX - clockHitW / 2.0).clamp(safeMarginX, maxClockLeft);

        final double titleFontSize =
        (14.5 * unitScale * cardScaleClamped).clamp(7.5, 22.0);
        final double subFontSize =
        (12.0 * unitScale * cardScaleClamped).clamp(6.5, 18.0);
        final double timeFontSize =
        (10.0 * unitScale * cardScaleClamped).clamp(5.5, 14.0);
        final double padH =
        (18.0 * unitScale * cardScaleClamped).clamp(6.0, 26.0);
        final double eqReserve = (24.0 * unitScale * cardScaleClamped);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: _backdropImage != null
                  ? RawImage(image: _backdropImage, fit: BoxFit.cover)
                  : Container(color: const Color(0xFF1A1025)),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: MusicOpticalPainter(
                  settings: s,
                  bgImage: _backdropImage,
                  clockText: clockText,
                  dateText: dateText,
                  cardRect: cardRect,
                  cardCorner: cardCorner,
                ),
              ),
            ),
            Positioned(
              top: clockTop,
              left: clockLeft,
              width: clockHitW,
              height: clockHitH,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTargetSelected != null
                    ? () {
                  HapticFeedback.selectionClick();
                  widget.onTargetSelected!(2);
                }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8 * unitScale + 4),
                    border: widget.showSelectionOutline &&
                        widget.selectedTarget == 2
                        ? Border.all(color: AppColors.accent, width: 1.4)
                        : null,
                  ),
                ),
              ),
            ),
            Positioned(
              left: coverLeft,
              top: coverTop,
              width: coverSize,
              height: coverSize,
              child: GestureDetector(
                onTap: widget.onTargetSelected != null
                    ? () {
                  HapticFeedback.selectionClick();
                  widget.onTargetSelected!(0);
                }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(coverCorner),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF375F),
                        Color(0xFFBF5AF2),
                        Color(0xFF5E5CE6),
                      ],
                    ),
                    border: Border.all(
                      color: widget.showSelectionOutline &&
                          widget.selectedTarget == 0
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.28),
                      width: widget.showSelectionOutline &&
                          widget.selectedTarget == 0
                          ? 1.8
                          : 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 12 * unitScale + 4,
                        offset: Offset(0, 6 * unitScale + 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: coverSize * 0.56,
                        height: coverSize * 0.56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.music_note_2,
                        color: Colors.white,
                        size: (coverSize * 0.34).clamp(16.0, 56.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: cardRect,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTargetSelected != null
                    ? () {
                  HapticFeedback.selectionClick();
                  widget.onTargetSelected!(1);
                }
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: padH),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardCorner),
                    border: widget.showSelectionOutline &&
                        widget.selectedTarget == 1
                        ? Border.all(color: AppColors.accent, width: 1.6)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: eqReserve),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  songTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: s.musicCardFont == 'Sans-Serif'
                                        ? null
                                        : s.musicCardFont,
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(
                                  height: (1.5 * unitScale).clamp(0.5, 4.0),
                                ),
                                Text(
                                  artistName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: s.musicCardFont == 'Sans-Serif'
                                        ? null
                                        : s.musicCardFont,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: subFontSize,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: eqReserve,
                            child: _MiniEqualizerBars(
                              controller: _eqController,
                              unitScale: unitScale * cardScaleClamped,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: (5.0 * unitScale).clamp(2.0, 10.0)),
                      Row(
                        children: [
                          Text(
                            '01:24',
                            style: TextStyle(
                              fontFamily: s.musicCardFont == 'Sans-Serif'
                                  ? null
                                  : s.musicCardFont,
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: timeFontSize,
                              fontFeatures: const [
                                ui.FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          SizedBox(width: (6.0 * unitScale).clamp(3.0, 10.0)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: 0.42,
                                minHeight: (3.2 * unitScale).clamp(1.6, 5.0),
                                backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: (6.0 * unitScale).clamp(3.0, 10.0)),
                          Text(
                            '-02:15',
                            style: TextStyle(
                              fontFamily: s.musicCardFont == 'Sans-Serif'
                                  ? null
                                  : s.musicCardFont,
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: timeFontSize,
                              fontFeatures: const [
                                ui.FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniEqualizerBars extends StatelessWidget {
  final AnimationController controller;
  final double unitScale;

  const _MiniEqualizerBars({
    required this.controller,
    required this.unitScale,
  });

  @override
  Widget build(BuildContext context) {
    final double barW = (1.8 * unitScale).clamp(1.0, 3.0);
    final double gap = (1.6 * unitScale).clamp(0.8, 3.0);
    final double maxH = (12.0 * unitScale).clamp(5.0, 18.0);
    final double minH = (3.0 * unitScale).clamp(1.5, 5.0);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double t = controller.value * 2 * math.pi;
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (i) {
            final double wave =
                0.25 + 0.75 * math.sin(t * (2.0 + i * 0.4) + i * 1.1).abs();
            final double barH = minH + (maxH - minH) * wave;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
              child: Container(
                width: barW,
                height: barH,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(barW),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}