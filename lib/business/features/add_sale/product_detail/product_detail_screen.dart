import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_dto.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ProductDetailSaleScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final String businessId;

  const ProductDetailSaleScreen({super.key, required this.product, required this.businessId});

  @override
  ConsumerState<ProductDetailSaleScreen> createState() => _ProductDetailSaleScreenState();
}

class _ProductDetailSaleScreenState extends ConsumerState<ProductDetailSaleScreen> {
  int _quantity = 1;
  String? _selectedVariantId;

  // Controladores editables
  late TextEditingController _nameSnapshotController;
  late TextEditingController _priceSnapshotController;
  final TextEditingController _commentController = TextEditingController();

  bool _isCustomPrice = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariantId = widget.product.variants.first.id;
    }

    _nameSnapshotController = TextEditingController(text: _defaultNameSnapshot);
    _priceSnapshotController = TextEditingController(text: _calculatedStandardUnitPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameSnapshotController.dispose();
    _priceSnapshotController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// Variante seleccionada
  ProductVariantModel get _currentVariant {
    return widget.product.variants.firstWhere((v) => v.id == _selectedVariantId, orElse: () => widget.product.variants.first);
  }

  /// Nombre por defecto para el snapshot
  String get _defaultNameSnapshot {
    final vName = _currentVariant.name;
    if (vName != null && vName.isNotEmpty && vName.toLowerCase() != 'general') {
      return '${widget.product.name} - $vName';
    }
    return widget.product.name;
  }

  /// Indica si aplica regla de mayoreo automática
  bool get _appliesWholesaleRule {
    final v = _currentVariant;
    return v.wholesalePrice != null && v.wholesaleQuantity != null && _quantity >= v.wholesaleQuantity!;
  }

  /// Precio original / lista sin descuentos aplicados
  double get _originalListPrice {
    final v = _currentVariant;
    if (_appliesWholesaleRule) {
      return v.wholesalePrice!;
    }
    return v.salePrice;
  }

  /// Precio calculado de manera estándar (Menudeo o Mayoreo)
  double get _calculatedStandardUnitPrice {
    return _originalListPrice;
  }

  /// Precio unitario final a cobrar
  double get _finalUnitPrice {
    if (_isCustomPrice) {
      return double.tryParse(_priceSnapshotController.text.trim()) ?? _calculatedStandardUnitPrice;
    }
    return _calculatedStandardUnitPrice;
  }

  /// Determina automáticamente el tipo de precio para la venta
  String get _priceType {
    if (_isCustomPrice) {
      return 'CUSTOM';
    }
    if (_appliesWholesaleRule) {
      return 'WHOLESALE';
    }
    return 'RETAIL';
  }

  /// Actualiza los campos al cambiar variante o cantidad
  void _syncCalculatedFields({bool resetCustomPrice = false}) {
    if (resetCustomPrice || !_isCustomPrice) {
      _isCustomPrice = false;
      _priceSnapshotController.text = _calculatedStandardUnitPrice.toStringAsFixed(2);
    }
    _nameSnapshotController.text = _defaultNameSnapshot;
  }

  void _incrementQuantity() {
    final stock = _currentVariant.stockQuantity;
    if (stock != null && _quantity >= stock) {
      SnackbarUtil.showWarning(context, 'Stock máximo alcanzado para esta variante');
      return;
    }
    setState(() {
      _quantity++;
      _syncCalculatedFields();
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _syncCalculatedFields();
      });
    }
  }

  void _resetPriceToDefault() {
    setState(() {
      _isCustomPrice = false;
      _priceSnapshotController.text = _calculatedStandardUnitPrice.toStringAsFixed(2);
    });
  }

  void _addToCart() {
    final variant = _currentVariant;
    final finalPrice = _finalUnitPrice;
    final originalPrice = _originalListPrice;
    final priceType = _priceType;
    final nameSnapshot = _nameSnapshotController.text.trim().isEmpty ? _defaultNameSnapshot : _nameSnapshotController.text.trim();

    // 1. Obtenemos la imagen correcta para el carrito
    final variantImage = variant.images.isNotEmpty ? variant.images.firstWhere((img) => img.main, orElse: () => variant.images.first) : null;
    final productImage = widget.product.images.isNotEmpty
        ? widget.product.images.firstWhere((img) => img.main, orElse: () => widget.product.images.first)
        : null;
    final displayImage = variantImage ?? productImage;

    // 2. Creamos el DTO (¡con los campos extra de UI!)
    final detail = CreateSaleDetailInnerDto(
      productVariantId: variant.id,
      productNameSnapshot: nameSnapshot,
      quantity: _quantity.toDouble(),
      originalPriceSnapshot: originalPrice,
      unitPrice: finalPrice,
      priceType: priceType,
      commentary: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      subtotal: finalPrice * _quantity,
      imageUrl: displayImage?.url,
    );

    // 3. Agregamos al carrito usando el provider generado
    ref.read(cartProvider.notifier).addItem(detail);

    // 4. Mostramos confirmación
    SnackbarUtil.showSuccess(context, 'Agregado al carrito: $nameSnapshot x$_quantity');

    // 5. Regresamos al catálogo
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final variant = _currentVariant;
    final double finalPrice = _finalUnitPrice;
    final String currentPriceType = _priceType;

    // Foto dinámica
    final variantImage = variant.images.isNotEmpty ? variant.images.firstWhere((img) => img.main, orElse: () => variant.images.first) : null;
    final productImage = widget.product.images.isNotEmpty
        ? widget.product.images.firstWhere((img) => img.main, orElse: () => widget.product.images.first)
        : null;
    final displayImage = variantImage ?? productImage;

    String formatQty(double? val) => val == null ? AppTexts.ilimited : (val == val.toInt() ? val.toInt().toString() : val.toString());

    return AppScaffold(
      title: widget.product.name,
      appBar: AppBar(
        title: AppText('Detalle de Venta', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(variant, finalPrice, currentPriceType, displayImage, formatQty),
      tablet: _buildContent(variant, finalPrice, currentPriceType, displayImage, formatQty),
      desktop: _buildContent(variant, finalPrice, currentPriceType, displayImage, formatQty),
    );
  }

  Widget _buildContent(ProductVariantModel variant, double finalPrice, String priceType, ProductImageModel? displayImage, String Function(double?) formatQty) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TARJETA PRINCIPAL (IMAGEN Y EDICIÓN DE NOMBRE)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen reactiva
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(14)),
                      child: displayImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: AdaptedFile.network(
                                  displayImage.url,
                                  blurHash: displayImage.blurHash,
                                ).getWidget(fit: BoxFit.cover, width: double.infinity, height: 220),
                              ),
                            )
                          : const Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.kPrimaryColor),
                    ),
                    const Gap(16),

                    // Nombre editable de la partida (productNameSnapshot)
                    const AppText('Nombre en Ticket / Partida:', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kNeutral600),
                    const Gap(6),
                    TextField(
                      controller: _nameSnapshotController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.kNeutral50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.kNeutral300),
                        ),
                      ),
                    ),
                    const Gap(8),

                    if (widget.product.description != null && widget.product.description!.isNotEmpty)
                      AppText(widget.product.description!, fontSize: 13, color: AppColors.kNeutral600),
                  ],
                ),
              ),
              const Gap(16),

              // 2. SELECCIÓN DE VARIANTE (Si aplica)
              if (widget.product.variants.isNotEmpty)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText('Selecciona una variante:', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                        const Gap(12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.product.variants.map((v) {
                            final isSelected = _selectedVariantId == v.id;
                            return ChoiceChip(
                              label: Text(v.name?.isNotEmpty == true ? v.name! : 'General'),
                              selected: isSelected,
                              selectedColor: AppColors.kPrimaryColor,
                              backgroundColor: AppColors.kNeutral100,
                              side: BorderSide(color: isSelected ? AppColors.kPrimaryColor : AppColors.kNeutral300),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.kNeutral800,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedVariantId = v.id;
                                    if (v.stockQuantity != null && _quantity > v.stockQuantity!) {
                                      _quantity = v.stockQuantity!.toInt();
                                      if (_quantity < 1) _quantity = 1;
                                    }
                                    _syncCalculatedFields(resetCustomPrice: true);
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              const Gap(16),

              // 3. TARJETA DE PRECIO UNITARIO Y EDICIÓN (PRECIO PERSONALIZADO / DESCUENTO)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText('Precio Unitario de Venta:', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                        // Badge con el PriceType actual
                        _PriceTypeBadge(priceType: priceType),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceSnapshotController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isCustomPrice ? AppColors.kWarning : AppColors.kPrimaryColor),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              labelText: 'Precio por unidad',
                              filled: true,
                              fillColor: _isCustomPrice ? AppColors.kWarning.withValues(alpha: 0.05) : AppColors.kNeutral50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (val) {
                              setState(() {
                                final parsed = double.tryParse(val.trim());
                                // Si cambia respecto al estándar, se marca como CUSTOM
                                if (parsed != null && parsed != _calculatedStandardUnitPrice) {
                                  _isCustomPrice = true;
                                } else {
                                  _isCustomPrice = false;
                                }
                              });
                            },
                          ),
                        ),
                        if (_isCustomPrice) ...[
                          const Gap(8),
                          IconButton(
                            tooltip: 'Restablecer precio lista',
                            icon: const Icon(Icons.refresh, color: AppColors.kNeutral600),
                            onPressed: _resetPriceToDefault,
                          ),
                        ],
                      ],
                    ),
                    if (_isCustomPrice) ...[
                      const Gap(6),
                      AppText(
                        'Precio personalizado. Precio lista original: \$${_originalListPrice.toStringAsFixed(2)}',
                        fontSize: 12,
                        color: AppColors.kWarning,
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(16),

              // 4. INFORMACIÓN DE INVENTARIO Y ATRIBUTOS
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.inventory_2_outlined, label: 'Stock Disponible', value: formatQty(variant.stockQuantity)),

                    if (variant.wholesalePrice != null && variant.wholesaleQuantity != null) ...[
                      const Divider(height: 24, color: AppColors.kNeutral200),
                      _InfoRow(
                        icon: Icons.local_offer_outlined,
                        label: 'Mayoreo a partir de ${formatQty(variant.wholesaleQuantity)} pz',
                        value: '\$${variant.wholesalePrice!.toStringAsFixed(2)} / ${widget.product.unitOfMeasure}',
                        valueColor: AppColors.kSuccess,
                      ),
                    ],

                    if (variant.sku != null && variant.sku!.isNotEmpty) ...[
                      const Divider(height: 24, color: AppColors.kNeutral200),
                      _InfoRow(icon: Icons.tag, label: 'SKU', value: variant.sku!),
                    ],

                    if (variant.barcode != null && variant.barcode!.isNotEmpty) ...[
                      const Divider(height: 24, color: AppColors.kNeutral200),
                      _InfoRow(icon: Icons.qr_code, label: 'Código de Barras', value: variant.barcode!),
                    ],

                    if (variant.attributes?.isNotEmpty == true) ...[
                      const Divider(height: 24, color: AppColors.kNeutral200),
                      const AppText('Atributos de Variante', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.kNeutral600),
                      const Gap(8),
                      ...variant.attributes!.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _InfoRow(icon: Icons.label_outline, label: entry.key, value: '${entry.value}'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(16),

              // 5. CANTIDAD, NOTAS Y SUBTOTAL
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText('Cantidad a vender:', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                    const Gap(16),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.kNeutral50,
                            border: Border.all(color: AppColors.kNeutral300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: AppColors.kNeutral700),
                                onPressed: _decrementQuantity,
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: AppText('$_quantity', fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: AppColors.kPrimaryColor),
                                onPressed: _incrementQuantity,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const AppText('Subtotal', fontSize: 12, color: AppColors.kNeutral600),
                            AppText(
                              '\$${(finalPrice * _quantity).toStringAsFixed(2)}',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kNeutral900,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(20),
                    const Divider(color: AppColors.kNeutral200),
                    const Gap(12),
                    const AppText('Notas adicionales (Opcional):', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.kNeutral800),
                    const Gap(8),
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ej. Para regalo, sin etiqueta, empaque especial...',
                        hintStyle: const TextStyle(color: AppColors.kNeutral500, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.kNeutral50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.kNeutral300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(28),

              // 6. BOTÓN DE AGREGAR AL CARRITO
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (variant.stockQuantity != null && variant.stockQuantity! <= 0) ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimaryColor,
                    disabledBackgroundColor: AppColors.kNeutral300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    (variant.stockQuantity != null && variant.stockQuantity! <= 0) ? 'Sin Stock Disponible' : 'Agregar a la Venta',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.kNeutral500),
        const Gap(12),
        Expanded(child: AppText(label, color: AppColors.kNeutral700, fontSize: 14)),
        AppText(value, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.kNeutral900, fontSize: 14),
      ],
    );
  }
}

class _PriceTypeBadge extends StatelessWidget {
  final String priceType;
  const _PriceTypeBadge({required this.priceType});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (priceType) {
      case 'CUSTOM':
        bg = AppColors.kWarning.withValues(alpha: 0.15);
        fg = AppColors.kWarning;
        text = 'Precio Especial (Custom)';
        break;
      case 'WHOLESALE':
        bg = AppColors.kSuccess.withValues(alpha: 0.15);
        fg = AppColors.kSuccess;
        text = 'Mayoreo';
        break;
      case 'RETAIL':
      default:
        bg = AppColors.kPrimary50;
        fg = AppColors.kPrimaryColor;
        text = 'Menudeo';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: AppText(text, fontSize: 11, fontWeight: FontWeight.bold, color: fg),
    );
  }
}
