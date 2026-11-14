import 'package:flutter/material.dart';

export 'l10n/app_strings.dart';
export 'navigation/glass_transition_route.dart';
export 'theme/app_colors.dart';
export 'theme/app_slider_theme.dart';

class AppLayout {
  const AppLayout._();

  static const double screenPaddingH = 20.0;
  static const double cardGap = 14.0;
  static const double dividerThickness = 0.5;
  static const double minTouchTarget = 44.0;

  static double bottomDockPadding(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return 124.0 + bottomInset;
  }

  static EdgeInsets scrollableTabPadding(
      BuildContext context, {
        double top = 4.0,
        bool hasBottomDock = true,
      }) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      screenPaddingH,
      top,
      screenPaddingH,
      hasBottomDock ? bottomDockPadding(context) : (20.0 + bottomInset),
    );
  }
}