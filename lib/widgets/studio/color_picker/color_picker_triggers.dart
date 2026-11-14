import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/core.dart';
import 'ios_color_picker_dialog.dart';

Future<void> showStudioColorPickerDialog({
  required BuildContext context,
  required Color currentColor,
  required List<Color> palette,
  required ValueChanged<Color> onColorPicked,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppStrings.cancel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, animation, secondaryAnimation) =>
        IosVisualColorPickerDialog(
          initialColor: currentColor,
          materialYouPalette: palette,
          onColorConfirmed: onColorPicked,
        ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class HexColorTriggerButton extends StatelessWidget {
  final Color currentColor;
  final bool isEnabled;
  final List<Color> palette;
  final ValueChanged<Color> onColorPicked;

  const HexColorTriggerButton({
    super.key,
    required this.currentColor,
    required this.isEnabled,
    required this.palette,
    required this.onColorPicked,
  });

  @override
  Widget build(BuildContext context) {
    final String hexLabel =
        '#${currentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled
          ? () => showStudioColorPickerDialog(
        context: context,
        currentColor: currentColor,
        palette: palette,
        onColorPicked: onColorPicked,
      )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              hexLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.eyedropper,
              size: 12,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class PaletteColorRow extends StatelessWidget {
  final Color selectedColor;
  final bool isEnabled;
  final List<Color> palette;
  final ValueChanged<Color> onColorSelected;

  const PaletteColorRow({
    super.key,
    required this.selectedColor,
    required this.isEnabled,
    required this.palette,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: palette.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isEnabled
                  ? () => showStudioColorPickerDialog(
                context: context,
                currentColor: selectedColor,
                palette: palette,
                onColorPicked: onColorSelected,
              )
                  : null,
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            );
          }

          final Color swatchColor = palette[index - 1];
          final bool isSelected =
              selectedColor.toARGB32() == swatchColor.toARGB32();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isEnabled
                ? () {
              HapticFeedback.selectionClick();
              onColorSelected(swatchColor);
            }
                : null,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutQuad,
                width: isSelected ? 40 : 36,
                height: isSelected ? 40 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatchColor,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 3.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: swatchColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}