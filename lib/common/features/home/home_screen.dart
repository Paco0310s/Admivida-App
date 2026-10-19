import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_config.dart';
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
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppTexts.home,
      appBar: AppBar(
        title: const AppText(AppTexts.home, color: AppColors.kPrimaryColor),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: AppTexts.logout,
            onPressed: () async {
              DashboardSession.clear();
              await StorageService.clear();
              if (!context.mounted) return;
              NavigationService.replaceUntil(context, Routes.signIn);
            },
            icon: const Icon(Icons.logout, color: AppColors.kPrimaryColor),
          ),
        ],
      ),
      mobile: const BusinessDetailView(crossAxisCount: 2),
      tablet: const BusinessDetailView(crossAxisCount: 3),
      desktop: const BusinessDetailView(crossAxisCount: 4),
    );
  }
}

class BusinessDetailView extends StatelessWidget {
  final int crossAxisCount;
  const BusinessDetailView({super.key, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = crossAxisCount >= 3;

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Negocios',
        'subtitle': 'Punto de venta, inventario, clientes y finanzas',
        'icon': Icons.storefront_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.businesses,
      },
      {
        'title': 'Control Personal',
        'subtitle': 'Gastos compartidos y billetera personal',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kSecondaryColor,
        'isEnabled': false,
        'route': '/personal_dashboard',
      },
      {
        'title': 'Portal Clientes',
        'subtitle': 'Compras, consultas y tickets digitales',
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 28 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sleek Welcome Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 20,
                    vertical: isDesktop ? 24 : 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF163542),
                        AppColors.kPrimaryColor,
                        AppColors.kSecondaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AppImage(
                          AdaptedFile.asset(AppAssets.icon),
                          height: isDesktop ? 52 : 44,
                          width: isDesktop ? 52 : 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Gap(18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Bienvenido a ${AppTexts.appName}',
                              fontSize: isDesktop ? 22 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            const Gap(4),
                            const AppText(
                              'Selecciona un módulo para comenzar a administrar tus operaciones.',
                              fontSize: 13,
                              color: Color(0xD9FFFFFF),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        const Gap(16),
                        ElevatedButton.icon(
                          onPressed: () => NavigationService.navigateTo(context, Routes.businesses),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.kPrimaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.storefront_rounded, size: 18),
                          label: const Text(
                            'Ir a Mis Empresas',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(24),
                const AppText(
                  AppTexts.modules,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kNeutral900,
                ),
                const Gap(12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isDesktop ? 1.45 : 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final option = modules[index];
                    final icon = option['icon'] as IconData;
                    final title = option['title'] as String;
                    final subtitle = option['subtitle'] as String;
                    final color = option['color'] as Color;
                    final isEnabled = option['isEnabled'] as bool;

                    return AppCard(
                      margin: EdgeInsets.zero,
                      backgroundColor: isEnabled ? Colors.white : AppColors.kNeutral50,
                      borderColor: isEnabled ? AppColors.kPrimary100 : AppColors.kNeutral200,
                      padding: const EdgeInsets.all(18),
                      onTap: () {
                        if (isEnabled) {
                          NavigationService.navigateTo(context, option['route']);
                        } else {
                          SnackbarUtil.showInfo(context, 'El módulo $title estará disponible pronto.');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isEnabled
                                      ? color.withValues(alpha: 0.12)
                                      : AppColors.kNeutral200.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  icon,
                                  color: isEnabled ? color : AppColors.kNeutral500,
                                  size: 24,
                                ),
                              ),
                              if (!isEnabled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.kNeutral200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const AppText(
                                    'Próximamente',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kNeutral600,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: AppColors.kPrimaryColor,
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                title,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isEnabled ? AppColors.kNeutral900 : AppColors.kNeutral600,
                              ),
                              const Gap(4),
                              AppText(
                                subtitle,
                                fontSize: 12,
                                color: AppColors.kNeutral600,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  'Desarrollado por Francisco Sotelo',
                  fontSize: 12,
                  color: AppColors.kNeutral500,
                  fontWeight: FontWeight.w600,
                ),
                const Gap(2),
                AppText(
                  'Versión ${AppConfig.appVersionName} (${AppConfig.appVersionCode})',
                  fontSize: 11,
                  color: AppColors.kNeutral400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
