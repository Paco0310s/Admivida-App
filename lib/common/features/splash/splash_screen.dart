import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/features/splash/splash_provider.dart';
import 'package:admivida/common/widgets/app_loading_widget.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashStartupLogicProvider(context));
    });

    return AppScaffold(
      showAppBar: false,
      title: AppTexts.appName,
      mobile: SplashView(),
      tablet: SplashView(),
      desktop: SplashView(),
      marginDesktop: 0,
      marginTablet: 0,
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: double.infinity, height: 200, child: Image.asset(AppAssets.logo)),
        const SizedBox(height: 16),
        const AppLoadingWidget(),
      ],
    );
  }
}
