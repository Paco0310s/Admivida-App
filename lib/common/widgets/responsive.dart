import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? mobileWhenIsLoading;
  final Widget tablet;
  final Widget? tabletWhenIsLoading;
  final Widget desktop;
  final Widget? desktopWhenIsLoading;
  final bool isLoading;
  final double marginDesktop;
  final double marginTablet;

  static const double mobileMaxWidth = 650;
  static const double tabletMaxWidth = 1024;
  static const double dashboardBreakpoint = 900;

  const Responsive({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required this.marginDesktop,
    required this.marginTablet,
    this.mobileWhenIsLoading,
    this.tabletWhenIsLoading,
    this.desktopWhenIsLoading,
    this.isLoading = false,
  });

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletMaxWidth && MediaQuery.of(context).size.width >= mobileMaxWidth;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletMaxWidth;

  /// True when the viewport is wide enough for the persistent Web/Desktop sidebar layout.
  static bool isDashboard(BuildContext context) => MediaQuery.of(context).size.width >= dashboardBreakpoint;

  static double getWidth(BuildContext context) => MediaQuery.of(context).size.width;

  static double getHeight(BuildContext context) => MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (isDesktop(context)) {
        return MarginWidget(margin: marginDesktop, child: desktopWhenIsLoading ?? desktop);
      } else if (isTablet(context)) {
        return MarginWidget(margin: marginTablet, child: tabletWhenIsLoading ?? tablet);
      } else {
        return mobileWhenIsLoading ?? mobile;
      }
    }

    if (isDesktop(context)) {
      return MarginWidget(margin: marginDesktop, child: desktop);
    } else if (isTablet(context)) {
      return MarginWidget(margin: marginTablet, child: tablet);
    } else {
      return mobile;
    }
  }
}

class MarginWidget extends StatelessWidget {
  final Widget child;
  final double margin;

  const MarginWidget({super.key, required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      // If a screen uses default large margins (140-160), constrain nicely inside the dashboard viewport
      // instead of squeezing content with huge fixed margins.
      if (margin >= 100) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: child,
            ),
          ),
        );
      }
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: child,
      );
    } else if (Responsive.isTablet(context)) {
      final effectiveMargin = margin >= 40 ? 20.0 : margin;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: effectiveMargin),
        child: child,
      );
    } else {
      return child;
    }
  }
}
