import 'dart:async';

import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/barcode_scanner_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppTexts.businessProducts,
      appBar: AppBar(
        title: AppText(AppTexts.businessProducts, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: ProductsListView(businessId: businessId),
      tablet: ProductsListView(businessId: businessId),
      desktop: ProductsListView(businessId: businessId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => NavigationService.navigateTo(context, Routes.createOrUpdateProduct, arguments: {'businessId': businessId, 'product': null}),
        backgroundColor: AppColors.kPrimaryColor,
        icon: const Icon(Icons.add),
        label: AppText(AppTexts.addProductButton, color: AppColors.kNeutral100),
      ),
    );
  }
}

class ProductsListView extends ConsumerStatefulWidget {
  const ProductsListView({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<ProductsListView> createState() => _ProductsListViewState();
}

class _ProductsListViewState extends ConsumerState<ProductsListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(query);
    });
  }

  /// Detects scroll proximity to trigger infinite scrolling via Riverpod.
  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(productsListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider(widget.businessId));

    return RefreshIndicator(
      onRefresh: () => ref.read(productsListProvider(widget.businessId).notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(AppTexts.productsListTitle, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(12),
            _buildSearchHeader(),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error loading products: $error', color: Colors.red)),
                data: (listState) {
                  final products = listState.products;

                  if (products.isEmpty) {
                    return Center(child: AppText(AppTexts.noData, color: AppColors.kNeutral600));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: products.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final product = products[index];
                      final firstVariant = product.defaultVariant;
                      final productImage = product.mainImageUrl;

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        onTap: () {
                          NavigationService.navigateTo(context, Routes.productDetail, arguments: {'businessId': widget.businessId, 'productId': product.id});
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: productImage == null
                                  ? Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.inventory_2_rounded, size: 32, color: AppColors.kPrimaryColor),
                                    )
                                  : SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: AdaptedFile.network(productImage, blurHash: product.images.first.blurHash).getWidget(width: 72, height: 72),
                                    ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(product.name, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                                  const Gap(4),
                                  if (product.description != null && product.description!.isNotEmpty)
                                    AppText(product.description!, color: AppColors.kNeutral700, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const Gap(6),
                                  Row(
                                    children: [
                                      AppText(
                                        product.productCategoryName ?? AppTexts.noData,
                                        color: AppColors.kSecondaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      const Spacer(),
                                      if (firstVariant != null)
                                        AppText(
                                          '\$${firstVariant.salePrice.toStringAsFixed(2)}',
                                          color: AppColors.kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                    ],
                                  ),
                                  const Gap(6),
                                  Row(
                                    children: [
                                      AppText('${AppTexts.unitOfMeasure}: ${product.unitOfMeasure}', color: AppColors.kNeutral600, fontSize: 11),
                                      const Spacer(),
                                      Builder(
                                        builder: (context) {
                                          if (firstVariant?.stockQuantity == null) {
                                            return SizedBox.shrink();
                                          }

                                          if (product.variants.length > 1) {
                                            return SizedBox.shrink();
                                          }

                                          return InkWell(
                                            onTap: () {
                                              if (firstVariant?.stockQuantity != null && firstVariant!.stockQuantity! > 0) {
                                                ref
                                                    .read(stockAdjustmentProvider.notifier)
                                                    .adjustStock(
                                                      businessId: widget.businessId,
                                                      productId: product.id,
                                                      variantId: firstVariant.id,
                                                      currentStock: firstVariant.stockQuantity!, // Es de tipo double
                                                      adjustment: -1.0,
                                                    );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: firstVariant?.stockQuantity != null && firstVariant!.stockQuantity! > 0
                                                    ? Colors.white
                                                    : AppColors.kNeutral100,
                                                border: Border.all(color: AppColors.kNeutral300),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.remove, size: 20),
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: firstVariant?.stockQuantity == null ? 0 : 12),
                                        child: _buildStockLabel(product, firstVariant),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          if (firstVariant?.stockQuantity == null) {
                                            return SizedBox.shrink();
                                          }

                                          if (product.variants.length > 1) {
                                            return SizedBox.shrink();
                                          }

                                          return InkWell(
                                            onTap: () {
                                              if (firstVariant?.stockQuantity != null) {
                                                ref
                                                    .read(stockAdjustmentProvider.notifier)
                                                    .adjustStock(
                                                      businessId: widget.businessId,
                                                      productId: product.id,
                                                      variantId: firstVariant!.id,
                                                      currentStock: firstVariant.stockQuantity!,
                                                      adjustment: 1.0,
                                                    );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.kNeutral300),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.add, size: 20),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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

  // 💡 Extracting this builder logic to a separate method keeps your main UI code much cleaner.
  Widget _buildStockLabel(ProductModel product, ProductVariantModel? firstVariant) {
    if (product.variants.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single variant logic
    if (product.variants.length == 1) {
      if (firstVariant?.stockQuantity == null) {
        return AppText(AppTexts.ilimited, color: AppColors.kWarning, fontSize: 12, fontWeight: FontWeight.bold);
      }

      // Format quantity to remove '.0' if it's an integer
      final stockVal = firstVariant!.stockQuantity!;
      final displayStock = stockVal == stockVal.toInt() ? stockVal.toInt().toString() : stockVal.toString();

      return AppText(
        displayStock,
        color: stockVal > 0 ? AppColors.kSuccess : AppColors.kWarning, // Dynamic color based on stock
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );
    }

    // Multiple variants logic (Total sum)
    final double totalQuantity = product.variants.fold(0.0, (sum, variant) => sum + (variant.stockQuantity ?? 0.0));

    final displayTotal = totalQuantity == totalQuantity.toInt() ? totalQuantity.toInt().toString() : totalQuantity.toString();

    return AppText(
      '$displayTotal (Total)', // Adding "(Total)" as we discussed earlier
      color: totalQuantity > 0 ? AppColors.kSuccess : AppColors.kWarning,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  }

  // --- HEADER: Search + Scanner ---
  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
                ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, SKU o código...',
                prefixIcon: const Icon(Icons.search, color: AppColors.kNeutral500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery('');
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

  // 💡 Barcode Scanner Logic using your custom Bottom Sheet
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
          onCode: (String code) {
            // 1. Write the scanned code into the search text field
            _searchController.text = code;

            // 2. Trigger the search in the provider immediately
            ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(code);

            // 3. Visual confirmation for the cashier
            SnackbarUtil.showSuccess(context, 'Código escaneado: $code');
          },
        );
      },
    );
  }
}
