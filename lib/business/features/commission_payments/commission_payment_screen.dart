import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/commission_payments/commission_payment_service.dart';
import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/commission_payments/models/create_commission_payment_dto.dart';
import 'package:admivida/business/features/commission_payments/models/pending_commission_item.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CommissionPaymentScreen extends ConsumerStatefulWidget {
  const CommissionPaymentScreen({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<CommissionPaymentScreen> createState() => _CommissionPaymentScreenState();
}

class _CommissionPaymentScreenState extends ConsumerState<CommissionPaymentScreen> {
  String? _selectedSellerId;
  String? _sourceAccountId; // Business account (Expense)
  String? _destinationAccountId; // Seller account (Income)
  String? _paymentMethodId; // Payment method (Cash, Transfer, etc.)
  bool _isSubmitting = false;
  bool _selectAllState = false; // Tracks master checkbox state

  // Local state for the products
  List<PendingCommissionItem> _pendingItems = [];

  // Maps to track which items are selected and their editable text controllers
  final Map<String, bool> _selectedCheckboxes = {};
  final Map<String, TextEditingController> _itemControllers = {};

  // Controllers for the grand total and notes
  final TextEditingController _totalController = TextEditingController(text: '0.00');
  final TextEditingController _notesController = TextEditingController();

  // Tracks the pure calculated sum of selected items to compare against manual edits
  double _calculatedPureTotal = 0.0;

  @override
  void dispose() {
    _totalController.dispose();
    _notesController.dispose();
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Calculates the total by summing only the selected items and updates difference meters
  void _calculateTotal() {
    double pureSum = 0.0;
    for (final item in _pendingItems) {
      if (_selectedCheckboxes[item.saleDetailId] == true) {
        final textValue = _itemControllers[item.saleDetailId]?.text ?? '0';
        pureSum += double.tryParse(textValue) ?? 0.0;
      }
    }

    setState(() {
      _calculatedPureTotal = pureSum;
      // If it's the first initialization or user hasn't overridden it manually with custom logic,
      // we keep total synced, but we allow them to change it freely.
      if (_totalController.text == '0.00' || _totalController.text.isEmpty) {
        _totalController.text = pureSum.toStringAsFixed(2);
      }
    });
  }

  /// Toggles select all items
  void _toggleSelectAll(bool? value) {
    final newValue = value ?? false;
    setState(() {
      _selectAllState = newValue;
      for (final item in _pendingItems) {
        _selectedCheckboxes[item.saleDetailId] = newValue;
      }
      _calculateTotal();

      // Auto-update total to match pure sum when selecting all
      if (newValue) {
        _totalController.text = _calculatedPureTotal.toStringAsFixed(2);
      } else {
        _totalController.text = '0.00';
      }
    });
  }

  /// Safely initializes controllers when new data arrives from the provider
  void _initializeItems(List<PendingCommissionItem> items) {
    if (!mounted) return;

    setState(() {
      _pendingItems = items;
      _selectedCheckboxes.clear();
      _selectAllState = false;

      // Dispose old controllers
      for (final controller in _itemControllers.values) {
        controller.dispose();
      }
      _itemControllers.clear();

      for (final item in items) {
        _selectedCheckboxes[item.saleDetailId] = false;

        final controller = TextEditingController(text: item.commission.toStringAsFixed(2));
        controller.addListener(() => _calculateTotal());
        _itemControllers[item.saleDetailId] = controller;
      }
      _calculateTotal();
    });
  }

  /// Handles the POST request to pay commissions
  Future<void> _submitPayment() async {
    final selectedDetails = _pendingItems.where((item) => _selectedCheckboxes[item.saleDetailId] == true).toList();

    if (selectedDetails.isEmpty) {
      SnackbarUtil.showError(context, 'Seleccione al menos una comisión para efectuar el pago.');
      return;
    }

    final double finalTotal = double.tryParse(_totalController.text) ?? 0.0;
    if (finalTotal <= 0) {
      SnackbarUtil.showError(context, 'El monto final a pagar debe ser mayor a cero.');
      return;
    }

    if (_selectedSellerId == null) {
      SnackbarUtil.showError(context, 'Debe seleccionar al colaborador correspondiente.');
      return;
    }

    if (_sourceAccountId == null || _destinationAccountId == null || _paymentMethodId == null) {
      SnackbarUtil.showError(context, 'Complete la configuración financiera (Cuentas y Método de Pago).');
      return;
    }

    setState(() => _isSubmitting = true);

    final itemsDto = selectedDetails.map((item) {
      final amountStr = _itemControllers[item.saleDetailId]?.text ?? '0';
      final amount = double.tryParse(amountStr) ?? item.commission;
      return CommissionPaymentItemDto(saleDetailId: item.saleDetailId, amountToPay: amount);
    }).toList();

    final dto = CreateCommissionPaymentDto(
      sellerUserId: _selectedSellerId!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      items: itemsDto,
      sourceAccountId: _sourceAccountId!,
      destinationAccountId: _destinationAccountId!,
      paymentMethodId: _paymentMethodId!,
      paidAmount: finalTotal,
    );

    final result = await CommissionPaymentsService.createCommissionPayment(dto, widget.businessId);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      (failure) {
        SnackbarUtil.showError(context, failure.message);
      },
      (successResponse) {
        SnackbarUtil.showSuccess(context, 'Pago de comisiones registrado correctamente.');
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(businessSellersProvider(widget.businessId));
    final accountsBusinessAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));
    final accountsUserAsync = ref.watch(accountsUserProvider(userId: _selectedSellerId)); // Fetches user accounts for the current logged-in user
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final pendingProvider = _selectedSellerId != null ? pendingCommissionsProvider(businessId: widget.businessId, sellerId: _selectedSellerId!) : null;

    final pendingAsync = pendingProvider != null ? ref.watch(pendingProvider) : const AsyncValue.data(<PendingCommissionItem>[]);

    if (pendingProvider != null) {
      ref.listen<AsyncValue<List<PendingCommissionItem>>>(pendingProvider, (previous, next) {
        next.whenData((items) => _initializeItems(items));
      });
    }

    return AppScaffold(
      title: 'Dispersión de Comisiones',
      appBar: AppBar(
        title: const AppText('Pago de Comisiones', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(sellersAsync, accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync, pendingAsync),
      tablet: _buildContent(sellersAsync, accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync, pendingAsync),
      desktop: _buildContent(sellersAsync, accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync, pendingAsync),
      marginDesktop: 160,
    );
  }

  Widget _buildContent(
    AsyncValue<List<BusinessStaffModel>> sellersAsync,
    AsyncValue accountsBusinessAsync,
    AsyncValue accountsUserAsync,
    AsyncValue paymentMethodsAsync,
    AsyncValue<List<PendingCommissionItem>> pendingAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSellerSelector(sellersAsync),
          const Gap(16),

          if (_selectedSellerId != null) ...[
            _buildPendingList(pendingAsync),
            const Gap(16),
            _buildFinancialConfigCard(accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync),
            const Gap(16),
            _buildSummaryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerSelector(AsyncValue<List<BusinessStaffModel>> sellersAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Colaborador / Vendedor', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          sellersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error al cargar equipo: $err'),
            data: (sellers) {
              if (sellers.isEmpty) {
                const Text('No se encontraron colaboradores registrados.');
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                hint: const Text('Seleccionar miembro del personal...'),
                initialValue: _selectedSellerId,
                items: sellers.map((seller) {
                  return DropdownMenuItem<String>(value: seller.userId, child: Text(seller.fullName));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSellerId = val;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList(AsyncValue<List<PendingCommissionItem>> pendingAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText('Comisiones Pendientes de Pago', fontWeight: FontWeight.bold, fontSize: 16),
              if (_pendingItems.isNotEmpty)
                Row(
                  children: [
                    const Text('Seleccionar todos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Checkbox(value: _selectAllState, activeColor: AppColors.kPrimaryColor, onChanged: _toggleSelectAll),
                  ],
                ),
            ],
          ),
          const Gap(12),
          pendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Text('Error al procesar elementos: $err'),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Este colaborador no cuenta con comisiones pendientes por liquidar.')),
                );
              }
              return Column(children: _pendingItems.map((item) => _buildCommissionItem(item)).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionItem(PendingCommissionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: _selectedCheckboxes[item.saleDetailId] ?? false,
            activeColor: AppColors.kPrimaryColor,
            onChanged: (val) {
              setState(() {
                _selectedCheckboxes[item.saleDetailId] = val ?? false;
                _calculateTopSelectAllState();
                _calculateTotal();
              });
            },
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(item.productName, fontWeight: FontWeight.w600, fontSize: 14),
                AppText('Cant: ${item.quantity} - Venta: ${item.soldAt.day}/${item.soldAt.month}/${item.soldAt.year}', color: Colors.grey, fontSize: 12),
              ],
            ),
          ),
          const Gap(8),
          Expanded(
            flex: 1,
            child: AppTextField(
              text: '',
              hintText: '0.00',
              controller: _itemControllers[item.saleDetailId],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateTopSelectAllState() {
    if (_pendingItems.isEmpty) {
      _selectAllState = false;
      return;
    }
    final allChecked = _pendingItems.every((item) => _selectedCheckboxes[item.saleDetailId] == true);
    _selectAllState = allChecked;
  }

  Widget _buildFinancialConfigCard(AsyncValue accountsBusinessAsync, AsyncValue accountsUserAsync, AsyncValue paymentMethodsAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Origen y Destino de Fondos', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),

          // Source Account
          accountsBusinessAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error al cargar cuentas: $e'),
            data: (accounts) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Cuenta de Origen (Retiro del Negocio)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Seleccionar cuenta...'),
                initialValue: _sourceAccountId,
                items: accounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(value: account.id, child: Text(account.name));
                }).toList(),
                onChanged: (val) => setState(() => _sourceAccountId = val),
              );
            },
          ),
          const Gap(12),

          // Destination Account
          accountsUserAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (accounts) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Cuenta de Destino (Abono al Colaborador)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Seleccionar cuenta destino...'),
                initialValue: _destinationAccountId,
                items: accounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(value: account.id, child: Text(account.name));
                }).toList(),
                onChanged: (val) => setState(() => _destinationAccountId = val),
              );
            },
          ),
          const Gap(12),

          // Payment Method
          paymentMethodsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error al cargar métodos: $e'),
            data: (methods) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Método de Operación',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Seleccionar método...'),
                initialValue: _paymentMethodId,
                items: methods.map<DropdownMenuItem<String>>((method) {
                  return DropdownMenuItem<String>(value: method.id, child: Text(method.name));
                }).toList(),
                onChanged: (val) => setState(() => _paymentMethodId = val),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final double userTypedTotal = double.tryParse(_totalController.text) ?? 0.0;
    final double difference = userTypedTotal - _calculatedPureTotal;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Resumen y Desglose Financiero', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          AppTextField(
            text: 'Observaciones de la Transacción',
            hintText: 'Ej. Liquidación de comisiones correspondientes al periodo',
            controller: _notesController,
          ),
          const Gap(12),
          AppTextField(
            text: 'Monto Final a Pagar (Editable)',
            hintText: '0.00',
            controller: _totalController,
            onChanged: (val) => setState(() {}), // Triggers rebuild to update real-time diff metrics
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          const Gap(16),

          // Desglose visual detallado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Suma de Comisiones:', '\$ ${_calculatedPureTotal.toStringAsFixed(2)}'),
                const Divider(height: 16),
                _buildSummaryRow('Monto que se pagará:', '\$ ${userTypedTotal.toStringAsFixed(2)}', isBold: true),
                const Divider(height: 16),
                _buildSummaryRow(
                  'Diferencia (Ajuste):',
                  '${difference >= 0 ? '+' : ''}\$ ${difference.toStringAsFixed(2)}',
                  textColor: difference == 0 ? Colors.grey : (difference > 0 ? Colors.orange.shade800 : Colors.blue.shade800),
                  isBold: true,
                ),
              ],
            ),
          ),

          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar y Registrar Pago', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        Text(
          value,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14, color: textColor ?? Colors.black87),
        ),
      ],
    );
  }
}
