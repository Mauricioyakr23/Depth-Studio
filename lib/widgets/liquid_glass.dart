export 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/theme/app_colors.dart';
import '../state/notifiers/app_notifiers.dart';

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? tint;
  final bool useOwnLayer;
  final GlassSurfaceStyle surfaceStyle;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.padding,
    this.margin,
    this.blur = 12.0,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
    this.tint,
    this.useOwnLayer = false,
    this.surfaceStyle = GlassSurfaceStyle.solid,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        final Color defaultGlassTint = AppColors.isLight
            ? Colors.white.withValues(alpha: 0.45)
            : (AppColors.isAmoled
                ? const Color(0xFF0D0D12).withValues(alpha: 0.55)
                : const Color(0xFF16161E).withValues(alpha: 0.48));

        final Color activeSelectedTint = AppColors.accent.withValues(
          alpha: AppColors.isLight ? 0.22 : 0.32,
        );

        final Color effectiveTint =
            tint ?? (isSelected ? activeSelectedTint : defaultGlassTint);

        Widget body = GlassContainer(
          width: width,
          height: height,
          padding: padding ?? EdgeInsets.zero,
          useOwnLayer: useOwnLayer,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
          settings: LiquidGlassSettings(
            blur: blur,
            thickness: AppColors.isLight ? 22.0 : 32.0,
            glassColor: effectiveTint,
            refractiveIndex: 1.45,
          ),
          child: child,
        );

        if (margin != null) {
          body = Padding(padding: margin!, child: body);
        }

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: body,
          );
        }

        return body;
      },
    );
  }
}

class LiquidGlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double height;

  const LiquidGlassButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.height = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final Color fgColor = isPrimary ? Colors.white : AppColors.textPrimary;

    return GlassButton.custom(
      onTap: isEnabled ? onPressed! : () {},
      height: height,
      enabled: isEnabled,
      shape: const LiquidRoundedSuperellipse(borderRadius: 14),
      glowColor: isPrimary ? AppColors.accent : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
