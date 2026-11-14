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
        GlassTransitionRoute(child: const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const int totalPages = 2;
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
                          const OnboardingOverviewSlide(),
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
                        20,
                      ),
                      child: GlassContainer.card(
                        surfaceStyle: GlassSurfaceStyle.solid,
                        width: double.infinity,
                        shape: const LiquidRoundedSuperellipse(borderRadius: 34),
                        padding: const EdgeInsets.fromLTRB(22, 10, 10, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                      vertical: 10.0,
                                    ),
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      height: 7.0,
                                      width: active ? 26.0 : 7.0,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.accent
                                            : AppColors.textSecondary
                                            .withValues(alpha: 0.30),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 14,
                              ),
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(26),
                              minimumSize: Size.zero,
                              onPressed: () {
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
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: Row(
                                  key: ValueKey<bool>(isLastPage),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isLastPage
                                          ? AppStrings.enterStudioBtn
                                          : AppStrings.nextBtn,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (!isLastPage) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        CupertinoIcons.arrow_right,
                                        color: CupertinoColors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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