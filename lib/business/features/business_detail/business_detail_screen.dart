import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key, required this.business});

  final BusinessModel business;

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  late BusinessModel business;

  @override
  void initState() {
    super.initState();
    business = widget.business;
    DashboardSession.setActiveBusiness(business);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: business.name,
      appBar: AppBar(
        title: AppText(business.name, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: _buildView(crossAxisCount: 2),
      tablet: _buildView(crossAxisCount: 3),
      desktop: _buildView(crossAxisCount: 4),
    );
  }

  Widget _buildView({required int crossAxisCount}) {
    final bool isDesktop = crossAxisCount >= 3;
    final List<String> roles = ['SELLER', 'ADMIN'];

    final List<Map<String, dynamic>> options = [
      {
        'title': AppTexts.businessSales,
        'subtitle': AppTexts.businessSalesDescription,
        'icon': Icons.point_of_sale_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.sales,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': AppTexts.businessProducts,
        'subtitle': AppTexts.businessProductsDescription,
        'icon': Icons.inventory_2_rounded,
        'color': AppColors.kSecondaryColor,
        'isEnabled': true,
        'route': Routes.products,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Clientes',
        'subtitle': 'Consulta el directorio de clientes y sus saldos pendientes.',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF0284C7),
        'isEnabled': true,
        'route': Routes.clients,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Movimientos',
        'subtitle': 'Consulta todos los ingresos, egresos y balances de cuentas.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kSuccess,
        'isEnabled': true,
        'route': Routes.transactions,
        'role': ['ADMIN'],
      },
      {
        'title': 'Historial de pagos',
        'subtitle': 'Consulta el historial de pagos recibidos y pendientes.',
        'icon': Icons.savings_rounded,
        'color': const Color(0xFF7C3AED),
        'isEnabled': true,
        'route': Routes.paymentsHistory,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Pago de Comisiones',
        'subtitle': 'Paga las comisiones pendientes a tus vendedores.',
        'icon': Icons.payments_rounded,
        'color': AppColors.kWarning,
        'isEnabled': true,
        'route': Routes.commissionPayments,
        'role': ['ADMIN'],
      },
      {
        'title': 'Pago a Empleados',
        'subtitle': 'Paga a tus empleados un monto libre.',
        'icon': Icons.payment_rounded,
        'color': const Color(0xFFEA580C),
        'isEnabled': true,
        'route': Routes.employeePayments,
        'role': ['ADMIN'],
      },
      {
        'title': 'Colaboradores',
        'subtitle': 'Busca usuarios, asigna roles y configura sus comisiones.',
        'icon': Icons.manage_accounts_rounded,
        'color': const Color(0xFF475569),
        'isEnabled': true,
        'route': Routes.userBusinesses,
        'role': ['ADMIN'],
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF163542),
                  AppColors.kPrimaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: business.image == null
                          ? Container(
                              width: isDesktop ? 72 : 60,
                              height: isDesktop ? 72 : 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.storefront_rounded, size: 34, color: Colors.white),
                            )
                          : SizedBox(
                              width: isDesktop ? 72 : 60,
                              height: isDesktop ? 72 : 60,
                              child: AdaptedFile.network(
                                business.image!.url,
                                blurHash: business.image!.blurHash,
                              ).getWidget(width: isDesktop ? 72 : 60, height: isDesktop ? 72 : 60),
                            ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AppText(
                                  business.name,
                                  fontSize: isDesktop ? 22 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Gap(10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: AppText(
                                  business.categoryName,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kPrimary100,
                                ),
                              ),
                            ],
                          ),
                          if (business.description != null && business.description!.trim().isNotEmpty) ...[
                            const Gap(4),
                            AppText(
                              business.description!,
                              color: const Color(0xD9FFFFFF),
                              fontSize: 13,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const Gap(12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final updatedBusiness = await NavigationService.navigateTo(
                            context,
                            Routes.createOrUpdateBusinessScreen,
                            arguments: business,
                          );

                          if (updatedBusiness != null && updatedBusiness is BusinessModel) {
                            setState(() {
                              business = updatedBusiness;
                            });
                            DashboardSession.setActiveBusiness(updatedBusiness);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 17, color: Colors.white),
                        label: const AppText(
                          AppTexts.editBusinessButton,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(10),
                      ElevatedButton.icon(
                        onPressed: () {
                          NavigationService.navigateTo(
                            context,
                            Routes.addSale,
                            arguments: {'businessId': business.id, 'businessName': business.name},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.kPrimaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text(
                          'Nueva Venta (POS)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ] else ...[
                      IconButton(
                        tooltip: AppTexts.editBusinessButton,
                        onPressed: () async {
                          final updatedBusiness = await NavigationService.navigateTo(
                            context,
                            Routes.createOrUpdateBusinessScreen,
                            arguments: business,
                          );

                          if (updatedBusiness != null && updatedBusiness is BusinessModel) {
                            setState(() {
                              business = updatedBusiness;
                            });
                            DashboardSession.setActiveBusiness(updatedBusiness);
                          }
                        },
                        icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Gap(24),

          // Grid Options
          const AppText(
            AppTexts.businessOptionsTitle,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.kNeutral900,
          ),
          const Gap(12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isDesktop ? 1.5 : 1.18,
            ),
            itemBuilder: (context, index) {
              final option = options[index];
              final icon = option['icon'] as IconData;
              final title = option['title'] as String;
              final subtitle = option['subtitle'] as String;
              final color = option['color'] as Color;
              final isEnabled = option['isEnabled'] as bool;
              final route = option['route'] as String;
              final roleRequired = option['role'] as List<String>;
              final hasRole = roles.any((role) => roleRequired.contains(role));

              if (!hasRole) {
                return const SizedBox.shrink();
              }

              return AppCard(
                margin: EdgeInsets.zero,
                backgroundColor: !isEnabled ? AppColors.kNeutral200 : Colors.white,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  if (isEnabled) {
                    DashboardSession.navigateToBusinessRoute(context, route, business);
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
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.kNeutral400,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          title,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kNeutral900,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
