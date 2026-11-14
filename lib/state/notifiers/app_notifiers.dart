import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/app_settings.dart';

final ValueNotifier<String> appLanguageNotifier = ValueNotifier<String>('es');

final ValueNotifier<String> appThemeNotifier = ValueNotifier<String>('dark');

final ValueNotifier<AppSettings> appSettingsNotifier =
ValueNotifier<AppSettings>(const AppSettings());

class MinuteClock {
  MinuteClock._();

  static final ValueNotifier<DateTime> now =
  ValueNotifier<DateTime>(DateTime.now());
  static Timer? _syncTimer;
  static Timer? _periodicTimer;

  static void ensureRunning() {
    if (_syncTimer != null || _periodicTimer != null) return;
    final DateTime current = DateTime.now();
    final int msUntilNextMinute =
    (((60 - current.second) * 1000) - current.millisecond + 50)
        .clamp(50, 60050);

    _syncTimer = Timer(Duration(milliseconds: msUntilNextMinute), () {
      _syncTimer = null;
      now.value = DateTime.now();
      _periodicTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        now.value = DateTime.now();
      });
    });
  }

  static void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}