import 'dart:async';
import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/cart/cart_service.dart';
import 'package:admivida/business/features/add_sale/cart/models/create_sale_dto.dart';
import 'package:admivida/business/features/add_sale/cart/widgets/client_selector_dialog.dart';
import 'package:admivida/business/features/add_sale/models/business_client_model.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/business/features/add_sale/offline/held_carts_service.dart';
import 'package:admivida/business/features/add_sale/offline/offline_sales_queue_service.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/pos_catalog_provider.dart';
import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/cash_shifts/cash_shifts_provider.dart';
import 'package:admivida/business/features/clients/clients_provider.dart';
import 'package:admivida/common/enums/app_failure_enum.dart';
import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/products/products_provider.dart' show productsListProvider;
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/sales_provider.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/pdf_receipt_service.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class CartScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String businessName;

  const CartScreen({super.key, required this.businessId, required this.businessName});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // --- Controllers for Checkout Form ---
  final TextEditingController _clientNameController = TextEditingController(text: 'Público General');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final FocusNode _discountFocusNode = FocusNode();

  // --- State Variables ---
  String? _selectedSellerId;
  String? _selectedPaymentMethodId;
  String? _selectedAccountId;
  String _selectedSaleStatus = 'COMPLETED'; // Default to COMPLETED
  String? _selectedClientId;
  int _selectedCartItemIndex = 0;
  int _lastCartLength = 0;

  double _discountAmount = 0.0;
  double _amountPaid = 0.0;
  bool _isLoadingSale = false;
  List<CreateSalePaymentDto> _mixedPayments = [];
  StreamSubscription<PosCartShortcutAction>? _shortcutBusSub;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_updateCalculations);
    _amountPaidController.addListener(_updateCalculations);
    HardwareKeyboard.instance.addHandler(_handleCartShortcuts);
    _shortcutBusSub = PosShortcutBus.stream.listen((action) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      _triggerCartShortcutAction(action, fromMouse: true);
    });
  }

  @override
  void dispose() {
    _shortcutBusSub?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleCartShortcuts);
    _clientNameController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _amountPaidController.dispose();
    _discountFocusNode.dispose();
    super.dispose();
  }

  bool _triggerCartShortcutAction(PosCartShortcutAction action, {bool fromMouse = false}) {
    final items = ref.read(cartProvider);
    final safeIdx = items.isEmpty ? 0 : _selectedCartItemIndex.clamp(0, items.length - 1);

    switch (action) {
      case PosCartShortcutAction.cycleCartSelection:
        if (items.isEmpty) {
          if (fromMouse) SnackbarUtil.showWarning(context, 'Agrega productos al carrito para seleccionarlos y editarlos');
          return false;
        }
        final nextIdx = items.length > 1 ? (safeIdx + 1) % items.length : 0;
        setState(() => _selectedCartItemIndex = nextIdx);
        if (fromMouse) {
          SnackbarUtil.showSuccess(
            context,
            'Seleccionado en carrito: ${items[nextIdx].productNameSnapshot} (usa + / - o F6 / F7)',
          );
        }
        return true;

      case PosCartShortcutAction.selectClient:
        final clients = ref.read(businessClientsProvider(widget.businessId)).value;
        if (clients != null && clients.isNotEmpty) {
          _openClientSelectorModal(clients);
          return true;
        }
        if (fromMouse) SnackbarUtil.showWarning(context, 'No hay clientes cargados todavía');
        return false;

      case PosCartShortcutAction.parkSale:
        if (items.isEmpty) {
          if (fromMouse) SnackbarUtil.showWarning(context, 'El carrito está vacío; agrega productos para pausar la venta');
          return false;
        }
        _parkCurrentCart(items);
        return true;

      case PosCartShortcutAction.editQuantity:
        if (items.isEmpty) {
          if (fromMouse) SnackbarUtil.showWarning(context, 'Agrega un producto al carrito para cambiar su cantidad');
          return false;
        }
        _showEditQuantityDialog(items[safeIdx]);
        return true;

      case PosCartShortcutAction.editPrice:
        if (items.isEmpty) {
          if (fromMouse) SnackbarUtil.showWarning(context, 'Agrega un producto al carrito para cambiar su precio');
          return false;
        }
        _showEditPriceDialog(items[safeIdx]);
        return true;

      case PosCartShortcutAction.focusDiscount:
        if (items.isEmpty) {
          if (fromMouse) SnackbarUtil.showWarning(context, 'Agrega productos al carrito para aplicar descuento');
          return false;
        }
        _discountFocusNode.requestFocus();
        _discountController.selection = TextSelection(baseOffset: 0, extentOffset: _discountController.text.length);
        return true;

      case PosCartShortcutAction.showHeldCarts:
        _showHeldCartsDialog();
        return true;

      case PosCartShortcutAction.cyclePaymentMethod:
        final methods = ref.read(paymentMethodsProvider).value;
        if (methods != null && methods.isNotEmpty) {
          final currentIdx = methods.indexWhere((m) => m.id == _selectedPaymentMethodId);
          final nextIdx = (currentIdx + 1) % methods.length;
          final nextMethod = methods[nextIdx];
          setState(() {
            _selectedPaymentMethodId = nextMethod.id;
            _mixedPayments = [];
          });
          SnackbarUtil.showSuccess(context, 'Método de pago: ${nextMethod.name} (F10)');
          return true;
        }
        return false;

      case PosCartShortcutAction.checkout:
        if (items.isEmpty) {
          if (fromMouse) SnackbarUtil.showWarning(context, 'Agrega al menos un producto al carrito para cobrar');
          return false;
        }
        if (_isLoadingSale) return false;
        double rawSubtotal = 0.0;
        for (final item in items) {
          if (item.isPaid) rawSubtotal += item.subtotal;
        }
        final finalTotal = (rawSubtotal - _discountAmount).clamp(0.0, double.infinity);
        _processSale(finalTotal, items);
        return true;
    }
  }

  bool _isAnyTextFieldFocused() {
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

  bool _handleCartShortcuts(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final key = event.logicalKey;
    final items = ref.read(cartProvider);
    final safeIdx = items.isEmpty ? 0 : _selectedCartItemIndex.clamp(0, items.length - 1);

    if (key == LogicalKeyboardKey.f3) {
      return _triggerCartShortcutAction(PosCartShortcutAction.selectClient);
    } else if (key == LogicalKeyboardKey.f4) {
      return _triggerCartShortcutAction(PosCartShortcutAction.parkSale);
    } else if (key == LogicalKeyboardKey.f6) {
      return _triggerCartShortcutAction(PosCartShortcutAction.editQuantity);
    } else if (key == LogicalKeyboardKey.f7) {
      return _triggerCartShortcutAction(PosCartShortcutAction.editPrice);
    } else if (key == LogicalKeyboardKey.f8) {
      return _triggerCartShortcutAction(PosCartShortcutAction.focusDiscount);
    } else if (key == LogicalKeyboardKey.f9) {
      return _triggerCartShortcutAction(PosCartShortcutAction.showHeldCarts);
    } else if (key == LogicalKeyboardKey.f10) {
      return _triggerCartShortcutAction(PosCartShortcutAction.cyclePaymentMethod);
    } else if (key == LogicalKeyboardKey.f12) {
      return _triggerCartShortcutAction(PosCartShortcutAction.checkout);
    }

    if (items.isEmpty) return false;

    // Alt + Flechas Arriba/Abajo selecciona producto en el carrito incluso si el buscador tiene foco
    if (HardwareKeyboard.instance.isAltPressed) {
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedCartItemIndex = (safeIdx - 1).clamp(0, items.length - 1);
        });
        return true;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedCartItemIndex = (safeIdx + 1).clamp(0, items.length - 1);
        });
        return true;
      }
    }

    if (_isAnyTextFieldFocused()) return false;

    if (key == LogicalKeyboardKey.numpadAdd || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.equal) {
      final target = items[safeIdx];
      final updated = ref.read(cartProvider.notifier).updateQuantity(target.id, target.quantity + 1);
      if (!updated && target.availableStock != null) {
        SnackbarUtil.showWarning(
          context,
          'Stock máximo alcanzado para ${target.productNameSnapshot} (${_formatQty(target.availableStock!)} disponibles)',
        );
      }
      return true;
    }

    if (key == LogicalKeyboardKey.numpadSubtract || key == LogicalKeyboardKey.minus) {
      final target = items[safeIdx];
      ref.read(cartProvider.notifier).updateQuantity(target.id, target.quantity - 1);
      return true;
    }

    if (key == LogicalKeyboardKey.delete) {
      final target = items[safeIdx];
      ref.read(cartProvider.notifier).removeItem(target.id);
      return true;
    }

    return false;
  }

  String _formatQty(double qty) {
    if (qty % 1 == 0) return qty.toInt().toString();
    return qty.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _parkCurrentCart(List<CreateSaleDetailInnerDto> cartItems) async {
    if (cartItems.isEmpty) return;
    final ticket = await HeldCartsService.parkCart(
      businessId: widget.businessId,
      items: cartItems,
      clientUserId: _selectedClientId,
      clientName: _clientNameController.text.trim().isEmpty ? 'Público General' : _clientNameController.text.trim(),
      discountAmount: _discountAmount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    ref.read(cartProvider.notifier).clearCart();
    setState(() {
      _clientNameController.text = 'Público General';
      _selectedClientId = null;
      _notesController.clear();
      _discountController.clear();
      _amountPaidController.clear();
    });

    if (mounted) {
      final totalHeld = HeldCartsService.forBusiness(widget.businessId).length;
      SnackbarUtil.showSuccess(context, 'Venta puesta en espera: ${ticket.label} ($totalHeld en espera)');
    }
  }

  Future<void> _restoreHeldTicket(HeldCartTicket ticket) async {
    final currentCart = ref.read(cartProvider);
    if (currentCart.isNotEmpty) {
      // Pausar automáticamente el carrito actual antes de restaurar el seleccionado para no perder nada
      await HeldCartsService.parkCart(
        businessId: widget.businessId,
        items: currentCart,
        clientUserId: _selectedClientId,
        clientName: _clientNameController.text.trim().isEmpty ? 'Público General' : _clientNameController.text.trim(),
        discountAmount: _discountAmount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    await HeldCartsService.removeTicket(ticket.id);
    ref.read(cartProvider.notifier).replaceCart(ticket.items);
    setState(() {
      _selectedClientId = ticket.clientUserId;
      _clientNameController.text = ticket.clientName;
      _discountController.text = ticket.discountAmount > 0 ? ticket.discountAmount.toStringAsFixed(2) : '';
      _notesController.text = ticket.notes ?? '';
      _amountPaidController.clear();
      _selectedCartItemIndex = ticket.items.isEmpty ? 0 : ticket.items.length - 1;
    });

    if (mounted) {
      SnackbarUtil.showSuccess(context, 'Ticket "${ticket.label}" recuperado al carrito');
    }
  }

  Future<void> _showHeldCartsDialog() async {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final timeFmt = DateFormat('hh:mm a');
    int selectedIdx = 0;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final tickets = HeldCartsService.forBusiness(widget.businessId);
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                NavigationService.pop(dialogContext);
                return KeyEventResult.handled;
              }
              if (tickets.isEmpty) return KeyEventResult.ignored;
              final safe = selectedIdx.clamp(0, tickets.length - 1);
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setDialogState(() => selectedIdx = (safe + 1).clamp(0, tickets.length - 1));
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setDialogState(() => selectedIdx = (safe - 1).clamp(0, tickets.length - 1));
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                final target = tickets[safe];
                NavigationService.pop(dialogContext);
                _restoreHeldTicket(target);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.delete) {
                HeldCartsService.removeTicket(tickets[safe].id);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ValueListenableBuilder<List<HeldCartTicket>>(
                    valueListenable: HeldCartsService.heldCartsNotifier,
                    builder: (context, allTickets, _) {
                      final tickets = allTickets.where((t) => t.businessId == widget.businessId).toList();
                      final currentCart = ref.read(cartProvider);
                      final safeIdx = tickets.isEmpty ? 0 : selectedIdx.clamp(0, tickets.length - 1);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.pause_circle_filled_rounded, color: Colors.amber.shade800, size: 24),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppText('Ventas en Espera (F9)', fontSize: 17, fontWeight: FontWeight.w800),
                                    AppText(
                                      tickets.isEmpty
                                          ? 'Puedes pausar múltiples ventas a la vez con F4'
                                          : '${tickets.length} ${tickets.length == 1 ? 'venta en espera' : 'ventas en espera'} • Usa ↑↓ y Enter para recuperar',
                                      fontSize: 12,
                                      color: AppColors.kNeutral600,
                                    ),
                                  ],
                                ),
                              ),
                              if (currentCart.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.kPrimaryColor,
                                      side: const BorderSide(color: AppColors.kPrimaryColor),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      await _parkCurrentCart(currentCart);
                                      setDialogState(() => selectedIdx = 0);
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Pausar actual (F4)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              IconButton(
                                onPressed: () => NavigationService.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded, color: AppColors.kNeutral500),
                              ),
                            ],
                          ),
                          const Gap(12),
                          const Divider(height: 1),
                          const Gap(12),
                          if (tickets.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.kNeutral400),
                                  Gap(10),
                                  AppText('Sin ventas en espera', fontWeight: FontWeight.w700, color: AppColors.kNeutral700),
                                  Gap(4),
                                  AppText(
                                    'Puedes pausar todas las ventas que necesites presionando "Pausar (F4)" para atender a varios clientes sin perder sus cuentas.',
                                    fontSize: 12,
                                    color: AppColors.kNeutral500,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: tickets.length,
                                separatorBuilder: (_, _) => const Gap(10),
                                itemBuilder: (context, idx) {
                                  final t = tickets[idx];
                                  final isHighlighted = idx == safeIdx;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setDialogState(() => selectedIdx = idx),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isHighlighted ? AppColors.kPrimary50.withValues(alpha: 0.45) : AppColors.kNeutral50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isHighlighted ? AppColors.kPrimaryColor : AppColors.kNeutral200,
                                          width: isHighlighted ? 1.8 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  AppText(t.label, fontWeight: FontWeight.w800, fontSize: 14),
                                                  const Gap(8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(color: AppColors.kNeutral200, borderRadius: BorderRadius.circular(6)),
                                                    child: AppText(timeFmt.format(t.createdAt), fontSize: 11, color: AppColors.kNeutral700),
                                                  ),
                                                ],
                                              ),
                                              AppText(currencyFmt.format(t.total), fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.kPrimaryColor),
                                            ],
                                          ),
                                          const Gap(6),
                                          Text(
                                            t.items.map((i) => '${_formatQty(i.quantity)}x ${i.productNameSnapshot}').join(', '),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppColors.kNeutral600),
                                          ),
                                          const Gap(10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: Colors.red.shade700),
                                                onPressed: () => HeldCartsService.removeTicket(t.id),
                                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                                label: const Text('Descartar (Supr)', style: TextStyle(fontSize: 12)),
                                              ),
                                              const Gap(8),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.kPrimaryColor,
                                                  foregroundColor: Colors.white,
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () async {
                                                  NavigationService.pop(dialogContext);
                                                  await _restoreHeldTicket(t);
                                                },
                                                icon: const Icon(Icons.play_arrow_rounded, size: 17),
                                                label: Text(
                                                  isHighlighted ? 'Recuperar (Enter ↵)' : 'Recuperar',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateCalculations() {
    setState(() {
      _discountAmount = double.tryParse(_discountController.text) ?? 0.0;
      _amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    });
  }

  // --- Modal to Select Client (Keyboard Searchable with Arrow Keys + Enter + Quick Create) ---
  void _openClientSelectorModal(List<BusinessClientModel> clients) {
    showClientSelectorDialog(
      context,
      businessId: widget.businessId,
      clients: clients,
      selectedClientId: _selectedClientId,
      onClientSelected: (clientId, fullName) {
        if (!mounted) return;
        setState(() {
          _selectedClientId = clientId;
          _clientNameController.text = fullName;
        });
      },
      onClientCreated: () {
        ref.invalidate(businessClientsProvider(widget.businessId));
        ref.invalidate(clientsDebtListProvider(widget.businessId));
        SnackbarUtil.showSuccess(context, 'Cliente creado y seleccionado');
      },
    );
  }

  // --- Dialog to Prompt Amount Paid if empty ---
  Future<bool> _showAmountPaidDialog(double finalTotal) async {
    final TextEditingController dialogAmountController = TextEditingController(text: finalTotal.toStringAsFixed(2));
    dialogAmountController.selection = TextSelection(baseOffset: 0, extentOffset: dialogAmountController.text.length);
    bool confirmed = false;

    final List<double> quickBills = <double>[50, 100, 200, 500, 1000].where((b) => b >= finalTotal).toList();

    void confirmAmount(BuildContext dialogCtx) {
      final paid = double.tryParse(dialogAmountController.text);
      if (paid != null && paid >= finalTotal) {
        setState(() {
          _amountPaidController.text = paid.toStringAsFixed(2);
          _amountPaid = paid;
        });
        confirmed = true;
        NavigationService.pop(dialogCtx);
      } else {
        SnackbarUtil.showWarning(context, 'El monto recibido no puede ser menor al total');
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final currentPaid = double.tryParse(dialogAmountController.text) ?? 0.0;
          final changePreview = (currentPaid - finalTotal).clamp(0.0, double.infinity);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const AppText('Monto Recibido', fontWeight: FontWeight.bold, fontSize: 18),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText('Total a cobrar:', fontSize: 14, color: AppColors.kNeutral600),
                      AppText('\$${finalTotal.toStringAsFixed(2)}', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kPrimaryColor),
                    ],
                  ),
                  const Gap(14),
                  TextField(
                    controller: dialogAmountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    onSubmitted: (_) => confirmAmount(dialogCtx),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      labelText: '¿Con cuánto paga el cliente?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Exacto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.kPrimary50,
                        side: BorderSide(color: AppColors.kPrimaryColor.withValues(alpha: 0.3)),
                        onPressed: () {
                          dialogAmountController.text = finalTotal.toStringAsFixed(2);
                          setDialogState(() {});
                        },
                      ),
                      ...quickBills.map(
                        (bill) => ActionChip(
                          label: Text('\$${bill.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          backgroundColor: AppColors.kNeutral100,
                          side: const BorderSide(color: AppColors.kNeutral300),
                          onPressed: () {
                            dialogAmountController.text = bill.toStringAsFixed(2);
                            setDialogState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  if (currentPaid >= finalTotal) ...[
                    const Gap(14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.kSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.kSuccess.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('Cambio a entregar:', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kNeutral800),
                          AppText('\$${changePreview.toStringAsFixed(2)}', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kSuccess),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  NavigationService.pop(dialogCtx);
                  final mixedOk = await _showMixedPaymentDialog(finalTotal);
                  if (mixedOk) {
                    confirmed = true;
                  }
                },
                icon: const Icon(Icons.call_split_rounded, size: 17, color: AppColors.kPrimaryColor),
                label: const Text(
                  'Pago Mixto',
                  style: TextStyle(color: AppColors.kPrimaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => NavigationService.pop(dialogCtx),
                child: const AppText('Cancelar', color: AppColors.kNeutral600),
              ),
              ElevatedButton(
                onPressed: () => confirmAmount(dialogCtx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                child: const Text(
                  'Confirmar & Cobrar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return confirmed;
  }

  // --- Dialog for Mixed / Split Payments ---
  Future<bool> _showMixedPaymentDialog(double finalTotal) async {
    final methods = ref.read(paymentMethodsProvider).value ?? const [];
    if (methods.isEmpty) {
      SnackbarUtil.showWarning(context, 'No hay métodos de pago disponibles');
      return false;
    }

    final List<({String methodId, TextEditingController amountCtrl})> rows = [];
    if (_mixedPayments.isNotEmpty) {
      for (final p in _mixedPayments) {
        rows.add((
          methodId: methods.any((m) => m.id == p.paymentMethodId) ? p.paymentMethodId : methods.first.id,
          amountCtrl: TextEditingController(text: p.amount.toStringAsFixed(2)),
        ));
      }
    } else {
      final firstId = _selectedPaymentMethodId ?? methods.first.id;
      final secondMethod = methods.firstWhere(
        (m) => m.id != firstId,
        orElse: () => methods.first,
      );
      rows.add((methodId: firstId, amountCtrl: TextEditingController()));
      rows.add((methodId: secondMethod.id, amountCtrl: TextEditingController()));
    }

    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          double totalEntered = 0.0;
          for (final r in rows) {
            totalEntered += double.tryParse(r.amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
          }
          final remaining = (finalTotal - totalEntered).clamp(0.0, double.infinity);
          final change = (totalEntered - finalTotal).clamp(0.0, double.infinity);

          void fillRemaining(int rowIndex) {
            double otherSum = 0.0;
            for (int i = 0; i < rows.length; i++) {
              if (i != rowIndex) {
                otherSum += double.tryParse(rows[i].amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
              }
            }
            final needed = (finalTotal - otherSum).clamp(0.0, double.infinity);
            rows[rowIndex].amountCtrl.text = needed.toStringAsFixed(2);
            setDialogState(() {});
          }

          void submitMixed() {
            final List<CreateSalePaymentDto> valid = [];
            for (final r in rows) {
              final amt = double.tryParse(r.amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
              if (amt > 0) {
                final methodName = methods.firstWhere((m) => m.id == r.methodId, orElse: () => methods.first).name;
                valid.add(
                  CreateSalePaymentDto(
                    paymentMethodId: r.methodId,
                    amount: amt,
                    paymentMethodName: methodName,
                  ),
                );
              }
            }

            if (valid.isEmpty) {
              SnackbarUtil.showWarning(context, 'Ingresa al menos un monto mayor a 0');
              return;
            }
            final sum = valid.fold(0.0, (s, p) => s + p.amount);
            if (_selectedSaleStatus == 'COMPLETED' && sum + 0.001 < finalTotal) {
              SnackbarUtil.showWarning(context, 'La suma de los pagos (\$${sum.toStringAsFixed(2)}) es menor al total (\$${finalTotal.toStringAsFixed(2)})');
              return;
            }

            setState(() {
              _mixedPayments = valid;
              _selectedPaymentMethodId = valid.first.paymentMethodId;
              _amountPaidController.text = sum.toStringAsFixed(2);
              _amountPaid = sum;
            });
            confirmed = true;
            NavigationService.pop(dialogCtx);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.call_split_rounded, color: AppColors.kPrimaryColor, size: 24),
                Gap(10),
                Expanded(
                  child: AppText('Pago Mixto / Dividir Cobro', fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary50.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('Total a cobrar:', fontSize: 13.5, fontWeight: FontWeight.w700),
                          AppText(
                            '\$${finalTotal.toStringAsFixed(2)}',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kPrimaryColor,
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    ...List.generate(rows.length, (idx) {
                      final row = rows[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: DropdownButtonFormField<String>(
                                initialValue: row.methodId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Método ${idx + 1}',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      rows[idx] = (methodId: val, amountCtrl: row.amountCtrl);
                                    });
                                  }
                                },
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: row.amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  labelText: 'Monto',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const Gap(4),
                            Tooltip(
                              message: 'Completar restante',
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.auto_fix_high_rounded, size: 18, color: AppColors.kPrimaryColor),
                                onPressed: () => fillRemaining(idx),
                              ),
                            ),
                            if (rows.length > 1)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    final removed = rows.removeAt(idx);
                                    removed.amountCtrl.dispose();
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            rows.add((methodId: methods.first.id, amountCtrl: TextEditingController()));
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('Agregar otro método de pago'),
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText('Suma capturada:', fontSize: 13, color: AppColors.kNeutral700),
                        AppText('\$${totalEntered.toStringAsFixed(2)}', fontSize: 15, fontWeight: FontWeight.w800),
                      ],
                    ),
                    const Gap(6),
                    if (remaining > 0.001)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('Falta por cubrir:', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
                          AppText('\$${remaining.toStringAsFixed(2)}', fontSize: 15, fontWeight: FontWeight.w800, color: Colors.orange),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('Cambio a entregar:', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kSuccess),
                          AppText('\$${change.toStringAsFixed(2)}', fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.kSuccess),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => NavigationService.pop(dialogCtx),
                child: const AppText('Cancelar', color: AppColors.kNeutral600),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                onPressed: submitMixed,
                child: const Text(
                  'Aplicar Pago Mixto',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    for (final r in rows) {
      r.amountCtrl.dispose();
    }

    return confirmed;
  }

  // --- Dialog to Edit Item Quantity (Enforces Integer for Piece vs. Decimals for Bulk / Common Product) ---
  Future<void> _showEditQuantityDialog(CreateSaleDetailInnerDto item) async {
    final bool allowsFractions = item.allowFractions || item.isCommonProduct;
    final TextEditingController qtyController = TextEditingController(text: _formatQty(item.quantity));
    qtyController.selection = TextSelection(baseOffset: 0, extentOffset: qtyController.text.length);

    final List<double> presets = allowsFractions
        ? <double>[0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 5.0, 10.0]
        : <double>[1.0, 2.0, 3.0, 5.0, 10.0, 12.0];

    void applyQty(BuildContext dialogCtx) {
      final newQty = double.tryParse(qtyController.text.trim().replaceAll(',', '.'));
      if (newQty == null || newQty <= 0) {
        SnackbarUtil.showWarning(context, 'Ingresa una cantidad mayor a 0');
        return;
      }
      if (!allowsFractions && newQty % 1 != 0) {
        SnackbarUtil.showWarning(
          context,
          'Este producto se vende por pieza cerrada y solo permite cantidades en números enteros',
        );
        return;
      }
      final updated = ref.read(cartProvider.notifier).updateQuantity(item.id, newQty);
      if (!updated && item.availableStock != null) {
        SnackbarUtil.showWarning(
          context,
          'Stock máximo disponible: ${_formatQty(item.availableStock!)}',
        );
        return;
      }
      NavigationService.pop(dialogCtx);
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: AppText(
          allowsFractions ? 'Cambiar Cantidad / Peso (F6)' : 'Cambiar Cantidad en Piezas (F6)',
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(item.productNameSnapshot, fontSize: 13.5, color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
            if (item.availableStock != null && !item.isCommonProduct) ...[
              const Gap(4),
              AppText(
                'Stock disponible: ${_formatQty(item.availableStock!)}',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.kPrimaryColor,
              ),
            ],
            const Gap(6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: allowsFractions ? AppColors.kPrimary50 : AppColors.kNeutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: AppText(
                allowsFractions
                    ? 'Admite fracciones / decimales (granel o producto común)'
                    : 'Producto por pieza cerrada: solo números enteros',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: allowsFractions ? AppColors.kPrimaryColor : AppColors.kNeutral700,
              ),
            ),
            const Gap(12),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: allowsFractions),
              onSubmitted: (_) => applyQty(dialogCtx),
              decoration: InputDecoration(
                labelText: allowsFractions ? 'Cantidad (ej. 0.5, 1.25, 12)' : 'Cantidad en piezas enteras (ej. 1, 2, 5)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Gap(10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: presets.map((preset) {
                final label = _formatQty(preset);
                return ActionChip(
                  label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.kNeutral100,
                  onPressed: () {
                    qtyController.text = label;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(dialogCtx),
            child: const AppText('Cancelar', color: AppColors.kNeutral600),
          ),
          ElevatedButton(
            onPressed: () => applyQty(dialogCtx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
            child: const Text(
              'Actualizar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialog to Edit Item Price ---
  Future<void> _showEditPriceDialog(CreateSaleDetailInnerDto item) async {
    final TextEditingController priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    priceController.selection = TextSelection(baseOffset: 0, extentOffset: priceController.text.length);

    void submitPrice(BuildContext dialogContext) {
      final newPrice = double.tryParse(priceController.text.replaceAll(',', '.'));
      if (newPrice != null && newPrice >= 0) {
        ref.read(cartProvider.notifier).updateUnitPrice(item.id, newPrice);
      }
      NavigationService.pop(dialogContext);
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText('Editar Precio (F7)', fontWeight: FontWeight.bold, fontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(item.productNameSnapshot, fontSize: 14, color: AppColors.kNeutral600),
            const Gap(12),
            TextField(
              controller: priceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => submitPrice(dialogContext),
              decoration: InputDecoration(
                prefixText: '\$ ',
                labelText: 'Nuevo Precio Unitario',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(dialogContext),
            child: const AppText('Cancelar (Esc)', color: AppColors.kNeutral600),
          ),
          ElevatedButton(
            onPressed: () => submitPrice(dialogContext),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
            child: const Text('Guardar (Enter)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Ticket Preview Dialog ---
  void _showTicketDialog(BuildContext context, SaleModel sale, {bool isOfflineQueued = false}) {
    bool isPrinting = false;
    String? printerFeedbackMessage;
    bool isPrinterError = false;

    Future<void> openPrinterSelectorFromDialog(BuildContext dialogContext, StateSetter setDialogState) async {
      final printerService = ref.read(printerServiceProvider);
      await printerService.showPrinterSelectionModal(dialogContext);
      ref.invalidate(hasSavedPrinterProvider);

      final selectedPrinter = await printerService.getSavedPrinter();
      if (dialogContext.mounted && selectedPrinter != null) {
        setDialogState(() {
          isPrinterError = false;
          printerFeedbackMessage = 'Impresora "${selectedPrinter.device.name}" vinculada. Ya puedes imprimir el ticket.';
        });
      }
    }

    void closeAndReset(BuildContext dialogContext) {
      NavigationService.pop(dialogContext); // Close the dialog
      ref.read(cartProvider.notifier).clearCart();

      // Clean up the checkout form fields
      setState(() {
        _selectedSellerId = null;
        _clientNameController.text = 'Público General';
        _selectedClientId = null;
        _selectedSaleStatus = 'COMPLETED';
        _notesController.clear();
        _discountController.clear();
        _amountPaidController.clear();
        _mixedPayments = [];
      });

      // Invalidate caches to keep entire POS, accounts and inventory synchronized
      if (!isOfflineQueued) {
        ref.invalidate(salesListProvider(widget.businessId));
        ref.invalidate(accountsBusinessProvider(businessId: widget.businessId));
        ref.invalidate(transactionsListProvider);
        ref.invalidate(productsListProvider(widget.businessId));
        ref.invalidate(clientsDebtListProvider(widget.businessId));
        ref.invalidate(pendingSalesProvider);
        ref.invalidate(cashShiftsProvider(widget.businessId));
      }
      ref.invalidate(posCatalogProvider(widget.businessId));

      // On mobile/tablet where CartScreen was pushed as a separate page, pop back to POS catalog
      if (ModalRoute.of(context)?.settings.name == Routes.cart) {
        NavigationService.pop(context);
      }
    }

    Future<void> triggerPrint(BuildContext dialogContext, StateSetter setDialogState) async {
      if (isPrinting) return;
      setDialogState(() {
        isPrinting = true;
        printerFeedbackMessage = null;
      });

      final printerService = ref.read(printerServiceProvider);
      final savedPrinter = await printerService.getSavedPrinter();

      if (savedPrinter == null) {
        if (context.mounted) {
          SnackbarUtil.showWarning(context, 'Selecciona una impresora primero desde el botón de impresora.');
        }
        if (dialogContext.mounted) {
          setDialogState(() {
            isPrinting = false;
            isPrinterError = true;
            printerFeedbackMessage =
                'Selecciona una impresora primero usando el botón de impresora en la esquina superior de esta ventana o "Agregar Impresora".';
          });
        }
        return;
      }

      final document = sale.toObjectToPrint(businessName: widget.businessName, openDrawer: false);

      final success = await printerService.printDocument(savedPrinter, document);
      if (dialogContext.mounted) {
        setDialogState(() {
          isPrinting = false;
          isPrinterError = !success;
          printerFeedbackMessage = success
              ? 'Ticket enviado a la impresora. Puedes volver a imprimir si necesitas otra copia.'
              : 'No se pudo conectar con la impresora seleccionada. Verifica su conexión o cámbiala desde el botón superior.';
        });
      }
      if (!success && context.mounted) {
        SnackbarUtil.showError(context, 'No se pudo conectar con la impresora seleccionada. Verifica su conexión o cámbiala desde el botón de impresora.');
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, _) {
          final hasPrinterAsync = dialogRef.watch(hasSavedPrinterProvider);
          final hasPrinter = hasPrinterAsync.value ?? false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) => Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.escape) {
                  closeAndReset(dialogContext);
                  return KeyEventResult.handled;
                }
                if (key == LogicalKeyboardKey.f11) {
                  triggerPrint(dialogContext, setDialogState);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isOfflineQueued ? Icons.cloud_upload_rounded : Icons.check_circle,
                            color: isOfflineQueued ? const Color(0xFFD97706) : AppColors.kSuccess,
                            size: 28,
                          ),
                          const Gap(8),
                          Flexible(
                            child: AppText(isOfflineQueued ? 'Venta Guardada Sin Internet' : '¡Venta Exitosa!', fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(color: AppColors.kSecondaryColor, borderRadius: BorderRadius.circular(10)),
                          child: IconButton(
                            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Abrir Cajón',
                            icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
                            onPressed: () async {
                              final printerService = ref.read(printerServiceProvider);
                              final savedPrinter = await printerService.getSavedPrinter();
                              if (savedPrinter == null) {
                                if (dialogContext.mounted) {
                                  setDialogState(() {
                                    isPrinterError = true;
                                    printerFeedbackMessage = 'Selecciona una impresora primero usando el botón de impresora o "Agregar Impresora".';
                                  });
                                }
                                return;
                              }
                              final opened = await printerService.openCashDrawerOnly();
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  isPrinterError = !opened;
                                  printerFeedbackMessage = opened
                                      ? 'Señal enviada para abrir el cajón.'
                                      : 'No se pudo conectar con la impresora para abrir el cajón.';
                                });
                              }
                            },
                          ),
                        ),
                        const Gap(6),
                        Container(
                          decoration: BoxDecoration(color: hasPrinter ? Colors.red : AppColors.kPrimaryColor, borderRadius: BorderRadius.circular(10)),
                          child: IconButton(
                            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                            padding: const EdgeInsets.all(8),
                            tooltip: hasPrinter ? 'Desvincular Impresora' : 'Agregar Impresora',
                            icon: Icon(hasPrinter ? Icons.print_disabled_rounded : Icons.print_rounded, color: Colors.white, size: 20),
                            onPressed: () async {
                              if (hasPrinter) {
                                await showDialog(
                                  context: dialogContext,
                                  builder: (confirmContext) => AlertDialog(
                                    title: const AppText('Eliminar impresora seleccionada', fontWeight: FontWeight.bold),
                                    content: const AppText('¿Estás seguro de que deseas eliminar la impresora seleccionada?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => NavigationService.pop(confirmContext),
                                        child: const AppText('Cancelar', color: AppColors.kNeutral600),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          NavigationService.pop(confirmContext);
                                          await ref.read(printerServiceProvider).clearSavedPrinter();
                                          ref.invalidate(hasSavedPrinterProvider);
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              isPrinterError = true;
                                              printerFeedbackMessage = 'Impresora desvinculada.';
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                await openPrinterSelectorFromDialog(dialogContext, setDialogState);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOfflineQueued) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.wifi_off_rounded, color: Color(0xFF92400E), size: 18),
                                Gap(8),
                                Expanded(
                                  child: Text(
                                    'Sin conexión a internet: Esta venta se guardó de forma segura en el dispositivo y se sincronizará sola en cuanto regrese el internet.',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        AppText('Folio ID: ${sale.id}', fontSize: 12, color: AppColors.kNeutral600),
                        AppText('Estatus: ${sale.status}', fontSize: 12, color: AppColors.kNeutral600),
                        AppText('Vendedor: ${sale.sellerName ?? 'N/D'}', fontSize: 12, color: AppColors.kNeutral600),
                        AppText('Cliente: ${sale.clientNameSnapshot}', fontSize: 12, color: AppColors.kNeutral600),
                        const Divider(height: 20),
                        const AppText('Resumen de Productos:', fontWeight: FontWeight.bold, fontSize: 14),
                        const Gap(8),
                        ...sale.details.map((detail) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_formatQty(detail.quantity)}x ${detail.productNameSnapshot} ${!detail.isPaid ? '(No pagado)' : ''}',
                                    style: TextStyle(fontSize: 13, color: !detail.isPaid ? Colors.orange : Colors.black),
                                  ),
                                ),
                                Text(
                                  '\$${(detail.productPriceSnapshot * detail.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText('Total Cobrado:', fontWeight: FontWeight.bold),
                            AppText(
                              '\$${sale.totalPriceSnapshot.toStringAsFixed(2)}',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.kPrimaryColor,
                            ),
                          ],
                        ),
                        if (sale.payments.length > 1) ...[
                          const Gap(8),
                          const AppText('Desglose de Pagos:', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kNeutral700),
                          const Gap(4),
                          ...sale.payments.map(
                            (p) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText('• ${p.paymentMethodName}', fontSize: 12, color: AppColors.kNeutral700),
                                AppText('\$${p.amount.toStringAsFixed(2)}', fontSize: 12, fontWeight: FontWeight.w700),
                              ],
                            ),
                          ),
                        ],
                        const Gap(4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const AppText('Efectivo Recibido:'), AppText('\$${sale.amountPaid?.toStringAsFixed(2) ?? '0.00'}')],
                        ),
                        const Gap(4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText('Cambio Devuelto:', fontWeight: FontWeight.bold, color: AppColors.kSuccess),
                            AppText('\$${sale.changeGiven?.toStringAsFixed(2) ?? '0.00'}', fontWeight: FontWeight.bold, color: AppColors.kSuccess),
                          ],
                        ),
                        if (printerFeedbackMessage != null) ...[
                          const Gap(14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPrinterError ? Colors.orange.withValues(alpha: 0.12) : AppColors.kSuccess.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isPrinterError ? Colors.orange : AppColors.kSuccess),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isPrinterError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                      size: 18,
                                      color: isPrinterError ? Colors.orange.shade800 : AppColors.kSuccess,
                                    ),
                                    const Gap(8),
                                    Expanded(
                                      child: Text(
                                        printerFeedbackMessage!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isPrinterError ? Colors.orange.shade900 : AppColors.kNeutral800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isPrinterError && !hasPrinter) ...[
                                  const Gap(8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => openPrinterSelectorFromDialog(dialogContext, setDialogState),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.kPrimaryColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                      label: const Text('Agregar Impresora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => PdfReceiptService.showSalePdfPreviewDialog(
                      context: dialogContext,
                      sale: sale,
                      fallbackBusinessName: widget.businessName,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('PDF / WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isPrinting ? null : () => triggerPrint(dialogContext, setDialogState),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kPrimaryColor,
                      side: const BorderSide(color: AppColors.kPrimaryColor),
                    ),
                    icon: isPrinting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Imprimir (F11)'),
                  ),
                  ElevatedButton(
                    onPressed: () => closeAndReset(dialogContext),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                    child: const Text('Aceptar (Enter)', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showQuickOpenShiftDialog() async {
    final amountCtrl = TextEditingController(text: '0.00');
    String? selectedAccountId;
    bool opened = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (ctx, dialogRef, _) {
          final accountsAsync = dialogRef.watch(accountsBusinessProvider(businessId: widget.businessId));
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: AppColors.kPrimaryColor),
                  Gap(10),
                  Expanded(child: AppText('Abre tu Turno de Caja', fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Para registrar ventas es obligatorio tener tu turno de caja abierto. Selecciona la caja/cuenta del turno e ingresa tu fondo inicial:',
                    fontSize: 13,
                    color: AppColors.kNeutral600,
                  ),
                  const Gap(14),
                  accountsAsync.when(
                    data: (accounts) {
                      final operationalAccounts = accounts.where((a) => !a.isCreditOrLoan).toList();
                      final selectable = operationalAccounts.isNotEmpty ? operationalAccounts : accounts;
                      if (selectedAccountId == null && selectable.isNotEmpty) {
                        final defaultAcc = selectable.firstWhere((a) => a.isDefault, orElse: () => selectable.first);
                        selectedAccountId = defaultAcc.id;
                      }
                      if (selectable.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedAccountId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Caja / Cuenta del Turno',
                            prefixIcon: const Icon(Icons.point_of_sale_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: selectable
                              .map(
                                (a) => DropdownMenuItem<String>(
                                  value: a.id,
                                  child: Text(a.isDefault ? '${a.name} (Principal)' : a.name, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedAccountId = val);
                          },
                        ),
                      );
                    },
                    loading: () => const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      labelText: 'Fondo Inicial en Efectivo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => NavigationService.pop(dialogContext),
                  child: const AppText('Cancelar', color: AppColors.kNeutral600),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                  onPressed: () async {
                    final parsed = double.tryParse(amountCtrl.text.trim());
                    if (parsed == null || parsed < 0) {
                      SnackbarUtil.showWarning(context, 'Ingresa un monto inicial válido mayor o igual a 0.');
                      return;
                    }
                    NavigationService.pop(dialogContext);
                    final error = await ref.read(cashShiftsProvider(widget.businessId).notifier).openShift(openingAmount: parsed, accountId: selectedAccountId);
                    if (!mounted) return;
                    if (error != null) {
                      SnackbarUtil.showError(context, error);
                    } else {
                      if (selectedAccountId != null) {
                        _selectedAccountId = selectedAccountId;
                      }
                      opened = true;
                      SnackbarUtil.showSuccess(context, 'Turno de caja abierto. Procesando venta...');
                    }
                  },
                  child: const Text(
                    'Abrir Caja y Cobrar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return opened;
  }

  // --- Process Sale Action ---
  Future<void> _processSale(double finalTotal, List<CreateSaleDetailInnerDto> cartItems) async {
    _selectedSellerId ??= SecureStorageService.getString(AppConfig.uuidKey);

    if (_selectedAccountId == null || _selectedPaymentMethodId == null || _selectedSellerId == null) {
      SnackbarUtil.showWarning(context, 'Selecciona vendedor, método de pago y cuenta destino');
      return;
    }

    final clientNameLower = _clientNameController.text.trim().toLowerCase();
    final isGeneralPublic = clientNameLower.isEmpty || clientNameLower == 'público general' || clientNameLower == 'publico general';

    if ((_selectedSaleStatus == 'CREDIT' || _selectedSaleStatus == 'LAYAWAY') && (_selectedClientId == null || _selectedClientId!.isEmpty || isGeneralPublic)) {
      SnackbarUtil.showWarning(context, 'Para ventas a crédito o apartado, debes seleccionar un cliente registrado (no Público General).');
      return;
    }

    // If amount paid is empty for a completed sale, pop up the quick dialog automatically
    if (_amountPaid <= 0 && _selectedSaleStatus == 'COMPLETED') {
      final bool paidConfirmed = await _showAmountPaidDialog(finalTotal);
      if (!paidConfirmed) return; // Cancelled by user
    } else if (_mixedPayments.isNotEmpty && _amountPaid + 0.001 < finalTotal && _selectedSaleStatus == 'COMPLETED') {
      final bool mixedAdjusted = await _showMixedPaymentDialog(finalTotal);
      if (!mixedAdjusted) return;
    }

    if (_amountPaid > 0 && _amountPaid < finalTotal && _selectedSaleStatus == 'COMPLETED') {
      if (!mounted) return;
      SnackbarUtil.showWarning(context, 'El monto pagado es menor al total en venta completada');
      return;
    }

    setState(() => _isLoadingSale = true);

    try {
      final clientNameToUse = _clientNameController.text.trim().isEmpty ? 'Público General' : _clientNameController.text.trim();
      final saleTimestamp = DateTime.now();

      // 1. Instanciamos el DTO unificado (incluyendo soldAt y pagos mixtos si aplican)
      final salePayload = CreateSaleDto(
        businessId: widget.businessId,
        sellerUserId: _selectedSellerId!,
        accountId: _selectedAccountId!,
        paymentMethodId: _mixedPayments.isNotEmpty ? _mixedPayments.first.paymentMethodId : _selectedPaymentMethodId!,
        clientUserId: _selectedClientId,
        clientNameSnapshot: clientNameToUse,
        status: _selectedSaleStatus,
        discountAmount: _discountAmount,
        amountPaid: _amountPaid > 0 ? _amountPaid : (_selectedSaleStatus == 'COMPLETED' ? finalTotal : 0.0),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        soldAt: saleTimestamp,
        details: cartItems,
        payments: _mixedPayments.isNotEmpty ? List<CreateSalePaymentDto>.from(_mixedPayments) : null,
      );

      // 2. Lo enviamos al servicio
      final saleResult = await CartService.createSale(salePayload);

      if (!mounted) return;

      // 3. Handle success and failure using EitherUtil pattern
      saleResult.when(
        (failure) async {
          if (!mounted) return;
          if (failure.type == AppFailure.cashShiftRequiredForSale.toCode() || failure.message == AppFailure.cashShiftRequiredForSale.message) {
            final opened = await _showQuickOpenShiftDialog();
            if (opened && mounted) {
              await _processSale(finalTotal, cartItems);
            }
            return;
          }

          // 🌐 Si no hay internet o hay timeout de red, guardar en la Cola de Ventas Offline de Isar
          if (OfflineSalesQueueService.isOfflineOrTimeoutFailure(failure)) {
            final sellers = ref.read(businessSellersProvider(widget.businessId)).value;
            final matchedSeller = sellers?.where((s) => s.userId == _selectedSellerId).firstOrNull;
            final sellerDisplayName = matchedSeller != null ? '${matchedSeller.firstName} ${matchedSeller.lastName}' : 'Cajero';

            final pending = await OfflineSalesQueueService.enqueueSale(dto: salePayload, businessName: widget.businessName, sellerName: sellerDisplayName);

            await ref.read(printerServiceProvider).openCashDrawerOnly();
            if (!mounted) return;

            ref.read(cartProvider.notifier).clearCart();
            ref.invalidate(posCatalogProvider(widget.businessId));
            _showTicketDialog(context, pending.previewSale, isOfflineQueued: true);
            return;
          }

          SnackbarUtil.showError(context, 'Error al procesar la venta: ${failure.message}');
        },
        (saleResponse) async {
          // Intentar abrir el cajón silenciosamente (sin imprimir ticket y sin mostrar avisos)
          await ref.read(printerServiceProvider).openCashDrawerOnly();

          if (!mounted) return;

          // Limpiar carrito y mostrar modal de UI desde donde puede imprimir las veces que desee
          ref.read(cartProvider.notifier).clearCart();
          ref.invalidate(cashShiftsProvider(widget.businessId));
          ref.invalidate(accountsBusinessProvider(businessId: widget.businessId));
          ref.invalidate(clientsDebtListProvider(widget.businessId));
          ref.invalidate(pendingSalesProvider);
          _showTicketDialog(context, saleResponse);
        },
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtil.showError(context, 'Error inesperado al procesar la venta');
    } finally {
      if (mounted) setState(() => _isLoadingSale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    if (cartItems.length != _lastCartLength) {
      _lastCartLength = cartItems.length;
      if (cartItems.isNotEmpty) {
        _selectedCartItemIndex = cartItems.length - 1;
      } else {
        _selectedCartItemIndex = 0;
      }
    }
    final safeCartIdx = cartItems.isEmpty ? 0 : _selectedCartItemIndex.clamp(0, cartItems.length - 1);

    double rawSubtotal = 0.0;
    double totalItemsCount = 0;
    for (var item in cartItems) {
      totalItemsCount += item.quantity;
      if (item.isPaid) {
        rawSubtotal += item.subtotal;
      }
    }

    final accountsAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final sellersAsync = ref.watch(businessSellersProvider(widget.businessId));
    final clientsAsync = ref.watch(businessClientsProvider(widget.businessId));
    final cashShiftsState = ref.watch(cashShiftsProvider(widget.businessId));
    final isAdmin = ref.watch(isBusinessAdminProvider(widget.businessId));

    final finalTotal = (rawSubtotal - _discountAmount).clamp(0.0, double.infinity);
    final changeGiven = (_amountPaid > finalTotal) ? (_amountPaid - finalTotal) : 0.0;

    if (cartItems.isEmpty) {
      return Column(
        children: [
          ValueListenableBuilder<List<HeldCartTicket>>(
            valueListenable: HeldCartsService.heldCartsNotifier,
            builder: (context, allTickets, _) {
              final held = allTickets.where((t) => t.businessId == widget.businessId).toList();
              if (held.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade600.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_filled_rounded, color: Colors.amber.shade900, size: 20),
                    const Gap(8),
                    Expanded(
                      child: AppText(
                        '${held.length} ${held.length == 1 ? 'venta en espera' : 'ventas en espera'}',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber.shade900,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showHeldCartsDialog,
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Recuperar (F9)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined, size: 80, color: AppColors.kNeutral400),
                  Gap(16),
                  AppText('El carrito está vacío', fontSize: 18, color: AppColors.kNeutral600),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // 1. PRODUCTS LIST (Scrollable)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: AppText('Productos en Ticket', fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<List<HeldCartTicket>>(
                        valueListenable: HeldCartsService.heldCartsNotifier,
                        builder: (context, allTickets, _) {
                          final heldCount = allTickets.where((t) => t.businessId == widget.businessId).length;
                          if (heldCount == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _showHeldCartsDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade600.withValues(alpha: 0.45)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restore_rounded, size: 14, color: Colors.amber.shade900),
                                    const Gap(4),
                                    Text(
                                      'Espera ($heldCount) [F9]',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Tooltip(
                        message: 'Poner venta actual en espera (puedes pausar múltiples ventas a la vez) [F4]',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _parkCurrentCart(cartItems),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.kPrimary50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pause_rounded, size: 14, color: AppColors.kPrimaryColor),
                                Gap(4),
                                Text(
                                  'Pausar (F4)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kPrimaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(6),
                      Tooltip(
                        message: 'Vaciar carrito',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => ref.read(cartProvider.notifier).clearCart(),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(12),
              ...cartItems.asMap().entries.map((entry) => _buildCartItem(entry.value, index: entry.key, isSelected: entry.key == safeCartIdx)),

              const Gap(24),
              const Divider(color: AppColors.kNeutral300),
              const Gap(16),

              // 2. CHECKOUT FORM
              AppText('Detalles del Cobro', fontWeight: FontWeight.bold, fontSize: 16),
              const Gap(16),

              // Seller Dropdown (Visible only to Business Admins; regular Sellers automatically use their own user)
              sellersAsync.when(
                data: (sellers) {
                  final currentUserId = SecureStorageService.getString(AppConfig.uuidKey);
                  final currentUserAsSeller = currentUserId != null ? sellers.where((s) => s.userId == currentUserId).firstOrNull : null;
                  final isCurrentUserAdmin = isAdmin || (currentUserAsSeller?.roles.any((r) => r.name.toUpperCase() == 'ADMIN') ?? false);

                  if (!isCurrentUserAdmin) {
                    _selectedSellerId = currentUserId ?? currentUserAsSeller?.userId ?? (sellers.isNotEmpty ? sellers.first.userId : null);
                    return const SizedBox.shrink();
                  }

                  if ((_selectedSellerId == null || !sellers.any((s) => s.userId == _selectedSellerId)) && sellers.isNotEmpty) {
                    _selectedSellerId = currentUserAsSeller?.userId ?? sellers.first.userId;
                  }
                  final itemsMap = {for (var s in sellers) s.userId: '${s.firstName} ${s.lastName}'};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDropdown(
                      label: 'Vendedor (Modo Administrador)',
                      icon: Icons.person_outline,
                      value: _selectedSellerId,
                      items: itemsMap,
                      onChanged: (val) => setState(() => _selectedSellerId = val),
                    ),
                  );
                },
                loading: () => isAdmin ? const LinearProgressIndicator() : const SizedBox.shrink(),
                error: (_, _) => isAdmin ? const Text('Error al cargar vendedores') : const SizedBox.shrink(),
              ),

              // Client Selector
              clientsAsync.when(
                data: (clients) {
                  if (_selectedClientId == null && clients.isNotEmpty) {
                    final generalPublicClient = clients.firstWhere(
                      (c) =>
                          '${c.firstName} ${c.lastName}'.toLowerCase().contains('público general') ||
                          '${c.firstName} ${c.lastName}'.toLowerCase().contains('publico general'),
                      orElse: () => clients.first,
                    );

                    _selectedClientId = generalPublicClient.userId;
                    if (_clientNameController.text.isEmpty || _clientNameController.text == 'Público General') {
                      _clientNameController.text = '${generalPublicClient.firstName} ${generalPublicClient.lastName}';
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(controller: _clientNameController, label: 'Cliente (F3)', icon: Icons.person_outline),
                          ),
                          const Gap(8),
                          Builder(
                            builder: (context) {
                              final nameLower = _clientNameController.text.trim().toLowerCase();
                              final isCustomClient = nameLower.isNotEmpty && nameLower != 'público general' && nameLower != 'publico general';

                              return IconButton(
                                icon: Icon(isCustomClient ? Icons.close : Icons.search, color: isCustomClient ? Colors.red : AppColors.kPrimaryColor),
                                tooltip: isCustomClient ? 'Volver a Público General' : 'Seleccionar de lista (F3)',
                                onPressed: () {
                                  if (isCustomClient) {
                                    setState(() {
                                      _clientNameController.text = 'Público General';
                                      final generalPublic = clients.where((c) {
                                        final fullName = '${c.firstName} ${c.lastName}'.toLowerCase();
                                        return fullName.contains('publico general') || fullName.contains('público general');
                                      }).firstOrNull;
                                      _selectedClientId = generalPublic?.userId;
                                    });
                                  } else {
                                    _openClientSelectorModal(clients);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const Gap(4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          _selectedClientId != null ? '• Cliente ID asignado: ${_selectedClientId!}' : '• Sin ID vinculado (Público General libre)',
                          style: const TextStyle(fontSize: 7, color: AppColors.kNeutral600, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => _buildTextField(controller: _clientNameController, label: 'Cliente (F3)', icon: Icons.person_outline),
                error: (_, _) => _buildTextField(controller: _clientNameController, label: 'Cliente (F3)', icon: Icons.person_outline),
              ),
              const Gap(12),

              // Sale Status Dropdown
              _buildDropdown(
                label: 'Estatus de Venta',
                icon: Icons.bookmark_border,
                value: _selectedSaleStatus,
                items: const {'COMPLETED': 'Completada (Contado)', 'CREDIT': 'Crédito (Fiado)', 'LAYAWAY': 'Apartado (Layaway)'},
                onChanged: (val) => setState(() => _selectedSaleStatus = val ?? 'COMPLETED'),
              ),
              const Gap(12),

              // Payment Method & Account (Regular Sellers only pick Payment Method; Server & POS auto-bind their Shift's Account)
              accountsAsync.when(
                data: (accounts) {
                  final operationalAccounts = accounts.where((a) => !a.isCreditOrLoan).toList();
                  final selectableAccounts = operationalAccounts.isNotEmpty ? operationalAccounts : accounts;
                  final shiftAccountId = cashShiftsState.activeShift?.accountId;

                  if (selectableAccounts.isNotEmpty) {
                    final defaultAcc = selectableAccounts.firstWhere(
                      (a) => a.isDefault,
                      orElse: () =>
                          selectableAccounts.firstWhere((a) => a.name.toLowerCase().startsWith('caja general'), orElse: () => selectableAccounts.first),
                    );
                    if (!isAdmin) {
                      if (shiftAccountId != null && selectableAccounts.any((a) => a.id == shiftAccountId)) {
                        _selectedAccountId = shiftAccountId;
                      } else {
                        _selectedAccountId ??= defaultAcc.id;
                      }
                    } else {
                      _selectedAccountId ??= shiftAccountId ?? defaultAcc.id;
                    }
                  }

                  final paymentMethodWidget = paymentMethodsAsync.when(
                    data: (methods) {
                      if (_selectedPaymentMethodId == null && methods.isNotEmpty) {
                        final cashMethod = methods.firstWhere(
                          (m) => m.name.toLowerCase().contains('efectivo') || m.name.toLowerCase().contains('cash'),
                          orElse: () => methods.first,
                        );
                        _selectedPaymentMethodId = cashMethod.id;
                      }
                      final itemsMap = {for (var m in methods) m.id: m.name};
                      return _buildDropdown(
                        label: 'Método de Pago (F10)',
                        icon: Icons.payment,
                        value: _selectedPaymentMethodId,
                        items: itemsMap,
                        onChanged: (val) => setState(() {
                          _selectedPaymentMethodId = val;
                          _mixedPayments = [];
                        }),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, _) => const Text('Error métodos pago'),
                  );

                  // For a regular Seller (!isAdmin), do not show the Account dropdown at all — the shift's account is used automatically
                  final accountOrPaymentRow = !isAdmin
                      ? paymentMethodWidget
                      : Row(
                          children: [
                            Expanded(child: paymentMethodWidget),
                            const Gap(12),
                            Expanded(
                              child: _buildDropdown(
                                label: 'Cuenta Destino',
                                icon: Icons.account_balance_wallet_outlined,
                                value: _selectedAccountId,
                                items: {for (var a in selectableAccounts) a.id: a.isDefault ? '${a.name} ★' : a.name},
                                onChanged: (val) => setState(() => _selectedAccountId = val),
                              ),
                            ),
                          ],
                        );

                  final activeShift = cashShiftsState.activeShift;
                  final isLinkedToShift = activeShift != null && (shiftAccountId == null || _selectedAccountId == shiftAccountId);
                  String? adminShiftHint;
                  if (isAdmin) {
                    if (activeShift == null) {
                      adminShiftHint = 'Sin turno abierto: ingresará directo a esta cuenta.';
                    } else if (isLinkedToShift) {
                      adminShiftHint = 'Coincide con tu turno abierto: se sumará a tu corte actual.';
                    } else {
                      adminShiftHint = 'Cuenta distinta a tu caja abierta: entrará directo sin afectar tu turno.';
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      accountOrPaymentRow,
                      if (adminShiftHint != null) ...[
                        const Gap(6),
                        Row(
                          children: [
                            Icon(
                              isLinkedToShift ? Icons.point_of_sale_rounded : Icons.info_outline_rounded,
                              size: 13.5,
                              color: isLinkedToShift ? AppColors.kSuccess : AppColors.kPrimaryColor,
                            ),
                            const Gap(5),
                            Expanded(
                              child: AppText(
                                adminShiftHint,
                                fontSize: 11,
                                color: isLinkedToShift ? AppColors.kSuccess : AppColors.kNeutral600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Gap(8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.kPrimaryColor,
                              side: BorderSide(color: AppColors.kPrimaryColor.withValues(alpha: 0.45)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final currentCart = ref.read(cartProvider);
                              double rawSub = 0.0;
                              for (final i in currentCart) {
                                if (i.isPaid) rawSub += i.subtotal;
                              }
                              final total = (rawSub - _discountAmount).clamp(0.0, double.infinity);
                              _showMixedPaymentDialog(total);
                            },
                            icon: const Icon(Icons.call_split_rounded, size: 16),
                            label: Text(
                              _mixedPayments.isEmpty ? 'Pago Mixto / Dividir' : 'Editar Pago Mixto (${_mixedPayments.length})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_mixedPayments.isNotEmpty) ...[
                            const Gap(8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimary50.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _mixedPayments.map((p) => '${p.paymentMethodName ?? 'Pago'} \$${p.amount.toStringAsFixed(0)}').join(' + '),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.kPrimaryColor),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _mixedPayments = [];
                                          _amountPaidController.clear();
                                        });
                                      },
                                      child: const Icon(Icons.close_rounded, size: 15, color: AppColors.kPrimaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => const Text('Error cuentas'),
              ),
              const Gap(12),

              // Notes
              _buildTextField(controller: _notesController, label: 'Notas de Venta (Opcional)', icon: Icons.note_alt_outlined),
              const Gap(12),

              // Discount & Amount Paid
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _discountController,
                      focusNode: _discountFocusNode,
                      label: 'Descuento Global \$ (F8)',
                      icon: Icons.local_offer_outlined,
                      isNumber: true,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _buildTextField(
                      controller: _amountPaidController,
                      label: 'Monto Recibido \$',
                      icon: Icons.payments_outlined,
                      isNumber: true,
                      onChanged: (_) {
                        if (_mixedPayments.isNotEmpty) {
                          setState(() => _mixedPayments = []);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (finalTotal > 0 && _mixedPayments.isEmpty) ...[
                const Gap(8),
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickAmountChip(
                        label: 'Exacto (\$${finalTotal.toStringAsFixed(2)})',
                        isPrimary: true,
                        onTap: () {
                          _amountPaidController.text = finalTotal.toStringAsFixed(2);
                          setState(() => _mixedPayments = []);
                        },
                      ),
                      const Gap(6),
                      for (final preset in const [50, 100, 200, 500]) ...[
                        _buildQuickAmountChip(
                          label: '\$$preset',
                          onTap: () {
                            _amountPaidController.text = preset.toString();
                            setState(() => _mixedPayments = []);
                          },
                        ),
                        const Gap(6),
                      ],
                      if (_amountPaidController.text.isNotEmpty)
                        _buildQuickAmountChip(
                          label: 'Limpiar',
                          onTap: () {
                            _amountPaidController.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ],

              // Change calculation display
              if (_amountPaid > 0) ...[
                const Gap(16),
                Builder(
                  builder: (context) {
                    final isComplete = _selectedSaleStatus == 'COMPLETED';
                    final hasChange = _amountPaid >= finalTotal;
                    final difference = (_amountPaid - finalTotal).abs();

                    Color boxColor;
                    Color borderColor;
                    String title;
                    String amountText;

                    if (hasChange) {
                      boxColor = AppColors.kSuccess.withValues(alpha: 0.1);
                      borderColor = AppColors.kSuccess;
                      title = 'Cambio a devolver:';
                      amountText = '\$${changeGiven.toStringAsFixed(2)}';
                    } else if (isComplete) {
                      boxColor = AppColors.kWarning.withValues(alpha: 0.12);
                      borderColor = AppColors.kWarning;
                      title = 'Falta por pagar:';
                      amountText = '\$${difference.toStringAsFixed(2)}';
                    } else {
                      // Fiado o Apartado con abono parcial
                      boxColor = Colors.purple.withValues(alpha: 0.08);
                      borderColor = Colors.purple.shade300;
                      title = 'Anticipo: \$${_amountPaid.toStringAsFixed(2)} · Restante:';
                      amountText = '\$${difference.toStringAsFixed(2)}';
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: AppText(title, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                          ),
                          AppText(
                            amountText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: hasChange ? AppColors.kSuccess : (isComplete ? Colors.orange.shade800 : Colors.purple.shade700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const Gap(8),
              AppText(widget.businessName, fontSize: 10, color: AppColors.kNeutral600),
              const Gap(40),
            ],
          ),
        ),

        // 3. BOTTOM PANEL (SUMMARY & CHARGE BUTTON)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (_discountAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText('Subtotal (Pagados):', color: AppColors.kNeutral600),
                        AppText('\$${rawSubtotal.toStringAsFixed(2)}', color: AppColors.kNeutral600),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText('Artículos: ${_formatQty(totalItemsCount)}', fontSize: 14, color: AppColors.kNeutral600),
                    AppText('Total: \$${finalTotal.toStringAsFixed(2)}', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                  ],
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoadingSale ? null : () => _processSale(finalTotal, cartItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoadingSale)
                          const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        else
                          const Icon(Icons.point_of_sale_rounded, size: 22, color: Colors.white),
                        const Gap(10),
                        const Text(
                          'Cobrar (F12)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widget: Cart Item with isPaid toggle & Keyboard selection ---
  Widget _buildCartItem(CreateSaleDetailInnerDto item, {required int index, required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCartItemIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimary50.withValues(alpha: 0.45) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.kPrimaryColor : AppColors.kNeutral200, width: isSelected ? 1.8 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.kPrimaryColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.kNeutral100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.kNeutral300),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: AdaptedFile.network(item.imageUrl!).getWidget(fit: BoxFit.cover),
                    )
                  : const Icon(Icons.inventory_2_outlined, color: AppColors.kNeutral500, size: 24),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Paid Badge Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: AppText(item.productNameSnapshot, fontWeight: FontWeight.bold, fontSize: 14, maxLines: 2)),
                      const Gap(8), // Space between name and badge
                      InkWell(
                        onTap: () {
                          ref.read(cartProvider.notifier).updateIsPaid(item.id, !item.isPaid);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isPaid ? AppColors.kSuccess.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: item.isPaid ? AppColors.kSuccess : Colors.orange),
                          ),
                          child: Text(
                            item.isPaid ? 'Pagado' : 'No pagado',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isPaid ? AppColors.kSuccess : Colors.orange.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8), // Increased space before price and controls
                  // Price, Edit Icon, and Price Type Row
                  Row(
                    children: [
                      AppText('\$${item.unitPrice.toStringAsFixed(2)} c/u', fontSize: 12, color: AppColors.kNeutral600),
                      const Gap(4),
                      Tooltip(
                        message: 'Editar precio (F7)',
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedCartItemIndex = index);
                            _showEditPriceDialog(item);
                          },
                          child: const Icon(Icons.edit, size: 14, color: AppColors.kPrimaryColor),
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.kNeutral200, borderRadius: BorderRadius.circular(4)),
                        child: AppText(item.priceType, fontSize: 9, color: AppColors.kNeutral700),
                      ),
                    ],
                  ),
                  const Gap(8),
                  // Quantity Controls
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _selectedCartItemIndex = index);
                          ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.kNeutral300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Tooltip(
                        message: 'Editar cantidad o granel (F6)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            setState(() => _selectedCartItemIndex = index);
                            _showEditQuantityDialog(item);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.kNeutral100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.kNeutral200),
                            ),
                            child: AppText(_formatQty(item.quantity), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _selectedCartItemIndex = index);
                          final updated = ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                          if (!updated && item.availableStock != null) {
                            SnackbarUtil.showWarning(
                              context,
                              'Stock máximo alcanzado para ${item.productNameSnapshot} (${_formatQty(item.availableStock!)} disponibles)',
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.kNeutral300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.add, size: 14),
                        ),
                      ),
                      if (isSelected) ...[
                        const Gap(8),
                        const Flexible(
                          child: Text(
                            '+/- · F6 Cant · F7 \$',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.kPrimaryColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Gap(8),
            // Subtotal & Delete Action Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText('\$${item.subtotal.toStringAsFixed(2)}', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.kPrimaryColor),
                const Gap(12),
                Tooltip(
                  message: 'Eliminar del carrito (Supr)',
                  child: InkWell(
                    onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.kNeutral500, size: 20),
        filled: true,
        fillColor: AppColors.kNeutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kNeutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kNeutral300),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required Map<String, String> items,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.kNeutral500, size: 20),
        filled: true,
        fillColor: AppColors.kNeutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kNeutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kNeutral300),
        ),
      ),
      items: items.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildQuickAmountChip({
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.kPrimary50 : AppColors.kNeutral100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppColors.kPrimaryColor.withValues(alpha: 0.45) : AppColors.kNeutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
            color: isPrimary ? AppColors.kPrimaryColor : AppColors.kNeutral700,
          ),
        ),
      ),
    );
  }
}
