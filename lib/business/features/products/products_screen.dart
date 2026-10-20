import 'dart:async';

import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/barcode_scanner_sheet.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isAdmin = ref.watch(isBusinessAdminProvider(businessId)).value ?? SecureStorageService.isBusinessAdmin(businessId);

    return AppScaffold(
      title: AppTexts.businessProducts,
      appBar: AppBar(
        title: const AppText(AppTexts.businessProducts, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: ProductsListView(businessId: businessId),
      tablet: ProductsListView(businessId: businessId),
      desktop: ProductsListView(businessId: businessId),
      floatingActionButton: isMobile && isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => NavigationService.navigateTo(
                context,
                Routes.createOrUpdateProduct,
                arguments: {'businessId': businessId, 'product': null},
              ),
              backgroundColor: AppColors.kPrimaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const AppText(AppTexts.addProductButton, color: AppColors.kNeutral100, fontWeight: FontWeight.w600),
            )
          : null,
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
  String _scannerBuffer = '';
  DateTime? _lastKeyEventTime;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted || (ModalRoute.of(context)?.isCurrent == false)) return false;
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();

    // Si pasan más de 100 ms entre teclas, es escritura manual; reiniciamos el buffer del lector
    if (_lastKeyEventTime != null && now.difference(_lastKeyEventTime!).inMilliseconds > 100) {
      _scannerBuffer = '';
    }
    _lastKeyEventTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_scannerBuffer.trim().isNotEmpty) {
        final scannedCode = _scannerBuffer.trim();
        _scannerBuffer = '';

        _debounce?.cancel();
        FocusManager.instance.primaryFocus?.unfocus();

        _searchController.value = TextEditingValue(
          text: scannedCode,
          selection: TextSelection.collapsed(offset: scannedCode.length),
        );

        ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(scannedCode);
        SnackbarUtil.showSuccess(context, 'Código escaneado: $scannedCode');
        return true;
      }
    }

    final character = event.character;
    if (character != null && character.isNotEmpty) {
      _scannerBuffer += character;
    }

    return false;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(query);
    });
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(productsListProvider(widget.businessId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider(widget.businessId));
    final bool isMobile = Responsive.isMobile(context);
    final bool isWideDesktop = MediaQuery.of(context).size.width >= 1280;

    return RefreshIndicator(
      onRefresh: () => ref.read(productsListProvider(widget.businessId).notifier).refresh(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchHeader(isMobile: isMobile),
            const Gap(8),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error loading products: $error', color: Colors.red)),
                data: (listState) {
                  final products = listState.products;

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(color: AppColors.kPrimary50, shape: BoxShape.circle),
                            child: const Icon(Icons.inventory_2_rounded, size: 36, color: AppColors.kPrimaryColor),
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
                        mainAxisExtent: 140,
                      ),
                      itemCount: products.length + (listState.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == products.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return _buildProductCard(context, products[index], isGrid: true);
                      },
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: products.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildProductCard(context, products[index], isGrid: false);
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

  Widget _buildProductCard(BuildContext context, ProductModel product, {required bool isGrid}) {
    final firstVariant = product.defaultVariant;
    final productImage = product.mainImageUrl;
    final isAdmin = ref.watch(isBusinessAdminProvider(widget.businessId)).value ?? SecureStorageService.isBusinessAdmin(widget.businessId);

    return AppCard(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () {
        NavigationService.navigateTo(
          context,
          Routes.productDetail,
          arguments: {'businessId': widget.businessId, 'productId': product.id},
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: productImage == null
                ? Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.inventory_2_rounded, size: 32, color: AppColors.kPrimaryColor),
                  )
                : SizedBox(
                    width: 76,
                    height: 76,
                    child: AdaptedFile.network(productImage, blurHash: product.images.first.blurHash).getWidget(width: 76, height: 76),
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
                        product.name,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.kNeutral900,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (firstVariant != null)
                      AppText(
                        '\$${firstVariant.salePrice.toStringAsFixed(2)}',
                        color: AppColors.kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                  ],
                ),
                const Gap(4),
                if (product.description != null && product.description!.isNotEmpty)
                  AppText(
                    product.description!,
                    color: AppColors.kNeutral600,
                    fontSize: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Gap(8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        product.productCategoryName ?? AppTexts.withoutCategory,
                        color: AppColors.kSecondaryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    AppText('${AppTexts.unitOfMeasure}: ${product.unitOfMeasure}', color: AppColors.kNeutral500, fontSize: 11),
                    const Spacer(),
                    if (isAdmin && firstVariant?.stockQuantity != null && product.variants.length <= 1)
                      InkWell(
                        onTap: () {
                          if (firstVariant?.stockQuantity != null && firstVariant!.stockQuantity! > 0) {
                            ref.read(stockAdjustmentProvider.notifier).adjustStock(
                                  businessId: widget.businessId,
                                  productId: product.id,
                                  variantId: firstVariant.id,
                                  currentStock: firstVariant.stockQuantity!,
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.remove, size: 18),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: (!isAdmin || firstVariant?.stockQuantity == null) ? 0 : 10),
                      child: _buildStockLabel(product, firstVariant),
                    ),
                    if (isAdmin && firstVariant?.stockQuantity != null && product.variants.length <= 1)
                      InkWell(
                        onTap: () {
                          if (firstVariant?.stockQuantity != null) {
                            ref.read(stockAdjustmentProvider.notifier).adjustStock(
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
                            color: Colors.white,
                            border: Border.all(color: AppColors.kNeutral300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add, size: 18),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLabel(ProductModel product, ProductVariantModel? firstVariant) {
    if (product.variants.isEmpty) {
      return const SizedBox.shrink();
    }

    if (product.variants.length == 1) {
      if (firstVariant?.stockQuantity == null) {
        return const AppText(AppTexts.ilimited, color: AppColors.kWarning, fontSize: 12, fontWeight: FontWeight.bold);
      }

      final stockVal = firstVariant!.stockQuantity!;
      final displayStock = stockVal == stockVal.toInt() ? stockVal.toInt().toString() : stockVal.toString();

      return AppText(
        displayStock,
        color: stockVal > 0 ? AppColors.kSuccess : AppColors.kWarning,
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
      );
    }

    final double totalQuantity = product.variants.fold(0.0, (sum, variant) => sum + (variant.stockQuantity ?? 0.0));
    final displayTotal = totalQuantity == totalQuantity.toInt() ? totalQuantity.toInt().toString() : totalQuantity.toString();

    return AppText(
      '$displayTotal (Total)',
      color: totalQuantity > 0 ? AppColors.kSuccess : AppColors.kWarning,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  }

  // --- HEADER: Search + Scanner + Desktop Action ---
  Widget _buildSearchHeader({required bool isMobile}) {
    final isAdmin = ref.watch(isBusinessAdminProvider(widget.businessId)).value ?? SecureStorageService.isBusinessAdmin(widget.businessId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) {
                    FocusScope.of(context).unfocus();
                    ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, SKU o código...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.kNeutral500),
                    suffixIcon: value.text.isNotEmpty
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
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(10),
          Material(
            color: isMobile ? AppColors.kPrimaryColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isMobile ? BorderSide.none : const BorderSide(color: AppColors.kNeutral200),
            ),
            child: InkWell(
              onTap: _openBarcodeScanner,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: isMobile ? Colors.white : AppColors.kPrimaryColor,
                  size: 22,
                ),
              ),
            ),
          ),
          if (!isMobile && isAdmin) ...[
            const Gap(10),
            ElevatedButton.icon(
              onPressed: () => NavigationService.navigateTo(
                context,
                Routes.createOrUpdateProduct,
                arguments: {'businessId': widget.businessId, 'product': null},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                AppTexts.addProductButton,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openBarcodeScanner() {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return BarcodeScannerSheet(
          onCode: (String code) {
            _searchController.text = code;
            ref.read(productsListProvider(widget.businessId).notifier).setSearchQuery(code);
            SnackbarUtil.showSuccess(context, 'Código escaneado: $code');
          },
        );
      },
    );
  }
}
