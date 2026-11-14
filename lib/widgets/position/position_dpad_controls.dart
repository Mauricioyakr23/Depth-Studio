import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../studio/studio_common_widgets.dart';

class PositionPresetGrid extends StatelessWidget {
  final double boxHeight;
  final double horizontalPos;
  final double verticalPos;
  final List<double> presetHValues;
  final List<double> presetVValues;
  final void Function(int col, int row) onSelectPreset;

  const PositionPresetGrid({
    super.key,
    required this.boxHeight,
    required this.horizontalPos,
    required this.verticalPos,
    required this.presetHValues,
    required this.presetVValues,
    required this.onSelectPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.presetsLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: boxHeight,
          child: Column(
            children: [
              for (int row = 0; row < 3; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (int col = 0; col < 3; col++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: _presetButton(col, row),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetButton(int col, int row) {
    final bool isSelected =
        (horizontalPos - presetHValues[col]).abs() < 0.03 &&
            (verticalPos - presetVValues[row]).abs() < 0.03;

    return PressScaleWrapper(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onSelectPreset(col, row);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.22)
                : AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.accent, width: 1.2)
                : null,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PositionDPad extends StatelessWidget {
  final double boxSize;
  final void Function(double dx, double dy) onMoveBy;
  final VoidCallback onResetCenter;

  const PositionDPad({
    super.key,
    required this.boxSize,
    required this.onMoveBy,
    required this.onResetCenter,
  });

  @override
  Widget build(BuildContext context) {
    final double btnSize = (boxSize * 0.32).clamp(44.0, 48.0);
    final double centerOffset = (boxSize - btnSize) / 2.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppStrings.fineAdjustLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: boxSize,
          height: boxSize,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: centerOffset,
                child: ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_up,
                  size: btnSize,
                  onTrigger: () => onMoveBy(0, -0.01),
                ),
              ),
              Positioned(
                bottom: 0,
                left: centerOffset,
                child: ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_down,
                  size: btnSize,
                  onTrigger: () => onMoveBy(0, 0.01),
                ),
              ),
              Positioned(
                left: 0,
                top: centerOffset,
                child: ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_left,
                  size: btnSize,
                  onTrigger: () => onMoveBy(-0.01, 0),
                ),
              ),
              Positioned(
                right: 0,
                top: centerOffset,
                child: ContinuousDpadButton(
                  icon: CupertinoIcons.chevron_right,
                  size: btnSize,
                  onTrigger: () => onMoveBy(0.01, 0),
                ),
              ),
              Positioned(
                top: centerOffset,
                left: centerOffset,
                child: PressScaleWrapper(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onResetCenter();
                    },
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        CupertinoIcons.scope,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ContinuousDpadButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTrigger;

  const ContinuousDpadButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onTrigger,
  });

  @override
  State<ContinuousDpadButton> createState() => _ContinuousDpadButtonState();
}

class _ContinuousDpadButtonState extends State<ContinuousDpadButton> {
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      HapticFeedback.selectionClick();
      widget.onTrigger();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScaleWrapper(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTrigger();
        },
        onLongPressStart: (_) {
          HapticFeedback.selectionClick();
          widget.onTrigger();
          _startTimer();
        },
        onLongPressEnd: (_) => _stopTimer(),
        onLongPressCancel: () => _stopTimer(),
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}