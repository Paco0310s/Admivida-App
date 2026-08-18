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

  static final double mobileMaxWidth = 650;
  static final double tabletMaxWidth = 1100;

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

  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width < tabletMaxWidth && MediaQuery.of(context).size.width >= mobileMaxWidth;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletMaxWidth;

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
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: child,
      );
    } else if (Responsive.isTablet(context)) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: child,
      );
    } else {
      return child;
    }
  }
}
