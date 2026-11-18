import 'package:flutter/material.dart';

/// Screen type categorization for responsive design.
enum ScreenType { mobile, tablet, desktop }

/// Utility class for responsive breakpoints and screen adaptations.
class Responsive {
  static const double mobileBreakpoint = 650.0;
  static const double tabletBreakpoint = 1024.0;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= mobileBreakpoint &&
      screenWidth(context) < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint;

  static bool isWide(BuildContext context) =>
      screenWidth(context) >= mobileBreakpoint;

  static ScreenType screenType(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) return ScreenType.mobile;
    if (width < tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  /// Calculates dynamic grid columns based on available width
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tabletPortrait = 3,
    int tabletLandscape = 4,
    int desktop = 5,
  }) {
    final width = screenWidth(context);
    if (width < 500) return mobile;
    if (width < 750) return tabletPortrait;
    if (width < 1100) return tabletLandscape;
    return desktop;
  }

  /// Responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 600) return 12.0;
    if (width < 1000) return 20.0;
    return 32.0;
  }
}

/// A builder widget that selects an appropriate layout for mobile, tablet, or desktop.
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
