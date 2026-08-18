import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BusinessModel>> businessesAsync = ref.watch(businessesListProvider);

    return AppScaffold(
      title: AppTexts.businessesModule,
      appBar: AppBar(
        title: AppText(AppTexts.businessesModule, color: AppColors.kNeutral100),
        iconTheme: IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: BusinessesList(businessesAsync: businessesAsync),
      tablet: BusinessesList(businessesAsync: businessesAsync),
      desktop: BusinessesList(businessesAsync: businessesAsync),
    );
  }
}

class BusinessesList extends ConsumerWidget {
  const BusinessesList({super.key, required this.businessesAsync});

  final AsyncValue<List<BusinessModel>> businessesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(businessesListProvider.notifier).refresh(),
      child: businessesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (businesses) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(AppTexts.businessListTitle, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                      IconButton(
                        icon: Icon(Icons.add),
                        color: AppColors.kPrimaryColor,
                        onPressed: () {
                          NavigationService.navigateTo(context, Routes.addBusiness);
                        },
                        tooltip: AppTexts.addBusinessButton,
                      ),
                    ],
                  ),
                  Gap(5),
                  ListView.builder(
                    itemCount: businesses.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final currentBusiness = businesses[index];
                      return AppCard(
                        backgroundColor: currentBusiness.isActive ? null : AppColors.kNeutral100,
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        onTap: () {
                          NavigationService.navigateTo(context, Routes.businessDetail, arguments: currentBusiness);
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: AppText(currentBusiness.name, color: AppColors.kNeutral900, fontWeight: FontWeight.bold),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  if (currentBusiness.description != null) {
                                    return Container();
                                  }

                                  return AppText(currentBusiness.description!);
                                },
                              ),
                              AppText(currentBusiness.categoryName, color: AppColors.kNeutral500, fontWeight: FontWeight.bold, fontSize: 9),
                              Builder(
                                builder: (context) {
                                  if (currentBusiness.isActive) {
                                    return Container();
                                  }

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(),
                                      AppText(
                                        currentBusiness.isActive ? AppTexts.active : AppTexts.inactive,
                                        color: currentBusiness.isActive ? AppColors.kSuccess : AppColors.kError,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          leading: currentBusiness.image == null
                              ? const Icon(Icons.business)
                              : SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: AdaptedFile.network(
                                    currentBusiness.image!.url,
                                    blurHash: currentBusiness.image!.blurHash,
                                  ).getWidget(width: 48, height: 48),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
