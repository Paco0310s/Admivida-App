import 'package:admivida/business/features/add_sale/cart/cart_provider.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_dto.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

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
  String? _selectedPaymentMethodId;
  String? _selectedAccountId;

  double _discountAmount = 0.0;
  double _amountPaid = 0.0;

  @override
  void initState() {
    super.initState();
    // Listeners to update calculations in real-time
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

  // --- Process Sale Action ---
  void _processSale(double finalTotal) {
    // 1. Basic Validations
    if (_selectedAccountId == null || _selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona método de pago y cuenta destino'), backgroundColor: AppColors.kWarning));
      return;
    }

    if (_amountPaid > 0 && _amountPaid < finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El monto pagado es menor al total'), backgroundColor: AppColors.kWarning));
      return;
    }

    // 2. Build the DTO for NestJS
    /*
    final saleDto = CreateSaleDto(
      businessId: 'YOUR_BUSINESS_ID',
      sellerUserId: 'LOGGED_IN_USER_ID',
      accountId: _selectedAccountId!,
      paymentMethodId: _selectedPaymentMethodId!,
      paymentMethodCode: 'CASH', // Extract from your payment method list
      clientNameSnapshot: _clientNameController.text.trim(),
      totalPriceSnapshot: finalTotal,
      discountAmount: _discountAmount,
      amountPaid: _amountPaid,
      changeGiven: _amountPaid > finalTotal ? _amountPaid - finalTotal : 0.0,
      notes: _notesController.text.trim(),
      items: ref.read(cartProvider),
    );
    
    // Call your API / Provider here
    */

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta Procesada Exitosamente'), backgroundColor: AppColors.kSuccess));
    ref.read(cartProvider.notifier).clearCart();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final rawSubtotal = ref.watch(cartTotalProvider);
    final totalItems = ref.watch(cartItemCountProvider);

    // Final calculations
    final finalTotal = (rawSubtotal - _discountAmount).clamp(0.0, double.infinity);
    final changeGiven = (_amountPaid > finalTotal) ? (_amountPaid - finalTotal) : 0.0;

    return _buildContent(cartItems, rawSubtotal, finalTotal, changeGiven, totalItems);
    // return AppScaffold(
    //   title: 'Cobrar Venta',
    //   appBar: AppBar(
    //     title: AppText('Carrito & Cobro', color: AppColors.kNeutral100),
    //     backgroundColor: AppColors.kPrimaryColor,
    //     iconTheme: const IconThemeData(color: AppColors.kNeutral100),
    //     actions: [
    //       if (cartItems.isNotEmpty)
    //         IconButton(
    //           icon: const Icon(Icons.delete_sweep),
    //           tooltip: 'Vaciar Carrito',
    //           onPressed: () => ref.read(cartProvider.notifier).clearCart(),
    //         ),
    //     ],
    //   ),
    //   mobile: _buildContent(cartItems, rawSubtotal, finalTotal, changeGiven, totalItems),
    //   tablet: _buildContent(cartItems, rawSubtotal, finalTotal, changeGiven, totalItems),
    //   desktop: _buildContent(cartItems, rawSubtotal, finalTotal, changeGiven, totalItems),
    // );
  }

  Widget _buildContent(List<CreateSaleDetailInnerDto> cartItems, double rawSubtotal, double finalTotal, double changeGiven, double totalItems) {
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
        // 1. LIST OF PRODUCTS (Scrollable)
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

              // 2. CHECKOUT FORM (Client, Notes, Discount, Payment)
              AppText('Detalles del Cobro', fontWeight: FontWeight.bold, fontSize: 16),
              const Gap(16),

              // Client Name
              _buildTextField(controller: _clientNameController, label: 'Cliente (Opcional)', icon: Icons.person_outline),
              const Gap(12),

              // Notes
              _buildTextField(controller: _notesController, label: 'Notas de Venta (Opcional)', icon: Icons.note_alt_outlined),
              const Gap(12),

              // Payment Method & Account (Mocked Selectors for UI)
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Método de Pago',
                      icon: Icons.payment,
                      value: _selectedPaymentMethodId,
                      items: {'efectivo-id': 'Efectivo', 'tarjeta-id': 'Tarjeta'},
                      onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Cuenta Destino',
                      icon: Icons.account_balance_wallet_outlined,
                      value: _selectedAccountId,
                      items: {'caja-id': 'Caja Principal', 'banco-id': 'Banco'},
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                  ),
                ],
              ),
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

              const Gap(40), // Bottom padding
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
                        AppText('Subtotal:', color: AppColors.kNeutral600),
                        AppText('\$${rawSubtotal.toStringAsFixed(2)}', color: AppColors.kNeutral600),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText('Artículos: ${totalItems.toInt()}', fontSize: 14, color: AppColors.kNeutral600),
                    AppText('Total: \$${finalTotal.toStringAsFixed(2)}', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                  ],
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _processSale(finalTotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
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

  // --- Helper Widget: Cart Item ---
  Widget _buildCartItem(CreateSaleDetailInnerDto item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
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

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(item.productNameSnapshot, fontWeight: FontWeight.bold, fontSize: 14, maxLines: 2),
                const Gap(4),
                // Editable Unit Price Row
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

          // Subtotal & Delete
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

  // --- Helper Widget: Custom TextField ---
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

  // --- Helper Widget: Custom Dropdown ---
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
              child: Text(e.value, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
