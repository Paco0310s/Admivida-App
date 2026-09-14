import 'dart:async';
import 'package:admivida/business/features/add_sale/add_sale_provider.dart';
import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/models/pos_catalog_state.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_provider.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_text.dart';
// 💡 IMPORTANT: Adjust this import to match the actual path of your BarcodeScannerSheet
import 'package:admivida/common/widgets/barcode_scanner_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PosCatalogScreen extends ConsumerStatefulWidget {
  final String businessId;
  final int crossAxisCount;

  const PosCatalogScreen({super.key, required this.businessId, required this.crossAxisCount});

  @override
  ConsumerState<PosCatalogScreen> createState() => _PosCatalogScreenState();
}

class _PosCatalogScreenState extends ConsumerState<PosCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(posCatalogProvider(widget.businessId).notifier).setSearchQuery(query);
    });
  }

  // Barcode Scanner Logic using your custom Bottom Sheet
  void _openBarcodeScanner() {
    // Hide keyboard if it was open for name search
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return BarcodeScannerSheet(
          onCode: (String code) async {
            final cleanCode = code.trim();
            if (cleanCode.isEmpty) return;

            try {
              final variant = await ref.read(scannedVariantProvider(cleanCode, widget.businessId).future);

              if (!context.mounted) return;

              if (variant.expirationDate != null && variant.expirationDate!.isBefore(DateTime.now())) {
                final proceed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                        Gap(10),
                        Expanded(
                          child: Text(
                            'Alerta de Caducidad Próxima',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      'El sistema indica que hay existencias de este producto que ya alcanzaron su fecha límite.\n\nPor favor, revisa físicamente la caducidad del artículo que tienes en las manos antes de cobrarlo para evitar entregar un producto vencido.\n\n¿Deseas agregarlo a la venta?',
                      style: TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.kNeutral600)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sí, vender', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (proceed != true) return;
              }

              final double price = variant.salePrice;
              final String displayName = (variant.name != null && variant.name!.isNotEmpty) ? variant.name! : variant.sku;

              final newItem = CreateSaleDetailInnerDto(
                productVariantId: variant.id,
                quantity: 1.0,
                unitPrice: price,
                originalPriceSnapshot: price,
                productNameSnapshot: displayName,
                priceType: 'RETAIL',
                isPaid: true,
                imageUrl: variant.images.isNotEmpty ? variant.images.first : null,
                subtotal: price,
              );

              ref.read(cartProvider.notifier).addItem(newItem);
              ref.read(posCatalogProvider(widget.businessId).notifier).setSearchQuery('');
              if (context.mounted) SnackbarUtil.showSuccess(context, '$displayName agregado');
            } catch (e) {
              if (context.mounted) {
                SnackbarUtil.showWarning(context, 'No se encontró el producto: $cleanCode');
              }
            }
          },
        );
      },
    );
  }

  void _onProductTap(ProductModel product) {
    NavigationService.navigateTo(context, Routes.productDetailSale, arguments: {'product': product, 'businessId': widget.businessId});
  }

  // --- HEADER: Search + Scanner ---
  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, SKU o código...',
                prefixIcon: const Icon(Icons.search, color: AppColors.kNeutral500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus(); // Hide keyboard on clear
                          ref.read(posCatalogProvider(widget.businessId).notifier).setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                filled: true,
                fillColor: AppColors.kNeutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.kNeutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.kNeutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.kPrimaryColor),
                ),
              ),
            ),
          ),
          const Gap(10),

          // Scanner Button
          Material(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(12),
            elevation: 2, // Small shadow to highlight it as a primary action button
            child: InkWell(
              onTap: _openBarcodeScanner,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PRODUCT CARD ---
  Widget _buildProductCard(ProductModel product) {
    // Get the real main image if it exists, to leverage the blurHash
    final mainImage = product.images.isNotEmpty ? product.images.firstWhere((img) => img.main, orElse: () => product.images.first) : null;

    final imageUrl = mainImage?.url ?? product.mainImageUrl;
    final blurHash = mainImage?.blurHash;
    final price = product.defaultPrice;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _onProductTap(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.kNeutral100,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                // 💡 Using AdaptedFile class for advanced image handling
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: AdaptedFile.network(imageUrl, blurHash: blurHash).getWidget(fit: BoxFit.cover, width: double.infinity),
                      )
                    : const Center(child: Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.kNeutral400)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(product.name, fontWeight: FontWeight.bold, fontSize: 14, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Gap(4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText('\$${price.toStringAsFixed(2)}', fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor, fontSize: 15),
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.kPrimaryColor,
                        child: Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PAGINATION FOOTER ---
  Widget _buildPaginationFooter(PosCatalogState state) {
    final meta = state.pageModel?.meta;
    final currentPage = state.currentPage;
    final totalPages = meta?.totalPages ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.kNeutral200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: (currentPage > 1 && !state.isLoading) ? () => ref.read(posCatalogProvider(widget.businessId).notifier).previousPage() : null,
            icon: Icon(Icons.arrow_back_ios, size: 18, color: currentPage > 1 ? AppColors.kNeutral900 : AppColors.kNeutral300),
          ),
          AppText('Página $currentPage de $totalPages', fontWeight: FontWeight.w600, fontSize: 14),
          IconButton(
            onPressed: (currentPage < totalPages && !state.isLoading) ? () => ref.read(posCatalogProvider(widget.businessId).notifier).nextPage() : null,
            icon: Icon(Icons.arrow_forward_ios, size: 18, color: currentPage < totalPages ? AppColors.kNeutral900 : AppColors.kNeutral300),
          ),
        ],
      ),
    );
  }

  // --- MAIN CONTENT ---
  Widget _buildCatalogLayout(BuildContext context, {required int crossAxisCount}) {
    final state = ref.watch(posCatalogProvider(widget.businessId));
    final products = state.pageModel?.data ?? [];

    return Column(
      children: [
        _buildSearchHeader(),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.kWarning),
                      const Gap(16),
                      AppText(state.errorMessage!, color: AppColors.kNeutral700),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: () => ref.read(posCatalogProvider(widget.businessId).notifier).fetchProducts(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                        child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 60, color: AppColors.kNeutral300),
                      const Gap(16),
                      AppText(
                        _searchController.text.isNotEmpty ? 'No encontramos nada para "${_searchController.text}"' : 'No hay productos disponibles.',
                        color: AppColors.kNeutral600,
                        fontSize: 16,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, // 2 for mobile, 3-4 for tablet/desktop
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
        ),

        // Show the pagination footer only if there is no error and there is data (or we are searching)
        if (state.errorMessage == null && (products.isNotEmpty || _searchController.text.isNotEmpty)) _buildPaginationFooter(state),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCatalogLayout(context, crossAxisCount: widget.crossAxisCount);
  }
}
