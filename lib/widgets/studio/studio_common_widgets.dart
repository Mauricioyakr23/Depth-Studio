import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/core.dart';

class PressScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool isEnabled;

  const PressScaleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutQuad,
    this.isEnabled = true,
  });

  @override
  State<PressScaleWrapper> createState() => _PressScaleWrapperState();
}

class _PressScaleWrapperState extends State<PressScaleWrapper> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (!widget.isEnabled) return;
    if (_isPressed != pressed) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => _setPressed(true) : null,
      onTapUp: widget.isEnabled ? (_) => _setPressed(false) : null,
      onTapCancel: widget.isEnabled ? () => _setPressed(false) : null,
      onTap: widget.isEnabled ? widget.onTap : null,
      onLongPress: widget.isEnabled ? widget.onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed && widget.isEnabled ? widget.scale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

class StudioDivider extends StatelessWidget {
  final double verticalPadding;

  const StudioDivider({
    super.key,
    this.verticalPadding = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Divider(
        color: AppColors.divider.withValues(
          alpha: AppColors.isLight ? 0.6 : 0.45,
        ),
        height: 1,
        thickness: 0.6,
      ),
    );
  }
}

class StudioNavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isEnabled;

  const StudioNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return PressScaleWrapper(
      isEnabled: isEnabled && onTap != null,
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.accent.withValues(alpha: 0.12)
              : (AppColors.isLight
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isEnabled ? AppColors.accent : AppColors.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: isEnabled
                  ? AppColors.textSecondary
                  : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

class StudioDisabledWrapper extends StatelessWidget {
  final bool isEnabled;
  final Widget child;
  final Duration duration;

  const StudioDisabledWrapper({
    super.key,
    required this.isEnabled,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: duration,
      opacity: isEnabled ? 1.0 : 0.45,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: child,
      ),
    );
  }
}

class IosSectionCard extends StatelessWidget {
  final String header;
  final Widget child;
  final Widget? trailingHeader;

  const IosSectionCard({
    super.key,
    required this.header,
    required this.child,
    this.trailingHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    header.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ?trailingHeader,
              ],
            ),
          ),
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            width: double.infinity,
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class StudioToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const StudioToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: isEnabled ? 1.0 : 0.45,
              child: IgnorePointer(
                ignoring: !isEnabled,
                child: GlassSwitch(
                  value: value,
                  activeColor: AppColors.accent,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioSliderRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final bool isEnabled;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  const StudioSliderRow({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.isEnabled,
    required this.onChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 42),
                  child: Text(
                    valueText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (isEnabled) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReset,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface
                                .withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_counterclockwise,
                            size: 13,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: GlassSlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.accent,
            onChanged: isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}