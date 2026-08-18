import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en tu pubspec.yaml para formatear fechas

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: product.name,
      appBar: AppBar(
        title: AppText(product.name, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: ProductDetailView(product: product),
      tablet: ProductDetailView(product: product),
      desktop: ProductDetailView(product: product),
    );
  }
}

class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key, required this.product});

  final ProductModel product;

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
                ...product.variants.asMap().entries.map((entry) => _VariantCard(index: entry.key, variant: entry.value)),

              const Gap(24),
              // Fechas de registro
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

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.index, required this.variant});

  final int index;
  final ProductVariantModel variant;

  @override
  Widget build(BuildContext context) {
    // Formateo de cantidades para mostrar enteros si no tienen decimales
    String formatQuantity(double? val) => val == null ? AppTexts.ilimited : (val == val.toInt() ? val.toInt().toString() : val.toString());

    final stock = formatQuantity(variant.stockQuantity);
    final stockColor = variant.stockQuantity != null && variant.stockQuantity! > 0 ? AppColors.kSuccess : AppColors.kWarning;
    final variantTitle = variant.name?.isNotEmpty == true ? variant.name! : '${AppTexts.variantLabel} ${index + 1}';

    // Obtener la imagen principal de esta variante (si tiene)
    final mainVariantImage = variant.images.isNotEmpty ? variant.images.firstWhere((img) => img.main, orElse: () => variant.images.first) : null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💡 HEADER DE LA VARIANTE (CON FOTO MINIATURA)
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

          // 💡 GRID DE DATOS (PRECIOS, STOCK, BARRAS)
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
              _VariantValue(label: AppTexts.productStockLabel, value: stock, valueColor: stockColor),
              _VariantValue(label: AppTexts.productMinimumStockLabel, value: formatQuantity(variant.minimumStock)),
              _VariantValue(label: AppTexts.productMaximumStockLabel, value: formatQuantity(variant.maximumStock)),
            ],
          ),

          // 💡 CARRUSEL SECUNDARIO (Solo si tiene MÁS de 1 foto)
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
                  // Opcional: No mostrar de nuevo la miniatura principal en el carrusel
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

          // 💡 ATRIBUTOS ADICIONALES (KEY-VALUE)
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
      width: 120, // Define un ancho fijo para alinear el grid de forma limpia
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
