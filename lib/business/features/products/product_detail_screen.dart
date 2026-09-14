import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/products/products_provider.dart';
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

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.businessId, required this.productId});

  final String businessId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 Watch the Single Source of Truth (SSOT)
    final productAsync = ref.watch(productDetailProvider(businessId: businessId, productId: productId));

    return productAsync.when(
      data: (product) {
        return AppScaffold(
          title: product.name,
          appBar: AppBar(
            title: AppText(product.name, color: AppColors.kNeutral100),
            iconTheme: const IconThemeData(color: AppColors.kNeutral100),
            backgroundColor: AppColors.kPrimaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.kNeutral100),
                onPressed: () {
                  NavigationService.navigateTo(context, Routes.createOrUpdateProduct, arguments: {'businessId': businessId, 'product': product});
                },
              ),
            ],
          ),
          // 💡 Pass IDs down to the view so it can be used for stock adjustments
          mobile: ProductDetailView(product: product, businessId: businessId, productId: productId),
          tablet: ProductDetailView(product: product, businessId: businessId, productId: productId),
          desktop: ProductDetailView(product: product, businessId: businessId, productId: productId),
        );
      },
      loading: () => AppScaffold(
        title: 'Cargando...',
        appBar: AppBar(
          title: const AppText('Cargando...', color: AppColors.kNeutral100),
          backgroundColor: AppColors.kPrimaryColor,
          iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        ),
        mobile: const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
        tablet: const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
        desktop: const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)),
      ),
      error: (error, stackTrace) => AppScaffold(
        title: 'Error',
        appBar: AppBar(
          title: const AppText('Error', color: AppColors.kNeutral100),
          backgroundColor: AppColors.kPrimaryColor,
          iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        ),
        mobile: Center(child: Text('Hubo un error al cargar el producto: $error')),
        tablet: Center(child: Text('Hubo un error al cargar el producto: $error')),
        desktop: Center(child: Text('Hubo un error al cargar el producto: $error')),
      ),
    );
  }
}

class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key, required this.product, required this.businessId, required this.productId});

  final ProductModel product;
  final String businessId;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductSummary(product: product),
              const Gap(20),
              AppText(AppTexts.productInformationTitle, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
              const Gap(12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: AppTexts.productCategoryLabel, value: product.productCategoryName ?? AppTexts.withoutCategory),
                    _DetailRow(label: AppTexts.unitOfMeasure, value: product.unitOfMeasure),
                    _DetailRow(label: AppTexts.productActiveLabel, value: product.isActive ? AppTexts.active : AppTexts.inactive),
                    _DetailRow(label: 'ID del Producto', value: product.id, isLast: true),
                  ],
                ),
              ),
              const Gap(20),
              AppText(AppTexts.productVariantsLabel, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
              const Gap(12),
              if (product.variants.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: AppText(AppTexts.noData, color: AppColors.kNeutral600),
                )
              else
                ...product.variants.asMap().entries.map(
                  (entry) => _VariantCard(index: entry.key, variant: entry.value, businessId: businessId, productId: productId),
                ),

              const Gap(24),
              // 💡 Registration dates
              Center(
                child: AppText(
                  'Creado el: ${DateFormat('dd/MM/yyyy HH:mm').format(product.createdAt.toLocal())}\nÚltima actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(product.updatedAt.toLocal())}',
                  fontSize: 12,
                  color: AppColors.kNeutral500,
                  textAlign: TextAlign.center,
                ),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final image = product.images.isEmpty ? null : product.images.firstWhere((item) => item.main, orElse: () => product.images.first);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 260,
                child: AdaptedFile.network(image.url, blurHash: image.blurHash).getWidget(width: double.infinity, height: 260, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.inventory_2_rounded, size: 64, color: AppColors.kPrimaryColor),
            ),
          const Gap(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(product.name, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                    const Gap(8),
                    AppText(product.description?.isNotEmpty == true ? product.description! : AppTexts.noData, color: AppColors.kNeutral700),
                  ],
                ),
              ),
              const Gap(16),
              _StatusBadge(isActive: product.isActive),
            ],
          ),
        ],
      ),
    );
  }
}

// 💡 Changed to ConsumerWidget to allow Riverpod interactions
class _VariantCard extends ConsumerWidget {
  const _VariantCard({required this.index, required this.variant, required this.businessId, required this.productId});

  final int index;
  final ProductVariantModel variant;
  final String businessId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 Format quantities to show integers if they have no decimal values
    String formatQuantity(double? val) => val == null ? AppTexts.ilimited : (val == val.toInt() ? val.toInt().toString() : val.toString());

    final stock = formatQuantity(variant.stockQuantity);
    final stockColor = variant.stockQuantity != null && variant.stockQuantity! > 0 ? AppColors.kSuccess : AppColors.kWarning;
    final variantTitle = variant.name?.isNotEmpty == true ? variant.name! : '${AppTexts.variantLabel} ${index + 1}';

