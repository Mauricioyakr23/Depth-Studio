import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';

class OnboardingFeatureSlide extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String badge;
  final String title;
  final String subtitle;

  const OnboardingFeatureSlide({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(
                        alpha: AppColors.isLight ? 0.22 : 0.32,
                      ),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              GlassContainer(
                width: 110,
                height: 110,
                quality: GlassQuality.premium,
                useOwnLayer: true,
                shape: const LiquidRoundedSuperellipse(borderRadius: 30),
                settings: LiquidGlassSettings(
                  blur: 18.0,
                  thickness: AppColors.isLight ? 22.0 : 34.0,
                  glassColor: accentColor.withValues(
                    alpha: AppColors.isLight ? 0.16 : 0.22,
                  ),
                  refractiveIndex: 1.45,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 48,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              badge.toUpperCase(),
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
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

class OnboardingPermissionsSlide extends StatelessWidget {
  final bool storageGranted;
  final bool musicGranted;
  final VoidCallback onRequestStorage;
  final VoidCallback onRequestMusic;
  final VoidCallback onOpenAppInfo;

  const OnboardingPermissionsSlide({
    super.key,
    required this.storageGranted,
    required this.musicGranted,
    required this.onRequestStorage,
    required this.onRequestMusic,
    required this.onOpenAppInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        8,
        AppLayout.screenPaddingH,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF30D158).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF30D158).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              AppStrings.onbPermBadge.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF30D158),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.onbPermTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              AppStrings.onbPermSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 22),

          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            width: double.infinity,
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _IosPermissionTile(
                  icon: CupertinoIcons.photo_on_rectangle,
                  title: AppStrings.onbStorageTitle,
                  description: AppStrings.onbStorageDesc,
                  isGranted: storageGranted,
                  buttonLabel: storageGranted
                      ? AppStrings.onbStorageGranted
                      : AppStrings.onbStorageAllow,
                  onTap: onRequestStorage,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: AppColors.divider.withValues(
                      alpha: AppColors.isLight ? 0.6 : 0.45,
                    ),
                    height: 1,
                    thickness: 0.6,
                  ),
                ),
                _IosPermissionTile(
                  icon: CupertinoIcons.music_albums_fill,
                  title: AppStrings.onbMusicTitle,
                  description: AppStrings.onbMusicDesc,
                  isGranted: musicGranted,
                  buttonLabel: musicGranted
                      ? AppStrings.onbMusicGranted
                      : AppStrings.onbMusicAllow,
                  onTap: onRequestMusic,
                ),
              ],
            ),
          ),

          if (!musicGranted) ...[
            const SizedBox(height: 14),
            GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              width: double.infinity,
              shape: const LiquidRoundedSuperellipse(borderRadius: 20),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.shield_lefthalf_fill,
                          color: Color(0xFFFF9F0A),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.onbRestrictedTitle,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.onbRestrictedDesc,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    minimumSize: Size.zero,
                    onPressed: onOpenAppInfo,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.gear_alt_fill,
                          color: Color(0xFFFF9F0A),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.onbOpenAppInfoBtn,
                          style: const TextStyle(
                            color: Color(0xFFFF9F0A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IosPermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final String buttonLabel;
  final VoidCallback onTap;

  const _IosPermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color stateColor =
        isGranted ? const Color(0xFF30D158) : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isGranted ? CupertinoIcons.checkmark_seal_fill : icon,
                  color: stateColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isGranted)
                const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Color(0xFF30D158),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: isGranted
                  ? const Color(0xFF30D158).withValues(alpha: 0.15)
                  : AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGranted
                        ? CupertinoIcons.check_mark
                        : CupertinoIcons.arrow_up_right_square,
                    size: 15,
                    color: isGranted ? const Color(0xFF30D158) : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      color: isGranted ? const Color(0xFF30D158) : Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}