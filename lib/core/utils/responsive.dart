import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1000;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1000;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Returns the ideal board size given available space.
  static double boardSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final safeWidth = size.width - padding.horizontal;
    final safeHeight = size.height - padding.vertical - 80;

    if (isDesktop(context)) {
      // Desktop: board is hero, centered, maxSize = min(screenHeight * 0.85, safeWidth - 360)
      final maxSize = (safeHeight * 0.85).clamp(360.0, safeWidth - 360);
      return maxSize.clamp(420.0, 720.0);
    } else if (isTablet(context)) {
      if (isPortrait(context)) {
        return (safeWidth * 0.9).clamp(320.0, 560.0);
      } else {
        return (safeHeight * 0.82).clamp(300.0, 540.0);
      }
    } else {
      // Mobile
      if (isPortrait(context)) {
        return (safeWidth - 24.0).clamp(240.0, 500.0);
      } else {
        return (safeHeight * 0.9).clamp(200.0, 380.0);
      }
    }
  }

  static bool isStacked(BuildContext context) =>
      isMobile(context) && isPortrait(context);

  static double sidePanelWidth(BuildContext context) {
    if (isDesktop(context)) return 320;
    if (isTablet(context)) return 240;
    return 200;
  }
}
