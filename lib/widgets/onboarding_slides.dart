import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';

class OnboardingOverviewSlide extends StatelessWidget {
  const OnboardingOverviewSlide({super.key});

  @override
  Widget build(BuildContext context) {
    final Color dividerColor = AppColors.divider.withValues(
      alpha: AppColors.isLight ? 0.6 : 0.45,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                16,
                AppLayout.screenPaddingH,
                16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/ds_icon.svg',
                    height: 185,
                  ),
                  const SizedBox(height: 28),
                  GlassContainer.card(
                    surfaceStyle: GlassSurfaceStyle.solid,
                    width: double.infinity,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _OverviewFeatureRow(
                          icon: CupertinoIcons.layers_alt_fill,
                          iconColor: const Color(0xFF0A84FF),
                          title: AppStrings.onbSlide1Title,
                          subtitle: AppStrings.onbSlide1Sub,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Divider(
                            color: dividerColor,
                            height: 1,
                            thickness: 0.6,
                          ),
                        ),
                        _OverviewFeatureRow(
                          icon: CupertinoIcons.drop_fill,
                          iconColor: const Color(0xFF64D2FF),
                          title: AppStrings.onbSlide2Title,
                          subtitle: AppStrings.onbSlide2Sub,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Divider(
                            color: dividerColor,
                            height: 1,
                            thickness: 0.6,
                          ),
                        ),
                        _OverviewFeatureRow(
                          icon: CupertinoIcons.music_note_2,
                          iconColor: const Color(0xFFFF375F),
                          title: AppStrings.onbSlide3Title,
                          subtitle: AppStrings.onbSlide3Sub,
                        ),
                      ],
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

class _OverviewFeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _OverviewFeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondarySurface.withValues(
                alpha: AppColors.isLight ? 0.75 : 0.65,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.border,
                width: 0.6,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final Color dividerColor = AppColors.divider.withValues(
      alpha: AppColors.isLight ? 0.6 : 0.45,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                16,
                AppLayout.screenPaddingH,
                16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.onbPermTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 28),
                  GlassContainer.card(
                    surfaceStyle: GlassSurfaceStyle.solid,
                    width: double.infinity,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 24),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Divider(
                            color: dividerColor,
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
                      shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9F0A)
                                      .withValues(alpha: 0.15),
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
                            color:
                            const Color(0xFFFF9F0A).withValues(alpha: 0.16),
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
            ),
          ),
        );
      },
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

  Future<void> _handlePress(BuildContext context) async {
    if (!isGranted) {
      onTap();
      return;
    }

    bool confirmed = false;
    await GlassDialog.show(
      context: context,
      title: AppStrings.reopenPermissionTitle,
      message: AppStrings.reopenPermissionDesc,
      actions: [
        GlassDialogAction(
          label: AppStrings.cancel,
          onPressed: () {
            confirmed = false;
            Navigator.of(context).pop();
          },
        ),
        GlassDialogAction(
          label: AppStrings.openSettingsBtn,
          onPressed: () {
            confirmed = true;
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    if (confirmed) {
      onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color stateColor =
    isGranted ? const Color(0xFF30D158) : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isGranted ? CupertinoIcons.checkmark_seal_fill : icon,
                  color: stateColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
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
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 11),
              color: isGranted
                  ? const Color(0xFF30D158).withValues(alpha: 0.15)
                  : AppColors.accent,
              borderRadius: BorderRadius.circular(13),
              onPressed: () => _handlePress(context),
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