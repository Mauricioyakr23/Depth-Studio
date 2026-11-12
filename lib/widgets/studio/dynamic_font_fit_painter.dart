import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/core.dart';
import 'studio_common_widgets.dart';

const List<String> kStudioFonts = [
  'Display 1',
  'Display 2',
  'Display 3',
  'Display 4',
  'Display 5',
  'Display 6',
  'Display 7',
  'Sans-Serif',
];

class FontSelectorGrid extends StatelessWidget {
  final String selectedFont;
  final bool isEnabled;
  final ValueChanged<String> onFontSelected;
  final String previewText;

  const FontSelectorGrid({
    super.key,
    required this.selectedFont,
    required this.isEnabled,
    required this.onFontSelected,
    this.previewText = '12:30',
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent:
            (56.0 * MediaQuery.textScalerOf(context).scale(1.0)).clamp(56.0, 76.0),
      ),
      itemCount: kStudioFonts.length,
      itemBuilder: (context, index) {
        final String font = kStudioFonts[index];
        final bool isSelected = selectedFont == font;

        return PressScaleWrapper(
          child: GestureDetector(
            onTap: isEnabled
                ? () {
                    HapticFeedback.selectionClick();
                    onFontSelected(font);
                  }
                : null,
            child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.22)
                  : AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 0.6,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SizedBox.expand(
                    child: DynamicFontPreview(
                      text: previewText,
                      fontFamily: font,
                      textColor: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  font,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }
}

class DynamicFontPreview extends StatelessWidget {
  final String text;
  final String fontFamily;
  final Color textColor;

  const DynamicFontPreview({
    super.key,
    required this.text,
    required this.fontFamily,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DynamicFontFitPainter(
        text: text,
        fontFamily: fontFamily,
        textColor: textColor,
      ),
    );
  }
}

class DynamicFontFitPainter extends CustomPainter {
  final String text;
  final String fontFamily;
  final Color textColor;

  DynamicFontFitPainter({
    required this.text,
    required this.fontFamily,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    const double baseFontSize = 40.0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily == 'Sans-Serif' ? null : fontFamily,
          fontSize: baseFontSize,
          color: textColor,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final List<ui.LineMetrics> metrics = tp.computeLineMetrics();
    double glyphWidth = tp.width;
    double glyphHeight = tp.height;

    if (metrics.isNotEmpty) {
      final m = metrics.first;
      glyphWidth = m.width > tp.width ? m.width : tp.width;
      final double trueVerticalSpan = m.ascent + m.descent;
      if (trueVerticalSpan > glyphHeight) {
        glyphHeight = trueVerticalSpan;
      }
    }

    if (glyphWidth <= 0 || glyphHeight <= 0) {
      canvas.restore();
      return;
    }

    final double availW = size.width * 0.86;
    final double availH = size.height * 0.82;

    final double scaleX = availW / glyphWidth;
    final double scaleY = availH / glyphHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.translate(size.width / 2.0, size.height / 2.0);
    canvas.scale(scale, scale);

    tp.paint(canvas, Offset(-tp.width / 2.0, -tp.height / 2.0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DynamicFontFitPainter oldDelegate) {
    return oldDelegate.fontFamily != fontFamily ||
        oldDelegate.text != text ||
        oldDelegate.textColor != textColor;
  }
}