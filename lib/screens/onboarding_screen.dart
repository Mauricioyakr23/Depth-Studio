import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/core.dart';
import '../models/app_settings.dart';
import '../services/platform_channel.dart';
import '../state/notifiers/app_notifiers.dart';
import '../widgets/onboarding_slides.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isReplay;
  final VoidCallback? onComplete;

  const OnboardingScreen({
    super.key,
    this.isReplay = false,
    this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _storageGranted = false;
  bool _musicGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final bool storage = await PlatformChannel.isStoragePermissionGranted();
    final bool music = await PlatformChannel.isMusicPermissionGranted();
    if (mounted) {
      setState(() {
        _storageGranted = storage;
        _musicGranted = music;
      });
    }
  }

  Future<void> _requestStorage() async {
    HapticFeedback.mediumImpact();
    await PlatformChannel.requestStoragePermission();
    await Future.delayed(const Duration(milliseconds: 600));
    await _checkAllPermissions();
  }

  Future<void> _requestMusic() async {
    HapticFeedback.mediumImpact();
    await PlatformChannel.openMusicPermissionSettings();
  }

  Future<void> _openAppInfo() async {
    HapticFeedback.lightImpact();
    await PlatformChannel.openAppInfoSettings();
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    final settings = await AppSettings.load();
    await settings.copyWith(hasSeenOnboarding: true).save();

    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else if (widget.isReplay && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        SlidePageRoute(child: const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const int totalPages = 4;
    final bool isLastPage = _currentPage == totalPages - 1;

    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, lang, _) {
            return GlassScaffold(
              backgroundColor: AppColors.bg,
              contentAwareBrightness: true,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        10,
                        AppLayout.screenPaddingH,
                        6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DEPTH STUDIO',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: !isLastPage
                                ? CupertinoButton(
                                    key: const ValueKey('skip_btn'),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    color: AppColors.secondarySurface
                                        .withValues(
                                      alpha: AppColors.isLight ? 0.7 : 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      _pageController.animateToPage(
                                        totalPages - 1,
                                        duration:
                                            const Duration(milliseconds: 380),
                                        curve: Curves.easeOutCubic,
                                      );
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppStrings.skipBtn,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('skip_empty'),
                                    height: 32,
                                    width: 64,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (idx) {
                          HapticFeedback.selectionClick();
                          setState(() => _currentPage = idx);
                          if (idx == totalPages - 1) {
                            _checkAllPermissions();
                          }
                        },
                        children: [
                          OnboardingFeatureSlide(
                            icon: CupertinoIcons.layers_alt_fill,
                            accentColor: const Color(0xFF0A84FF),
                            badge: AppStrings.onbSlide1Badge,
                            title: AppStrings.onbSlide1Title,
                            subtitle: AppStrings.onbSlide1Sub,
                          ),
                          OnboardingFeatureSlide(
                            icon: CupertinoIcons.drop_fill,
                            accentColor: const Color(0xFF64D2FF),
                            badge: AppStrings.onbSlide2Badge,
                            title: AppStrings.onbSlide2Title,
                            subtitle: AppStrings.onbSlide2Sub,
                          ),
                          OnboardingFeatureSlide(
                            icon: CupertinoIcons.music_note_2,
                            accentColor: const Color(0xFFFF375F),
                            badge: AppStrings.onbSlide3Badge,
                            title: AppStrings.onbSlide3Title,
                            subtitle: AppStrings.onbSlide3Sub,
                          ),
                          OnboardingPermissionsSlide(
                            storageGranted: _storageGranted,
                            musicGranted: _musicGranted,
                            onRequestStorage: _requestStorage,
                            onRequestMusic: _requestMusic,
                            onOpenAppInfo: _openAppInfo,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        8,
                        AppLayout.screenPaddingH,
                        22,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(totalPages, (index) {
                              final bool active = index == _currentPage;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _pageController.animateToPage(
                                    index,
                                    duration:
                                        const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                    vertical: 8.0,
                                  ),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    height: 6.0,
                                    width: active ? 24.0 : 6.0,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.accent
                                          : AppColors.textSecondary.withValues(
                                              alpha: 0.28,
                                            ),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            height: 52,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 18,
                            ),
                            glowColor: AppColors.accent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (isLastPage) {
                                _finishOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.92, end: 1.0)
                                        .animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: Row(
                                  key: ValueKey<bool>(isLastPage),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          isLastPage
                                              ? AppStrings.enterStudioBtn
                                              : AppStrings.nextBtn,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isLastPage
                                          ? CupertinoIcons.sparkles
                                          : CupertinoIcons.arrow_right,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
