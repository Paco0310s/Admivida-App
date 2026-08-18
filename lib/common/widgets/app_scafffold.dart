import 'package:admivida/common/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/responsive.dart';

class AppScaffold extends StatelessWidget {
  final bool showAppBar;
  final AppBar? appBar;
  final String title;
  final Widget mobile;
  final Widget? mobileWhenIsLoading;
  final Widget tablet;
  final Widget? tabletWhenIsLoading;
  final Widget desktop;
  final Widget? desktopWhenIsLoading;
  final bool isLoading;
  final Widget? floatingActionButton;
  final double marginDesktop;
  final double marginTablet;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    this.showAppBar = true,
    this.appBar,
    required this.title,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    this.mobileWhenIsLoading,
    this.tabletWhenIsLoading,
    this.desktopWhenIsLoading,
    this.isLoading = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.marginDesktop = 140,
    this.marginTablet = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? appBar ?? AppBar(title: AppText(title, color: AppColors.kBackgroundColor)) : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        child: Responsive(
          mobile: mobile,
          mobileWhenIsLoading: mobileWhenIsLoading,
          tablet: tablet,
          tabletWhenIsLoading: tabletWhenIsLoading,
          desktop: desktop,
          desktopWhenIsLoading: desktopWhenIsLoading,
          isLoading: isLoading,
          marginDesktop: marginDesktop,
          marginTablet: marginTablet,
        ),
      ),
    );
  }
}
