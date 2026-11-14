import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/core.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/custom_font_service.dart';
import 'services/platform_channel.dart';
import 'state/notifiers/app_notifiers.dart';

Future<void> _registerBundledFontsToNative() async {
  const List<({String name, List<String> candidates})> bundledFonts = [
    (
    name: 'Display 1',
    candidates: [
      'assets/fonts/bigclock',
      'assets/fonts/bigclock.ttf',
      'assets/fonts/bigclock.otf'
    ]
    ),
    (
    name: 'Display 2',
    candidates: [
      'assets/fonts/tall1',
      'assets/fonts/tall1.ttf',
      'assets/fonts/tall1.otf'
    ]
    ),
    (
    name: 'Display 3',
    candidates: [
      'assets/fonts/tall3',
      'assets/fonts/tall3.ttf',
      'assets/fonts/tall3.otf'
    ]
    ),
    (
    name: 'Display 4',
    candidates: [
      'assets/fonts/tall4.otf',
      'assets/fonts/tall4',
      'assets/fonts/tall4.ttf'
    ]
    ),
    (
    name: 'Display 5',
    candidates: [
      'assets/fonts/tall5.otf',
      'assets/fonts/tall5',
      'assets/fonts/tall5.ttf'
    ]
    ),
    (
    name: 'Display 6',
    candidates: [
      'assets/fonts/tall7',
      'assets/fonts/tall7.ttf',
      'assets/fonts/tall7.otf'
    ]
    ),
    (
    name: 'Display 7',
    candidates: [
      'assets/fonts/tall8',
      'assets/fonts/tall8.ttf',
      'assets/fonts/tall8.otf'
    ]
    ),
  ];

  for (final font in bundledFonts) {
    for (final assetPath in font.candidates) {
      try {
        final ByteData data = await rootBundle.load(assetPath);
        await PlatformChannel.registerBundledFont(
          font.name,
          data.buffer.asUint8List(),
        );
        break;
      } catch (_) {}
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiquidGlassWidgets.initialize(
    warmUpMode: GlassWarmUpMode.auto,
    enablePerformanceMonitor: false,
  );

  await _registerBundledFontsToNative();
  await CustomFontService.initAndLoadAll();

  final settings = await AppSettings.load();
  appLanguageNotifier.value = settings.languageCode;
  appThemeNotifier.value = settings.themeMode;
  appSettingsNotifier.value = settings;

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
      child: DepthStudioApp(hasSeenOnboarding: settings.hasSeenOnboarding),
    ),
  );
}

class DepthStudioApp extends StatefulWidget {
  final bool hasSeenOnboarding;

  const DepthStudioApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  State<DepthStudioApp> createState() => _DepthStudioAppState();
}

class _DepthStudioAppState extends State<DepthStudioApp> {
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