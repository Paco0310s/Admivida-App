import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppTexts.home,
      appBar: AppBar(
        title: AppText(AppTexts.home, color: AppColors.kPrimaryColor),
        backgroundColor: Colors.transparent,
        actions: [
          // Log out
          IconButton(
            onPressed: () {
              StorageService.clear();
              NavigationService.replaceUntil(context, Routes.signIn);
            },
            icon: const Icon(Icons.logout, color: AppColors.kPrimaryColor),
          ),
        ],
      ),
      mobile: BusinessDetailView(crossAxisCount: 2),
      tablet: BusinessDetailView(crossAxisCount: 3),
      desktop: BusinessDetailView(crossAxisCount: 4),
    );
  }
}

class BusinessDetailView extends StatelessWidget {
  final int crossAxisCount;
  const BusinessDetailView({super.key, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Negocios',
        'subtitle': 'Gestiona tus negocios',
        'icon': Icons.storefront_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.businesses,
      },
      {
        'title': 'Control Personal',
        'subtitle': 'Gastos compartidos y billetera',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kSecondaryColor,
        'isEnabled': false,
        'route': '/personal_dashboard',
      },
      {
        'title': 'Portal Clientes',
        'subtitle': 'Compras, consultas y tickets',
        'icon': Icons.people_alt_rounded,
        'color': AppColors.kTertiaryColor,
        'isEnabled': false,
        'route': '/clients_dashboard',
      },
      {
        'title': 'Control Escolar',
        'subtitle': 'Asistencias de alumnos y agenda',
        'icon': Icons.auto_stories_rounded,
        'color': AppColors.kWarning,
        'isEnabled': false,
        'route': '/school_dashboard',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(AdaptedFile.asset(AppAssets.logo), height: MediaQuery.of(context).size.width * 0.4, width: double.infinity, fit: BoxFit.cover),
          AppText(AppTexts.modules, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
          const Gap(12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final option = modules[index];
              final icon = option['icon'] as IconData;
              final title = option['title'] as String;
              final subtitle = option['subtitle'] as String;
              final color = option['color'] as Color;
              final isEnabled = option['isEnabled'] as bool;

              return AppCard(
                backgroundColor: !isEnabled ? AppColors.kNeutral200 : null,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  if (isEnabled) {
                    NavigationService.navigateTo(context, option['route']);
                  } else {
                    SnackbarUtil.showInfo(context, 'El módulo $title estará disponible pronto.');
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.kBackgroundColor, shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Gap(12),
                    AppText(title, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                    const Gap(4),
                    Flexible(
                      child: AppText(
                        subtitle,
                        fontSize: 12,
                        color: AppColors.kNeutral700,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
