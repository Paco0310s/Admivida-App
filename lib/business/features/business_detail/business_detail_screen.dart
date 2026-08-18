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

class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({super.key, required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: business.name,
      appBar: AppBar(
        title: AppText(business.name, color: AppColors.kNeutral100),
        iconTheme: IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: BusinessDetailView(business: business, crossAxisCount: 2),
      tablet: BusinessDetailView(business: business, crossAxisCount: 3),
      desktop: BusinessDetailView(business: business, crossAxisCount: 4),
    );
  }
}

class BusinessDetailView extends StatelessWidget {
  const BusinessDetailView({super.key, required this.business, required this.crossAxisCount});

  final BusinessModel business;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
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
        'title': 'Movimientos',
        'subtitle': 'Consulta todos los movimientos de dinero ordenados del más reciente al más antiguo.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.kPrimaryColor,
        'isEnabled': true,
        'route': Routes.transactions,
        'role': ['ADMIN'],
      },
      // {
      //   'title': AppTexts.businessCustomers,
      //   'subtitle': AppTexts.businessCustomersDescription,
      //   'icon': Icons.people_alt_rounded,
      //   'color': AppColors.kPrimaryColor,
      //   'isEnabled': false,
      //   'route': 'business_customers',
      //   'role': ['SELLER', 'ADMIN'],
      // },
      // {
      //   'title': AppTexts.businessReports,
      //   'subtitle': AppTexts.businessReportsDescription,
      //   'icon': Icons.bar_chart_rounded,
      //   'color': AppColors.kPrimaryColor,
      //   'isEnabled': false,
      //   'route': 'business_reports',
      //   'role': ['SELLER', 'ADMIN'],
      // },
      // {
      //   'title': AppTexts.gains,
      //   'subtitle': AppTexts.gainsDescription,
      //   'icon': Icons.monetization_on_rounded,
      //   'color': AppColors.kPrimaryColor,
      //   'isEnabled': false,
      //   'route': 'business_gains',
      //   'role': ['SELLER', 'ADMIN'],
      // },
      // {
      //   'title': AppTexts.profile,
      //   'subtitle': AppTexts.profileDescription,
      //   'icon': Icons.person_rounded,
      //   'color': AppColors.kPrimaryColor,
      //   'isEnabled': false,
      //   'route': 'business_profile',
      //   'role': ['SELLER', 'ADMIN'],
      // },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                  ],
                ),
              ],
            ),
          ),
          const Gap(20),
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
                  if (!hasRole) {
                    return const SizedBox.shrink();
                  }

                  return AppCard(
                    backgroundColor: !isEnabled ? AppColors.kNeutral200 : null,
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      if (isEnabled) {
                        if (title == AppTexts.businessProducts || title == AppTexts.businessSales || title == 'Movimientos') {
                          NavigationService.navigateTo(context, route, arguments: business.id);
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
              );
            },
          ),
        ],
      ),
    );
  }
}
