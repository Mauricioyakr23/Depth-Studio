import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/core.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/notifiers/app_notifiers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiquidGlassWidgets.initialize(
    warmUpMode: GlassWarmUpMode.auto,
    enablePerformanceMonitor: false,
  );

  final settings = await AppSettings.load();
  appLanguageNotifier.value = settings.languageCode;
  appThemeNotifier.value = settings.themeMode;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      adaptiveQuality: true,
      theme: GlassThemeData(
        light: GlassThemeVariant(
          settings: const GlassThemeSettings(
            thickness: 30,
            blur: 10,
          ),
          quality: GlassQuality.standard,
          glowColors: const GlassGlowColors(
            primary: Color(0xFF0A84FF),
            glowBlurRadius: 14,
            glowOpacity: 0.75,
          ),
        ),
        dark: GlassThemeVariant(
          settings: const GlassThemeSettings(
            thickness: 38,
            blur: 14,
          ),
          quality: GlassQuality.standard,
          glowColors: const GlassGlowColors(
            primary: Color(0xFF0A84FF),
            glowBlurRadius: 16,
            glowOpacity: 0.85,
          ),
        ),
      ),
      child: DepthWallpaperApp(hasSeenOnboarding: settings.hasSeenOnboarding),
    ),
  );
}

class DepthWallpaperApp extends StatefulWidget {
  final bool hasSeenOnboarding;

  const DepthWallpaperApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  State<DepthWallpaperApp> createState() => _DepthWallpaperAppState();
}

class _DepthWallpaperAppState extends State<DepthWallpaperApp> {
  late bool _hasSeenOnboarding = widget.hasSeenOnboarding;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        final bool isLight = themeMode == 'light';

        SystemChrome.setSystemUIOverlayStyle(
          isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        );

        return MaterialApp(
          title: 'Depth Studio',
          debugShowCheckedModeBanner: false,
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) => Material(
            type: MaterialType.transparency,
            child: child ?? const SizedBox.shrink(),
          ),
          home: _hasSeenOnboarding
              ? const HomeScreen()
              : OnboardingScreen(
            onComplete: () {
              if (mounted) {
                setState(() => _hasSeenOnboarding = true);
              }
            },
          ),
        );
      },
    );
  }
}