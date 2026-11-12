import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool homescreenClock;
  final bool use24Hour;
  final bool hasSeenOnboarding;
  final String themeMode; // 'dark', 'amoled', 'light'
  final bool musicModeEnabled;
  final String musicTargetPackage;
  final String languageCode; // 'es', 'en'

  const AppSettings({
    this.homescreenClock = false,
    this.use24Hour = true,
    this.hasSeenOnboarding = false,
    this.themeMode = 'dark',
    this.musicModeEnabled = true,
    this.musicTargetPackage = 'all',
    this.languageCode = 'es',
  });

  AppSettings copyWith({
    bool? homescreenClock,
    bool? use24Hour,
    bool? hasSeenOnboarding,
    String? themeMode,
    bool? musicModeEnabled,
    String? musicTargetPackage,
    String? languageCode,
  }) {
    return AppSettings(
      homescreenClock: homescreenClock ?? this.homescreenClock,
      use24Hour: use24Hour ?? this.use24Hour,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      themeMode: themeMode ?? this.themeMode,
      musicModeEnabled: musicModeEnabled ?? this.musicModeEnabled,
      musicTargetPackage: musicTargetPackage ?? this.musicTargetPackage,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      homescreenClock: prefs.getBool('homescreenClock') ?? false,
      use24Hour: prefs.getBool('use24Hour') ?? true,
      hasSeenOnboarding: prefs.getBool('hasSeenOnboarding') ?? false,
      themeMode: prefs.getString('themeMode') ?? 'dark',
      musicModeEnabled: prefs.getBool('musicModeEnabled') ?? true,
      musicTargetPackage: prefs.getString('musicTargetPackage') ?? 'all',
      languageCode: prefs.getString('appLanguage') ?? 'es',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('homescreenClock', homescreenClock);
    await prefs.setBool('use24Hour', use24Hour);
    await prefs.setBool('hasSeenOnboarding', hasSeenOnboarding);
    await prefs.setString('themeMode', themeMode);
    await prefs.setBool('musicModeEnabled', musicModeEnabled);
    await prefs.setString('musicTargetPackage', musicTargetPackage);
    await prefs.setString('appLanguage', languageCode);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.homescreenClock == homescreenClock &&
        other.use24Hour == use24Hour &&
        other.hasSeenOnboarding == hasSeenOnboarding &&
        other.themeMode == themeMode &&
        other.musicModeEnabled == musicModeEnabled &&
        other.musicTargetPackage == musicTargetPackage &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode => Object.hash(
    homescreenClock,
    use24Hour,
    hasSeenOnboarding,
    themeMode,
    musicModeEnabled,
    musicTargetPackage,
    languageCode,
  );
}