import 'package:admivida/business/features/add_sale/add_sale_provider.dart';
import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/cart/cart_screen.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_provider.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_screen.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class AddSaleScreen extends ConsumerWidget {
  final String businessId;
  const AddSaleScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posCatalogProvider(businessId));

    return PosScannerListener(
      onBarcodeScanned: (code) async {
        final cleanCode = code.trim();
        if (cleanCode.isEmpty) return;

        try {
          final variant = await ref.read(scannedVariantProvider(cleanCode, businessId).future);

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
          ref.read(posCatalogProvider(businessId).notifier).setSearchQuery('');
          if (context.mounted) SnackbarUtil.showSuccess(context, '$displayName agregado');
        } catch (e) {
          if (context.mounted) {
            SnackbarUtil.showWarning(context, 'No se encontró el producto: $cleanCode');
          }
        }
      },
      child: AppScaffold(
        title: AppTexts.createSale,
        isLoading: state.isLoading && state.pageModel == null,
        appBar: AppBar(
          title: AppText(AppTexts.createSale, color: AppColors.kBackgroundColor),
          backgroundColor: AppColors.kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        mobile: MobileTabletView(businessId: businessId, crossAxisCount: 2),
        tablet: MobileTabletView(businessId: businessId, crossAxisCount: 4),
        desktop: Row(
          children: [
            Flexible(flex: 72, child: PosCatalogScreen(businessId: businessId, crossAxisCount: 6)),
            Container(width: 2, color: AppColors.kNeutral300),
            Flexible(flex: 28, child: CartScreen(businessId: businessId)),
          ],
        ),
        marginDesktop: 5,
      ),
    );
  }
}

class MobileTabletView extends StatelessWidget {
  const MobileTabletView({super.key, required this.businessId, required this.crossAxisCount});

  final String businessId;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PosCatalogScreen(businessId: businessId, crossAxisCount: crossAxisCount),
        Positioned(
          bottom: 70,
          right: 10,
          child: FloatingActionButton(
            onPressed: () {
              NavigationService.navigateTo(context, Routes.cart, arguments: businessId);
            },
            backgroundColor: AppColors.kPrimaryColor,
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 110,
          right: 5,
          child: Consumer(
            builder: (context, ref, _) {
              final itemCount = ref.watch(cartItemCountProvider);

              return itemCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Center(
                        child: Text(
                          '${itemCount > 99 ? '99+' : itemCount.toInt()}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class PosScannerListener extends StatefulWidget {
  final Widget child;
  final TextEditingController? searchController;
  final Function(String code) onBarcodeScanned;

  const PosScannerListener({super.key, required this.child, required this.onBarcodeScanned, this.searchController});

  @override
  State<PosScannerListener> createState() => _PosScannerListenerState();
}

class _PosScannerListenerState extends State<PosScannerListener> {
  String _buffer = '';
  DateTime? _lastKeyEventTime;

  @override
  void initState() {
    super.initState();
    // 🟢 Registramos el escuchador global de teclado físico a nivel sistema
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    // 🔴 Removemos el escuchador al salir de la pantalla para evitar fugas de memoria
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    // Solo procesamos cuando la tecla se presiona hacia abajo (KeyDownEvent)
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();

    // Si pasan más de 100 ms entre caracteres, es un humano tecleando a mano.
    // Reiniciamos el buffer acumulador.
    if (_lastKeyEventTime != null && now.difference(_lastKeyEventTime!).inMilliseconds > 100) {
      _buffer = '';
    }
    _lastKeyEventTime = now;

    // Detectar fin de lectura del escáner (Tecla Enter / Numpad Enter)
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_buffer.trim().isNotEmpty) {
        final scannedSku = _buffer.trim();
        _buffer = ''; // Limpiamos el acumulador

        // 1. Quitamos el foco de cualquier TextField activo (para cerrar teclado si estaba abierto)
        FocusManager.instance.primaryFocus?.unfocus();

        // 2. Si había texto en el buscador, lo limpiamos para reajustar la vista
        if (widget.searchController != null) {
          widget.searchController!.clear();
        }

        // 3. Ejecutamos la acción de agregar al carrito con el SKU detectado
        widget.onBarcodeScanned(scannedSku);

        return true; // Indicamos que el evento fue manejado por el escáner
      }
    }

    // Acumular caracteres del código de barras
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      _buffer += character;
    }

    return false; // Permitimos que otros widgets (como un TextField) sigan recibiendo la tecla si es escritura manual
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
