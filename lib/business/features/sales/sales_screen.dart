import 'package:admivida/business/features/sales/sales_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppTexts.businessSales,
      appBar: AppBar(
        title: AppText(AppTexts.businessSales, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: SalesListView(businessId: businessId),
      tablet: SalesListView(businessId: businessId),
      desktop: SalesListView(businessId: businessId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => NavigationService.navigateTo(context, Routes.addSale, arguments: businessId),
        backgroundColor: AppColors.kPrimaryColor,
        icon: const Icon(Icons.add),
        label: AppText(AppTexts.addSaleButton, color: AppColors.kNeutral100),
      ),
    );
  }
}

class SalesListView extends ConsumerStatefulWidget {
  const SalesListView({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<SalesListView> createState() => _SalesListViewState();
}

class _SalesListViewState extends ConsumerState<SalesListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Detects scroll proximity to trigger infinite scrolling via Riverpod.
  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(salesListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesListProvider(widget.businessId));

    return RefreshIndicator(
      onRefresh: () => ref.read(salesListProvider(widget.businessId).notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(AppTexts.salesListTitle, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(12),
            Expanded(
              child: salesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error loading sales: $error', color: Colors.red)),
                data: (listState) {
                  final sales = listState.sales;

                  if (sales.isEmpty) {
                    return Center(child: AppText(AppTexts.noData, color: AppColors.kNeutral600));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: sales.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == sales.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final sale = sales[index];

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        onTap: () {
                          NavigationService.navigateTo(context, Routes.saleDetail, arguments: sale);
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.kPrimaryColor),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(sale.clientNameSnapshot, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                                  const Gap(4),
                                  AppText('Venta ${sale.id}', color: AppColors.kNeutral600, fontSize: 12),
                                  const Gap(8),
                                  Row(
                                    children: [
                                      AppText('\$${sale.totalPriceSnapshot.toStringAsFixed(2)}', color: AppColors.kPrimaryColor, fontWeight: FontWeight.bold),
                                      const Spacer(),
                                      AppText(
                                        '${sale.details.length} producto${sale.details.length == 1 ? '' : 's'}',
                                        color: AppColors.kSecondaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                  const Gap(6),
                                  AppText('${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year}', color: AppColors.kNeutral500, fontSize: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
