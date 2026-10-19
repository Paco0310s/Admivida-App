import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BusinessModel>> businessesAsync = ref.watch(businessesListProvider);
    final bool isMobile = Responsive.isMobile(context);

    return AppScaffold(
      title: AppTexts.businessesModule,
      appBar: AppBar(
        title: const AppText(AppTexts.businessesModule, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () {
                NavigationService.navigateTo(context, Routes.createOrUpdateBusinessScreen, arguments: null);
              },
              backgroundColor: AppColors.kPrimaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const AppText(AppTexts.addBusinessButton, color: Colors.white, fontWeight: FontWeight.w600),
            )
          : null,
      mobile: BusinessesList(businessesAsync: businessesAsync, gridColumns: 1),
      tablet: BusinessesList(businessesAsync: businessesAsync, gridColumns: 2),
      desktop: BusinessesList(businessesAsync: businessesAsync, gridColumns: 3),
    );
  }
}

class BusinessesList extends ConsumerWidget {
  const BusinessesList({
    super.key,
    required this.businessesAsync,
    this.gridColumns = 1,
  });

  final AsyncValue<List<BusinessModel>> businessesAsync;
  final int gridColumns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = gridColumns == 1;

    return RefreshIndicator(
      onRefresh: () => ref.read(businessesListProvider.notifier).refresh(),
      child: businessesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (businesses) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppText(
                          AppTexts.businessListTitle,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kNeutral900,
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            '${businesses.length}',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (!isMobile)
                      ElevatedButton.icon(
                        onPressed: () {
                          NavigationService.navigateTo(context, Routes.createOrUpdateBusinessScreen, arguments: null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          AppTexts.addBusinessButton,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const Gap(16),
                if (businesses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: AppText(AppTexts.noData, color: AppColors.kNeutral600),
                    ),
                  )
                else if (isMobile)
                  ListView.separated(
                    itemCount: businesses.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, _) => const Gap(12),
                    itemBuilder: (context, index) => _BusinessCardItem(business: businesses[index]),
                  )
                else
                  GridView.builder(
                    itemCount: businesses.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 136,
                    ),
                    itemBuilder: (context, index) => _BusinessCardItem(business: businesses[index]),
                  ),
                const Gap(60),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BusinessCardItem extends StatelessWidget {
  final BusinessModel business;

  const _BusinessCardItem({required this.business});

  @override
  Widget build(BuildContext context) {
    final hasDescription = business.description != null && business.description!.trim().isNotEmpty;

    return AppCard(
      margin: EdgeInsets.zero,
      backgroundColor: business.isActive ? Colors.white : AppColors.kNeutral100,
      padding: const EdgeInsets.all(16),
      onTap: () {
        DashboardSession.setActiveBusiness(business);
        NavigationService.navigateTo(context, Routes.businessDetail, arguments: business);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: business.image == null
                ? Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.kPrimary50,
                          AppColors.kPrimary100.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 28, color: AppColors.kPrimaryColor),
                  )
                : SizedBox(
                    width: 60,
                    height: 60,
                    child: AdaptedFile.network(
                      business.image!.url,
                      blurHash: business.image!.blurHash,
                    ).getWidget(width: 60, height: 60),
                  ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        business.name,
                        color: AppColors.kNeutral900,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: business.isActive
                            ? AppColors.kSuccess.withValues(alpha: 0.12)
                            : AppColors.kError.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AppText(
                        business.isActive ? 'Activo' : AppTexts.inactive,
                        color: business.isActive ? AppColors.kSuccess : AppColors.kError,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                AppText(
                  hasDescription ? business.description! : 'Sin descripción registrada',
                  color: hasDescription ? AppColors.kNeutral600 : AppColors.kNeutral400,
                  fontSize: 12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        business.categoryName,
                        color: AppColors.kSecondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.kNeutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.kPrimaryColor, size: 14),
          ),
        ],
      ),
    );
  }
}
