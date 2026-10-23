import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final bool showAppBar;
  final bool showDashboardShell;
  final AppBar? appBar;
  final String title;
  final Widget mobile;
  final Widget? mobileWhenIsLoading;
  final Widget? tablet;
  final Widget? tabletWhenIsLoading;
  final Widget? desktop;
  final Widget? desktopWhenIsLoading;
  final bool isLoading;
  final Widget? floatingActionButton;
  final double marginDesktop;
  final double marginTablet;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    this.showAppBar = true,
    this.showDashboardShell = true,
    this.appBar,
    required this.title,
    required this.mobile,
    this.tablet,
    this.desktop,
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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isPublicOrAuth = !showAppBar || !showDashboardShell || DashboardSession.isAuthOrPublicRoute(currentRoute);
    final bool isDashboardDesktop = !isPublicOrAuth && Responsive.isDashboard(context);

    final responsiveBody = Responsive(
      mobile: mobile,
      mobileWhenIsLoading: mobileWhenIsLoading,
      tablet: tablet ?? mobile,
      tabletWhenIsLoading: tabletWhenIsLoading,
      desktop: desktop ?? tablet ?? mobile,
      desktopWhenIsLoading: desktopWhenIsLoading,
      isLoading: isLoading,
      marginDesktop: marginDesktop,
      marginTablet: marginTablet,
    );

    // 💻 Desktop / Web Dashboard Layout (Windows & Web)
    if (isDashboardDesktop) {
      return Scaffold(
        backgroundColor: AppColors.kBackgroundColor,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSidebar(currentRoute: currentRoute),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardTopBar(
                    title: title,
                    currentRoute: currentRoute,
                    originalAppBar: appBar,
                  ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: responsiveBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 📱 Mobile (Android) & Public/Auth Layout — Clean native mobile flow
    return Scaffold(
      backgroundColor: AppColors.kBackgroundColor,
      appBar: showAppBar
          ? (appBar != null
              ? _ensureMobileAppBarTheme(appBar!)
              : AppBar(
                  title: AppText(title, color: AppColors.kBackgroundColor),
                  backgroundColor: AppColors.kPrimaryColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actionsIconTheme: const IconThemeData(color: Colors.white),
                ))
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(child: responsiveBody),
    );
  }

  AppBar _ensureMobileAppBarTheme(AppBar bar) {
    if (bar.backgroundColor == Colors.transparent) {
      return bar;
    }

    return AppBar(
      key: bar.key,
      leading: bar.leading,
      automaticallyImplyLeading: bar.automaticallyImplyLeading,
      title: bar.title,
      actions: bar.actions,
      flexibleSpace: bar.flexibleSpace,
      bottom: bar.bottom,
      elevation: bar.elevation,
      scrolledUnderElevation: bar.scrolledUnderElevation,
      notificationPredicate: bar.notificationPredicate,
      shadowColor: bar.shadowColor,
      surfaceTintColor: bar.surfaceTintColor,
      shape: bar.shape,
      backgroundColor: bar.backgroundColor ?? AppColors.kPrimaryColor,
      foregroundColor: bar.foregroundColor ?? Colors.white,
      iconTheme: bar.iconTheme ?? const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      primary: bar.primary,
      centerTitle: bar.centerTitle,
      excludeHeaderSemantics: bar.excludeHeaderSemantics,
      titleSpacing: bar.titleSpacing,
      toolbarOpacity: bar.toolbarOpacity,
      bottomOpacity: bar.bottomOpacity,
      toolbarHeight: bar.toolbarHeight,
      leadingWidth: bar.leadingWidth,
      toolbarTextStyle: bar.toolbarTextStyle,
      titleTextStyle: bar.titleTextStyle,
      systemOverlayStyle: bar.systemOverlayStyle,
      forceMaterialTransparency: bar.forceMaterialTransparency,
      clipBehavior: bar.clipBehavior,
    );
  }
}
