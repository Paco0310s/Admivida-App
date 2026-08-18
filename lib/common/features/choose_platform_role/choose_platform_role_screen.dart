import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ChoosePlatformRoleScreen extends ConsumerWidget {
  const ChoosePlatformRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showAppBar: false,
      appBar: AppBar(
        title: AppText(AppTexts.chooseRole, color: AppColors.kTertiaryColor),
        backgroundColor: AppColors.kBackgroundColor,
      ),
      title: AppTexts.chooseRole,
      mobile: ChoosePlatformMobile(context),
      tablet: ChoosePlatformTablet(context),
      desktop: ChoosePlatformDesktop(context),
    );
  }
}

class ChoosePlatform extends StatelessWidget {
  const ChoosePlatform({super.key, required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Builder(
          builder: (context) {
            if (Responsive.isDesktop(context)) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                AppImage(AdaptedFile.asset(AppAssets.logo), height: 200, width: double.infinity, fit: BoxFit.fitWidth),
                Gap(20),
              ],
            );
          },
        ),
        AppText(AppTexts.chooseAnRole, color: AppColors.kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 22),
        Gap(30),
        ListView.separated(
          shrinkWrap: true,
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            return AppButton(
              text: role,
              onPressed: () {
                StorageService.setString(AppConfig.currentPlatformRoleKey, role);
                NavigationService.replaceWith(context, Routes.home);
              },
            );
          },
          separatorBuilder: (context, index) {
            return const SizedBox(height: 15);
          },
        ),
      ],
    );
  }
}

class ChoosePlatformMobile extends StatelessWidget {
  final BuildContext context;

  const ChoosePlatformMobile(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: ChoosePlatformWidget(ponderContainers: 0, ponderForm: 100));
  }
}

class ChoosePlatformTablet extends StatelessWidget {
  final BuildContext context;

  const ChoosePlatformTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Flexible(flex: 100, child: ChoosePlatformWidget(ponderContainers: 10, ponderForm: 90))],
      ),
    );
  }
}

class ChoosePlatformDesktop extends StatelessWidget {
  final BuildContext context;

  const ChoosePlatformDesktop(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(flex: 45, child: ChoosePlatformImage()),
        Flexible(flex: 55, child: ChoosePlatformWidget()),
      ],
    );
  }
}

class ChoosePlatformImage extends StatelessWidget {
  const ChoosePlatformImage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImage(AdaptedFile.local(AppAssets.logo), height: double.infinity, width: double.infinity, fit: BoxFit.contain);
  }
}

class ChoosePlatformWidget extends StatelessWidget {
  final int ponderContainers;
  final int ponderForm;

  const ChoosePlatformWidget({super.key, this.ponderContainers = 20, this.ponderForm = 60});

  @override
  Widget build(BuildContext context) {
    String rolesString = StorageService.getString(AppConfig.rolesKey) ?? '';
    List<String> roles = rolesString.split(',');

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(
              flex: ponderForm,
              child: ChoosePlatform(roles: roles),
            ),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}
