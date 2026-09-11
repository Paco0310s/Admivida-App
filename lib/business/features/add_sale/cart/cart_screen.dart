import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/cart/cart_service.dart';
import 'package:admivida/business/features/add_sale/cart/models/create_sale_dto.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/sales_provider.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CartScreen extends ConsumerStatefulWidget {
  final String businessId;
  const CartScreen({super.key, required this.businessId});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // --- Controllers for Checkout Form ---
  final TextEditingController _clientNameController = TextEditingController(text: 'Público General');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();

  // --- State Variables ---
  String? _selectedSellerId;
  String? _selectedPaymentMethodId;
  String? _selectedAccountId;
  String _selectedSaleStatus = 'COMPLETED'; // Default to COMPLETED
  String? _selectedClientId;

  double _discountAmount = 0.0;
  double _amountPaid = 0.0;
  bool _isLoadingSale = false;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_updateCalculations);
    _amountPaidController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    setState(() {
      _discountAmount = double.tryParse(_discountController.text) ?? 0.0;
      _amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    });
  }

  // --- Modal to Select Client ---
  void _openClientSelectorModal(List<dynamic> clients) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Seleccionar Cliente', fontWeight: FontWeight.bold, fontSize: 18),
              const Gap(12),
              const AppText('Selecciona un cliente de la lista:', fontSize: 12, color: AppColors.kNeutral600),
              const Gap(8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final c = clients[index];
                    final fullName = '${c.firstName} ${c.lastName}';
                    final isGeneralPublic = fullName.toLowerCase().contains('público general') || fullName.toLowerCase().contains('publico general');

                    // Comparamos directamente con el ID del cliente de la base de datos
                    final isSelected = _selectedClientId == c.userId;

                    return ListTile(
                      leading: Icon(
                        isGeneralPublic ? Icons.public : Icons.person_outline,
                        color: isGeneralPublic ? AppColors.kPrimaryColor : AppColors.kNeutral700,
                      ),
                      title: Text(fullName),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.kPrimaryColor) : null,
                      onTap: () {
                        setState(() {
                          _selectedClientId = c.userId; // ¡Enviamos siempre el ID real!
                          _clientNameController.text = fullName;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Dialog to Prompt Amount Paid if empty ---
  Future<bool> _showAmountPaidDialog(double finalTotal) async {
    final TextEditingController dialogAmountController = TextEditingController(text: finalTotal.toStringAsFixed(2));
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: AppText('Monto Recibido', fontWeight: FontWeight.bold, fontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('Total a pagar: \$${finalTotal.toStringAsFixed(2)}', fontSize: 14, color: AppColors.kNeutral600),
            const Gap(12),
            TextField(
              controller: dialogAmountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                labelText: '¿Con cuánto paga el cliente?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final paid = double.tryParse(dialogAmountController.text);
              if (paid != null && paid >= finalTotal) {
                setState(() {
                  _amountPaidController.text = paid.toStringAsFixed(2);
                  _amountPaid = paid;
                });
                confirmed = true;
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('El monto recibido no puede ser menor al total'), backgroundColor: AppColors.kWarning));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
            child: const Text('Confirmar & Cobrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return confirmed;
  }

  // --- Dialog to Edit Item Price ---
  Future<void> _showEditPriceDialog(CreateSaleDetailInnerDto item) async {
    final TextEditingController priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('Editar Precio', fontWeight: FontWeight.bold, fontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(item.productNameSnapshot, fontSize: 14, color: AppColors.kNeutral600),
            const Gap(12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                labelText: 'Nuevo Precio Unitario',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice >= 0) {
                ref.read(cartProvider.notifier).updateUnitPrice(item.id, newPrice);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Ticket Preview Dialog ---
  void _showTicketDialog(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.kSuccess, size: 28),
            Gap(8),
            AppText('¡Venta Exitosa!', fontWeight: FontWeight.bold, fontSize: 18),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText('Folio ID: ${sale.id}', fontSize: 12, color: AppColors.kNeutral600),
                AppText('Estatus: ${sale.status}', fontSize: 12, color: AppColors.kNeutral600),
                AppText('Vendedor: ${sale.sellerName ?? 'N/D'}', fontSize: 12, color: AppColors.kNeutral600),
                AppText('Cliente: ${sale.clientNameSnapshot}', fontSize: 12, color: AppColors.kNeutral600),
                const Divider(height: 20),
                const AppText('Resumen de Productos:', fontWeight: FontWeight.bold, fontSize: 14),
                const Gap(8),
                // Al usar el modelo, el mapeo de los detalles queda súper limpio:
                ...sale.details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${detail.quantity}x ${detail.productNameSnapshot} ${!detail.isPaid ? '(No pagado)' : ''}',
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
                    AppText('\$${sale.totalPriceSnapshot.toStringAsFixed(2)}', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.kPrimaryColor),
                  ],
                ),
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
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              NavigationService.pop(context); // Close the dialog
              ref.read(cartProvider.notifier).clearCart();

              // Clean up the checkout form fields
              _clientNameController.text = 'Público General';
              _notesController.clear();
              _discountController.clear();
              _amountPaidController.clear();

              ref.invalidate(salesListProvider(widget.businessId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Process Sale Action ---
  Future<void> _processSale(double finalTotal, List<CreateSaleDetailInnerDto> cartItems) async {
    if (_selectedAccountId == null || _selectedPaymentMethodId == null || _selectedSellerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona vendedor, método de pago y cuenta destino'), backgroundColor: AppColors.kWarning));
      return;
    }

    // If amount paid is empty for a completed sale, pop up the quick dialog automatically
    if (_amountPaid <= 0 && _selectedSaleStatus == 'COMPLETED') {
      final bool paidConfirmed = await _showAmountPaidDialog(finalTotal);
      if (!paidConfirmed) return; // Cancelled by user
    }

    if (_amountPaid > 0 && _amountPaid < finalTotal && _selectedSaleStatus == 'COMPLETED') {
      if (!mounted) return;
      SnackbarUtil.showWarning(context, 'El monto pagado es menor al total en venta completada');
      return;
    }

    setState(() => _isLoadingSale = true);

    try {
      final clientNameToUse = _clientNameController.text.trim().isEmpty ? 'Público General' : _clientNameController.text.trim();

      // 1. Instanciamos el DTO unificado
      final salePayload = CreateSaleDto(
        businessId: widget.businessId,
        sellerUserId: _selectedSellerId!,
        accountId: _selectedAccountId!,
        paymentMethodId: _selectedPaymentMethodId!,
        clientUserId: _selectedClientId,
        clientNameSnapshot: clientNameToUse,
        status: _selectedSaleStatus,
        discountAmount: _discountAmount,
        amountPaid: _amountPaid > 0 ? _amountPaid : (_selectedSaleStatus == 'COMPLETED' ? finalTotal : 0.0),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        // Opcional: Si tienes acceso a la ubicación y hora, pásalos aquí
        // latitude: 20.357812,
        // longitude: -102.775833,
        // soldAt: DateTime.now(),
        details: cartItems,
      );

      // 2. Lo enviamos al servicio
      final saleResult = await CartService.createSale(salePayload);

      if (!mounted) return;

      // 2. Handle success and failure using EitherUtil pattern
      saleResult.when(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar la venta: ${failure.message}'), backgroundColor: Colors.red));
        },
        (saleResponse) {
          // 3. Clear cart and show ticket on success
          ref.read(cartProvider.notifier).clearCart();
          _showTicketDialog(context, saleResponse);
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error inesperado al procesar la venta'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingSale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);

    double rawSubtotal = 0.0;
    double totalItemsCount = 0;
    for (var item in cartItems) {
      totalItemsCount += item.quantity;
      if (item.isPaid) {
        rawSubtotal += item.subtotal;
      }
    }

    final accountsAsync = ref.watch(accountsProvider(businessId: widget.businessId));
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final sellersAsync = ref.watch(businessSellersProvider(widget.businessId));
    final clientsAsync = ref.watch(businessClientsProvider(widget.businessId));

    final finalTotal = (rawSubtotal - _discountAmount).clamp(0.0, double.infinity);
    final changeGiven = (_amountPaid > finalTotal) ? (_amountPaid - finalTotal) : 0.0;

    if (cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_outlined, size: 80, color: AppColors.kNeutral400),
            Gap(16),
            AppText('El carrito está vacío', fontSize: 18, color: AppColors.kNeutral600),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 1. PRODUCTS LIST (Scrollable)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppText('Productos en Ticket', fontWeight: FontWeight.bold, fontSize: 16),
              const Gap(12),
              ...cartItems.map((item) => _buildCartItem(item)),

              const Gap(24),
              const Divider(color: AppColors.kNeutral300),
              const Gap(16),

              // 2. CHECKOUT FORM
              AppText('Detalles del Cobro', fontWeight: FontWeight.bold, fontSize: 16),
              const Gap(16),

              // Seller Dropdown
              sellersAsync.when(
                data: (sellers) {
                  _selectedSellerId ??= sellers.isNotEmpty ? sellers.first.userId : null;
                  final itemsMap = {for (var s in sellers) s.userId: '${s.firstName} ${s.lastName}'};
                  return _buildDropdown(
                    label: 'Vendedor',
                    icon: Icons.person_outline,
                    value: _selectedSellerId,
                    items: itemsMap,
                    onChanged: (val) => setState(() => _selectedSellerId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Error al cargar vendedores'),
              ),
              const Gap(12),

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
                            child: _buildTextField(controller: _clientNameController, label: 'Cliente (Snapshot / Nombre)', icon: Icons.person_outline),
                          ),
                          const Gap(8),
                          IconButton(
                            icon: const Icon(Icons.search, color: AppColors.kPrimaryColor),
                            tooltip: 'Seleccionar de lista',
                            onPressed: () => _openClientSelectorModal(clients),
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
                loading: () => _buildTextField(controller: _clientNameController, label: 'Cliente', icon: Icons.person_outline),
                error: (_, _) => _buildTextField(controller: _clientNameController, label: 'Cliente', icon: Icons.person_outline),
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

              // Payment Method & Account (Defaulting Cash & Caja General)
              Row(
                children: [
                  Expanded(
                    child: paymentMethodsAsync.when(
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
                          label: 'Método de Pago',
                          icon: Icons.payment,
                          value: _selectedPaymentMethodId,
                          items: itemsMap,
                          onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, _) => const Text('Error métodos pago'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: accountsAsync.when(
                      data: (accounts) {
                        if (_selectedAccountId == null && accounts.isNotEmpty) {
                          final defaultAcc = accounts.firstWhere((a) => a.name.toLowerCase().startsWith('caja general'), orElse: () => accounts.first);
                          _selectedAccountId = defaultAcc.id;
                        }
                        final itemsMap = {for (var a in accounts) a.id: a.name};
                        return _buildDropdown(
                          label: 'Cuenta Destino',
                          icon: Icons.account_balance_wallet_outlined,
                          value: _selectedAccountId,
                          items: itemsMap,
                          onChanged: (val) => setState(() => _selectedAccountId = val),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, _) => const Text('Error cuentas'),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // Notes
              _buildTextField(controller: _notesController, label: 'Notas de Venta (Opcional)', icon: Icons.note_alt_outlined),
              const Gap(12),

              // Discount & Amount Paid
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(controller: _discountController, label: 'Descuento Global \$', icon: Icons.local_offer_outlined, isNumber: true),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _buildTextField(controller: _amountPaidController, label: 'Monto Recibido \$', icon: Icons.payments_outlined, isNumber: true),
                  ),
                ],
              ),

              // Change calculation display
              if (_amountPaid > 0) ...[
                const Gap(16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: changeGiven > 0 ? AppColors.kSuccess.withValues(alpha: 0.1) : AppColors.kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: changeGiven > 0 ? AppColors.kSuccess : AppColors.kWarning),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText('Cambio a devolver:', fontWeight: FontWeight.bold),
                      AppText('\$${changeGiven.toStringAsFixed(2)}', fontWeight: FontWeight.bold, fontSize: 18),
                    ],
                  ),
                ),
              ],
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
                    AppText('Artículos: ${totalItemsCount.toInt()}', fontSize: 14, color: AppColors.kNeutral600),
                    AppText('Total: \$${finalTotal.toStringAsFixed(2)}', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                  ],
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingSale ? null : () => _processSale(finalTotal, cartItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoadingSale
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Cobrar Venta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  // --- Helper Widget: Cart Item with isPaid toggle ---
  Widget _buildCartItem(CreateSaleDetailInnerDto item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
                    InkWell(
                      onTap: () => _showEditPriceDialog(item),
                      child: const Icon(Icons.edit, size: 14, color: AppColors.kPrimaryColor),
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
                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.kNeutral300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AppText('${item.quantity.toInt()}', fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.kNeutral300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, size: 14),
                      ),
                    ),
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
              InkWell(
                onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: controller,
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
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
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
}
