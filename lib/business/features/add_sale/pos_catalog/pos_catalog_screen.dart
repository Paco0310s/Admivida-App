import 'dart:async';
import 'package:admivida/business/features/add_sale/add_sale_provider.dart';
import 'package:admivida/business/features/add_sale/add_sale_service.dart';
import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/business/features/add_sale/offline/offline_sales_queue_service.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/models/pos_catalog_state.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_provider.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_text.dart';
// 💡 IMPORTANT: Adjust this import to match the actual path of your BarcodeScannerSheet
import 'package:admivida/business/features/add_sale/offline/offline_sales_queue_dialog.dart';
import 'package:admivida/common/widgets/barcode_scanner_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PosCatalogScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String businessName;
  final int crossAxisCount;

  const PosCatalogScreen({
    super.key,
    required this.businessId,
    this.businessName = '',
    required this.crossAxisCount,
  });

  @override
  ConsumerState<PosCatalogScreen> createState() => _PosCatalogScreenState();
}

class _PosCatalogScreenState extends ConsumerState<PosCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'PosSearchField');
  final FocusNode _catalogFocusNode = FocusNode(debugLabel: 'PosCatalogGrid');
  final ScrollController _gridScrollController = ScrollController();
  Timer? _debounce;
  int _selectedProductIndex = 0;
  Duration? _lastHandledKeyTimeStamp;
  DateTime? _lastProductActionTime;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleCatalogShortcutsFallback);
    unawaited(OfflineSalesQueueService.getLocalCatalogProducts(widget.businessId));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleCatalogShortcutsFallback);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _catalogFocusNode.dispose();
    _gridScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _isAnyOtherTextFieldFocused() {
    if (_searchFocusNode.hasFocus) return false;
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return false;
    bool hasEditable = false;
    focus.context!.visitAncestorElements((el) {
      if (el.widget is EditableText) {
        hasEditable = true;
        return false;
      }
      return true;
    });
    if (focus.context!.widget is EditableText) hasEditable = true;
    return hasEditable;
  }

  KeyEventResult _onCatalogFocusKeyEvent(FocusNode node, KeyEvent event) {
    if (_processCatalogKeyEvent(event)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _handleCatalogShortcutsFallback(KeyEvent event) {
    return _processCatalogKeyEvent(event);
  }

  bool _processCatalogKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    // Evitar doble ejecución si ya fue procesado por Focus.onKeyEvent
    if (_lastHandledKeyTimeStamp == event.timeStamp) return true;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.f1) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _showKeyboardShortcutsModal();
      return true;
    }

    if (key == LogicalKeyboardKey.f2) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
      return true;
    }

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    if (key == LogicalKeyboardKey.f5 || (isCtrlPressed && key == LogicalKeyboardKey.keyP)) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _showCommonProductDialog();
      return true;
    }

    if (key == LogicalKeyboardKey.escape && _searchFocusNode.hasFocus) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        ref.read(posCatalogProvider(widget.businessId).notifier).setSearchQuery('');
      } else {
        _catalogFocusNode.requestFocus();
      }
      return true;
    }

    if (key == LogicalKeyboardKey.pageUp) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      ref.read(posCatalogProvider(widget.businessId).notifier).previousPage();
      setState(() => _selectedProductIndex = 0);
      return true;
    }

    if (key == LogicalKeyboardKey.pageDown) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      ref.read(posCatalogProvider(widget.businessId).notifier).nextPage();
      setState(() => _selectedProductIndex = 0);
      return true;
    }

    // Si hay otro campo de texto enfocado (ej. descuento o cliente en el carrito), no interceptar flechas ni Enter
    if (_isAnyOtherTextFieldFocused()) return false;

    final state = ref.read(posCatalogProvider(widget.businessId));
    final products = state.pageModel?.data ?? const <ProductModel>[];
    if (products.isEmpty) return false;

    final safeIndex = _selectedProductIndex.clamp(0, products.length - 1);

    // Si el buscador está enfocado:
    // - Flecha Abajo baja el foco a la cuadrícula de productos
    // - Enter selecciona el producto resaltado (si tiene 1 variante lo agrega; si tiene 2+ abre selector de variante)
    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowDown) {
        _lastHandledKeyTimeStamp = event.timeStamp;
        _catalogFocusNode.requestFocus();
        setState(() => _selectedProductIndex = safeIndex);
        return true;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        _lastHandledKeyTimeStamp = event.timeStamp;
        final forceDetail = HardwareKeyboard.instance.isShiftPressed;
        _quickAddOrOpenProduct(products[safeIndex], forceDetail: forceDetail);
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
        return true;
      }
      return false;
    }

    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    if (isAltPressed) return false; // Alt+Flechas se reserva para navegar el carrito

    if (key == LogicalKeyboardKey.arrowRight) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _catalogFocusNode.requestFocus();
      if (safeIndex + 1 < products.length) {
        _moveProductSelection(safeIndex + 1, products.length);
      } else {
        final meta = state.pageModel?.meta;
        if (meta != null && state.currentPage < meta.totalPages && !state.isLoading) {
          ref.read(posCatalogProvider(widget.businessId).notifier).nextPage();
          setState(() => _selectedProductIndex = 0);
        }
      }
      return true;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _catalogFocusNode.requestFocus();
      if (safeIndex - 1 >= 0) {
        _moveProductSelection(safeIndex - 1, products.length);
      } else if (state.currentPage > 1 && !state.isLoading) {
        ref.read(posCatalogProvider(widget.businessId).notifier).previousPage();
        setState(() => _selectedProductIndex = 0);
      }
      return true;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _catalogFocusNode.requestFocus();
      final nextIdx = safeIndex + widget.crossAxisCount;
      if (nextIdx < products.length) {
        _moveProductSelection(nextIdx, products.length);
      } else {
        _moveProductSelection(products.length - 1, products.length);
      }
      return true;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      final prevIdx = safeIndex - widget.crossAxisCount;
      if (prevIdx >= 0) {
        _catalogFocusNode.requestFocus();
        _moveProductSelection(prevIdx, products.length);
      } else {
        // Si ya está en la primera fila y presiona Arriba, regresar al buscador
        _searchFocusNode.requestFocus();
      }
      return true;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _lastHandledKeyTimeStamp = event.timeStamp;
      _catalogFocusNode.requestFocus();
      final forceDetail = HardwareKeyboard.instance.isShiftPressed;
      _quickAddOrOpenProduct(products[safeIndex], forceDetail: forceDetail);
      return true;
    }

    return false;
  }

  void _moveProductSelection(int newIndex, int totalCount) {
    final clamped = newIndex.clamp(0, totalCount - 1);
    setState(() => _selectedProductIndex = clamped);

    if (_gridScrollController.hasClients) {
      final row = clamped ~/ widget.crossAxisCount;
      const estimatedRowHeight = 210.0;
      final targetOffset = (row * estimatedRowHeight).clamp(
        0.0,
        _gridScrollController.position.maxScrollExtent,
      );
      _gridScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _quickAddOrOpenProduct(ProductModel product, {bool forceDetail = false}) async {
    final now = DateTime.now();
    if (_lastProductActionTime != null && now.difference(_lastProductActionTime!).inMilliseconds < 220) {
      return;
    }
    _lastProductActionTime = now;

    if (product.isOutOfStock) {
      SnackbarUtil.showWarning(context, 'Este producto no tiene existencias disponibles');
      return;
    }

    // Si tiene 2 o más variantes (o si se solicitó explícitamente ver el detalle con Shift+Enter / icono de opciones),
    // NO se agrega al carrito todavía: se abre la vista para seleccionar la variante primero.
    if (forceDetail || product.variants.length > 1) {
      _onProductTap(product);
      return;
    }

    // Si solo tiene 1 variante, se agrega directamente a la venta sin abrir la vista de variantes.
    final variant = product.defaultVariant;
    if (variant == null) {
      _onProductTap(product);
      return;
    }

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
            'El sistema indica que hay existencias de este producto que ya alcanzaron su fecha límite.\n\n¿Deseas agregarlo a la venta?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => NavigationService.pop(ctx, false),
              child: const AppText('Cancelar', color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => NavigationService.pop(ctx, true),
              child: const AppText('Sí, vender', color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final variantName = variant.name;
    final displayName = (variantName != null && variantName.isNotEmpty && variantName.toLowerCase() != 'general')
        ? '${product.name} - $variantName'
        : product.name;

    final newItem = CreateSaleDetailInnerDto(
      productVariantId: variant.id,
      quantity: 1.0,
      unitPrice: variant.salePrice,
      originalPriceSnapshot: variant.salePrice,
      productNameSnapshot: displayName,
      priceType: 'RETAIL',
      isPaid: true,
      imageUrl: product.mainImageUrl,
      subtotal: variant.salePrice,
      allowFractions: product.allowsFractionalQuantity,
      availableStock: variant.stockQuantity,
    );

    final added = ref.read(cartProvider.notifier).addItem(newItem);
    if (mounted) {
      if (added) {
        SnackbarUtil.showSuccess(context, '$displayName agregado al carrito');
      } else {
        final stockVal = variant.stockQuantity;
        final stockText = stockVal == null ? '' : ' (${stockVal % 1 == 0 ? stockVal.toInt() : stockVal} disponibles)';
        SnackbarUtil.showWarning(context, 'Stock máximo alcanzado para $displayName$stockText');
      }
    }
  }

  Future<void> _showCommonProductDialog() async {
    final nameCtrl = TextEditingController(text: 'Producto Común');
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    final nameFocus = FocusNode();
    final qtyFocus = FocusNode();
    final priceFocus = FocusNode();

    nameCtrl.selection = TextSelection(baseOffset: 0, extentOffset: nameCtrl.text.length);

    String formatQty(double qty) {
      if (qty % 1 == 0) return qty.toInt().toString();
      return qty.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final parsedQty = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
          final parsedPrice = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
          final liveSubtotal = (parsedQty > 0 && parsedPrice >= 0) ? parsedQty * parsedPrice : 0.0;

          void submitCommonProduct() {
            final name = nameCtrl.text.trim().isEmpty ? 'Producto Común' : nameCtrl.text.trim();
            final qty = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
            final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));

            if (qty == null || qty <= 0) {
              SnackbarUtil.showWarning(context, 'Ingresa una cantidad válida mayor a 0 (puede ser decimal, ej. 0.5)');
              qtyFocus.requestFocus();
              return;
            }
            if (price == null || price <= 0) {
              SnackbarUtil.showWarning(context, 'Ingresa el precio unitario del producto común');
              priceFocus.requestFocus();
              return;
            }

            final item = CreateSaleDetailInnerDto(
              productVariantId: CreateSaleDetailInnerDto.commonProductPlaceholderVariantId,
              productNameSnapshot: name,
              quantity: qty,
              originalPriceSnapshot: price,
              unitPrice: price,
              priceType: 'CUSTOM',
              isPaid: true,
              subtotal: qty * price,
              allowFractions: true,
            );

            ref.read(cartProvider.notifier).addItem(item);
            NavigationService.pop(dialogCtx);
            if (mounted) {
              SnackbarUtil.showSuccess(
                context,
                'Agregado: $name (${formatQty(qty)} x \$${price.toStringAsFixed(2)})',
              );
              _catalogFocusNode.requestFocus();
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppColors.kPrimaryColor, size: 22),
                ),
                const Gap(10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText('Agregar Producto Común', fontWeight: FontWeight.w800, fontSize: 17),
                      AppText(
                        'Venta rápida sin registro previo (Ctrl + P / F5)',
                        fontSize: 11.5,
                        color: AppColors.kNeutral600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Descripción del producto', fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.kNeutral700),
                  const Gap(6),
                  TextField(
                    controller: nameCtrl,
                    focusNode: nameFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      qtyFocus.requestFocus();
                      qtyCtrl.selection = TextSelection(baseOffset: 0, extentOffset: qtyCtrl.text.length);
                    },
                    decoration: InputDecoration(
                      hintText: 'Ej. Producto varios, Tornillos, Verdura a granel...',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      filled: true,
                      fillColor: AppColors.kNeutral50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Gap(14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText('Cantidad (acepta decimales)', fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.kNeutral700),
                            const Gap(6),
                            TextField(
                              controller: qtyCtrl,
                              focusNode: qtyFocus,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setDialogState(() {}),
                              onSubmitted: (_) {
                                priceFocus.requestFocus();
                                priceCtrl.selection = TextSelection(baseOffset: 0, extentOffset: priceCtrl.text.length);
                              },
                              decoration: InputDecoration(
                                hintText: 'Ej. 1, 0.5, 2.25',
                                prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                                filled: true,
                                fillColor: AppColors.kNeutral50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText('Precio Unitario', fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.kNeutral700),
                            const Gap(6),
                            TextField(
                              controller: priceCtrl,
                              focusNode: priceFocus,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setDialogState(() {}),
                              onSubmitted: (_) => submitCommonProduct(),
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                hintText: '0.00',
                                filled: true,
                                fillColor: AppColors.kNeutral50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 5.0].map((preset) {
                      final label = formatQty(preset);
                      return ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Cant: $label', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.kNeutral100,
                        onPressed: () {
                          qtyCtrl.text = label;
                          setDialogState(() {});
                          priceFocus.requestFocus();
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText('Importe a agregar:', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kNeutral800),
                        AppText(
                          '\$${liveSubtotal.toStringAsFixed(2)}',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kPrimaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => NavigationService.pop(dialogCtx),
                child: const AppText('Cancelar (Esc)', color: AppColors.kNeutral600),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: submitCommonProduct,
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Agregar a la Venta (Enter ↵)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showKeyboardShortcutsModal() {
    const shortcuts = [
      ('F1', 'Abrir esta guía completa de atajos de teclado'),
      ('F2', 'Enfocar buscador de productos (nombre, SKU o código de barras)'),
      ('Enter (en buscador)', 'Si tiene 1 variante lo agrega directo; si tiene 2+ abre variantes'),
      ('← ↑ ↓ →', 'Navegar entre los productos de la cuadrícula del catálogo'),
      ('Enter (en catálogo)', 'Agregar producto (1 variante) o elegir variante (2+ variantes)'),
      ('Shift + Enter', 'Abrir vista detallada del producto (cambiar precio/mayoreo/notas)'),
      ('Ctrl + P  ó  F5', 'Agregar Producto Común / Venta Rápida (nombre, cantidad decimal y precio)'),
      ('RePág / AvPág', 'Cambiar a la página anterior o siguiente del catálogo'),
      ('Esc', 'Limpiar búsqueda activa o cerrar cualquier ventana/modal abierto'),
      ('Alt + ↑ / ↓', 'Seleccionar otro producto dentro del carrito sin usar el mouse'),
      ('+ / -', 'Aumentar o disminuir en 1 la cantidad del producto en el carrito'),
      ('F6', 'Cambiar cantidad exacta (enteros por pieza / decimales a granel o común)'),
      ('F7', 'Modificar el precio unitario del producto seleccionado en el carrito'),
      ('Supr (Delete)', 'Eliminar el producto seleccionado del carrito o descartar ticket pausado'),
      ('F3', 'Buscar y asignar Cliente con teclado (↑↓ y Enter)'),
      ('F4', 'Pausar / poner en espera la venta actual (soporta múltiples ventas)'),
      ('F8', 'Enfocar el campo de Descuento Global de la venta'),
      ('F9', 'Ver y recuperar Ventas en Espera con ↑↓ y Enter'),
      ('F10', 'Alternar Método de Pago (Efectivo / Transferencia / Tarjeta)'),
      ('F12', 'Cobrar venta (Enter confirma monto recibido y Enter cierra el ticket)'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.keyboard_alt_outlined, color: AppColors.kPrimaryColor, size: 26),
            Gap(10),
            Expanded(
              child: AppText('Atajos de Teclado del POS (Sin Mouse)', fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: shortcuts.map((pair) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minWidth: 135),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.kNeutral100,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.kNeutral300),
                        ),
                        child: Text(
                          pair.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kPrimaryColor,
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: AppText(pair.$2, fontSize: 13, color: AppColors.kNeutral800),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
            onPressed: () => NavigationService.pop(ctx),
            child: const Text('Entendido (Esc)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() => _selectedProductIndex = 0);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
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
                        onPressed: () => NavigationService.pop(ctx, false),
                        child: const AppText('Cancelar', color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => NavigationService.pop(ctx, true),
                        child: const AppText('Sí, vender', color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );

                if (proceed != true) return;
              }

              if (variant.stockQuantity <= 0) {
                if (context.mounted) {
                  SnackbarUtil.showWarning(context, 'Este producto no tiene existencias disponibles');
                }
                return;
              }

              final double price = variant.salePrice;
              final String displayName = (variant.name != null && variant.name!.isNotEmpty)
                  ? variant.name!
                  : (variant.sku ?? variant.barcode ?? cleanCode);

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
                allowFractions: variant.allowFractions,
                availableStock: variant.stockQuantity,
              );

              final added = ref.read(cartProvider.notifier).addItem(newItem);
              ref.read(posCatalogProvider(widget.businessId).notifier).setSearchQuery('');
              if (context.mounted) {
                if (added) {
                  SnackbarUtil.showSuccess(context, '$displayName agregado');
                } else {
                  final stockText = variant.stockQuantity % 1 == 0 ? variant.stockQuantity.toInt().toString() : variant.stockQuantity.toString();
                  SnackbarUtil.showWarning(context, 'Stock máximo alcanzado para $displayName ($stockText disponibles)');
                }
              }
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

  void _focusSearchField() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _triggerSelectedCatalogProduct({bool forceDetail = false}) {
    final products = ref.read(posCatalogProvider(widget.businessId)).pageModel?.data ?? const <ProductModel>[];
    if (products.isEmpty) {
      SnackbarUtil.showWarning(context, 'No hay productos en la vista actual');
      return;
    }
    final safeIdx = _selectedProductIndex.clamp(0, products.length - 1);
    _catalogFocusNode.requestFocus();
    _quickAddOrOpenProduct(products[safeIdx], forceDetail: forceDetail);
  }

  // --- HEADER: Search + Scanner + Shortcuts ---
  Widget _buildSearchHeader() {
    final hasPrinterAsync = ref.watch(hasSavedPrinterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onEditingComplete: () {},
                  onSubmitted: (_) {
                    final products = ref.read(posCatalogProvider(widget.businessId)).pageModel?.data ?? const [];
                    if (products.isNotEmpty) {
                      final safeIdx = _selectedProductIndex.clamp(0, products.length - 1);
                      _quickAddOrOpenProduct(products[safeIdx]);
                      _searchController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _searchController.text.length,
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, SKU o código... (F2 · Enter selecciona)',
                    prefixIcon: const Icon(Icons.search, color: AppColors.kNeutral500),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? ExcludeFocus(
                            child: IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _catalogFocusNode.requestFocus();
                                ref.read(posCatalogProvider(widget.businessId).notifier).setSearchQuery('');
                              },
                            ),
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

              // Scanner & Common Product Buttons
              ExcludeFocus(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Agregar Producto Común / Venta Rápida (Ctrl + P ó F5)',
                      child: Material(
                        color: AppColors.kPrimary50,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          canRequestFocus: false,
                          onTap: _showCommonProductDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded, color: AppColors.kPrimaryColor, size: 20),
                                Gap(5),
                                Text(
                                  'Prod. Común (F5)',
                                  style: TextStyle(
                                    color: AppColors.kPrimaryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(6),
                    Material(
                      color: AppColors.kPrimaryColor,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      child: InkWell(
                        canRequestFocus: false,
                        onTap: _openBarcodeScanner,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                    const Gap(5),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.kSecondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        tooltip: 'Abrir Cajón',
                        icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white),
                        onPressed: () async {
                          await ref.read(printerServiceProvider).openCashDrawerWithFeedback(context);
                        },
                      ),
                    ),
                    const Gap(5),
                    hasPrinterAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => const Icon(Icons.error, color: Colors.red),
                      data: (hasPrinter) {
                        return Container(
                          decoration: BoxDecoration(color: hasPrinter ? Colors.red : AppColors.kPrimaryColor, borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(4),
                          child: IconButton(
                            tooltip: hasPrinter ? 'Desvincular Impresora' : 'Vincular Impresora',
                            icon: Icon(hasPrinter ? Icons.print_disabled : Icons.print, color: Colors.white),
                            onPressed: () async {
                              if (hasPrinter) {
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const AppText('Eliminar impresora seleccionada', fontWeight: FontWeight.bold),
                                    content: const AppText('¿Estás seguro de que deseas eliminar la impresora seleccionada?'),
                                    actions: [
                                      TextButton(onPressed: () => NavigationService.pop(context), child: const AppText('Cancelar', color: AppColors.kNeutral600)),
                                      ElevatedButton(
                                        onPressed: () async {
                                          NavigationService.pop(context);
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
                        );
                      },
                    ),
                    const Gap(5),
                    ValueListenableBuilder<bool>(
                      valueListenable: OfflineSalesQueueService.isCatalogSyncingNotifier,
                      builder: (context, isSyncingCatalog, _) {
                        return ValueListenableBuilder<Map<String, int>>(
                          valueListenable: OfflineSalesQueueService.catalogCountByBusinessNotifier,
                          builder: (context, counts, _) {
                            final cachedCount = counts[widget.businessId];
                            final tooltipMsg = isSyncingCatalog
                                ? 'Descargando catálogo completo para modo sin internet...'
                                : cachedCount != null && cachedCount > 0
                                    ? 'Catálogo sin internet listo ($cachedCount productos) • Toca para actualizar'
                                    : 'Descargar catálogo completo para vender y escanear sin internet';
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.kNeutral100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.kNeutral300),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: IconButton(
                                tooltip: tooltipMsg,
                                icon: isSyncingCatalog
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.2),
                                      )
                                    : Icon(
                                        cachedCount != null && cachedCount > 0
                                            ? Icons.cloud_done_outlined
                                            : Icons.cloud_download_outlined,
                                        color: cachedCount != null && cachedCount > 0
                                            ? AppColors.kSuccess
                                            : AppColors.kNeutral700,
                                      ),
                                onPressed: isSyncingCatalog
                                    ? null
                                    : () async {
                                        final syncedCount = await AddSaleService.syncFullCatalogForOffline(widget.businessId);
                                        if (!context.mounted) return;
                                        if (syncedCount != null) {
                                          SnackbarUtil.showSuccess(
                                            context,
                                            'Catálogo listo sin internet ($syncedCount productos sincronizados)',
                                          );
                                          ref.read(posCatalogProvider(widget.businessId).notifier).fetchProducts();
                                        } else {
                                          SnackbarUtil.showWarning(
                                            context,
                                            'No se pudo actualizar el catálogo; verifica tu conexión a internet',
                                          );
                                        }
                                      },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(10),
          // Atajos de teclado en la barra superior (clicables también con el mouse)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildShortcutPill(
                  'F1',
                  'Guía Teclado',
                  tooltip: 'Ver la guía completa de atajos del POS',
                  onTap: _showKeyboardShortcutsModal,
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F2',
                  'Buscar',
                  tooltip: 'Enfocar el buscador de productos',
                  onTap: _focusSearchField,
                ),
                const Gap(6),
                _buildShortcutPill(
                  'Ctrl+P / F5',
                  'Prod. Común',
                  tooltip: 'Agregar un producto común (nombre, cantidad y precio)',
                  onTap: _showCommonProductDialog,
                ),
                const Gap(6),
                _buildShortcutPill(
                  'Flechas + Enter',
                  'Agregar Prod.',
                  tooltip: 'Agregar el producto seleccionado en el catálogo (o abrir variantes si tiene 2+)',
                  onTap: () => _triggerSelectedCatalogProduct(forceDetail: false),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'Shift+Enter',
                  'Detalle/Variantes',
                  tooltip: 'Abrir detalle completo del producto seleccionado',
                  onTap: () => _triggerSelectedCatalogProduct(forceDetail: true),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'Alt+↑↓ / + -',
                  'Editar Carrito',
                  tooltip: 'Cambiar el producto seleccionado dentro del carrito',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.cycleCartSelection),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F6',
                  'Cantidad/Granel',
                  tooltip: 'Editar la cantidad o peso del producto seleccionado en el carrito',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.editQuantity),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F7',
                  'Precio',
                  tooltip: 'Cambiar el precio unitario del producto seleccionado en el carrito',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.editPrice),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F3',
                  'Cliente',
                  tooltip: 'Buscar y seleccionar cliente para la venta',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.selectClient),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F4',
                  'Pausar',
                  tooltip: 'Pausar / poner en espera la venta actual',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.parkSale),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F8',
                  'Descuento',
                  tooltip: 'Enfocar el campo de descuento global',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.focusDiscount),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F9',
                  'En Espera',
                  tooltip: 'Ver y recuperar ventas pausadas en espera',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.showHeldCarts),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F10',
                  'Método Pago',
                  tooltip: 'Cambiar el método de pago (Efectivo / Transferencia / Tarjeta)',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.cyclePaymentMethod),
                ),
                const Gap(6),
                _buildShortcutPill(
                  'F12',
                  'Cobrar',
                  tooltip: 'Cobrar y finalizar la venta actual',
                  onTap: () => PosShortcutBus.emit(PosCartShortcutAction.checkout),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PRODUCT CARD ---
  Widget _buildProductCard(ProductModel product, {required bool isSelected, required int index}) {
    // Get the real main image if it exists, to leverage the blurHash
    final mainImage = product.images.isNotEmpty ? product.images.firstWhere((img) => img.main, orElse: () => product.images.first) : null;

    final imageUrl = mainImage?.url ?? product.mainImageUrl;
    final blurHash = mainImage?.blurHash;
    final price = product.defaultPrice;
    final isOutOfStock = product.isOutOfStock;
    final hasMultipleVariants = product.variants.length > 1;

    return ExcludeFocus(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.kPrimaryColor : Colors.transparent,
            width: isSelected ? 2.2 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.kPrimaryColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: AppCard(
          padding: EdgeInsets.zero,
          backgroundColor: isOutOfStock ? AppColors.kNeutral100 : Colors.white,
          child: InkWell(
            canRequestFocus: false,
            onTap: () {
              setState(() => _selectedProductIndex = index);
              _catalogFocusNode.requestFocus();
              // Si tiene 1 sola variante se agrega directo a la venta; si tiene 2+ variantes abre la vista de variantes
              _quickAddOrOpenProduct(product);
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.kNeutral100,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: ColorFiltered(
                          colorFilter: isOutOfStock
                              ? const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0, //
                                  0.2126, 0.7152, 0.0722, 0, 0, //
                                  0.2126, 0.7152, 0.0722, 0, 0, //
                                  0, 0, 0, 0.45, 0, //
                                ])
                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: AdaptedFile.network(imageUrl, blurHash: blurHash).getWidget(fit: BoxFit.cover, width: double.infinity),
                                )
                              : const Center(child: Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.kNeutral400)),
                        ),
                      ),
                      if (isSelected && !isOutOfStock)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.kPrimaryColor.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasMultipleVariants ? 'Enter ↵ Elegir (${product.variants.length})' : 'Enter ↵ Agregar',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      if (!isOutOfStock && hasMultipleVariants && !isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.kNeutral900.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${product.variants.length} variantes',
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      if (!isOutOfStock && !hasMultipleVariants)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Tooltip(
                            message: 'Ver detalle / mayoreo (Shift + Enter)',
                            child: InkWell(
                              canRequestFocus: false,
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() => _selectedProductIndex = index);
                                _catalogFocusNode.requestFocus();
                                _onProductTap(product);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.tune_rounded, size: 13, color: AppColors.kNeutral700),
                              ),
                            ),
                          ),
                        ),
                      if (isOutOfStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.kNeutral800.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 12, color: Colors.white),
                                Gap(4),
                                Text(
                                  'Sin stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        product.name,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: isOutOfStock ? AppColors.kNeutral500 : AppColors.kNeutral900,
                      ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            '\$${price.toStringAsFixed(2)}',
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? AppColors.kNeutral500 : AppColors.kPrimaryColor,
                            fontSize: 15,
                          ),
                          InkWell(
                            canRequestFocus: false,
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() => _selectedProductIndex = index);
                              _catalogFocusNode.requestFocus();
                              _quickAddOrOpenProduct(product);
                            },
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: isOutOfStock ? AppColors.kNeutral300 : AppColors.kPrimaryColor,
                              child: Icon(
                                isOutOfStock
                                    ? Icons.block_rounded
                                    : (hasMultipleVariants ? Icons.layers_outlined : Icons.add),
                                size: 15,
                                color: isOutOfStock ? AppColors.kNeutral600 : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutPill(String keyLabel, String actionLabel, {String? tooltip, VoidCallback? onTap}) {
    return ExcludeFocus(
      child: Tooltip(
        message: tooltip ?? actionLabel,
        child: Material(
          color: AppColors.kNeutral100,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(6),
            hoverColor: AppColors.kPrimary50,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.kNeutral200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    keyLabel,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.kPrimaryColor),
                  ),
                  const Gap(4),
                  Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.kNeutral700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PAGINATION FOOTER ---
  Widget _buildPaginationFooter(PosCatalogState state) {
    final meta = state.pageModel?.meta;
    final currentPage = state.currentPage;
    final totalPages = meta?.totalPages ?? 1;

    return ExcludeFocus(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.kNeutral200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Página anterior (RePág)',
              onPressed: (currentPage > 1 && !state.isLoading) ? () => ref.read(posCatalogProvider(widget.businessId).notifier).previousPage() : null,
              icon: Icon(Icons.arrow_back_ios, size: 16, color: currentPage > 1 ? AppColors.kNeutral900 : AppColors.kNeutral300),
            ),
            AppText('Página $currentPage de $totalPages', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.kNeutral800),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Página siguiente (AvPág)',
              onPressed: (currentPage < totalPages && !state.isLoading) ? () => ref.read(posCatalogProvider(widget.businessId).notifier).nextPage() : null,
              icon: Icon(Icons.arrow_forward_ios, size: 16, color: currentPage < totalPages ? AppColors.kNeutral900 : AppColors.kNeutral300),
            ),
          ],
        ),
      ),
    );
  }

  // --- MAIN CONTENT ---
  Widget _buildCatalogLayout(BuildContext context, {required int crossAxisCount}) {
    final state = ref.watch(posCatalogProvider(widget.businessId));
    final products = state.pageModel?.data ?? [];
    final safeSelected = products.isEmpty ? 0 : _selectedProductIndex.clamp(0, products.length - 1);

    return Focus(
      focusNode: _catalogFocusNode,
      autofocus: true,
      onKeyEvent: _onCatalogFocusKeyEvent,
      child: Column(
        children: [
          OfflineSalesQueueBanner(
            businessId: widget.businessId,
            businessName: widget.businessName,
          ),
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
                    controller: _gridScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(
                        products[index],
                        isSelected: index == safeSelected,
                        index: index,
                      );
                    },
                  ),
          ),

          // Show the pagination footer only if there is no error and there is data (or we are searching)
          if (state.errorMessage == null && (products.isNotEmpty || _searchController.text.isNotEmpty)) _buildPaginationFooter(state),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCatalogLayout(context, crossAxisCount: widget.crossAxisCount);
  }
}
