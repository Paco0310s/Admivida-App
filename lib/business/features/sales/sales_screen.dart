import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/sales_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

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

  // 💡 Detects scroll proximity to trigger infinite scrolling via Riverpod.
  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(salesListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  // 💡 Helper to build a status badge based on the sale status
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    // Puedes ajustar estos strings según lo que envíe tu enum SaleStatusEnum desde NestJS
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: AppText(label, fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
    );
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
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
                error: (error, stackTrace) => Center(child: AppText('Error al cargar ventas: $error', color: Colors.red)),
                data: (listState) {
                  final sales = listState.sales;

                  if (sales.isEmpty) {
                    return Center(child: AppText(AppTexts.noData, color: AppColors.kNeutral600));
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

                      final sale = sales[index];
                      final dateFormatted = DateFormat('dd MMM yyyy • hh:mm a').format(sale.createdAt.toLocal());

                      // 💡 Generate product preview text (e.g. "Bolis Oreo, Bolis Vainilla...")
                      final previewNames = sale.details.take(3).map((d) => d.productNameSnapshot).join(', ');
                      final hasMoreProducts = sale.details.length > 3;
                      final productsPreview = hasMoreProducts ? '$previewNames...' : previewNames;

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        onTap: () {
                          NavigationService.navigateTo(context, Routes.saleDetail, arguments: sale);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(dateFormatted, color: AppColors.kNeutral500, fontSize: 12),
                                _buildStatusBadge(sale.status),
                              ],
                            ),
                            const Gap(12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _StackedSaleImages(details: sale.details),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(sale.clientNameSnapshot, fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 15),
                                      const Gap(4),
                                      // 💡 Showing the preview text here
                                      AppText(productsPreview, color: AppColors.kNeutral600, fontSize: 12, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const Gap(8),
                                AppText(
                                  '\$${sale.totalPriceSnapshot.toStringAsFixed(2)}',
                                  color: AppColors.kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ],
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

class _StackedSaleImages extends StatelessWidget {
  const _StackedSaleImages({required this.details});

  final List<SaleDetailModel> details;

  @override
  Widget build(BuildContext context) {
    // 1. Filtramos los detalles que SÍ tienen imagen
    final itemsWithImages = details.where((d) => d.imageUrl != null).toList();

    // Si no hay ninguna imagen, mostramos el ícono del recibo por defecto
    if (itemsWithImages.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.receipt_long_rounded, color: AppColors.kPrimaryColor),
      );
    }

    // 2. Tomamos hasta 3 imágenes
    final maxImagesToShow = 3;
    final displayItems = itemsWithImages.take(maxImagesToShow).toList();
    final remainingCount = details.length - displayItems.length;

    return SizedBox(
      width: 60, // Ancho suficiente para que quepan las imágenes apiladas
      height: 42,
      child: Stack(
        children: [
          // Dibujamos las imágenes apiladas (de derecha a izquierda para que la primera quede arriba)
          for (int i = displayItems.length - 1; i >= 0; i--)
            Positioned(
              left: i * 14.0, // Cada imagen se desplaza 14 pixeles a la derecha
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2), // Borde blanco para el efecto apilado
                  color: AppColors.kNeutral200,
                ),
                child: ClipOval(child: AdaptedFile.network(displayItems[i].imageUrl!).getWidget(fit: BoxFit.cover)),
              ),
            ),

          // 3. Si hay más productos, agregamos el circulito flotante "+X"
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
