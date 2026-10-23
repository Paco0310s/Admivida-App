import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/sales_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key, required this.businessId, required this.businessName});

  final String businessId;
  final String businessName;

  Future<void> _handlePrinterToggle(BuildContext context, WidgetRef ref, bool hasPrinter) async {
    if (hasPrinter) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const AppText('Eliminar impresora seleccionada', fontWeight: FontWeight.bold),
          content: const AppText('¿Estás seguro de que deseas eliminar la impresora seleccionada?'),
          actions: [
            TextButton(onPressed: () => NavigationService.pop(dialogContext), child: const AppText('Cancelar', color: AppColors.kNeutral600)),
            ElevatedButton(
              onPressed: () async {
                NavigationService.pop(dialogContext);
                await ref.read(printerServiceProvider).clearSavedPrinter();
                ref.invalidate(hasSavedPrinterProvider);
                if (context.mounted) {
                  SnackbarUtil.showSuccess(context, 'Impresora desvinculada correctamente.');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      await ref.read(printerServiceProvider).showPrinterSelectionModal(context);
      ref.invalidate(hasSavedPrinterProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = Responsive.isMobile(context);
    final hasPrinterAsync = ref.watch(hasSavedPrinterProvider);

    return AppScaffold(
      title: AppTexts.businessSales,
      appBar: AppBar(
        title: const AppText(AppTexts.businessSales, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
          hasPrinterAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (hasPrinter) => IconButton(
              tooltip: hasPrinter ? 'Desvincular Impresora' : 'Seleccionar Impresora',
              icon: Icon(hasPrinter ? Icons.print_disabled_rounded : Icons.print_rounded),
              onPressed: () => _handlePrinterToggle(context, ref, hasPrinter),
            ),
          ),
        ],
      ),
      mobile: SalesListView(businessId: businessId, businessName: businessName),
      tablet: SalesListView(businessId: businessId, businessName: businessName),
      desktop: SalesListView(businessId: businessId, businessName: businessName),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => NavigationService.navigateTo(
                context,
                Routes.addSale,
                arguments: {'businessId': businessId, 'businessName': businessName},
              ),
              backgroundColor: AppColors.kPrimaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const AppText(AppTexts.addSaleButton, color: AppColors.kNeutral100, fontWeight: FontWeight.w600),
            )
          : null,
    );
  }
}

class SalesListView extends ConsumerStatefulWidget {
  const SalesListView({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

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

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(salesListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
        bgColor = AppColors.kSuccess.withValues(alpha: 0.12);
        textColor = AppColors.kSuccess;
        label = 'Pagado';
        break;
      case 'PENDING':
        bgColor = AppColors.kWarning.withValues(alpha: 0.12);
        textColor = AppColors.kWarning;
        label = 'Pendiente';
        break;
      case 'CANCELLED':
        bgColor = Colors.red.withValues(alpha: 0.12);
        textColor = Colors.red;
        label = 'Cancelado';
        break;
      default:
        bgColor = AppColors.kNeutral200;
        textColor = AppColors.kNeutral700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: AppText(label, fontSize: 10.5, fontWeight: FontWeight.bold, color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesListProvider(widget.businessId));
    final bool isMobile = Responsive.isMobile(context);
    final bool isWideDesktop = MediaQuery.of(context).size.width >= 1280;

    return RefreshIndicator(
      onRefresh: () => ref.read(salesListProvider(widget.businessId).notifier).refresh(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppText(
                        'Historial de ventas recientes',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kNeutral700,
                      ),
                      if (salesAsync.value != null) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            '${salesAsync.value!.sales.length}',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kPrimaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      ref.watch(hasSavedPrinterProvider).when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (hasPrinter) => Container(
                              decoration: BoxDecoration(
                                color: hasPrinter ? Colors.red : AppColors.kPrimaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                tooltip: hasPrinter ? 'Desvincular Impresora' : 'Seleccionar Impresora',
                                icon: Icon(hasPrinter ? Icons.print_disabled_rounded : Icons.print_rounded, color: Colors.white, size: 20),
                                onPressed: () async {
                                  if (hasPrinter) {
                                    await showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const AppText('Eliminar impresora seleccionada', fontWeight: FontWeight.bold),
                                        content: const AppText('¿Estás seguro de que deseas eliminar la impresora seleccionada?'),
                                        actions: [
                                          TextButton(onPressed: () => NavigationService.pop(dialogContext), child: const AppText('Cancelar', color: AppColors.kNeutral600)),
                                          ElevatedButton(
                                            onPressed: () async {
                                              NavigationService.pop(dialogContext);
                                              await ref.read(printerServiceProvider).clearSavedPrinter();
                                              ref.invalidate(hasSavedPrinterProvider);
                                              if (context.mounted) {
                                                SnackbarUtil.showSuccess(context, 'Impresora desvinculada correctamente.');
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                                            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    await ref.read(printerServiceProvider).showPrinterSelectionModal(context);
                                    ref.invalidate(hasSavedPrinterProvider);
                                  }
                                },
                              ),
                            ),
                          ),
                      const Gap(10),
                      ElevatedButton.icon(
                        onPressed: () => NavigationService.navigateTo(
                          context,
                          Routes.addSale,
                          arguments: {'businessId': widget.businessId, 'businessName': widget.businessName},
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text(
                          AppTexts.addSaleButton,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(16),
            ],
            Expanded(
              child: salesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
                error: (error, stackTrace) => Center(child: AppText('Error al cargar ventas: $error', color: Colors.red)),
                data: (listState) {
                  final sales = listState.sales;

                  if (sales.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(color: AppColors.kPrimary50, shape: BoxShape.circle),
                            child: const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.kPrimaryColor),
                          ),
                          const Gap(12),
                          const AppText(AppTexts.noData, color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
                        ],
                      ),
                    );
                  }

                  if (isWideDesktop) {
                    return GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 128,
                      ),
                      itemCount: sales.length + (listState.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == sales.length) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor));
                        }
                        return _buildSaleCard(context, sales[index], isGrid: true);
                      },
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: sales.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == sales.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
                        );
                      }
                      return _buildSaleCard(context, sales[index], isGrid: false);
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

  Future<void> _reprintSale(BuildContext context, SaleModel sale) async {
    final document = sale.toObjectToPrint(
      businessName: widget.businessName,
      openDrawer: false,
    );
    await ref.read(printerServiceProvider).showPrintersAndPrint(context, document);
  }

  Widget _buildSaleCard(BuildContext context, SaleModel sale, {required bool isGrid}) {
    final dateFormatted = DateFormat('dd MMM yyyy • hh:mm a').format(sale.createdAt.toLocal());

    final previewNames = sale.details.take(3).map((d) => d.productNameSnapshot).join(', ');
    final hasMoreProducts = sale.details.length > 3;
    final productsPreview = hasMoreProducts ? '$previewNames...' : previewNames;

    return AppCard(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        NavigationService.navigateTo(context, Routes.saleDetail, arguments: sale);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.kNeutral400),
                  const Gap(5),
                  AppText(dateFormatted, color: AppColors.kNeutral500, fontSize: 12),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusBadge(sale.status),
                  const Gap(8),
                  Material(
                    color: AppColors.kPrimary50,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _reprintSale(context, sale),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print_rounded, size: 14, color: AppColors.kPrimaryColor),
                            Gap(4),
                            AppText(
                              'Reimprimir',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StackedSaleImages(details: sale.details),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      sale.clientNameSnapshot.isNotEmpty ? sale.clientNameSnapshot : 'Público General',
                      fontWeight: FontWeight.bold,
                      color: AppColors.kNeutral900,
                      fontSize: 15,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(3),
                    AppText(
                      productsPreview.isNotEmpty ? productsPreview : '${sale.details.length} artículos',
                      color: AppColors.kNeutral600,
                      fontSize: 12,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AppText('Total', fontSize: 10, color: AppColors.kNeutral500),
                  AppText(
                    '\$${sale.totalPriceSnapshot.toStringAsFixed(2)}',
                    color: AppColors.kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StackedSaleImages extends StatelessWidget {
  const _StackedSaleImages({required this.details});

  final List<SaleDetailModel> details;

  @override
  Widget build(BuildContext context) {
    final itemsWithImages = details.where((d) => d.imageUrl != null).toList();

    if (itemsWithImages.isEmpty) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(13)),
        child: const Icon(Icons.receipt_long_rounded, color: AppColors.kPrimaryColor, size: 22),
      );
    }

    const maxImagesToShow = 3;
    final displayItems = itemsWithImages.take(maxImagesToShow).toList();
    final remainingCount = details.length - displayItems.length;

    return SizedBox(
      width: 60,
      height: 42,
      child: Stack(
        children: [
          for (int i = displayItems.length - 1; i >= 0; i--)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: AppColors.kNeutral200,
                ),
                child: ClipOval(child: AdaptedFile.network(displayItems[i].imageUrl!).getWidget(fit: BoxFit.cover)),
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.kNeutral800,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: AppText('+$remainingCount', color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
