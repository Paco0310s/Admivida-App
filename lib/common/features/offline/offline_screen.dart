import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/splash/splash_provider.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(title: AppTexts.offline, mobile: OfflineView(), tablet: OfflineView(), desktop: OfflineView(), showAppBar: false);
  }
}

class OfflineView extends ConsumerWidget {
  const OfflineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(splashLoadingProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage(AdaptedFile.asset(AppAssets.logo), height: 200, width: 200, fit: BoxFit.contain),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Text(
              AppTexts.youAreOffline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(
              AppTexts.withoutConnection,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 48),
            AppButton(
              leadingWidget: Icon(Icons.refresh_rounded, size: 20, color: AppColors.kWhiteColor),
              text: AppTexts.retry,
              onPressed: () async {
                ref.read(splashLoadingProvider.notifier).setLoading(true);
                await ref.read(splashStartupLogicProvider(context).future);
                ref.read(splashLoadingProvider.notifier).setLoading(false);
              },
              width: 200,
              height: 50,
              backgroundColor: AppColors.kPrimaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
