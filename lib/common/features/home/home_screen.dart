import 'package:admivida/common/services/whats_new_service.dart';
import 'package:admivida/common/widgets/whats_new_bell_button.dart';
import 'package:admivida/common/services/external_link_service.dart';

import 'package:admivida/common/widgets/floating_whatsapp_button.dart';

import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/sign_in/sign_in_service.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WhatsNewService.checkAndShowOnFirstLaunch(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppTexts.home,
      floatingActionButton: const FloatingWhatsAppButton(heroTag: 'home_whatsapp_fab'),
      appBar: AppBar(
        title: const AppText(AppTexts.home, color: AppColors.kPrimaryColor),
        backgroundColor: Colors.transparent,
        actions: [
          const WhatsNewBellButton(),
          IconButton(
            tooltip: 'Descargar app (Windows y Android)',
            onPressed: () => ExternalLinkService.openAdmividaWeb(),
            icon: const Icon(Icons.public_rounded, color: AppColors.kPrimaryColor),
          ),
          IconButton(
            tooltip: AppTexts.logout,
            onPressed: () async {
              await SignInService.signOut();
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = crossAxisCount >= 3;

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Negocios',
        'subtitle': 'Punto de venta, inventario, clientes, cortes de caja y finanzas.',
        'icon': Icons.storefront_rounded,
        'color': AppColors.kPrimaryColor,
        'badge': 'Principal',
        'isEnabled': true,
        'route': Routes.businesses,
      },
      {
        'title': 'Control Personal',
        'subtitle': 'Efectivo, cuentas personales, ingresos y gastos diarios.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kSecondaryColor,
        'badge': 'Finanzas',
        'isEnabled': true,
        'route': Routes.personalDashboard,
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
                // Sleek Welcome Banner with subtle ambient geometry
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF122C38), AppColors.kPrimaryColor, AppColors.kSecondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -40,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 80,
                        bottom: -50,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 20, vertical: isDesktop ? 26 : 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AppImage(
                                AdaptedFile.asset(AppAssets.icon),
                                height: isDesktop ? 50 : 42,
                                width: isDesktop ? 50 : 42,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Gap(18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: AppText(
                                      '${_getGreeting()} • Panel Inteligente',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.kPrimary100,
                                    ),
                                  ),
                                  const Gap(6),
                                  AppText(
                                    'Bienvenido a ${AppTexts.appName}',
                                    fontSize: isDesktop ? 23 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  const Gap(4),
                                  const AppText(
                                    'Todo tu ecosistema comercial y personal en un solo lugar, rápido y claro.',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                    ],
                  ),
                ),
                const Gap(28),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.kSecondaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(8),
                    const AppText(
                      AppTexts.modules,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kNeutral900,
                    ),
                  ],
                ),
                const Gap(14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.45 : 1.12,
                  ),
                  itemBuilder: (context, index) {
                    final option = modules[index];
                    final icon = option['icon'] as IconData;
                    final title = option['title'] as String;
                    final subtitle = option['subtitle'] as String;
                    final color = option['color'] as Color;
                    final badge = option['badge'] as String?;
                    final isEnabled = option['isEnabled'] as bool;

                    if (!isEnabled) {
                      return const SizedBox.shrink();
                    }
                    return AppCard(
                      margin: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      borderColor: AppColors.kNeutral200,
                      padding: const EdgeInsets.all(20),
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
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      color.withValues(alpha: 0.16),
                                      color.withValues(alpha: 0.07),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (badge != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: AppText(
                                        badge,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                    const Gap(6),
                                  ],
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.kNeutral100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 15,
                                      color: AppColors.kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                title,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kNeutral900,
                              ),
                              const Gap(4),
                              AppText(
                                subtitle,
                                fontSize: 12,
                                color: AppColors.kNeutral500,
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
                // Enlace al portafolio de Francisco Sotelo
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => ExternalLinkService.openPortfolio(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.code_rounded, size: 14, color: AppColors.kPrimaryColor),
                        Gap(4),
                        AppText(
                          'Desarrollado por Francisco Sotelo',
                          fontSize: 12,
                          color: AppColors.kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        Gap(2),
                        Icon(Icons.arrow_outward_rounded, size: 12, color: AppColors.kPrimaryColor),
                      ],
                    ),
                  ),
                ),
                const Gap(6),
                // Versión actual y enlace a la web de descargas
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => ExternalLinkService.openAdmividaWeb(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.kNeutral100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.kNeutral200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, size: 13, color: AppColors.kNeutral600),
                          const Gap(4),
                          AppText(
                            'v${AppConfig.appVersionName} "${AppConfig.appVersionCodename}" • Descargar para Windows o Android',
                            fontSize: 11,
                            color: AppColors.kNeutral700,
                            fontWeight: FontWeight.w500,
                          ),
                          const Gap(3),
                          const Icon(Icons.open_in_new_rounded, size: 11, color: AppColors.kNeutral500),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
