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
  }

  @override
  Widget build(BuildContext context) {
    // Al unificar el widget, el setState también repintará el título del AppScaffold
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
    List<String> roles = ['SELLER', 'ADMIN'];

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
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.products,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Historial de pagos',
        'subtitle': 'Consulta el historial de pagos recibidos y pendientes.',
        'icon': Icons.savings_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.paymentsHistory,
        'role': ['SELLER', 'ADMIN'],
      },
      {
        'title': 'Pago a Empleados',
        'subtitle': 'Paga a tus empleados un monto libre',
        'icon': Icons.payment,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.employeePayments,
        'role': ['ADMIN'],
      },
      {
        'title': 'Pago de Comisiones',
        'subtitle': 'Paga las comisiones pendientes a tus vendedores.',
        'icon': Icons.payments_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.commissionPayments,
        'role': ['ADMIN'],
      },
      {
        'title': 'Movimientos',
        'subtitle': 'Consulta todos los movimientos de dinero ordenados del más reciente al más antiguo.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.transactions,
        'role': ['ADMIN'],
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      // 💡 Cambiamos "widget.business" por "business" (tu estado local actualizado)
                      child: business.image == null
                          ? Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.storefront_rounded, size: 40, color: AppColors.kPrimaryColor),
                            )
                          : SizedBox(
                              width: 80,
                              height: 80,
                              child: AdaptedFile.network(business.image!.url, blurHash: business.image!.blurHash).getWidget(width: 80, height: 80),
                            ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(business.name, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                          const Gap(6),
                          Builder(
                            builder: (context) {
                              if (business.description == null) {
                                return Container();
                              }
                              return AppText(business.description!, color: AppColors.kNeutral700, maxLines: 3, overflow: TextOverflow.ellipsis);
                            },
                          ),
                          const Gap(8),
                          AppText(business.categoryName, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kSecondaryColor),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final updatedBusiness = await NavigationService.navigateTo(context, Routes.createOrUpdateBusinessScreen, arguments: business);

                        if (updatedBusiness != null && updatedBusiness is BusinessModel) {
                          setState(() {
                            business = updatedBusiness;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, size: 20),
                          const Gap(8),
                          AppText(AppTexts.editBusinessButton, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kNeutral100),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(20),

          // Grid Options
          AppText(AppTexts.businessOptionsTitle, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
          const Gap(12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
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

              return Builder(
                builder: (context) {
                  // Hide option if user does not have the required role
                  if (!hasRole) {
                    return const SizedBox.shrink();
                  }

                  return AppCard(
                    backgroundColor: !isEnabled ? AppColors.kNeutral200 : null,
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      if (isEnabled) {
                        if (route == Routes.products ||
                            route == Routes.sales ||
                            route == Routes.transactions ||
                            route == Routes.commissionPayments ||
                            route == Routes.employeePayments) {
                          NavigationService.navigateTo(context, route, arguments: business.id);
                        } else if (route == Routes.paymentsHistory) {
                          NavigationService.navigateTo(context, route, arguments: {'businessId': business.id, 'isAdmin': roles.contains('ADMIN')});
                        } else {
                          NavigationService.navigateTo(context, route);
                        }
                      } else {
                        SnackbarUtil.showInfo(context, 'El módulo $title estará disponible pronto.');
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppColors.kBackgroundColor, shape: BoxShape.circle),
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
              );
            },
          ),
        ],
      ),
    );
  }
}
