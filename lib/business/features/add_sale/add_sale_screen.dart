import 'package:admivida/business/features/add_sale/cart/cart_screen.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_provider.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_screen.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddSaleScreen extends ConsumerWidget {
  final String businessId;
  const AddSaleScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posCatalogProvider(businessId));

    return PosScannerListener(
      onBarcodeScanned: (code) {
        debugPrint('SKU Detectado por el Escáner: $code');

        ref.read(posCatalogProvider(businessId).notifier).setSearchQuery('');

        SnackbarUtil.showSuccess(context, 'Producto escaneado y agregado: $code');
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
            Flexible(flex: 28, child: CartScreen()),
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
            onPressed: () {},
            backgroundColor: AppColors.kPrimaryColor,
            child: const Icon(Icons.shopping_cart, color: Colors.white),
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