    // 💡 Get the main image of this variant (if available)
    final mainVariantImage = variant.images.isNotEmpty ? variant.images.firstWhere((img) => img.main, orElse: () => variant.images.first) : null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (mainVariantImage != null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.kNeutral300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: AdaptedFile.network(mainVariantImage.url, blurHash: mainVariantImage.blurHash).getWidget(fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.sell_outlined, size: 24, color: AppColors.kPrimaryColor),
                ),
              const Gap(12),
              Expanded(
                child: AppText(variantTitle, fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 18),
              ),
            ],
          ),
          const Gap(16),

          // 💡 DATA GRID (PRICES, STOCK, BARCODES)
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _VariantValue(label: AppTexts.productSkuLabel, value: variant.sku ?? AppTexts.noData),
              _VariantValue(label: 'Código de Barras', value: variant.barcode ?? AppTexts.noData),
              _VariantValue(
                label: AppTexts.productPurchasePriceLabel,
                value: variant.purchasePrice != null ? '\$${variant.purchasePrice!.toStringAsFixed(2)}' : 'No definido',
              ),
              _VariantValue(label: AppTexts.productSalePriceLabel, value: '\$${variant.salePrice.toStringAsFixed(2)}', valueColor: AppColors.kPrimaryColor),
              _VariantValue(label: 'Precio Mayoreo', value: variant.wholesalePrice != null ? '\$${variant.wholesalePrice!.toStringAsFixed(2)}' : 'No aplica'),
              _VariantValue(label: 'Cant. Mayoreo', value: formatQuantity(variant.wholesaleQuantity)),

              // 💡 Interactive Stock Adjuster
              if (variant.stockQuantity == null)
                _VariantValue(label: AppTexts.productStockLabel, value: AppTexts.ilimited)
              else
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(AppTexts.productStockLabel, fontSize: 11, color: AppColors.kNeutral600),
                      const Gap(4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: variant.stockQuantity! > 0
                                ? () async {
                                    await ref
                                        .read(stockAdjustmentProvider.notifier)
                                        .adjustStock(
                                          businessId: businessId,
                                          productId: productId,
                                          variantId: variant.id,
                                          currentStock: variant.stockQuantity!,
                                          adjustment: -1.0,
                                        );
                                    ref.invalidate(productDetailProvider(businessId: businessId, productId: productId));
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.kNeutral300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.remove, size: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: AppText(stock, color: stockColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          InkWell(
                            onTap: () async {
                              await ref
                                  .read(stockAdjustmentProvider.notifier)
                                  .adjustStock(
                                    businessId: businessId,
                                    productId: productId,
                                    variantId: variant.id,
                                    currentStock: variant.stockQuantity!,
                                    adjustment: 1.0,
                                  );
                              // 💡 Refresh the detail view SSOT automatically
                              ref.invalidate(productDetailProvider(businessId: businessId, productId: productId));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.kNeutral300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ----------------------------------------------------
              _VariantValue(label: AppTexts.productMinimumStockLabel, value: formatQuantity(variant.minimumStock)),
              _VariantValue(label: AppTexts.productMaximumStockLabel, value: formatQuantity(variant.maximumStock)),

              if (variant.expirationDate != null)
                _VariantValue(
                  label: 'Caducidad Próxima',
                  value: DateFormat('dd/MM/yyyy').format(variant.expirationDate!),
                  valueColor: variant.expirationDate!.isBefore(DateTime.now()) ? Colors.red : AppColors.kNeutral900,
                ),
            ],
          ),

          // 💡 SECONDARY CAROUSEL (Only if there is MORE than 1 photo)
          if (variant.images.length > 1) ...[
            const Gap(20),
            AppText('Otras Fotos de la Variante', fontWeight: FontWeight.bold, color: AppColors.kNeutral700, fontSize: 13),
            const Gap(10),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: variant.images.length,
                itemBuilder: (context, i) {
                  final img = variant.images[i];
                  // 💡 Optional: Prevent showing the main thumbnail again in the carousel
                  if (img.id == mainVariantImage?.id) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.kNeutral300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AdaptedFile.network(img.url, blurHash: img.blurHash).getWidget(fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],

          // 💡 ADDITIONAL ATTRIBUTES (KEY-VALUE)
          if (variant.attributes?.isNotEmpty == true) ...[
            const Gap(20),
            AppText(AppTexts.metadataLabel, fontWeight: FontWeight.bold, color: AppColors.kNeutral700, fontSize: 13),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kNeutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.kNeutral200),
              ),
              child: Column(
                children: variant.attributes!.entries
                    .map((entry) => _DetailRow(label: entry.key, value: '${entry.value}', isLast: entry.key == variant.attributes!.keys.last))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantValue extends StatelessWidget {
  const _VariantValue({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label, fontSize: 11, color: AppColors.kNeutral600),
          const Gap(4),
          AppText(value, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.kNeutral900),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.kNeutral200)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: AppText(label, color: AppColors.kNeutral600, fontSize: 13)),
          Expanded(
            child: AppText(value, fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.kSuccess : AppColors.kNeutral600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: AppText(isActive ? AppTexts.active : AppTexts.inactive, fontSize: 12, fontWeight: FontWeight.bold, color: color),
    );
  }
}
